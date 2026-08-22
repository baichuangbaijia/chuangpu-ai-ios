import SwiftUI

/// 2.1.18：我的AI记忆页（我的 → 我的AI记忆）对齐安卓截图：搜索框"搜索记忆内容" + 幽灵空态"暂无记忆内容" + 列表删除
/// 方案A：只做 列表+搜索+删除，不做添加/详情/编辑（截图空态：👻 幽灵 emoji + 暂无记忆内容）
struct MemoryView: View {
    // 2.1.20：覆盖层模式（由 MainTabView 传入 onClose，默认空）替代 @Environment(\.dismiss)
    var onClose: () -> Void = {}
    @State private var memories: [Memory] = []
    @State private var isLoading = false
    @State private var searchText = ""
    @State private var showDeleteAlert = false
    @State private var memoryToDelete: Memory?
    
    // 本地过滤（方案A：不动后端，关键词过滤 content）
    private var filteredMemories: [Memory] {
        if searchText.isEmpty {
            return memories
        }
        return memories.filter { $0.content.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        ZStack {
            Constants.bgPrimary.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 顶部导航（标题"我的AI记忆"，去掉原"记忆库"+右侧加号）
                navBar
                
                // 搜索框（对齐截图占位文案"搜索记忆内容"）
                searchField
                
                if isLoading && memories.isEmpty {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Constants.primaryPurple))
                    Spacer()
                } else if filteredMemories.isEmpty {
                    emptyState
                } else {
                    memoriesList
                }
            }
        }
        .alert("删除记忆", isPresented: $showDeleteAlert) {
            Button("取消", role: .cancel) {}
            Button("删除", role: .destructive) {
                if let memory = memoryToDelete {
                    deleteMemory(memory)
                }
            }
        } message: {
            Text("确定要删除这条记忆吗？")
        }
        .onAppear {
            loadMemories()
        }
    }
    
    private var navBar: some View {
        HStack {
            Button(action: { onClose() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            Text("我的AI记忆")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            
            Spacer()
            
            // 右侧占位保持标题居中（原加号按钮已删）
            Color.clear.frame(width: 20)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
    
    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14))
                .foregroundColor(Constants.textSecondary)
            TextField("搜索记忆内容", text: $searchText)
                .font(.system(size: 14))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Constants.bgTertiary)
        .cornerRadius(10)
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            
            // 幽灵 emoji（对齐截图空态，彩色 emoji 深色底显示正常）
            Text("👻")
                .font(.system(size: 64))
            
            Text(searchText.isEmpty ? "暂无记忆内容" : "没有找到匹配的记忆")
                .font(.system(size: 16))
                .foregroundColor(Constants.textSecondary)
            
            Spacer()
        }
    }
    
    private var memoriesList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(filteredMemories) { memory in
                    memoryCard(memory)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }
    
    private func memoryCard(_ memory: Memory) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(memory.content)
                .font(.system(size: 15))
                .foregroundColor(.white)
                .multilineTextAlignment(.leading)
            
            HStack {
                if let createdAt = memory.createdAt {
                    Text(formatDate(createdAt))
                        .font(.system(size: 12))
                        .foregroundColor(Constants.textSecondary)
                }
                
                Spacer()
                
                Button(action: {
                    memoryToDelete = memory
                    showDeleteAlert = true
                }) {
                    Image(systemName: "trash")
                        .font(.system(size: 14))
                        .foregroundColor(.red.opacity(0.7))
                }
            }
        }
        .padding(16)
        .background(Constants.bgSecondary)
        .cornerRadius(12)
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "yyyy-MM-dd HH:mm"
            return displayFormatter.string(from: date)
        }
        
        return dateString
    }
    
    private func loadMemories() {
        isLoading = true
        Task {
            do {
                let result = try await APIService.shared.getMemories()
                await MainActor.run {
                    memories = result
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                }
            }
        }
    }
    
    private func deleteMemory(_ memory: Memory) {
        Task {
            do {
                _ = try await APIService.shared.deleteMemory(id: memory.id)
                await MainActor.run {
                    memories.removeAll { $0.id == memory.id }
                }
            } catch {
                print("删除记忆失败: \(error)")
            }
        }
    }
}

#Preview {
    NavigationStack {
        MemoryView()
    }
}
