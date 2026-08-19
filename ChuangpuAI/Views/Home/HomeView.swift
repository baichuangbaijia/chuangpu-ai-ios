import SwiftUI

struct HomeView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var inputText = ""
    @State private var currentModel = "deepseek-v4-flash"
    @State private var showModelSelector = false
    @State private var showSidebar = false
    @State private var glowPhase: Double = 0.4
    
    var body: some View {
        ZStack {
            Constants.bgPrimary.ignoresSafeArea()
            VStack(spacing: 0) {
                topBar
                lobsterOffice
                Spacer(minLength: 4)
                quickSkillsArea
                platformArea
                Spacer(minLength: 4)
                startYangXiaBtn
                Spacer()
                bottomInputBar
            }
        }
        .sheet(isPresented: $showSidebar) { SidebarView(onSelectConversation: { _ in }) }
        .sheet(isPresented: $showModelSelector) { ModelSelectorSheet(currentModel: $currentModel) }
        .onAppear { currentModel = authManager.getCurrentModel(); startAnimations() }
    }
    
    private var topBar: some View {
        HStack {
            Button(action: { showSidebar = true }) {
                Image(systemName: "line.3.horizontal").font(.system(size: 22, weight: .medium)).foregroundColor(.white)
            }
            Spacer()
            Text("开始养虾").font(.system(size: 16, weight: .semibold)).foregroundColor(.white)
            Spacer()
            Button(action: { showModelSelector = true }) {
                let name = getModelName(currentModel)
                HStack(spacing: 4) {
                    Circle().fill(Constants.accentGreen).frame(width: 6, height: 6)
                    Text(name).font(.system(size: 12)).foregroundColor(Constants.textSecondary)
                    Image(systemName: "chevron.down").font(.system(size: 10)).foregroundColor(Constants.textSecondary)
                }.padding(.horizontal, 10).padding(.vertical, 6).background(Constants.bgTertiary).cornerRadius(16)
            }
        }.padding(.horizontal, 16).padding(.top, 12).padding(.bottom, 2)
    }
    
    private var lobsterOffice: some View {
        LobsterOfficeView()
            .frame(height: 320)
            .padding(.horizontal, 0)
    }
    
    private func getModelName(_ id: String) -> String {
        let m: [(String, String)] = [("deepseek-v4-flash","DeepSeek-V4-Flash"),("deepseek-v3","DeepSeek V3"),("kimi-2.5","Kimi 2.5"),("glm-5","GLM-5"),("minimax-m2.5","MiniMax M2.5"),("doubao-2.0","豆包 2.0")]
        for item in m { if item.0 == id { return item.1 } }
        return "DeepSeek-V4-Flash"
    }
    
    private var quickSkillsArea: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                skillBtn(icon: "tablecells", title: "创建表格", bg: Constants.primaryPurple, gradient: false)
                skillBtn(icon: "magnifyingglass", title: "市场调研", bg: Constants.bgTertiary, gradient: false)
                skillBtn(icon: "note.text", title: "日常记录", bg: Constants.secondaryPurple, gradient: false)
            }
            HStack(spacing: 8) {
                skillBtn(icon: "doc.text", title: "创建合同", bg: Constants.primaryPurple, gradient: true)
                skillBtn(icon: "globe", title: "创建网站", bg: Constants.bgTertiary, gradient: true)
                skillBtn(icon: "airplane", title: "旅行规划", bg: Constants.secondaryPurple, gradient: true)
            }
        }.padding(.horizontal, 16)
    }
    
    private func skillBtn(icon: String, title: String, bg: Color, gradient: Bool) -> some View {
        Button(action: { inputText = "帮我\(title)" }) {
            HStack(spacing: 8) {
                Image(systemName: icon).font(.system(size: 16)).foregroundColor(.white)
                Text(title).font(.system(size: 12, weight: .medium)).foregroundColor(.white)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity).frame(height: 48)
            .background(
                Group {
                    if gradient {
                        LinearGradient(colors: [bg, bg.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    } else {
                        LinearGradient(colors: [bg, bg], startPoint: .leading, endPoint: .trailing)
                    }
                }
            )
            .cornerRadius(24)
        }
    }
    
    private var startYangXiaBtn: some View {
        VStack(spacing: 10) {
            Button(action: {}) {
                HStack(spacing: 10) {
                    Text("\u{1F99E}").font(.system(size: 22))
                    Text("开始养虾").font(.system(size: 16, weight: .bold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity).frame(height: 48)
                .background(LinearGradient(colors: [Constants.primaryPurple, Constants.secondaryPurple], startPoint: .leading, endPoint: .trailing))
                .cornerRadius(24)
                .shadow(color: Constants.primaryPurple.opacity(glowPhase), radius: 14, x: 0, y: 4)
            }
            Text("7×24小时帮你干活的全场景私人助理")
                .font(.system(size: 12))
                .foregroundColor(Constants.textSecondary)
        }.padding(.horizontal, 32)
    }
    
    // 聊天平台接入区（对照安卓：微信/企微/飞书/钉钉）
    private var platformArea: some View {
        VStack(spacing: 8) {
            Text("聊天平台接入").font(.system(size: 11)).foregroundColor(Constants.textSecondary)
            HStack(spacing: 28) {
                platformIcon(icon: "message.fill", name: "微信", bg: Color(red: 0.03, green: 0.76, blue: 0.38))
                platformIcon(icon: "building.2.fill", name: "企业微信", bg: Color(red: 0.00, green: 0.51, blue: 0.94))
                platformIcon(icon: "paperplane.fill", name: "飞书", bg: Color(red: 0.20, green: 0.44, blue: 1.00))
                platformIcon(icon: "pin.fill", name: "钉钉", bg: Color(red: 0.00, green: 0.54, blue: 1.00))
            }
        }
    }
    
    private func platformIcon(icon: String, name: String, bg: Color) -> some View {
        VStack(spacing: 4) {
            ZStack {
                RoundedRectangle(cornerRadius: 10).fill(bg).frame(width: 40, height: 40)
                Image(systemName: icon).font(.system(size: 18, weight: .medium)).foregroundColor(.white)
            }
            Text(name).font(.system(size: 10)).foregroundColor(Constants.textSecondary)
        }
    }
    
    private var bottomInputBar: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                Button(action: {}) { Image(systemName: "calendar.badge.clock").font(.system(size: 22)).foregroundColor(Constants.primaryPurple) }
                TextField("分配一个任务或提问任何问题", text: $inputText).font(.system(size: 16)).foregroundColor(.white).padding(.horizontal, 16).padding(.vertical, 12).background(Constants.bgTertiary).cornerRadius(24)
                Button(action: {}) {
                    Image(systemName: "arrow.up.circle.fill").font(.system(size: 36)).foregroundStyle(Constants.accentOrange)
                }.disabled(inputText.isEmpty).opacity(inputText.isEmpty ? 0.5 : 1)
            }
            HStack(spacing: 12) {
                Button(action: {}) {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar").font(.system(size: 10))
                        Text("定时任务").font(.system(size: 11))
                    }
                    .foregroundColor(Constants.accentOrange)
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(Constants.accentOrange.opacity(0.15))
                    .cornerRadius(12)
                }
                Button(action: { showModelSelector = true }) {
                    HStack(spacing: 4) {
                        Circle().fill(Constants.accentGreen).frame(width: 5, height: 5)
                        Text(getModelName(currentModel)).font(.system(size: 11))
                    }
                    .foregroundColor(Constants.textSecondary)
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(Constants.bgTertiary)
                    .cornerRadius(12)
                }
            }
        }.padding(.horizontal, 16).padding(.vertical, 10).background(Constants.bgSecondary)
    }
    
    private func startAnimations() {
        withAnimation(.easeInOut(duration: 1.25).repeatForever(autoreverses: true)) { glowPhase = 0.7 }
    }
}

