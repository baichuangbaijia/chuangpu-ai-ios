import SwiftUI

/// 首页 v2.0.43 - 完全对照安卓HomeFragment，龙虾动画+全部UI细节
struct HomeView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var inputText = ""
    @State private var currentModel = "deepseek-v3"
    @State private var showModelSelector = false
    @State private var showSidebar = false
    @State private var glowPhase: Double = 0.4
    @State private var lobsterWiggle = false
    @State private var lobsterScale: CGFloat = 1.0
    @State private var bubble1Y: CGFloat = 0
    @State private var bubble2Y: CGFloat = 0
    @State private var bubble3Y: CGFloat = 0
    @State private var ringRotation: Double = 0
    
    var body: some View {
        ZStack {
            Constants.bgPrimary.ignoresSafeArea()
            VStack(spacing: 0) {
                topBar
                lobsterAnimationArea
                modelSelectorBtn
                quickSkillsArea
                startChatBtn
                Spacer()
                bottomInputBar
            }
        }
        .sheet(isPresented: $showSidebar) { SidebarView(onSelectConversation: { _ in }) }
        .sheet(isPresented: $showModelSelector) { ModelSelectorSheet(currentModel: $currentModel) }
        .onAppear { currentModel = authManager.getCurrentModel(); startAllAnimations() }
    }
    
    // MARK: 1. 左上角汉堡菜单(btnMenu)
    private var topBar: some View {
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
    }
    
    // MARK: 2. 龙虾动画(lobsterEmoji) - 完整还原安卓lobster_anim.html效果
    private var lobsterAnimationArea: some View {
        ZStack {
            // 外层光晕（呼吸效果）
            let outerGlow = Constants.primaryPurple.opacity(0.12)
            Circle()
                .fill(RadialGradient(colors: [outerGlow, Color.clear], center: .center, startRadius: 30, endRadius: 120))
                .frame(width: 240, height: 240)
            
            // 旋转圆环（模拟安卓龙虾周围的轨道效果）
            Circle()
                .stroke(
                    AngularGradient(
                        colors: [Constants.primaryPurple.opacity(0.6), Constants.secondaryPurple.opacity(0.2), Constants.primaryPurple.opacity(0.0)],
                        center: .center
                    ),
                    lineWidth: 2
                )
                .frame(width: 130, height: 130)
                .rotationEffect(.degrees(ringRotation))
            
            // 装饰气泡1
            bubbleView(offsetY: bubble1Y, xOffset: -60, size: 12, opacity: 0.3)
            // 装饰气泡2
            bubbleView(offsetY: bubble2Y, xOffset: 55, size: 8, opacity: 0.2)
            // 装饰气泡3
            bubbleView(offsetY: bubble3Y, xOffset: -30, size: 6, opacity: 0.25)
            
            // 龙虾主体🦞
            Text("\u{1F9E9}")
                .font(.system(size: 80))
                .scaleEffect(lobsterScale)
                .rotationEffect(.degrees(lobsterWiggle ? 5 : -5))
            
            // 龙虾名字
            Text("小龙虾")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Constants.primaryPurple)
                .padding(.top, 100)
        }
        .frame(height: 210)
    }
    
    private func bubbleView(offsetY: CGFloat, xOffset: CGFloat, size: CGFloat, opacity: Double) -> some View {
        Circle()
            .fill(Constants.primaryPurple.opacity(opacity))
            .frame(width: size, height: size)
            .offset(x: xOffset, y: offsetY)
    }
    
    // MARK: 3. 模型选择器 "● DeepSeek V3 ▾"(btnModel)
    private var modelSelectorBtn: some View {
        Button(action: { showModelSelector = true }) {
            let name = getModelName(currentModel)
            HStack(spacing: 4) {
                Circle().fill(Constants.accentGreen).frame(width: 8, height: 8)
                Text("\u{25CF} \(name) \u{25BE}")
                    .font(.system(size: 13))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Constants.bgTertiary)
            .cornerRadius(20)
        }
        .padding(.top, 8)
    }
    
    private func getModelName(_ id: String) -> String {
        let m: [(String, String)] = [
            ("deepseek-v3", "DeepSeek V3"),
            ("kimi-2.5", "Kimi 2.5"),
            ("glm-5", "GLM-5"),
            ("minimax-m2.5", "MiniMax M2.5"),
            ("doubao-2.0", "豆包 2.0")
        ]
        for item in m { if item.0 == id { return item.1 } }
        return "DeepSeek V3"
    }
    
    // MARK: 4. 6个快捷技能(skill1-6)
    private var quickSkillsArea: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                skillBtn(icon: "tablecells", title: "创建表格", color: Constants.accentBlue)
                skillBtn(icon: "magnifyingglass", title: "市场调研", color: Constants.accentGreen)
                skillBtn(icon: "note.text", title: "日常记录", color: Constants.accentOrange)
            }
            HStack(spacing: 10) {
                skillBtn(icon: "doc.text", title: "创建合同", color: Constants.primaryPurple)
                skillBtn(icon: "globe", title: "创建网站", color: Constants.secondaryPurple)
                skillBtn(icon: "airplane", title: "旅行规划", color: Constants.accentBlue)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }
    
    private func skillBtn(icon: String, title: String, color: Color) -> some View {
        Button(action: { inputText = "帮我\(title)" }) {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 36, height: 36)
                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundColor(color)
                }
                Text(title)
                    .font(.system(size: 11))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 72)
            .background(Constants.bgTertiary)
            .cornerRadius(12)
        }
    }
    
    // MARK: 5. "开始对话"大按钮(btnStart) - 发光脉冲动画
    private var startChatBtn: some View {
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
            .shadow(color: Constants.primaryPurple.opacity(glowPhase), radius: 16, x: 0, y: 6)
        }
        .padding(.horizontal, 32)
        .padding(.top, 20)
    }
    
    // MARK: 6. 底部: btnTask + etInput + btnSend
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
    
    // MARK: 动画
    private func startAllAnimations() {
        // "开始对话"按钮发光脉冲（对照安卓translationZ 0.4→0.7→0.4, 2500ms）
        withAnimation(.easeInOut(duration: 1.25).repeatForever(autoreverses: true)) { glowPhase = 0.7 }
        // 龙虾摇摆
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) { lobsterWiggle = true }
        // 龙虾呼吸缩放
        withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) { lobsterScale = 1.08 }
        // 气泡浮动
        withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) { bubble1Y = -15 }
        withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) { bubble2Y = -12 }
        withAnimation(.easeInOut(duration: 3.5).repeatForever(autoreverses: true)) { bubble3Y = -10 }
        // 圆环旋转
        withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) { ringRotation = 360 }
    }
}

