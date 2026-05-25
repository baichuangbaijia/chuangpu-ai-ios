import SwiftUI

/// 首页视图 - 显示对话列表和快捷操作
struct HomeView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var conversations: [Conversation] = []
    @State private var isLoading = false
    @State private var showNewChat = false
    @State private var selectedConversation: Conversation?
    @State private var inputText = ""
    @State private var currentModel = "deepseek-v3"
    @State private var showModelSelector = false
    @State private var showSidebar = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Constants.bgPrimary.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // 顶部导航
                    topNavBar
                    
                    if conversations.isEmpty && !isLoading {
                        emptyState
                    } else {
                        conversationList
                    }
                    
                    // 底部输入区域
                    bottomInputArea
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showSidebar) {
                SidebarView(onSelectConversation: { conv in
                    selectedConversation = conv
                    showSidebar = false
                })
            }
            .fullScreenCover(item: $selectedConversation) { conv in
                ChatView(conversation: conv)
            }
            .fullScreenCover(isPresented: $showNewChat) {
                ChatView(conversation: nil)
            }
            .sheet(isPresented: $showModelSelector) {
                modelSelectorSheet
            }
            .onAppear {
                currentModel = authManager.getCurrentModel()
                loadConversations()
            }
        }
    }
    
    private var topNavBar: some View {
        HStack {
            Button(action: { showSidebar = true }) {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            Text("创普AI")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            
            Spacer()
            
            Button(action: { showNewChat = true }) {
                Image(systemName: "plus")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
    
    private var emptyState: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Logo动画效果
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Constants.primaryPurple.opacity(0.3), Color.clear],
                            center: .center,
                            startRadius: 30,
                            endRadius: 100
                        )
                    )
                    .frame(width: 180, height: 180)
                
                Image(systemName: "brain")
                    .font(.system(size: 60))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Constants.primaryPurple, Constants.secondaryPurple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            VStack(spacing: 8) {
                Text("你好，我是创普AI")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                
                Text("有什么我可以帮你的吗？")
                    .font(.system(size: 14))
                    .foregroundColor(Constants.textSecondary)
            }
            
            // 快捷技能
            quickSkillsGrid
            
            Spacer()
        }
        .padding(.horizontal, 24)
    }
    
    private var quickSkillsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 12) {
            quickSkillItem(icon: "tablecells", title: "创建表格")
            quickSkillItem(icon: "magnifyingglass", title: "市场调研")
            quickSkillItem(icon: "note.text", title: "日常记录")
            quickSkillItem(icon: "doc.text", title: "创建合同")
            quickSkillItem(icon: "globe", title: "创建网站")
            quickSkillItem(icon: "airplane", title: "旅行规划")
        }
    }
    
    private func quickSkillItem(icon: String, title: String) -> some View {
        Button(action: {
            inputText = "帮我\(title)"
        }) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(Constants.primaryPurple)
                
                Text(title)
                    .font(.system(size: 12))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 80)
            .background(Constants.bgTertiary)
            .cornerRadius(12)
        }
    }
    
    private var conversationList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(conversations) { conv in
                    ConversationRow(conversation: conv)
                        .onTapGesture {
                            selectedConversation = conv
                        }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }
    
    private var bottomInputArea: some View {
        VStack(spacing: 12) {
            // 模型选择器
            Button(action: { showModelSelector = true }) {
                HStack {
                    Circle()
                        .fill(Constants.accentGreen)
                        .frame(width: 8, height: 8)
                    Text(getModelName(currentModel))
                        .font(.system(size: 13))
                        .foregroundColor(.white)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 11))
                        .foregroundColor(Constants.textSecondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Constants.bgTertiary)
                .cornerRadius(16)
            }
            
            // 输入框
            HStack(spacing: 12) {
                TextField("输入消息...", text: $inputText)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Constants.bgTertiary)
                    .cornerRadius(24)
                
                Button(action: startNewChat) {
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
                .disabled(inputText.isEmpty)
                .opacity(inputText.isEmpty ? 0.5 : 1)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Constants.bgSecondary)
    }
    
    private var modelSelectorSheet: some View {
        NavigationStack {
            ZStack {
                Constants.bgPrimary.ignoresSafeArea()
                
                VStack(spacing: 16) {
                    ForEach(Constants.availableModels, id: \.0) { model in
                        modelRow(id: model.0, name: model.1, available: model.2)
                    }
                }
                .padding()
            }
            .navigationTitle("选择模型")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        showModelSelector = false
                    }
                    .foregroundColor(Constants.primaryPurple)
                }
            }
        }
        .presentationDetents([.medium])
    }
    
    private func modelRow(id: String, name: String, available: Bool) -> some View {
        Button(action: {
            if available {
                currentModel = id
                authManager.setCurrentModel(id)
                showModelSelector = false
            }
        }) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(name)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                        
                        if id == currentModel {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(Constants.primaryPurple)
                        }
                    }
                    
                    if !available {
                        Text("即将上线")
                            .font(.system(size: 12))
                            .foregroundColor(Constants.accentOrange)
                    }
                }
                
                Spacer()
            }
            .padding()
            .background(Constants.bgTertiary)
            .cornerRadius(12)
            .opacity(available ? 1 : 0.6)
        }
        .disabled(!available)
    }
    
    private func getModelName(_ id: String) -> String {
        return Constants.availableModels.first { $0.0 == id }?.1 ?? "DeepSeek V3"
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
    
    private func startNewChat() {
        guard !inputText.isEmpty else { return }
        showNewChat = true
    }
}

#Preview {
    HomeView()
        .environmentObject(AuthManager.shared)
}