#Preview { HomeView().environmentObject(AuthManager.shared) }

struct ModelSelectorSheet: View {
    @Binding var currentModel: String
    @Environment(\.dismiss) private var dismiss
    private let models = [("deepseek-v4-flash","DeepSeek-V4-Flash",true),("deepseek-v3","DeepSeek V3",true),("kimi-2.5","Kimi 2.5",false),("glm-5","GLM-5",false),("minimax-m2.5","MiniMax M2.5",false),("doubao-2.0","豆包 2.0",false)]
    var body: some View {
        NavigationStack {
            ZStack {
                Constants.bgPrimary.ignoresSafeArea()
                VStack(spacing: 8) {
                    ForEach(models, id: \.0) { m in modelRow(m) }
                    Button(action: { dismiss() }) { Text("取消").font(.system(size: 16, weight: .medium)).foregroundColor(Constants.textSecondary).frame(maxWidth: .infinity).frame(height: 48).background(Constants.bgSecondary).cornerRadius(12) }.padding(.top, 8)
                    Spacer()
                }.padding(16)
            }
            .navigationTitle("选择模型").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .navigationBarTrailing) { Button("取消") { dismiss() }.foregroundColor(Constants.primaryPurple) } }
        }.presentationDetents([.medium])
    }
    private func modelRow(_ m: (String, String, Bool)) -> some View {
        Button(action: { if m.2 { currentModel = m.0; dismiss() } }) {
            HStack {
                Text(m.1).font(.system(size: 16)).foregroundColor(m.2 ? .white : Constants.textSecondary)
                if !m.2 { Text("即将上线").font(.system(size: 12)).foregroundColor(Constants.accentOrange).padding(.horizontal, 8).padding(.vertical, 2).background(Constants.accentOrange.opacity(0.2)).cornerRadius(4) }
                Spacer()
                if m.0 == currentModel { Text("\u{2713}").font(.system(size: 16, weight: .medium)).foregroundColor(Constants.primaryPurple) }
            }.padding(.horizontal, 16).padding(.vertical, 16).background(m.0 == currentModel ? Constants.primaryPurple.opacity(0.15) : Constants.bgSecondary).cornerRadius(12)
        }.disabled(!m.2).opacity(m.2 ? 1 : 0.6)
    }
}
