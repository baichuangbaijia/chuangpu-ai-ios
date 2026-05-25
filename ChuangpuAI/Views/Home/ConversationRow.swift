import SwiftUI

/// 会话行组件
struct ConversationRow: View {
    let conversation: Conversation
    
    var body: some View {
        HStack(spacing: 12) {
            // 图标
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Constants.primaryPurple.opacity(0.3), Constants.secondaryPurple.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 48, height: 48)
                
                Image(systemName: "bubble.left.and.bubble.right")
                    .font(.system(size: 20))
                    .foregroundColor(Constants.primaryPurple)
            }
            
            // 内容
            VStack(alignment: .leading, spacing: 4) {
                Text(conversation.title.isEmpty ? "新对话" : conversation.title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    Text(conversation.model)
                        .font(.system(size: 12))
                        .foregroundColor(Constants.textSecondary)
                    
                    if let updatedAt = conversation.updatedAt {
                        Text(formatDate(updatedAt))
                            .font(.system(size: 12))
                            .foregroundColor(Constants.textSecondary)
                    }
                }
            }
            
            Spacer()
            
            // 消息数量
            if conversation.messageCount > 0 {
                Text("\(conversation.messageCount)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Constants.textSecondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Constants.bgTertiary)
                    .cornerRadius(10)
            }
        }
        .padding(12)
        .background(Constants.bgSecondary)
        .cornerRadius(12)
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            let calendar = Calendar.current
            
            if calendar.isDateInToday(date) {
                displayFormatter.dateFormat = "HH:mm"
            } else if calendar.isDateInYesterday(date) {
                return "昨天"
            } else {
                displayFormatter.dateFormat = "MM/dd"
            }
            
            return displayFormatter.string(from: date)
        }
        
        // 尝试简化格式
        let simpleFormatter = ISO8601DateFormatter()
        if let date = simpleFormatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "MM/dd HH:mm"
            return displayFormatter.string(from: date)
        }
        
        return dateString
    }
}

#Preview {
    ConversationRow(conversation: Conversation(
        id: 1,
        title: "测试对话",
        sessionId: "abc123",
        model: "deepseek-v3",
        updatedAt: nil,
        createdAt: nil,
        userId: 1,
        messageCount: 5
    ))
    .padding()
    .background(Constants.bgPrimary)
}