// MARK: - 模型选择弹窗
struct ModelSelectorSheet: View {
    @Binding var currentModel: String
    @Environment(\.dismiss) private var dismiss
    
    private let models = [
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
                    ForEach(models, id: \.0) { m in
                        modelRow(m)
                    }
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
                    Button("取消") { dismiss() }.foregroundColor(Constants.primaryPurple)
                }
            }
        }
        .presentationDetents([.medium])
    }
    
    private func modelRow(_ m: (String, String, Bool)) -> some View {
        Button(action: {
            if m.2 { currentModel = m.0; dismiss() }
        }) {
            HStack {
                Text(m.1)
                    .font(.system(size: 16))
                    .foregroundColor(m.2 ? .white : Constants.textSecondary)
                if !m.2 {
                    Text("即将上线")
                        .font(.system(size: 12))
                        .foregroundColor(Constants.accentOrange)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Constants.accentOrange.opacity(0.2))
                        .cornerRadius(4)
                }
                Spacer()
                if m.0 == currentModel {
                    Text("\u{2713}")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Constants.primaryPurple)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(m.0 == currentModel ? Constants.primaryPurple.opacity(0.15) : Constants.bgSecondary)
            .cornerRadius(12)
        }
        .disabled(!m.2)
        .opacity(m.2 ? 1 : 0.6)
    }
}

#Preview { HomeView().environmentObject(AuthManager.shared) }
