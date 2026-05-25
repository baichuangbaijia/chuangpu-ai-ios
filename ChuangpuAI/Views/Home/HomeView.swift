import SwiftUI

/// 首页 - 完全对照安卓HomeFragment
/// 安卓布局从上到下：
/// 1. 左上角汉堡菜单(btnMenu)
/// 2. 龙虾动画WebView(lobsterEmoji) - 加载lobster_anim.html
/// 3. 模型选择器 "● DeepSeek V3 ▾"(btnModel)
/// 4. 6个快捷技能按钮(skill1-6): 创建表格/市场调研/日常记录/创建合同/创建网站/旅行规划
/// 5. "开始对话"大按钮(btnStart) - 发光脉冲动画(translationZ 0.4→0.7→0.4, 2500ms循环)
/// 6. 底部：输入框(etInput) + 发送按钮(btnSend) + 任务按钮(btnTask)
struct HomeView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var inputText = ""
    @State private var currentModel = "deepseek-v3"
    @State private var showModelSelector = false
    @State private var showSidebar = false
    @State private var glowPhase: Float = 0.4
    @State private var lobsterWiggle = false
    @State private var lobsterScale: CGFloat = 1.0
    @State private var bubbleOffset: CGFloat = 0
    
    private let availableModels = [
        ("deepseek-v3", "DeepSeek V3", true),
        ("kimi-2.5", "Kimi 2.5", false),
        ("glm-5", "GLM-5", false),
        ("minimax-m2.5", "MiniMax M2.5", false),
        ("doubao-2.0", "豆包 2.0", false)
    ]
    
    var body: some View {
        ZStack {
            // 背景
            Constants.bgPrimary.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // === 1. 顶部栏：左上角汉堡菜单 ===
                HStack {
                    Button(action: { showSidebar = true }) {
                        Image(systemName: "line.3.horizontal")
                            .font(.system(size: 22, weight: .medium))
                            .foregroundColor(.white)
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 8)
                
                // === 2. 龙虾动画区(lobsterEmoji) ===
                // 安卓用WebView加载lobster_anim.html，iOS用原生动画模拟
                lobsterAnimation
                
                // === 3. 模型选择器 "● DeepSeek V3 ▾" ===
                Button(action: { showModelSelector = true }) {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Constants.accentGreen)
                            .frame(width: 8, height: 8)
                        Text("● \(getModelName(currentModel)) ▾")
                            .font(.system(size: 13))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Constants.bgTertiary)
                    .cornerRadius(20)
                }
                .padding(.top, 8)
                
                // === 4. 6个快捷技能按钮 ===
                quickSkillsArea
                
                // === 5. "开始对话"大按钮 + 发光脉冲 ===
                startChatButton
                
                Spacer()
                
                // === 6. 底部：任务按钮 + 输入框 + 发送按钮 ===
                bottomInputBar
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
            startGlowAnimation()
            startLobsterAnimation()
        }
    }
    
    // MARK: - 龙虾动画
    private var lobsterAnimation: some View {
        ZStack {
            // 光晕背景
            Circle()
                .fill(RadialGradient(
                    colors: [Constants.primaryPurple.opacity(0.15), Color.clear],
                    center: .center,
                    startRadius: 20,
                    endRadius: 120
                ))
                .frame(width: 240, height: 240)
            
            // 气泡装饰
            ForEach(0..<5, id: \.self) { i in
                Circle()
                    .fill(Constants.primaryPurple.opacity(0.1))
                    .frame(width: CGFloat(8 + i * 4), height: CGFloat(8 + i * 4))
                    .offset(
                        x: CGFloat.cos(Double(i) * 1.2) * 80,
                        y: CGFloat.sin(Double(i) * 1.2) * 80 + bubbleOffset
                    )
                    .opacity(0.6)
            }
            
            // 龙虾emoji主体（安卓用lobster_anim.html，iOS用🦞 + 原生动画）
            Text("🦞")
                .font(.system(size: 80))
                .scaleEffect(lobsterScale)
                .rotationEffect(.degrees(lobsterWiggle ? 3 : -3))
            
            // 龙虾名字
            Text("小龙虾")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Constants.primaryPurple)
                .padding(.top, 100)
        }
        .frame(height: 200)
    }
    
    // MARK: - 快捷技能（2行3列）
    private var quickSkillsArea: some View {
        VStack(spacing: 10) {
            // 第一行
            HStack(spacing: 10) {
                skillBtn(icon: "tablecells", title: "创建表格")
                skillBtn(icon: "magnifyingglass", title: "市场调研")
                skillBtn(icon: "note.text", title: "日常记录")
            }
            // 第二行
            HStack(spacing: 10) {
                skillBtn(icon: "doc.text", title: "创建合同")
                skillBtn(icon: "globe", title: "创建网站")
                skillBtn(icon: "airplane", title: "旅行规划")
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }
    
    private func skillBtn(icon: String, title: String) -> some View {
        Button(action: { inputText = "帮我\(title)" }) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(Constants.primaryPurple)
                Text(title)
                    .font(.system(size: 12))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 68)
            .background(Constants.bgTertiary)
            .cornerRadius(12)
        }
    }
    
    // MARK: - "开始对话"大按钮（发光脉冲）
    private var startChatButton: some View {
        Button(action: {}) {
            HStack(spacing: 10) {
                Image(systemName: "message.fill")
                    .font(.system(size: 20))
                Text("开始对话")
                    .font(.system(size: 18, weight: .bold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(
                LinearGradient(
                    colors: [Constants.primaryPurple, Constants.secondaryPurple],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(27)
            // 安卓: translationZ从0.4到0.7循环，2500ms
            .shadow(color: Constants.primaryPurple.opacity(Double(glowPhase)), radius: CGFloat(glowPhase) * 20, x: 0, y: CGFloat(glowPhase) * 8)
        }
        .padding(.horizontal, 32)
        .padding(.top, 20)
    }
    
    // MARK: - 底部输入栏
    private var bottomInputBar: some View {
        HStack(spacing: 12) {
            // 任务按钮(btnTask)
            Button(action: {}) {
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 22))
                    .foregroundColor(Constants.primaryPurple)
            }
            
            // 输入框(etInput)
            TextField("输入消息...", text: $inputText)
                .font(.system(size: 16))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Constants.bgTertiary)
                .cornerRadius(24)
            
            // 发送按钮(btnSend)
            Button(action: {}) {
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
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Constants.bgSecondary)
    }
    
    // MARK: - 动画
    private func startGlowAnimation() {
        withAnimation(.easeInOut(duration: 1.25).repeatForever(autoreverses: true)) {
            glowPhase = 0.7
        }
    }
    
    private func startLobsterAnimation() {
        // 龙虾摇摆动画
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            lobsterWiggle = true
        }
        // 龙虾呼吸缩放
        withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
            lobsterScale = 1.08
        }
        // 气泡浮动
        withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
            bubbleOffset = -10
        }
    }
    
    private func getModelName(_ id: String) -> String {
        for m in availableModels { if m.0 == id { return m.1 } }
        return "DeepSeek V3"
    }
}

