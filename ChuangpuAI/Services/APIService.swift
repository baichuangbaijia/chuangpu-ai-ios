import Foundation

/// API服务类 - 处理所有HTTP请求
class APIService {
    static let shared = APIService()
    private init() {}
    
    private let baseURL = "https://ai.xianbaba188.cn/api/"
    private let agentBaseURL = "https://ai.xianbaba188.cn/agent/api/"
    
    private var authToken: String? {
        UserDefaults.standard.string(forKey: Constants.tokenKey)
    }
    
    private func request<T: Decodable>(
        url: String,
        method: String = "GET",
        body: [String: Any]? = nil,
        requiresAuth: Bool = true
    ) async throws -> T {
        guard let requestURL = URL(string: url) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: requestURL)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        if requiresAuth, let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        if let body = body {
            request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
            NotificationCenter.default.post(name: .vipRequired, object: nil)
            throw APIError.unauthorized
        }
        
        if httpResponse.statusCode != 200 {
            throw APIError.serverError(httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode(T.self, from: data)
    }
    
    func sendSmsCode(phone: String, type: String) async throws -> ApiResult<EmptyResponse> {
        let body: [String: Any] = ["phone": phone, "type": type]
        return try await request(url: baseURL + "auth/sms-code", method: "POST", body: body, requiresAuth: false)
    }
    
    func login(phone: String, code: String? = nil, password: String? = nil, loginType: String = "sms") async throws -> ApiResult<LoginData> {
        var body: [String: Any] = ["phone": phone]
        if loginType == "sms", let code = code {
            body["code"] = code
            body["type"] = loginType
        } else if loginType == "pwd", let password = password {
            body["password"] = password
        }
        return try await request(url: baseURL + "auth/login", method: "POST", body: body, requiresAuth: false)
    }
    
    func register(phone: String, password: String, code: String) async throws -> ApiResult<LoginData> {
        let body: [String: Any] = ["phone": phone, "password": password, "code": code]
        return try await request(url: baseURL + "auth/register", method: "POST", body: body, requiresAuth: false)
    }
    
    func getMe() async throws -> ApiResult<User> {
        return try await request(url: baseURL + "auth/me")
    }
    
    func updateProfile(nickname: String) async throws -> ApiResult<EmptyResponse> {
        let body: [String: Any] = ["nickname": nickname]
        return try await request(url: baseURL + "auth/profile", method: "PUT", body: body)
    }
    
    func getConversations() async throws -> [Conversation] {
        let result: ApiListResult<Conversation> = try await request(url: agentBaseURL + "chat/conversations")
        return result.data?.list ?? []
    }
    
    func createConversation() async throws -> Conversation? {
        let result: ApiResult<Conversation> = try await request(url: agentBaseURL + "chat/conversations", method: "POST", body: [:])
        return result.data
    }
    
    func getHistory(sessionId: String) async throws -> [Message] {
        struct HistoryResponse: Decodable {
            let code: Int
            let data: [HistoryMessage]?
            let message: String?
        }
        let result: HistoryResponse = try await request(url: agentBaseURL + "chat/history/\(sessionId)")
        return result.data?.map { msg in
            Message(role: msg.role ?? "user", content: msg.content ?? "")
        } ?? []
    }
    
    func getCreditBalance() async throws -> ApiResult<CreditData> {
        return try await request(url: baseURL + "credit/balance")
    }
    
    func searchSkills(params: [String: Any]) async throws -> ApiListResult<Skill> {
        var url = baseURL + "skill/search?page=\(params["page"] ?? 1)&limit=\(params["limit"] ?? 20)"
        if let category = params["category"], category as? String != "all" {
            url += "&category=\(category)"
        }
        if let q = params["q"] as? String, !q.isEmpty {
            url += "&q=\(q.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        }
        return try await request(url: url)
    }
    
    func getSkillDetail(slug: String) async throws -> ApiResult<SkillDetail> {
        return try await request(url: baseURL + "skill/detail/\(slug)")
    }
    
    func getServerInstalled() async throws -> ApiListResult<Skill> {
        return try await request(url: agentBaseURL + "skill/installed")
    }
    
    func getMySkills() async throws -> ApiResult<MySkillsData> {
        return try await request(url: agentBaseURL + "skill/my")
    }
    
    func getCategories() async throws -> [String] {
        struct CategoriesResponse: Decodable {
            let code: Int
            let data: CategoriesData?
            let message: String?
        }
        struct CategoriesData: Decodable {
            let categories: [String]?
        }
        let result: CategoriesResponse = try await request(url: baseURL + "skill/categories/list")
        return result.data?.categories ?? []
    }
    
    func getMemories() async throws -> [Memory] {
        let result: ApiResult<MemoryListData> = try await request(url: agentBaseURL + "memory/list")
        return result.data?.list ?? []
    }
    
    func addMemory(content: String) async throws -> ApiResult<Memory> {
        let body: [String: Any] = ["content": content]
        return try await request(url: agentBaseURL + "memory/add", method: "POST", body: body)
    }
    
    func deleteMemory(id: String) async throws -> ApiResult<EmptyResponse> {
        return try await request(url: agentBaseURL + "memory/delete/\(id)", method: "DELETE")
    }
    
    func getTasks() async throws -> [AgentTask] {
        let result: ApiResult<TaskListData> = try await request(url: agentBaseURL + "task/list")
        return result.data?.list ?? []
    }
    
    func activateTestVip() async throws -> PaymentOrderResult {
        return try await request(url: baseURL + "vip/activate-test", method: "POST", body: [:], requiresAuth: false)
    }
    
    func getContainerStatus() async throws -> PaymentOrderResult {
        return try await request(url: baseURL + "vip/status")
    }
    
    func createContainer() async throws -> PaymentOrderResult {
        return try await request(url: baseURL + "vip/create-container", method: "POST", body: [:], requiresAuth: false)
    }
    
    func deleteConversation(sessionId: String) async throws -> ApiResult<EmptyResponse> {
        return try await request(url: agentBaseURL + "chat/conversations/\(sessionId)", method: "DELETE")
    }
}

struct EmptyResponse: Codable {}

struct HistoryMessage: Codable {
    let role: String?
    let content: String?
}

struct MemoryListData: Codable {
    let list: [Memory]?
    let total: Int
}

struct TaskListData: Codable {
    let list: [AgentTask]?
}

struct MySkillsData: Codable {
    let learned: [String]?
    let installed: [Skill]?
}

enum APIError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case unauthorized
    case serverError(Int)
    case decodingError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "无效的URL"
        case .invalidResponse: return "无效的响应"
        case .unauthorized: return "未授权，请先登录"
        case .serverError(let code): return "服务器错误: \(code)"
        case .decodingError: return "数据解析错误"
        }
    }
}

extension Notification.Name {
    static let vipRequired = Notification.Name("vipRequired")
}
