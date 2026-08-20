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
    @State private var showChat = false
    @FocusState private var inputFocused: Bool
    @State private var isKeyboardUp = false
    // 2.1.5：键盘弹起目标拉伸高度（键盘通知到达瞬间一次性预计算，动画期间锁死为常量不再重算 → 收起不晃）
    @State private var stretchedHeight: CGFloat = 0
    // 2.1.5：安全区顶部高度（GeometryReader 仅读一次系统值，非逐帧测量；键盘通知回调拿不到 geo，故存状态）
    @State private var topSafe: CGFloat = 0

    // 屏幕自适应参数
    private let hPadding: CGFloat = 16
    private let itemSpacing: CGFloat = 8

    var body: some View {
        // 2.0.95：去掉导航栈改 ZStack 手动全屏切换（规避 iOS16 导航栈根视图输入框键盘不弹）
        // 2.1.5：外包 GeometryReader 仅读取安全区顶部高度（常量，非逐帧测量）；输入栏聚焦高度改为键盘通知瞬间预计算目标常量，动画与键盘同步，收起单调回缩不晃
        GeometryReader { geo in
        ZStack {
            VStack(spacing: 0) {
                topBar
                // 首页模式常驻：龙虾/按钮/弹性空白（2.0.93 输入跳转独立对话页，不再就地切换聊天）
                Group {
                    homeTop
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                // 输入框（2.0.94：点击聚焦就地输入不跳转，固定一行不拉伸；点发送才跳转新对话页）
                inputBar()
                    .padding(.horizontal, hPadding)

                // 首页下区：6 快捷卡片 + 平台接入（2.0.96：键盘弹起让位隐藏，输入栏贴键盘顶）
                if !isKeyboardUp {
                    homeBottom
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Constants.bgPrimary.ignoresSafeArea())
            // 2.1.5：安全区顶只读一次存状态（常量），供键盘通知预计算目标高度使用
            .onAppear { topSafe = geo.safeAreaInsets.top }
            // 2.0.95：首页点空白收键盘（对齐新对话页 2.0.88 做法）
            .contentShape(Rectangle())
            .onTapGesture { if inputFocused { inputFocused = false } }
            // 2.0.96：键盘弹起下区让位隐藏，收起恢复；输入栏由系统避让自动贴键盘顶
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { note in
                // 2.1.5：键盘通知到达瞬间一次性预计算目标拉伸高度并锁死为常量（动画期间不再重算），
                // 输入栏拉伸与键盘同动画同速（时长取键盘通知），收起时单调平滑回缩 → 杜绝冲高回落/末帧跳变/闪烁
                let info = note.userInfo
                let kbH = (info?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect)?.height ?? 0
                let kbDur = (info?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double) ?? 0.25
                let target = stretchedInputHeight(keyboardH: kbH)
                withAnimation(.easeOut(duration: kbDur)) {
                    isKeyboardUp = true
                    stretchedHeight = target
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { note in
                // 2.1.5：收起只翻 isKeyboardUp，输入栏高度由布尔驱动从目标常量单调平滑回缩到原高，
                // 全程不碰键盘高度数值（2.1.4 用动态高度重算 → 先胀后缩 + 末帧跳变 = 晃，已废除）
                let kbDur = (note.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double) ?? 0.25
                withAnimation(.easeOut(duration: kbDur)) {
                    isKeyboardUp = false
                    stretchedHeight = 0
                }
            }
            .sheet(isPresented: $showSidebar) { SidebarView(onSelectConversation: { _ in }) }
            .sheet(isPresented: $showModelSelector) { ModelSelectorSheet(currentModel: $currentModel) }
            .onAppear { currentModel = authManager.getCurrentModel(); inputFocused = false; startAnimations() }

            // 2.0.95：跳转新对话页用 ZStack 全屏覆盖（不依赖导航栈），返回回调关掉覆盖层
            if showChat {
                ChatConversationView(initialText: inputText, onClose: {
                    withAnimation(.easeInOut(duration: 0.25)) { showChat = false }
                })
                .transition(.move(edge: .trailing))
                .zIndex(1)
            }
        }
        }
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

    // 龙虾主视觉高度（按屏幕比例自适应，钳制 100~200）
    private var heroHeight: CGFloat {
        min(max(UIScreen.main.bounds.height * 0.18, 100), 200)
    }

    // 主视觉：红色大龙虾（2.1.3：键盘弹起不再压缩，恒等原高 → 开始养虾按钮与 7×24 文案位置不动）
    private var lobsterHero: some View {
        Image("lobster")
            .resizable()
            .scaledToFit()
            .frame(maxWidth: .infinity)
            .frame(height: heroHeight)
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

    // 输入框（2.1.5）：点击聚焦就地输入不跳转；聚焦时等键盘通知到达后按剩余空间预计算目标高度（上限两倍 200pt）并锁死为常量，动画与键盘同速不再闪；收起时单调平滑回缩不再晃；上区（龙虾/按钮/文案）不动只挤压留白；标签行固定下方不上浮；点发送才跳转新对话页
    private func inputBar() -> some View {
        VStack(spacing: 10) {
            // 输入行：输入框（固定一行）+ 发送键（点发送带内容跳转）
            HStack(spacing: 10) {
                TextField("分配一个任务或提问任何问题", text: $inputText)
                    .lineLimit(1)
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .focused($inputFocused)
                    .submitLabel(.send)
                    .onSubmit { if inputFocused { jumpToChat() } }  // 2.0.95：防失焦误触发跳转
                Button(action: jumpToChat) {
                    Image(systemName: "arrow.up.circle.fill").font(.system(size: 30)).foregroundStyle(Constants.accentOrange)
                }
                .disabled(inputText.isEmpty).opacity(inputText.isEmpty ? 0.5 : 1)
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 2)

            // 标签行：定时任务 / 选择模型（固定在下，不随聚焦上浮；2.1.2）
            tagRow
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        // 2.1.5：键盘弹起时用预计算目标高度（常量，动画期间不再重算）；收起时 isKeyboardUp 布尔翻转 → 从目标值单调平滑回缩到原高；键盘未弹起保持原高
        .frame(height: inputFocused && isKeyboardUp ? stretchedHeight : nil, alignment: .bottom)
        .background(Constants.bgTertiary)
        .cornerRadius(24)
    }

    // 2.1.5：输入栏聚焦目标高度 = min(两倍 200, 全屏高度 - 安全区顶 - 键盘最终高 - 固定上区)；
    // 仅在键盘通知到达瞬间调用一次（keyboardH 为键盘最终高度），算完即锁死为常量，动画期间不再重算
    private func stretchedInputHeight(keyboardH: CGFloat) -> CGFloat {
        let available = UIScreen.main.bounds.height - topSafe - keyboardH
        // 固定上区：topBar(~40) + homeTop padding top(4) + 龙虾(heroHeight) + spacing(8) + 开始养虾按钮组(50+8+16=74) + 最小留白(8)
        let fixedTop: CGFloat = 40 + 4 + heroHeight + itemSpacing + 74 + itemSpacing
        return min(200, max(93, available - fixedTop))
    }

    // 标签行：定时任务 / 选择模型（2.0.99 抽出复用；聚焦时上浮到输入行上方，未聚焦在输入行下方）
    private var tagRow: some View {
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

    // 发送跳转（2.0.94）：点输入框不跳转，点发送才带内容跳转新对话页
    private func jumpToChat() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        inputFocused = false
        withAnimation(.easeInOut(duration: 0.25)) { showChat = true }
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


// 独立对话页（2.0.93）：点首页输入框跳转进入，顶部返回键；输入框固定单行不自动拉伸
struct ChatConversationView: View {
    @EnvironmentObject var authManager: AuthManager
    // 2.0.95：无导航栈，返回用回调
    let onClose: () -> Void
    @State private var inputText: String
    @State private var currentModel = "deepseek-v4-flash"
    @State private var showModelSelector = false
    @State private var messages: [ChatMessage] = []
    @State private var initialText: String = ""
    @FocusState private var inputFocused: Bool

    init(initialText: String = "", onClose: @escaping () -> Void = {}) {
        self.onClose = onClose
        _inputText = State(initialValue: "")
        _initialText = State(initialValue: initialText)
        // 带词跳转：发送的内容直接上屏为第一条用户消息（2.0.94）
        var msgs: [ChatMessage] = []
        let t = initialText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !t.isEmpty {
            msgs.append(ChatMessage(text: t, isUser: true))
        }
        _messages = State(initialValue: msgs)
    }

    var body: some View {
        VStack(spacing: 0) {
            // 顶部导航栏：返回 + 标题（对标微信对话页）
            HStack {
                Button(action: { onClose() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                Spacer()
                Text("新对话").font(.system(size: 16, weight: .semibold)).foregroundColor(.white)
                Spacer()
                Color.clear.frame(width: 44, height: 44)
            }
            .padding(.horizontal, 8)
            .padding(.top, 4)
            .padding(.bottom, 4)

            // 聊天区：空状态纯空白 / 消息气泡；点空白收键盘（2.0.94 问候语全删）
            Group {
                if messages.isEmpty {
                    Color.clear
                } else {
                    chatHistoryArea
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
            .onTapGesture { inputFocused = false }

            // 输入框（固定单行，不自动拉伸）+ 标签行
            inputBar
                .padding(.horizontal, 16)
                .padding(.bottom, 10)
        }
        .background(Constants.bgPrimary.ignoresSafeArea())
        .sheet(isPresented: $showModelSelector) { ModelSelectorSheet(currentModel: $currentModel) }
        .onAppear {
            currentModel = authManager.getCurrentModel()
            // 跳转后自动聚焦弹出键盘（与微信点搜索框跳转一致）
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { inputFocused = true }
            // 带词跳转：自动补 AI 回复（仅当还没有回复时补，防返回再进重复追加）
            let t = initialText.trimmingCharacters(in: .whitespacesAndNewlines)
            if !t.isEmpty && messages.count == 1 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    messages.append(ChatMessage(text: "收到，我马上帮你处理「\(t)」（演示回复，接入接口后自动替换）", isUser: false))
                }
            }
        }
    }

    // 聊天记录区：消息列表自动滚动到底
    private var chatHistoryArea: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 10) {
                    ForEach(messages) { msg in
                        chatBubble(msg)
                    }
                }
                .padding(.vertical, 4)
            }
            .scrollDismissesKeyboard(.interactively)
            .onChange(of: messages.count) { _ in
                if let last = messages.last {
                    withAnimation(.easeOut(duration: 0.25)) { proxy.scrollTo(last.id, anchor: .bottom) }
                }
            }
        }
    }

    // 输入框：固定单行（lineLimit 1）不自动拉伸；发送键 + 标签行（定时任务/模型）
    private var inputBar: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                TextField("分配一个任务或提问任何问题", text: $inputText)
                    .lineLimit(1)
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .focused($inputFocused)
                    .submitLabel(.send)
                    .onSubmit { if inputFocused { sendMessage() } }  // 2.0.95：防失焦误触发发送
                Button(action: sendMessage) {
                    Image(systemName: "arrow.up.circle.fill").font(.system(size: 30)).foregroundStyle(Constants.accentOrange)
                }
                .disabled(inputText.isEmpty).opacity(inputText.isEmpty ? 0.5 : 1)
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 2)

            // 标签行：定时任务 / 选择模型
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

    private func getModelName(_ id: String) -> String {
        let m: [(String, String)] = [("deepseek-v4-flash","DeepSeek-V4-Flash"),("deepseek-v3","DeepSeek V3"),("kimi-2.5","Kimi 2.5"),("glm-5","GLM-5"),("minimax-m2.5","MiniMax M2.5"),("doubao-2.0","豆包 2.0")]
        for item in m { if item.0 == id { return item.1 } }
        return "DeepSeek-V4-Flash"
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
}
