import SwiftUI

/// 2.1.18：独立对话历史页（我的 → 对话历史）内容对标汉堡抽屉历史聊天记录
/// 搜索(输入会话主题) + 今天/昨天/5天前分组 + 绿色已完成 + 长按编辑(占位)/删除 + 点条目打开历史对话(ChatView 传 conversation 自动 loadHistory)
struct HistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var conversations: [Conversation] = []
    @State private var isLoading = false
    @State private var searchText = ""
    @State private var showDeleteAlert = false
    @State private var conversationToDelete: Conversation?
    @State private var toastText: String? = nil

    // 搜索过滤（对标抽屉：按标题过滤）
    private var filteredConversations: [Conversation] {
        if searchText.isEmpty {
            return conversations
        }
        return conversations.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
    }

    // 历史分组（今天 / 昨天 / 5天前，与抽屉一致）
    private var groupedSections: [(String, [Conversation])] {
        let list = filteredConversations
        let cal = Calendar.current
        var today: [Conversation] = []
        var yesterday: [Conversation] = []
        var older: [Conversation] = []
        for c in list {
            if let s = c.updatedAt, let d = ISO8601DateFormatter().date(from: s) {
                if cal.isDateInToday(d) { today.append(c) }
                else if cal.isDateInYesterday(d) { yesterday.append(c) }
                else { older.append(c) }
            } else {
                older.append(c)
            }
        }
        var sections: [(String, [Conversation])] = []
        if !today.isEmpty { sections.append(("今天", today)) }
        if !yesterday.isEmpty { sections.append(("昨天", yesterday)) }
        if !older.isEmpty { sections.append(("5天前", older)) }
        return sections
    }

    var body: some View {
        ZStack {
            Constants.bgPrimary.ignoresSafeArea()

            VStack(spacing: 0) {
                // 顶部导航（返回 + 标题"对话历史"）
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.white)
                    }
                    Spacer()
                    Text("对话历史")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                    Spacer()
                    Color.clear.frame(width: 20)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)

                // 搜索框（对标抽屉"输入会话主题"）
                TextField("输入会话主题", text: $searchText)
                    .font(.system(size: 14))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Constants.bgTertiary)
                    .cornerRadius(10)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)

                if isLoading && conversations.isEmpty {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Constants.primaryPurple))
                    Spacer()
                } else if filteredConversations.isEmpty {
                    emptyState
                } else {
                    conversationList
                }

                // 底部提示（对标抽屉）
                Text("长按记录可编辑或删除")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.6))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.black.opacity(0.35))
            }
        }
        .toolbar(.hidden, for: .navigationBar) // 2.1.19: iOS16+ 正确隐藏系统导航栏(替换失效的 navigationBarHidden)
        .onAppear {
            loadConversations()
        }
        .alert("删除对话", isPresented: $showDeleteAlert) {
            Button("取消", role: .cancel) {}
            Button("删除", role: .destructive) {
                if let conv = conversationToDelete {
                    deleteConversation(conv)
                }
            }
        } message: {
            Text("确定要删除这个对话吗？此操作不可撤销。")
        }
        // 占位 toast（长按"编辑"提示）
        .overlay(alignment: .bottom) {
            if let t = toastText {
                Text(t)
                    .font(.system(size: 12))
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.8))
                    .cornerRadius(16)
                    .padding(.bottom, 12)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 50))
                .foregroundColor(Constants.textSecondary)
            Text(searchText.isEmpty ? "暂无对话记录" : "没有找到匹配的对话")
                .font(.system(size: 15))
                .foregroundColor(Constants.textSecondary)
            Spacer()
        }
    }

    private var conversationList: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(groupedSections, id: \.0) { section in
                    Text(section.0)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Constants.textSecondary)
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                        .padding(.bottom, 4)
                    ForEach(section.1) { conv in
                        historyRow(conv)
                    }
                }
            }
            .padding(.bottom, 8)
        }
    }

    // 点条目 → 打开历史对话（ChatView 传 conversation 自动加载该会话历史）
    private func historyRow(_ conv: Conversation) -> some View {
        NavigationLink(destination: ChatView(conversation: conv)) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Constants.primaryPurple.opacity(0.2))
                        .frame(width: 40, height: 40)
                    Image(systemName: "bubble.left.and.bubble.right")
                        .font(.system(size: 16))
                        .foregroundColor(Constants.primaryPurple)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(conv.title.isEmpty ? "新对话" : conv.title)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    HStack(spacing: 8) {
                        Text(conv.model)
                            .font(.system(size: 11))
                            .foregroundColor(Constants.textSecondary)
                        if let updatedAt = conv.updatedAt {
                            Text(formatDate(updatedAt))
                                .font(.system(size: 11))
                                .foregroundColor(Constants.textSecondary)
                        }
                    }
                }
                Spacer()
                // 绿色"已完成"标记（对标抽屉）
                Text("已完成")
                    .font(.system(size: 12))
                    .foregroundColor(Color(red: 0.30, green: 0.85, blue: 0.40))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 9)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        // 长按：编辑(占位) / 删除
        .contextMenu {
            Button(action: { showToast("编辑功能开发中") }) {
                Label("编辑", systemImage: "pencil")
            }
            Button(role: .destructive, action: {
                conversationToDelete = conv
                showDeleteAlert = true
            }) {
                Label("删除", systemImage: "trash")
            }
        }
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

        return ""
    }

    private func loadConversations() {
        isLoading = true
        Task {
            do {
                let convs = try await APIService.shared.getConversations()
                await MainActor.run {
                    conversations = convs
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                }
            }
        }
    }

    private func deleteConversation(_ conv: Conversation) {
        Task {
            do {
                _ = try await APIService.shared.deleteConversation(sessionId: conv.sessionId)
                await MainActor.run {
                    conversations.removeAll { $0.id == conv.id }
                }
            } catch {
                print("删除失败: \(error)")
            }
        }
    }

    private func showToast(_ text: String) {
        withAnimation { toastText = text }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation { toastText = nil }
        }
    }
}

#Preview {
    NavigationStack {
        HistoryView()
    }
}
