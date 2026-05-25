import SwiftUI

/// 消息行组件
struct MessageRow: View {
    let message: Message
    
    var isUser: Bool {
        message.role == "user"
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if isUser {
                Spacer(minLength: 60)
            }
            
            // 头像
            avatarView
            
            // 消息内容
            VStack(alignment: isUser ? .trailing : .leading, spacing: 6) {
                // 消息气泡
                messageBubble
                
                // 文件卡片
                if let fileCards = message.fileCards, !fileCards.isEmpty {
                    fileCardsView(fileCards)
                }
                
                // 图片
                if let imageUrl = message.imageUrl, !imageUrl.isEmpty {
                    imageView(imageUrl)
                }
                
                // 视频缩略图
                if let videoUrl = message.videoUrl, !videoUrl.isEmpty {
                    videoView(videoUrl)
                }
            }
            
            if !isUser {
                Spacer(minLength: 60)
            }
        }
    }
    
    private var avatarView: some View {
        ZStack {
            Circle()
                .fill(
                    isUser ?
                    LinearGradient(colors: [Constants.primaryPurple, Constants.secondaryPurple], startPoint: .topLeading, endPoint: .bottomTrailing) :
                    LinearGradient(colors: [Constants.accentBlue, Constants.accentGreen], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .frame(width: 36, height: 36)
            
            Image(systemName: isUser ? "person.fill" : "brain")
                .font(.system(size: 16))
                .foregroundColor(.white)
        }
    }
    
    private var messageBubble: some View {
        Text(message.content)
            .font(.system(size: 16))
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                isUser ?
                LinearGradient(colors: [Constants.primaryPurple, Constants.secondaryPurple], startPoint: .topLeading, endPoint: .bottomTrailing) :
                LinearGradient(colors: [Constants.bgTertiary], startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            .cornerRadius(18)
            .textSelection(.enabled)
    }
    
    private func fileCardsView(_ fileCards: [FileCard]) -> some View {
        ForEach(fileCards, id: \.filename) { card in
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Constants.primaryPurple.opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    Text(card.icon.isEmpty ? String(card.filename.prefix(1)) : card.icon)
                        .font(.system(size: 18))
                        .foregroundColor(Constants.primaryPurple)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(card.filename)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Text(card.type)
                        .font(.system(size: 12))
                        .foregroundColor(Constants.textSecondary)
                }
                
                Spacer()
            }
            .padding(12)
            .background(Constants.bgTertiary)
            .cornerRadius(12)
            .padding(.top, 4)
        }
    }
    
    private func imageView(_ url: String) -> some View {
        AsyncImage(url: URL(string: url)) { phase in
            switch phase {
            case .empty:
                ProgressView()
                    .frame(width: 200, height: 150)
                    .background(Constants.bgTertiary)
                    .cornerRadius(12)
            case .success(let image):
                image
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: 250, maxHeight: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            case .failure:
                Image(systemName: "photo")
                    .font(.system(size: 40))
                    .foregroundColor(Constants.textSecondary)
                    .frame(width: 200, height: 150)
                    .background(Constants.bgTertiary)
                    .cornerRadius(12)
            @unknown default:
                EmptyView()
            }
        }
        .padding(.top, 4)
    }
    
    private func videoView(_ url: String) -> some View {
        ZStack {
            AsyncImage(url: URL(string: url)) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                case .failure, .empty:
                    Color(Constants.bgTertiary)
                @unknown default:
                    EmptyView()
                }
            }
            .frame(width: 220, height: 140)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            // 播放按钮
            ZStack {
                Circle()
                    .fill(Color.black.opacity(0.5))
                    .frame(width: 48, height: 48)
                
                Image(systemName: "play.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
            }
        }
        .padding(.top, 4)
    }
}

#Preview {
    VStack(spacing: 20) {
        MessageRow(message: Message(role: "user", content: "你好，你能帮我做什么？"))
        
        MessageRow(message: Message(role: "assistant", content: "你好！我是创普AI助手。我可以帮助你：\n\n1. 回答各种问题\n2. 编写文章和代码\n3. 分析数据\n4. 提供创意建议\n\n有什么我可以帮你的吗？"))
    }
    .padding()
    .background(Constants.bgPrimary)
}
