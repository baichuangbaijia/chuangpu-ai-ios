import SwiftUI

/// 任务页面
struct TaskView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var tasks: [Task] = []
    @State private var isLoading = false
    @State private var showAddSheet = false
    
    var body: some View {
        ZStack {
            Constants.bgPrimary.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 顶部导航
                navBar
                
                if isLoading && tasks.isEmpty {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Constants.primaryPurple))
                    Spacer()
                } else if tasks.isEmpty {
                    emptyState
                } else {
                    tasksList
                }
                
                // 底部添加按钮
                addButton
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showAddSheet) {
            addTaskSheet
        }
        .onAppear {
            loadTasks()
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
            
            Text("定时任务")
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
            
            Image(systemName: "list.bullet.rectangle")
                .font(.system(size: 60))
                .foregroundColor(Constants.textSecondary)
            
            Text("暂无定时任务")
                .font(.system(size: 17))
                .foregroundColor(Constants.textSecondary)
            
            Text("创建任务让我自动执行")
                .font(.system(size: 14))
                .foregroundColor(Constants.textSecondary.opacity(0.7))
            
            Spacer()
        }
    }
    
    private var tasksList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(tasks) { task in
                    taskCard(task)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }
    
    private func taskCard(_ task: Task) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(task.name)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                    
                    if let description = task.description, !description.isEmpty {
                        Text(description)
                            .font(.system(size: 13))
                            .foregroundColor(Constants.textSecondary)
                            .lineLimit(2)
                    }
                }
                
                Spacer()
                
                // 状态标签
                Text(task.status == "active" ? "运行中" : "已停止")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(task.status == "active" ? Constants.accentGreen : Constants.textSecondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        (task.status == "active" ? Constants.accentGreen : Constants.textSecondary).opacity(0.2)
                    )
                    .cornerRadius(8)
            }
            
            Divider()
                .background(Constants.bgTertiary)
            
            HStack {
                // 执行频率
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.system(size: 12))
                    Text(task.cronExpression)
                        .font(.system(size: 12))
                }
                .foregroundColor(Constants.textSecondary)
                
                Spacer()
                
                // 执行次数
                HStack(spacing: 4) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 12))
                    Text("执行 \(task.runCount) 次")
                        .font(.system(size: 12))
                }
                .foregroundColor(Constants.textSecondary)
            }
            
            // 下次执行时间
            if let nextRun = task.nextRun {
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.system(size: 12))
                    Text("下次: \(nextRun)")
                        .font(.system(size: 12))
                }
                .foregroundColor(Constants.primaryPurple)
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
                Text("创建任务")
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
    
    private var addTaskSheet: some View {
        NavigationStack {
            ZStack {
                Constants.bgPrimary.ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Text("创建定时任务功能开发中...")
                        .font(.system(size: 15))
                        .foregroundColor(Constants.textSecondary)
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("创建任务")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        showAddSheet = false
                    }
                    .foregroundColor(Constants.textSecondary)
                }
            }
        }
        .presentationDetents([.medium])
    }
    
    private func loadTasks() {
        isLoading = true
        Swift.Task {
            do {
                let result = try await APIService.shared.getTasks()
                await MainActor.run {
                    tasks = result
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        TaskView()
    }
}