// MARK: - 模型选择弹窗（对照安卓BottomSheetDialog）
struct ModelSelectorSheet: View {
    @Binding var currentModel: String
    @Environment(\.dismiss) private var dismiss
    
    private let availableModels = [
        ("deepseek-v3", "DeepSeek V3", true),
        ("kimi-2.5", "Kimi 2.5", false),
        ("glm-5", "GLM-5", false),
        ("minimax-m2.5", "MiniMax M2.5", false),
        ("doubao-2.0", "豆包 2.0", false)
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Constants.bgPrimary.ignoresSafeArea()
                VStack(spacing: 8) {
                    ForEach(availableModels, id: \.0) { model in
                        Button(action: {
                            if model.2 { currentModel = model.0; dismiss() }
                        }) {
                            HStack {
                                Text(model.1)
                                    .font(.system(size: 16))
                                    .foregroundColor(model.2 ? .white : Constants.textSecondary)
                                if !model.2 {
                                    Text("即将上线")
                                        .font(.system(size: 12))
                                        .foregroundColor(Constants.accentOrange)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 2)
                                        .background(Constants.accentOrange.opacity(0.2))
                                        .cornerRadius(4)
                                }
                                Spacer()
                                if model.0 == currentModel {
                                    Text("✓")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(Constants.primaryPurple)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 16)
                            .background(model.0 == currentModel ? Constants.primaryPurple.opacity(0.15) : Constants.bgSecondary)
                            .cornerRadius(12)
                        }
                        .disabled(!model.2)
                        .opacity(model.2 ? 1 : 0.6)
                    }
                    
                    // 取消按钮（对照安卓tvCancel）
                    Button(action: { dismiss() }) {
                        Text("取消")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Constants.textSecondary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(Constants.bgSecondary)
                            .cornerRadius(12)
                    }
                    .padding(.top, 8)
                    
                    Spacer()
                }
                .padding(16)
            }
            .navigationTitle("选择模型")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("取消") { dismiss() }
                        .foregroundColor(Constants.primaryPurple)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

#Preview { HomeView().environmentObject(AuthManager.shared) }
