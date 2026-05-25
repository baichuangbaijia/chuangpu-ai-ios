import SwiftUI
import PhotosUI

/// 聊天页面
struct ChatView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authManager: AuthManager
    @State private var messages: [Message] = []
    @State private var inputText = ""
    @State private var isLoading = false
    @State private var isStreaming = false
    @State private var currentModel = "deepseek-v3"
    @State private var sessionId: String?
    @State private var showSidebar = false
    @State private var showAttachment = false
    @State private var connectionStatus: ConnectionStatus = .checking
    @State private var attachedImages: [AttachedImage] = []
    @State private var attachedVideos: [AttachedVideo] = []
    
    let conversation: Conversation?
    
    struct AttachedImage: Identifiable {
        let id = UUID()
        let image: UIImage
        let url: String?
    }
    
    struct AttachedVideo: Identifiable {
        let id = UUID()
        let url: URL
        let localPath: String?
    }
    
    enum ConnectionStatus {
        case checking, creating, running, offline
    }
    
    var body: some View {
        ZStack {
            Constants.bgPrimary.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 顶部导航
                chatNavBar
                
                // 连接状态
                if connectionStatus != .running {
                    connectionStatusBar
                }
                
                // 消息列表
                messageList
                
                // 附件预览
                attachmentPreview
                
                // 输入区域
                inputArea
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showSidebar) {
            SidebarView(onSelectConversation: { conv in
                dismiss()
            })
        }
        .sheet(isPresented: $showAttachment) {
            attachmentSheet
        }
        .onAppear {
            currentModel = conversation?.model ?? authManager.getCurrentModel()
            sessionId = conversation?.sessionId
            
            if let conv = conversation {
                loadHistory(sessionId: conv.sessionId)
            } else {
                createNewConversation()
            }
            
            checkConnection()
        }
    }
    
    private var chatNavBar: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            // 连接状态指示
            HStack(spacing: 6) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)
                Text(statusText)
                    .font(.system(size: 13))
                    .foregroundColor(Constants.textSecondary)
            }
            
            Spacer()
            
            Button(action: { showSidebar = true }) {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
    
    private var statusColor: Color {
        switch connectionStatus {
        case .running: return Constants.accentGreen
        case .creating, .checking: return Constants.accentOrange
        case .offline: return Constants.textSecondary
        }
    }
    
    private var statusText: String {
        switch connectionStatus {
        case .running: return "在线"
        case .creating: return "连接中..."
        case .checking: return "检查中..."
        case .offline: return "离线"
        }
    }
    
    private var connectionStatusBar: some View {
        HStack {
            if connectionStatus == .creating {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(0.8)
                
                Text("正在分配云主机...")
                    .font(.system(size: 13))
                    .foregroundColor(.white)
                
                Spacer()
                
                // 进度点
                HStack(spacing: 8) {
                    Circle()
                        .fill(connectionStatus == .creating ? Constants.primaryPurple : Constants.bgTertiary)
                        .frame(width: 8, height: 8)
                    Circle()
                        .fill(Constants.bgTertiary)
                        .frame(width: 8, height: 8)
                    Circle()
                        .fill(Constants.bgTertiary)
                        .frame(width: 8, height: 8)
                }
            } else if connectionStatus == .checking {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(0.8)
                Text("检查连接状态...")
                    .font(.system(size: 13))
                    .foregroundColor(.white)
            } else {
                Text("当前处于离线状态")
                    .font(.system(size: 13))
                    .foregroundColor(.red)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Constants.bgSecondary)
    }
    
    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(messages) { message in
                        MessageRow(message: message)
                            .id(message.id)
                    }
                    
                    if isStreaming {
                        HStack {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: Constants.primaryPurple))
                            Text("思考中...")
                                .font(.system(size: 13))
                                .foregroundColor(Constants.textSecondary)
                        }
                        .padding(.vertical, 8)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .onChange(of: messages.count) { _ in
                if let lastMessage = messages.last {
                    withAnimation {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
        }
    }
    
    private var attachmentPreview: some View {
        Group {
            if !attachedImages.isEmpty || !attachedVideos.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(attachedImages) { item in
                            ZStack(alignment: .topTrailing) {
                                Image(uiImage: item.image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 80, height: 80)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                
                                Button(action: {
                                    attachedImages.removeAll { $0.id == item.id }
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.white)
                                        .background(Circle().fill(Color.black.opacity(0.5)))
                                }
                                .offset(x: 4, y: -4)
                            }
                        }
                        
                        ForEach(attachedVideos) { item in
                            ZStack(alignment: .center) {
                                Rectangle()
                                    .fill(Constants.bgTertiary)
                                    .frame(width: 80, height: 80)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                
                                Image(systemName: "video.fill")
                                    .foregroundColor(.white)
                                
                                Button(action: {
                                    attachedVideos.removeAll { $0.id == item.id }
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.white)
                                        .background(Circle().fill(Color.black.opacity(0.5)))
                                }
                                .offset(x: 4, y: -4)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .frame(height: 90)
            }
        }
    }
    
    private var inputArea: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                // 附件按钮
                Button(action: { showAttachment = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(Constants.primaryPurple)
                }
                
                // 输入框
                TextField("输入消息...", text: $inputText, axis: .vertical)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .lineLimit(1...5)
                    .background(Constants.bgTertiary)
                    .cornerRadius(20)
                
                // 发送按钮
                Button(action: sendMessage) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Constants.primaryPurple, Constants.secondaryPurple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .disabled(inputText.isEmpty && attachedImages.isEmpty && attachedVideos.isEmpty)
                .opacity((inputText.isEmpty && attachedImages.isEmpty && attachedVideos.isEmpty) ? 0.5 : 1)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Constants.bgSecondary)
    }
    
    private var attachmentSheet: some View {
        NavigationStack {
            ZStack {
                Constants.bgPrimary.ignoresSafeArea()
                
                VStack(spacing: 20) {
                    attachmentOption(icon: "photo", title: "图片") {
                        // TODO: 实现图片选择
                        showAttachment = false
                    }
                    
                    attachmentOption(icon: "video", title: "视频") {
                        // TODO: 实现视频选择
                        showAttachment = false
                    }
                    
                    attachmentOption(icon: "doc", title: "文件") {
                        // TODO: 实现文件选择
                        showAttachment = false
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("添加附件")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("取消") {
                        showAttachment = false
                    }
                    .foregroundColor(Constants.primaryPurple)
                }
            }
        }
        .presentationDetents([.medium])
    }
    
    private func attachmentOption(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(Constants.primaryPurple)
                    .frame(width: 50, height: 50)
                    .background(Constants.bgTertiary)
                    .clipShape(Circle())
                
                Text(title)
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(Constants.textSecondary)
            }
            .padding()
            .background(Constants.bgSecondary)
            .cornerRadius(12)
        }
    }
    
    private func checkConnection() {
        connectionStatus = .checking
        
        Task {
            do {
                let result = try await APIService.shared.getContainerStatus()
                let status = result.data?["container_status"]?.value as? String ?? "none"
                
                await MainActor.run {
                    if status == "running" {
                        connectionStatus = .running
                    } else {
                        connectionStatus = .offline
                        createContainer()
                    }
                }
            } catch {
                await MainActor.run {
                    connectionStatus = .offline
                }
            }
        }
    }
    
    private func createContainer() {
        connectionStatus = .creating
        
        Task {
            do {
                let result = try await APIService.shared.createContainer()
                if result.code == 0 {
                    // 轮询容器状态
                    pollContainerStatus()
                } else {
                    await MainActor.run {
                        connectionStatus = .offline
                    }
                }
            } catch {
                await MainActor.run {
                    connectionStatus = .offline
                }
            }
        }
    }
    
    private func pollContainerStatus() {
        Task {
            do {
                let result = try await APIService.shared.getContainerStatus()
                let status = result.data?["container_status"]?.value as? String ?? "none"
                
                await MainActor.run {
                    if status == "running" {
                        connectionStatus = .running
                    } else if status == "error" {
                        connectionStatus = .offline
                    } else {
                        // 继续轮询
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            pollContainerStatus()
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    connectionStatus = .offline
                }
            }
        }
    }
    
    private func createNewConversation() {
        Task {
            do {
                if let conv = try await APIService.shared.createConversation() {
                    await MainActor.run {
                        sessionId = conv.sessionId
                    }
                }
            } catch {
                print("创建会话失败: \(error)")
            }
        }
    }
    
    private func loadHistory(sessionId: String) {
        Task {
            do {
                let history = try await APIService.shared.getHistory(sessionId: sessionId)
                await MainActor.run {
                    messages = history
                }
            } catch {
                print("加载历史失败: \(error)")
            }
        }
    }
    
    private func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        
        let userMessage = Message(role: "user", content: text)
        messages.append(userMessage)
        inputText = ""
        
        isStreaming = true
        
        var chatMessages: [[String: String]] = messages.map { msg in
            ["role": msg.role, "content": msg.content]
        }
        
        SSEService.shared.startChat(
            messages: chatMessages,
            sessionId: sessionId,
            model: currentModel,
            onChunk: { chunk in
                await MainActor.run {
                    if let lastMsg = messages.last, lastMsg.role == "assistant" {
                        messages[messages.count - 1].content += chunk
                    } else {
                        let aiMessage = Message(role: "assistant", content: chunk)
                        messages.append(aiMessage)
                    }
                }
            },
            onComplete: { finalContent in
                await MainActor.run {
                    isStreaming = false
                    if let lastMsg = messages.last, lastMsg.role == "assistant" {
                        messages[messages.count - 1].content = finalContent
                    }
                }
            },
            onError: { error in
                await MainActor.run {
                    isStreaming = false
                    let errorMsg = Message(role: "assistant", content: "抱歉，发生了错误: \(error.localizedDescription)")
                    messages.append(errorMsg)
                }
            }
        )
    }
}

#Preview {
    ChatView(conversation: nil)
        .environmentObject(AuthManager.shared)
}
