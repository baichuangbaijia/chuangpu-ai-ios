import UIKit
import SwiftUI

struct ChatMessage: Identifiable {
    let id = UUID()
    let text: String
    let isUser: Bool
}

struct HomeView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var inputText = ""
    @State private var currentModel = "deepseek-v4-flash"
    @State private var showModelSelector = false
    @State private var showSidebar = false
    @State private var glowPhase: Double = 0.4
    @FocusState private var inputFocused: Bool
    @State private var messages: [ChatMessage] = []

    // 屏幕自适应参数
    private let hPadding: CGFloat = 16
    private let itemSpacing: CGFloat = 8

    var body: some View {
        VStack(spacing: 0) {
            topBar
            // 内容区：聊天模式显示聊天记录，首页模式显示首页卡片（都不含输入框）
            Group {
                if inputFocused {
                    // 聊天模式：聊天区占满输入栏上方，独立滚动，点空白收键盘
                    chatHistoryArea
                        .scrollDismissesKeyboard(.interactively)
                        .onTapGesture { inputFocused = false }
                } else {
                    // 首页模式：龙虾/按钮/弹性空白（不含输入框，输入框常驻下方）
                    homeTop
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // 输入框常驻（VStack 第 3 元素，永不销毁；未聚焦时位于 6 卡片上方，聚焦时贴键盘顶）
            inputBar
                .padding(.horizontal, hPadding)

            // 首页下区：6 快捷卡片 + 平台接入（聚焦时隐藏；非输入框，切换销毁无副作用）
            if !inputFocused {
                homeBottom
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Constants.bgPrimary.ignoresSafeArea())
        .sheet(isPresented: $showSidebar) { SidebarView(onSelectConversation: { _ in }) }
        .sheet(isPresented: $showModelSelector) { ModelSelectorSheet(currentModel: $currentModel) }
        .onAppear { currentModel = authManager.getCurrentModel(); startAnimations() }
    }

    // 首页上区：龙虾/开始养虾/弹性空白（占满，把输入框顶到 6 卡片上方）
    private var homeTop: some View {
        VStack(spacing: itemSpacing) {
            lobsterHero
            startYangXiaBtn
            Spacer(minLength: itemSpacing)
        }
        .padding(.top, 4)
    }

    // 首页下区：6 快捷卡片 + 平台接入（在输入框下方；顶部 16pt 与输入栏分隔，避免视觉粘连）
    private var homeBottom: some View {
        VStack(spacing: itemSpacing) {
            quickSkillsArea
            platformArea
        }
        .padding(.horizontal, hPadding)
        .padding(.top, 16)
        .padding(.bottom, 16)
    }

    // 导航栏：只留汉堡（对照安卓，无标题无模型标签）
    private var topBar: some View {
        HStack {
            Button(action: { showSidebar = true }) {
                Image(systemName: "line.3.horizontal").font(.system(size: 22, weight: .medium)).foregroundColor(.white)
            }
            Spacer()
        }
        .padding(.horizontal, hPadding)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }

    // 主视觉：红色大龙虾（高度按屏幕比例自适应，钳制 170~300）
    private var lobsterHero: some View {
        let heroH = min(max(UIScreen.main.bounds.height * 0.18, 100), 200)
        return Image("lobster")
            .resizable()
            .scaledToFit()
            .frame(maxWidth: .infinity)
            .frame(height: heroH)
    }

    private func getModelName(_ id: String) -> String {
        let m: [(String, String)] = [("deepseek-v4-flash","DeepSeek-V4-Flash"),("deepseek-v3","DeepSeek V3"),("kimi-2.5","Kimi 2.5"),("glm-5","GLM-5"),("minimax-m2.5","MiniMax M2.5"),("doubao-2.0","豆包 2.0")]
        for item in m { if item.0 == id { return item.1 } }
        return "DeepSeek-V4-Flash"
    }

    // 「开始养虾」大按钮 + 副文案（紧贴龙虾下方）
    private var startYangXiaBtn: some View {
        VStack(spacing: 8) {
            Button(action: {}) {
                HStack(spacing: 10) {
                    Text("\u{1F99E}").font(.system(size: 22))
                    Text("开始养虾").font(.system(size: 16, weight: .bold))
                }
                .foregroundColor(.white)
                .frame(width: (UIScreen.main.bounds.width - hPadding * 2) / 2).frame(height: 50)
                .background(LinearGradient(colors: [Constants.primaryPurple, Constants.secondaryPurple], startPoint: .leading, endPoint: .trailing))
                .cornerRadius(25)
                .shadow(color: Constants.primaryPurple.opacity(glowPhase), radius: 14, x: 0, y: 4)
            }
            Text("7×24小时帮你干活的全场景私人助理")
                .font(.system(size: 12))
                .foregroundColor(Constants.textSecondary)
        }
        .padding(.horizontal, 8)
    }

    // 聊天框（放大版）：输入行 + 发送键 + 标签行（定时任务/模型）都在框内
    private var inputBar: some View {
        VStack(spacing: 10) {
            // 输入行：输入框 + 发送键（左侧无图标）
            HStack(spacing: 10) {
                TextField("分配一个任务或提问任何问题", text: $inputText, axis: .vertical)
                    .lineLimit(1...5)
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .focused($inputFocused)
                Button(action: sendMessage) {
                    Image(systemName: "arrow.up.circle.fill").font(.system(size: 30)).foregroundStyle(Constants.accentOrange)
                }
                .disabled(inputText.isEmpty).opacity(inputText.isEmpty ? 0.5 : 1)
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 2)

            // 标签行：定时任务 / 选择模型（在聊天框内）
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
                    .background(Constants.bgSecondary)
                    .cornerRadius(12)
                }
                Spacer()
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Constants.bgTertiary)
        .cornerRadius(24)
        .frame(maxWidth: .infinity)
    }

    // 快捷按钮 6 个：3 列自动等分撑满整行，高度按屏宽比例自适应
    private var quickSkillsArea: some View {
        let btnH = (UIScreen.main.bounds.width - 48) / 3 * 0.45
        return VStack(spacing: 8) {
            HStack(spacing: 8) {
                skillBtn(icon: "tablecells", title: "创建表格", bg: Constants.primaryPurple, gradient: false, h: btnH)
                skillBtn(icon: "magnifyingglass", title: "市场调研", bg: Constants.bgTertiary, gradient: false, h: btnH)
                skillBtn(icon: "note.text", title: "日常记录", bg: Constants.secondaryPurple, gradient: false, h: btnH)
            }
            HStack(spacing: 8) {
                skillBtn(icon: "doc.text", title: "创建合同", bg: Constants.primaryPurple, gradient: true, h: btnH)
                skillBtn(icon: "globe", title: "创建网站", bg: Constants.bgTertiary, gradient: true, h: btnH)
                skillBtn(icon: "airplane", title: "旅行规划", bg: Constants.secondaryPurple, gradient: true, h: btnH)
            }
        }
    }

    private func skillBtn(icon: String, title: String, bg: Color, gradient: Bool, h: CGFloat) -> some View {
        Button(action: { inputText = "帮我\(title)" }) {
            HStack(spacing: 8) {
                Image(systemName: icon).font(.system(size: 15)).foregroundColor(.white)
                Text(title).font(.system(size: 11, weight: .medium)).foregroundColor(.white)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 10)
            .frame(maxWidth: .infinity)
            .frame(height: h)
            .background(
                Group {
                    if gradient {
                        LinearGradient(colors: [bg, bg.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    } else {
                        LinearGradient(colors: [bg, bg], startPoint: .leading, endPoint: .trailing)
                    }
                }
            )
            .cornerRadius(h/2)
        }
    }

    // 支持聊天平台接入区（对照安卓：微信/企微/飞书/钉钉）
    private var platformArea: some View {
        VStack(spacing: 8) {
            Text("支持聊天平台接入").font(.system(size: 11)).foregroundColor(Constants.textSecondary)
            HStack(spacing: 8) {
                platformIcon(icon: "message.fill", name: "微信", bg: Color(red: 0.03, green: 0.76, blue: 0.38)).frame(maxWidth: .infinity)
                platformIcon(icon: "building.2.fill", name: "企业微信", bg: Color(red: 0.00, green: 0.51, blue: 0.94)).frame(maxWidth: .infinity)
                platformIcon(icon: "paperplane.fill", name: "飞书", bg: Color(red: 0.20, green: 0.44, blue: 1.00)).frame(maxWidth: .infinity)
                platformIcon(icon: "pin.fill", name: "钉钉", bg: Color(red: 0.00, green: 0.54, blue: 1.00)).frame(maxWidth: .infinity)
            }
        }
    }

    private func platformIcon(icon: String, name: String, bg: Color) -> some View {
        VStack(spacing: 4) {
            ZStack {
                RoundedRectangle(cornerRadius: 10).fill(bg).frame(width: 36, height: 36)
                Image(systemName: icon).font(.system(size: 18, weight: .medium)).foregroundColor(.white)
            }
            Text(name).font(.system(size: 10)).foregroundColor(Constants.textSecondary)
        }
    }

    // 聊天记录区（聚焦时显示，自动占满输入栏上方空间，独立滚动）
    private var chatHistoryArea: some View {
        Group {
            if messages.isEmpty {
                emptyChatGuide
            } else {
                ScrollViewReader { proxy in
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 10) {
                            ForEach(messages) { msg in
                                chatBubble(msg)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .onChange(of: messages.count) { _ in
                        if let last = messages.last {
                            withAnimation(.easeOut(duration: 0.25)) { proxy.scrollTo(last.id, anchor: .bottom) }
                        }
                    }
                }
            }
        }
    }

    // 空状态引导：品牌问候 + 派活卡片（messages 为空时显示，点击卡片自动填入输入框）
    private var emptyChatGuide: some View {
        VStack(spacing: 24) {
            Spacer(minLength: 0)
            VStack(spacing: 6) {
                Text("🦞 一人成军 · AI 相助")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                Text("向你的 AI 员工派活吧")
                    .font(.system(size: 13))
                    .foregroundColor(Constants.textSecondary)
            }
            VStack(spacing: 10) {
                taskCard(icon: "doc.text", title: "帮我写一份工作周报")
                taskCard(icon: "chart.bar", title: "帮我分析这份销售数据")
                taskCard(icon: "globe", title: "帮我做个公司官网")
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 16)
    }

    // 派活卡片：点击自动填入输入框（不直接发送，用户确认后按发送）
    private func taskCard(icon: String, title: String) -> some View {
        Button(action: { inputText = title }) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 15))
                    .foregroundColor(Constants.accentOrange)
                Text(title)
                    .font(.system(size: 14))
                    .foregroundColor(.white)
                Spacer(minLength: 0)
                Image(systemName: "arrow.up.left")
                    .font(.system(size: 11))
                    .foregroundColor(Constants.textSecondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 13)
            .frame(maxWidth: .infinity)
            .background(Constants.bgSecondary.opacity(0.6))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
        }
    }

    // 聊天气泡：用户消息右侧紫色，AI 回复左侧深色
    private func chatBubble(_ msg: ChatMessage) -> some View {
        HStack {
            if msg.isUser { Spacer(minLength: 40) }
            Text(msg.text)
                .font(.system(size: 14))
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(msg.isUser ? Constants.primaryPurple : Constants.bgTertiary)
                .cornerRadius(14)
            if !msg.isUser { Spacer(minLength: 40) }
        }
        .id(msg.id)
    }

    // 发送消息（本地演示版：上屏+模拟AI回复，接真实接口后替换）
    private func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        messages.append(ChatMessage(text: text, isUser: true))
        inputText = ""
        inputFocused = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            messages.append(ChatMessage(text: "收到，我马上帮你处理「\(text)」（演示回复，接入接口后自动替换）", isUser: false))
        }
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
