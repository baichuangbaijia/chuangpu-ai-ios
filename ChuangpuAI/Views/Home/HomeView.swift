import SwiftUI

/// 首页 v2.0.45 - 虚拟办公室版
/// 布局：汉堡菜单 → 虚拟办公室(6龙虾) → 模型选择器 → 快捷技能6个 → "开始养虾"按钮 → 底部输入栏
struct HomeView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var inputText = ""
    @State private var currentModel = "deepseek-v3"
    @State private var showModelSelector = false
    @State private var showSidebar = false
    @State private var glowPhase: Double = 0.4
    
    var body: some View {
        ZStack {
            Constants.bgPrimary.ignoresSafeArea()
            VStack(spacing: 0) {
                topBar
                lobsterOffice
                modelSelectorBtn
                quickSkillsArea
                startYangXiaBtn
                Spacer()
                bottomInputBar
            }
        }
        .sheet(isPresented: $showSidebar) { SidebarView(onSelectConversation: { _ in }) }
        .sheet(isPresented: $showModelSelector) { ModelSelectorSheet(currentModel: $currentModel) }
        .onAppear { currentModel = authManager.getCurrentModel(); startAnimations() }
    }
    
    // 1. 顶部栏
    private var topBar: some View {
        HStack {
            Button(action: { showSidebar = true }) {
                Image(systemName: "line.3.horizontal").font(.system(size: 22, weight: .medium)).foregroundColor(.white)
            }
            Spacer()
            Text("创普AI团队").font(.system(size: 16, weight: .semibold)).foregroundColor(.white)
            Spacer()
            Button(action: { showModelSelector = true }) {
                let name = getModelName(currentModel)
                HStack(spacing: 4) {
                    Circle().fill(Constants.accentGreen).frame(width: 6, height: 6)
                    Text(name).font(.system(size: 12)).foregroundColor(Constants.textSecondary)
                    Image(systemName: "chevron.down").font(.system(size: 10)).foregroundColor(Constants.textSecondary)
                }.padding(.horizontal, 10).padding(.vertical, 6).background(Constants.bgTertiary).cornerRadius(16)
            }
        }.padding(.horizontal, 16).padding(.top, 12).padding(.bottom, 4)
    }
    
    // 2. 虚拟办公室 - 6只龙虾
    private var lobsterOffice: some View {
        LobsterOfficeView()
            .frame(height: 220)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 8)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Constants.primaryPurple.opacity(0.3), lineWidth: 1)
            )
    }
    
    // 3. 模型选择器（简化显示）
    private var modelSelectorBtn: some View {
        Button(action: { showModelSelector = true }) {
            let name = getModelName(currentModel)
            HStack(spacing: 4) {
                Circle().fill(Constants.accentGreen).frame(width: 8, height: 8)
                Text("● \(name) ▾").font(.system(size: 13)).foregroundColor(.white)
            }.padding(.horizontal, 14).padding(.vertical, 8).background(Constants.bgTertiary).cornerRadius(20)
        }.padding(.top, 8)
    }
    
    private func getModelName(_ id: String) -> String {
        let m: [(String, String)] = [("deepseek-v3","DeepSeek V3"),("kimi-2.5","Kimi 2.5"),("glm-5","GLM-5"),("minimax-m2.5","MiniMax M2.5"),("doubao-2.0","豆包 2.0")]
        for item in m { if item.0 == id { return item.1 } }
        return "DeepSeek V3"
    }
    
    // 4. 6个快捷技能
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
        }.padding(.horizontal, 20).padding(.top, 16)
    }
    
    private func skillBtn(icon: String, title: String, color: Color) -> some View {
        Button(action: { inputText = "帮我\(title)" }) {
            VStack(spacing: 6) {
                ZStack {
                    Circle().fill(color.opacity(0.15)).frame(width: 36, height: 36)
                    Image(systemName: icon).font(.system(size: 18)).foregroundColor(color)
                }
                Text(title).font(.system(size: 11)).foregroundColor(.white)
            }.frame(maxWidth: .infinity).frame(height: 72).background(Constants.bgTertiary).cornerRadius(12)
        }
    }
    
    // 5. "开始养虾"大按钮
    private var startYangXiaBtn: some View {
        Button(action: {}) {
            HStack(spacing: 10) {
                Image(systemName: "message.fill").font(.system(size: 20))
                Text("开始养虾").font(.system(size: 18, weight: .bold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity).frame(height: 54)
            .background(LinearGradient(colors: [Constants.primaryPurple, Constants.secondaryPurple], startPoint: .leading, endPoint: .trailing))
            .cornerRadius(27)
            .shadow(color: Constants.primaryPurple.opacity(glowPhase), radius: 16, x: 0, y: 6)
        }.padding(.horizontal, 32).padding(.top, 16)
    }
    
    // 6. 底部输入栏
    private var bottomInputBar: some View {
        HStack(spacing: 12) {
            Button(action: {}) { Image(systemName: "calendar.badge.clock").font(.system(size: 22)).foregroundColor(Constants.primaryPurple) }
            TextField("输入消息...", text: $inputText).font(.system(size: 16)).foregroundColor(.white).padding(.horizontal, 16).padding(.vertical, 12).background(Constants.bgTertiary).cornerRadius(24)
            Button(action: {}) {
                Image(systemName: "arrow.up.circle.fill").font(.system(size: 36)).foregroundStyle(LinearGradient(colors: [Constants.primaryPurple, Constants.secondaryPurple], startPoint: .topLeading, endPoint: .bottomTrailing))
            }.disabled(inputText.isEmpty).opacity(inputText.isEmpty ? 0.5 : 1)
        }.padding(.horizontal, 16).padding(.vertical, 14).background(Constants.bgSecondary)
    }
    
    private func startAnimations() {
        withAnimation(.easeInOut(duration: 1.25).repeatForever(autoreverses: true)) { glowPhase = 0.7 }
    }
}

#Preview { HomeView().environmentObject(AuthManager.shared) }
