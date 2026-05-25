import SwiftUI

/// 首页 - 对照安卓HomeFragment
/// 安卓首页要素: 菜单按钮/hamburger、龙虾动画WebView、模型选择器、快捷技能6个(创建表格/市场调研/日常记录/创建合同/创建网站/旅行规划)、"开始对话"大按钮(发光脉冲)、底部输入框、任务按钮
struct HomeView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var inputText = ""
    @State private var currentModel = "deepseek-v3"
    @State private var showModelSelector = false
    @State private var showSidebar = false
    @State private var glowActive = true
    
    var body: some View {
        ZStack {
            Constants.bgPrimary.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 顶部导航栏
                topBar
                
                Spacer()
                
                // 中心区域：Logo + 快捷技能
                centerContent
                
                Spacer()
                
                // 底部区域：模型选择 + 输入框 + 任务按钮
                bottomArea
            }
        }
        .sheet(isPresented: $showSidebar) {
            SidebarView(onSelectConversation: { _ in })
        }
        .sheet(isPresented: $showModelSelector) {
            ModelSelectorSheet(currentModel: $currentModel)
        }
        .onAppear {
            currentModel = authManager.getCurrentModel()
        }
    }
    
    // MARK: - 顶部导航
    private var topBar: some View {
        HStack {
            // 菜单按钮（对照安卓btnMenu）
            Button(action: { showSidebar = true }) {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 22))
                    .foregroundColor(.white)
            }
            Spacer()
            Text("创普AI")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            Spacer()
            // 右侧占位
            Color.clear.frame(width: 22)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
    
    // MARK: - 中心内容
    private var centerContent: some View {
        VStack(spacing: 24) {
            // Logo光晕（对照安卓lobsterEmoji）
            ZStack {
                Circle()
                    .fill(RadialGradient(colors: [Constants.primaryPurple.opacity(0.2), Color.clear], center: .center, startRadius: 30, endRadius: 100))
                    .frame(width: 180, height: 180)
                
                Circle()
                    .stroke(LinearGradient(colors: [Constants.primaryPurple.opacity(0.5), Constants.secondaryPurple.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 2)
                    .frame(width: 120, height: 120)
                
                Image(systemName: "brain")
                    .font(.system(size: 50))
                    .foregroundStyle(LinearGradient(colors: [Constants.primaryPurple, Constants.secondaryPurple], startPoint: .topLeading, endPoint: .bottomTrailing))
            }
            
            VStack(spacing: 8) {
                Text("你好，我是创普AI")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
                Text("有什么我可以帮你的吗？")
                    .font(.system(size: 14))
                    .foregroundColor(Constants.textSecondary)
            }
            
            // 快捷技能6个（对照安卓skill1-6）
            quickSkillsGrid
            
            // "开始对话"大按钮（对照安卓btnStart，发光脉冲效果）
            Button(action: {}) {
                HStack(spacing: 10) {
                    Image(systemName: "message.fill")
                        .font(.system(size: 20))
                    Text("开始对话")
                        .font(.system(size: 18, weight: .bold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    LinearGradient(colors: [Constants.primaryPurple, Constants.secondaryPurple], startPoint: .leading, endPoint: .trailing)
                )
                .cornerRadius(28)
                .shadow(color: Constants.primaryPurple.opacity(glowActive ? 0.6 : 0.2), radius: glowActive ? 16 : 4)
                .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: glowActive)
            }
            .padding(.horizontal, 40)
            .onAppear { glowActive = true }
        }
        .padding(.horizontal, 24)
    }
    
    // MARK: - 快捷技能网格（6个，2行3列）
    private var quickSkillsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            quickSkillBtn(icon: "tablecells", title: "创建表格")
            quickSkillBtn(icon: "magnifyingglass", title: "市场调研")
            quickSkillBtn(icon: "note.text", title: "日常记录")
            quickSkillBtn(icon: "doc.text", title: "创建合同")
            quickSkillBtn(icon: "globe", title: "创建网站")
            quickSkillBtn(icon: "airplane", title: "旅行规划")
        }
    }
    
    private func quickSkillBtn(icon: String, title: String) -> some View {
        Button(action: { inputText = "帮我\(title)" }) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(Constants.primaryPurple)
                Text(title)
                    .font(.system(size: 12))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 72)
            .background(Constants.bgTertiary)
            .cornerRadius(12)
        }
    }
    
    // MARK: - 底部区域
    private var bottomArea: some View {
        VStack(spacing: 12) {
            // 模型选择器（对照安卓btnModel）
            Button(action: { showModelSelector = true }) {
                HStack(spacing: 6) {
                    Circle().fill(Constants.accentGreen).frame(width: 8, height: 8)
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
            
            // 输入框 + 发送按钮 + 任务按钮
            HStack(spacing: 12) {
                // 任务按钮（对照安卓btnTask）
                Button(action: {}) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 22))
                        .foregroundColor(Constants.primaryPurple)
                }
                
                // 输入框（对照安卓etInput）
                TextField("输入消息...", text: $inputText)
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Constants.bgTertiary)
                    .cornerRadius(24)
                
                // 发送按钮（对照安卓btnSend）
                Button(action: {}) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(LinearGradient(colors: [Constants.primaryPurple, Constants.secondaryPurple], startPoint: .topLeading, endPoint: .bottomTrailing))
                }
                .disabled(inputText.isEmpty)
                .opacity(inputText.isEmpty ? 0.5 : 1)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Constants.bgSecondary)
    }
    
    private func getModelName(_ id: String) -> String {
        let models = Constants.availableModels
        for m in models { if m.0 == id { return m.1 } }
        return "DeepSeek V3"
    }
}

// MARK: - 模型选择弹窗
struct ModelSelectorSheet: View {
    @Binding var currentModel: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Constants.bgPrimary.ignoresSafeArea()
                VStack(spacing: 12) {
                    ForEach(Constants.availableModels, id: \.0) { model in
                        Button(action: { currentModel = model.0; dismiss() }) {
                            HStack {
                                Text(model.1).font(.system(size: 16)).foregroundColor(model.2 ? .white : Constants.textSecondary)
                                if !model.2 {
                                    Text("即将上线").font(.system(size: 12)).foregroundColor(Constants.accentOrange).padding(.horizontal, 8).padding(.vertical, 2).background(Constants.accentOrange.opacity(0.2)).cornerRadius(4)
                                }
                                Spacer()
                                if model.0 == currentModel {
                                    Image(systemName: "checkmark").font(.system(size: 14, weight: .medium)).foregroundColor(Constants.primaryPurple)
                                }
                            }.padding(.horizontal, 16).padding(.vertical, 16).background(Constants.bgSecondary).cornerRadius(12)
                        }.disabled(!model.2).opacity(model.2 ? 1 : 0.6)
                    }
                    Spacer()
                }.padding(16)
            }
            .navigationTitle("选择模型")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .navigationBarTrailing) { Button("取消") { dismiss() }.foregroundColor(Constants.primaryPurple) } }
        }
        .presentationDetents([.medium])
    }
}

#Preview { HomeView().environmentObject(AuthManager.shared) }
