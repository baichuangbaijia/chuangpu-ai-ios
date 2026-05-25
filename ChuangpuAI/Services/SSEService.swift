import Foundation

/// SSE流式对话服务
class SSEService: NSObject, URLSessionDataDelegate {
    static let shared = SSEService()
    
    private var currentTask: URLSessionDataTask?
    private var session: URLSession?
    private var buffer = ""
    private var currentContent = ""
    private var onChunk: ((String) -> Void)?
    private var onComplete: ((String) -> Void)?
    private var onError: ((Error) -> Void)?
    private var timeoutTimer: Timer?
    private var lastChunkTime: Date = Date()
    
    private let chatURL = "https://ai.xianbaba188.cn/agent/api/chat/completions"
    
    /// 开始SSE流式对话
    func startChat(
        messages: [[String: String]],
        sessionId: String?,
        model: String,
        onChunk: @escaping (String) -> Void,
        onComplete: @escaping (String) -> Void,
        onError: @escaping (Error) -> Void
    ) {
        self.onChunk = onChunk
        self.onComplete = onComplete
        self.onError = onError
        self.currentContent = ""
        self.buffer = ""
        self.lastChunkTime = Date()
        
        guard let url = URL(string: chatURL) else {
            onError(APIError.invalidURL)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
        
        if let token = UserDefaults.standard.string(forKey: Constants.tokenKey) {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        var body: [String: Any] = [
            "model": model,
            "messages": messages,
            "stream": true
        ]
        if let sessionId = sessionId {
            body["session_id"] = sessionId
        }
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            onError(error)
            return
        }
        
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 120
        config.timeoutIntervalForResource = 300
        
        session = URLSession(configuration: config, delegate: self, delegateQueue: .main)
        currentTask = session?.dataTask(with: request)
        currentTask?.resume()
        
        startTimeoutTimer()
    }
    
    /// 取消当前请求
    func cancel() {
        stopTimeoutTimer()
        currentTask?.cancel()
        currentTask = nil
        session?.invalidateAndCancel()
        session = nil
    }
    
    private func startTimeoutTimer() {
        stopTimeoutTimer()
        // 30秒没收到新数据就超时
        timeoutTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            let elapsed = Date().timeIntervalSince(self.lastChunkTime)
            if elapsed > 30 {
                self.handleTimeout()
            }
        }
    }
    
    private func stopTimeoutTimer() {
        timeoutTimer?.invalidate()
        timeoutTimer = nil
    }
    
    private func handleTimeout() {
        cancel()
        if !currentContent.isEmpty {
            onComplete?(currentContent)
        } else {
            onError?(APIError.serverError(408))
        }
    }
    
    // MARK: - URLSessionDataDelegate
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        lastChunkTime = Date()
        
        guard let text = String(data: data, encoding: .utf8) else { return }
        buffer += text
        
        // 按行解析SSE数据
        let lines = buffer.components(separatedBy: "\n")
        
        // 最后一行可能不完整，保留在buffer中
        if !buffer.hasSuffix("\n") {
            buffer = lines.last ?? ""
        } else {
            buffer = ""
        }
        
        for line in lines.dropLast(buffer.isEmpty ? 0 : 1) {
            processLine(line)
        }
    }
    
    private func processLine(_ line: String) {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        
        // 空行跳过
        guard !trimmed.isEmpty else { return }
        
        // SSE数据行
        if trimmed.hasPrefix("data: ") {
            let jsonStr = String(trimmed.dropFirst(6)).trimmingCharacters(in: .whitespaces)
            
            // 流结束标记
            if jsonStr == "[DONE]" {
                stopTimeoutTimer()
                onComplete?(currentContent)
                cancel()
                return
            }
            
            parseSSEData(jsonStr)
        } else if trimmed.hasPrefix("data:") {
            let jsonStr = String(trimmed.dropFirst(5)).trimmingCharacters(in: .whitespaces)
            
            if jsonStr == "[DONE]" {
                stopTimeoutTimer()
                onComplete?(currentContent)
                cancel()
                return
            }
            
            parseSSEData(jsonStr)
        }
    }
    
    private func parseSSEData(_ jsonStr: String) {
        guard let data = jsonStr.data(using: .utf8) else { return }
        
        // 尝试标准格式: {"content": "xxx", "session_id": "xxx"}
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            // 检查choices格式（OpenAI兼容）
            if let choices = json["choices"] as? [[String: Any]],
               let firstChoice = choices.first,
               let delta = firstChoice["delta"] as? [String: Any],
               let content = delta["content"] as? String, !content.isEmpty {
                currentContent += content
                onChunk?(content)
                return
            }
            
            // 直接content格式
            if let content = json["content"] as? String, !content.isEmpty {
                currentContent += content
                onChunk?(content)
                return
            }
            
            // 检查session_id
            if let sessionId = json["session_id"] as? String {
                // 存储新会话ID
                UserDefaults.standard.set(sessionId, forKey: "current_session_id")
            }
        }
        
        // 尝试SSEMessage解码
        if let sseMsg = try? JSONDecoder().decode(SSEMessage.self, from: data) {
            if let content = sseMsg.content, !content.isEmpty {
                currentContent += content
                onChunk?(content)
            }
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        stopTimeoutTimer()
        
        if let error = error {
            // 用户主动取消不算错误
            if (error as NSError).code == NSURLErrorCancelled {
                return
            }
            onError?(error)
        } else if !currentContent.isEmpty {
            onComplete?(currentContent)
        }
    }
}
