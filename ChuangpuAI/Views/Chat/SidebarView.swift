import SwiftUI

/// 侧边栏视图
struct SidebarView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var conversations: [Conversation] = []
    @State private var isLoading = false
    @State private var searchText = ""
    @State private var showDeleteAlert = false
    @State private var conversationToDelete: Conversation?
    
    let onSelectConversation: (Conversation) -> Void
    
    var filteredConversations: [Conversation] {
        if searchText.isEmpty {
            return conversations
        }
        return conversations.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Constants.bgPrimary.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // 搜索栏
                    searchBar
                    
                    if isLoading {
                        Spacer()
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: Constants.primaryPurple))
                        Spacer()
                    } else if filteredConversations.isEmpty {
                        emptyState
                    } else {
                        conversationList
                    }
                }
            }
            .navigationTitle("对话历史")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("关闭") {
                        dismiss()
                    }
                    .foregroundColor(Constants.primaryPurple)
                }
            }
        }
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
    }
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(Constants.textSecondary)
            
            TextField("搜索对话...", text: $searchText)
                .foregroundColor(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Constants.bgTertiary)
        .cornerRadius(10)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
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
        List {
            ForEach(filteredConversations) { conv in
                sidebarRow(conv)
                    .listRowBackground(Constants.bgSecondary)
                    .listRowSeparatorTint(Constants.bgTertiary)
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            conversationToDelete = conv
                            showDeleteAlert = true
                        } label: {
                            Label("删除", systemImage: "trash")
                        }
                    }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }
    
    private func sidebarRow(_ conv: Conversation) -> some View {
        Button(action: {
            onSelectConversation(conv)
        }) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Constants.primaryPurple.opacity(0.2))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: "bubble.left.and.bubble.right")
                        .font(.system(size: 18))
                        .foregroundColor(Constants.primaryPurple)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(conv.title.isEmpty ? "新对话" : conv.title)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    HStack(spacing: 8) {
                        Text(conv.model)
                            .font(.system(size: 12))
                            .foregroundColor(Constants.textSecondary)
                        
                        if conv.messageCount > 0 {
                            Text("\(conv.messageCount)条消息")
                                .font(.system(size: 12))
                                .foregroundColor(Constants.textSecondary)
                        }
                    }
                }
                
                Spacer()
                
                if let updatedAt = conv.updatedAt {
                    Text(formatDate(updatedAt))
                        .font(.system(size: 12))
                        .foregroundColor(Constants.textSecondary)
                }
            }
            .padding(.vertical, 8)
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
        Swift.Task {
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
        Swift.Task {
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
}

#Preview {
    SidebarView(onSelectConversation: { _ in })
}
