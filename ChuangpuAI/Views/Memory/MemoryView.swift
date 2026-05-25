import SwiftUI

/// 记忆页面
struct MemoryView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var memories: [Memory] = []
    @State private var isLoading = false
    @State private var newMemoryText = ""
    @State private var showAddSheet = false
    @State private var showDeleteAlert = false
    @State private var memoryToDelete: Memory?
    
    var body: some View {
        ZStack {
            Constants.bgPrimary.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 顶部导航
                navBar
                
                if isLoading && memories.isEmpty {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Constants.primaryPurple))
                    Spacer()
                } else if memories.isEmpty {
                    emptyState
                } else {
                    memoriesList
                }
                
                // 底部添加按钮
                addButton
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showAddSheet) {
            addMemorySheet
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
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            Text("记忆库")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            
            Spacer()
            
            Button(action: { showAddSheet = true }) {
                Image(systemName: "plus")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: "brain")
                .font(.system(size: 60))
                .foregroundColor(Constants.textSecondary)
            
            Text("暂无记忆")
                .font(.system(size: 17))
                .foregroundColor(Constants.textSecondary)
            
            Text("添加记忆让我更懂你")
                .font(.system(size: 14))
                .foregroundColor(Constants.textSecondary.opacity(0.7))
            
            Spacer()
        }
    }
    
    private var memoriesList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(memories) { memory in
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
    
    private var addButton: some View {
        Button(action: { showAddSheet = true }) {
            HStack {
                Image(systemName: "plus.circle.fill")
                Text("添加记忆")
            }
            .font(.system(size: 15, weight: .medium))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Constants.primaryPurple)
            .cornerRadius(12)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Constants.bgSecondary)
    }
    
    private var addMemorySheet: some View {
        NavigationStack {
            ZStack {
                Constants.bgPrimary.ignoresSafeArea()
                
                VStack(spacing: 20) {
                    TextEditor(text: $newMemoryText)
                        .scrollContentBackground(.hidden)
                        .foregroundColor(.white)
                        .padding()
                        .background(Constants.bgTertiary)
                        .cornerRadius(12)
                        .frame(minHeight: 150)
                    
                    Text("记忆将帮助AI更好地了解你，提供更个性化的回答")
                        .font(.system(size: 13))
                        .foregroundColor(Constants.textSecondary)
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("添加记忆")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        newMemoryText = ""
                        showAddSheet = false
                    }
                    .foregroundColor(Constants.textSecondary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        addMemory()
                    }
                    .foregroundColor(Constants.primaryPurple)
                    .disabled(newMemoryText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
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
        Swift.Task {
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
    
    private func addMemory() {
        let content = newMemoryText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !content.isEmpty else { return }
        
        Swift.Task {
            do {
                _ = try await APIService.shared.addMemory(content: content)
                await MainActor.run {
                    newMemoryText = ""
                    showAddSheet = false
                    loadMemories()
                }
            } catch {
                print("添加记忆失败: \(error)")
            }
        }
    }
    
    private func deleteMemory(_ memory: Memory) {
        Swift.Task {
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
