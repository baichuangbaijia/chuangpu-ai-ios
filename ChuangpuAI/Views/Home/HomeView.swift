import UIKit
import SwiftUI

// 2.1.13：设备底部安全区（窗口坐标系，非视图相对值）：全面屏=34、无Home键=0
// 背景：视图 safeAreaInsets 是相对值（视图底边到安全区底边的距离），页面底边恰在安全区底边时恒为 0，
//       而键盘垫高公式需要的是"VStack 底边到屏幕底的距离"=设备底部安全区 → 改用窗口安全区读取
private func deviceBottomSafeInset() -> CGFloat {
    if let window = UIApplication.shared.connectedScenes
        .compactMap({ ($0 as? UIWindowScene)?.keyWindow }).first {
        return window.safeAreaInsets.bottom
    }
    return 0
}

struct ChatMessage: Identifiable {
    let id = UUID()
    let text: String
    let isUser: Bool
}

struct HomeView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var inputText = ""
    // 2.1.7：跳转对话页前暂存发送原文（先暂存再清空 inputText，对话页渲染时读 pendingText 上屏）
    @State private var pendingText = ""
    // 2.1.8：对话页标题（开始养虾入口="创普AI助手"，发送入口=nil 显示"新对话"）
    @State private var chatTitle: String? = nil
    @State private var currentModel = "deepseek-v4-flash"
    @State private var showModelSelector = false
    @State private var glowPhase: Double = 0.4
    @State private var showChat = false
    // 2.1.9：对话页全屏状态回调（通知 MainTabView 隐藏/恢复底部 TabBar，大厂二级页效果）
    var onChatPresentedChanged: ((Bool) -> Void)? = nil
    // 2.1.10：汉堡点击回调（通知 MainTabView 打开 3/4 宽左滑抽屉）
    var onOpenDrawer: (() -> Void)? = nil
    @FocusState private var inputFocused: Bool
    @State private var isKeyboardUp = false
    // 2.1.5：键盘弹起目标拉伸高度（键盘通知到达瞬间一次性预计算，动画期间锁死为常量不再重算 → 收起不晃）
    @State private var stretchedHeight: CGFloat = 0
    // 2.1.5：安全区顶部高度（GeometryReader 仅读一次系统值，非逐帧测量；键盘通知回调拿不到 geo，故存状态）
    @State private var topSafe: CGFloat = 0
    // 2.1.11：安全区底部高度（键盘垫高 = keyboardHeight - bottomSafe，输入栏精确贴键盘顶）
    @State private var bottomSafe: CGFloat = 0
    // 2.1.6：接管系统键盘避让——键盘最终高度（弹起时 VStack 底部 padding=该值把输入栏推到键盘顶，收起归零；与拉伸/下区显隐同一 withAnimation 单一动画源 → 消灭与系统避让双时钟对撞的收起晃动）
    @State private var keyboardHeight: CGFloat = 0

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
            // 2.1.6：接管避让——键盘弹起时底部垫高键盘高度（输入栏贴键盘顶），收起归零；与拉伸/下区显隐同一动画源，全程单调平滑
            .padding(.bottom, isKeyboardUp ? max(0, keyboardHeight - bottomSafe) : 0)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Constants.bgPrimary.ignoresSafeArea())
            // 2.1.5：安全区顶只读一次存状态（常量），供键盘通知预计算目标高度使用
            .onAppear { topSafe = geo.safeAreaInsets.top; bottomSafe = deviceBottomSafeInset() }
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
                    keyboardHeight = kbH
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { note in
                // 2.1.5：收起只翻 isKeyboardUp，输入栏高度由布尔驱动从目标常量单调平滑回缩到原高，
                // 全程不碰键盘高度数值（2.1.4 用动态高度重算 → 先胀后缩 + 末帧跳变 = 晃，已废除）
                let kbDur = (note.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double) ?? 0.25
                withAnimation(.easeOut(duration: kbDur)) {
                    isKeyboardUp = false
                    stretchedHeight = 0
                    keyboardHeight = 0
                }
            }
            .sheet(isPresented: $showModelSelector) { ModelSelectorSheet(currentModel: $currentModel) }
            .onAppear { currentModel = authManager.getCurrentModel(); inputFocused = false; startAnimations() }
            // 2.1.9：对话页显隐变化 → 通知 MainTabView 隐藏/恢复 TabBar（覆盖全部入口：发送/开始养虾/返回）
            .onChange(of: showChat) { newValue in
                onChatPresentedChanged?(newValue)
            }

            // 2.0.95：跳转新对话页用 ZStack 全屏覆盖（不依赖导航栈），返回回调关掉覆盖层
            if showChat {
                ChatConversationView(initialText: pendingText, welcomeTitle: chatTitle, onClose: {
                    withAnimation(.easeInOut(duration: 0.25)) { showChat = false }
                }, onOpenDrawer: { onOpenDrawer?() })
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
            Button(action: { inputFocused = false; onOpenDrawer?() }) {
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
            Button(action: { jumpToYangXia() }) {
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
        .frame(height: inputFocused && isKeyboardUp ? stretchedHeight : 93, alignment: .bottom)
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
        chatTitle = nil  // 2.1.8：发送入口标题走默认"新对话"
        pendingText = inputText  // 2.1.7：先暂存原文（对话页渲染时读取）
        inputText = ""           // 2.1.7：发送后清空首页输入框（返回首页不再残留已发送文字）
        withAnimation(.easeInOut(duration: 0.25)) { showChat = true }
    }

    // 2.1.8：开始养虾 → 跳转对话页欢迎态（空对话显示欢迎区：主标语/问候/功能卡片）
    private func jumpToYangXia() {
        inputFocused = false
        pendingText = ""  // 2.1.8：清空暂存（欢迎态不带上一条发送内容）
        chatTitle = "创普AI助手"
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
            // 2.1.16：纯展示（入口移至抽屉"渠道"，此处不可点击）
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
    // 2.1.8：对话页标题（nil=默认"新对话"；非空=显示该标题+在线状态，如"创普AI助手"）
    let welcomeTitle: String?
    // 2.1.10：当前标题（初始=welcomeTitle；＋新建会话后=nil 显示"新对话"）
    @State private var currentTitle: String?
    // 2.1.10：汉堡回调（打开抽屉）
    let onOpenDrawer: () -> Void
    // 2.1.10：⋯ 下拉菜单显隐
    @State private var showMoreMenu = false
    // 2.1.10：占位提示 toast
    @State private var toastText: String? = nil
    @State private var inputText: String
    @State private var currentModel = "deepseek-v4-flash"
    @State private var showModelSelector = false
    @State private var showAttachment = false  // 2.1.30：＋号展开输入栏下方横排四卡片（拍照/相册/文件/视频）
    @State private var messages: [ChatMessage] = []
    @State private var initialText: String = ""
    @FocusState private var inputFocused: Bool
    // 2.1.6：接管键盘避让——键盘最终高度（弹起时 VStack 底部 padding=该值把输入栏推到键盘顶，收起归零）
    @State private var keyboardHeight: CGFloat = 0
    // 2.1.11：安全区底部高度（键盘垫高 = keyboardHeight - bottomSafe，输入栏精确贴键盘顶）
    @State private var bottomSafe: CGFloat = 0

    init(initialText: String = "", welcomeTitle: String? = nil, onClose: @escaping () -> Void = {}, onOpenDrawer: @escaping () -> Void = {}) {
        self.onClose = onClose
        self.welcomeTitle = welcomeTitle
        self.onOpenDrawer = onOpenDrawer
        _currentTitle = State(initialValue: welcomeTitle)
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
            // 2.1.11：顶部导航栏：左=汉堡+标题(欢迎态=创普AI助手+创普AI在线；普通=新对话) / 右=✕(关页)＋(新页)⋯(下拉)
            HStack(spacing: 10) {
                // 左：汉堡（打开抽屉）
                Button(action: { inputFocused = false; onOpenDrawer() }) {
                    Image(systemName: "line.3.horizontal")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 40, height: 44)
                        .contentShape(Rectangle())
                }
                // 标题移到汉堡右侧（欢迎态=标题+创普AI在线原样；普通="新对话"）
                if let wt = currentTitle {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(wt).font(.system(size: 16, weight: .semibold)).foregroundColor(.white)
                        HStack(spacing: 4) {
                            Circle().fill(Color(red: 0.30, green: 0.85, blue: 0.40)).frame(width: 6, height: 6)
                            Text("创普AI 在线").font(.system(size: 10)).foregroundColor(Color(red: 0.30, green: 0.85, blue: 0.40))
                        }
                    }
                } else {
                    Text("新对话").font(.system(size: 16, weight: .semibold)).foregroundColor(.white)
                }
                Spacer()
                // 右：✕ ＋ ⋯
                Button(action: { onClose() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 36, height: 44)
                        .contentShape(Rectangle())
                }
                Button(action: { newConversation() }) {
                    Image(systemName: "plus")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 36, height: 44)
                        .contentShape(Rectangle())
                }
                Button(action: { showMoreMenu.toggle() }) {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 36, height: 44)
                        .contentShape(Rectangle())
                }
            }
            .padding(.horizontal, 8)
            .padding(.top, 4)
            .padding(.bottom, 4)

            // 聊天区：空状态纯空白 / 消息气泡；点空白收键盘（2.0.94 问候语全删）
            Group {
                if messages.isEmpty {
                    welcomeArea
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
                .padding(.bottom, keyboardHeight > 0 ? 0 : 10)
        }
        // 2.1.6：接管键盘避让（MainTabView 内容区已全局忽略键盘安全区，对话页输入栏需自己垫高贴键盘顶；与首页同一动画源机制，防输入栏被键盘盖住）
        .padding(.bottom, keyboardHeight > 0 ? max(0, keyboardHeight - bottomSafe) : 0)
        .background(Constants.bgPrimary.ignoresSafeArea())
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { note in
            let kbH = (note.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect)?.height ?? 0
            let kbDur = (note.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double) ?? 0.25
            withAnimation(.easeOut(duration: kbDur)) { keyboardHeight = kbH }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { note in
            let kbDur = (note.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double) ?? 0.25
            withAnimation(.easeOut(duration: kbDur)) { keyboardHeight = 0 }
        }
        // 2.1.10：⋯ 下拉菜单（搜索/日程/文件/邮箱/图片调试=占位；点任意处收回）
        .overlay(alignment: .topTrailing) {
            if showMoreMenu {
                ZStack(alignment: .topTrailing) {
                    Color.black.opacity(0.001)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .ignoresSafeArea()
                        .onTapGesture { showMoreMenu = false }
                    VStack(alignment: .leading, spacing: 0) {
                        moreMenuItem("搜索", "magnifyingglass")
                        moreMenuItem("日程", "calendar")
                        moreMenuItem("文件", "folder")
                        moreMenuItem("邮箱", "envelope")
                        moreMenuItem("图片调试", "photo")
                    }
                    .fixedSize(horizontal: true, vertical: false)
                    .background(Constants.bgSecondary)
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Constants.bgTertiary, lineWidth: 0.5))
                    .shadow(color: Color.black.opacity(0.4), radius: 12, x: 0, y: 4)
                    .padding(.trailing, 8)
                    .padding(.top, 54)
                }
            }
        }
        // 2.1.10：占位提示 toast
        .overlay(alignment: .bottom) {
            if let t = toastText {
                Text(t)
                    .font(.system(size: 13))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.black.opacity(0.8))
                    .cornerRadius(20)
                    .padding(.bottom, 80)
                    .transition(.opacity)
            }
        }
        .sheet(isPresented: $showModelSelector) { ModelSelectorSheet(currentModel: $currentModel) }
        .onAppear {
            bottomSafe = deviceBottomSafeInset()
            currentModel = authManager.getCurrentModel()
            // 带词跳转：自动补 AI 回复（仅当还没有回复时补，防返回再进重复追加）
            let t = initialText.trimmingCharacters(in: .whitespacesAndNewlines)
            if !t.isEmpty {
                // 2.1.8：仅带词跳转自动聚焦弹键盘；欢迎态（开始养虾）不弹，完整展示欢迎区
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { inputFocused = true }
            }
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

    // 2.1.8：欢迎区（开始养虾入口空对话时展示；点功能卡片直接发起任务）
    private var welcomeArea: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                Text("创普在手 天下任我走")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.top, 36)
                Text("全新一代24小时在线的AI全能私人助理")
                    .font(.system(size: 13))
                    .foregroundColor(Constants.textSecondary)
                    .padding(.top, 10)
                Text("你好老板，我是你的AI员工")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color.white.opacity(0.92))
                    .padding(.top, 34)
                Text("有什么吩咐尽管说，一句话我立马帮你干活")
                    .font(.system(size: 13))
                    .foregroundColor(Constants.textSecondary)
                    .padding(.top, 8)
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible())], spacing: 12) {
                    welcomeCard(icon: "文", name: "帮我写文档", desc: "一键生成", color: Color(red: 0.42, green: 0.30, blue: 1.00))
                    welcomeCard(icon: "数", name: "数据分析", desc: "智能处理", color: Color(red: 0.24, green: 0.48, blue: 1.00))
                    welcomeCard(icon: "研", name: "市场调研", desc: "行业分析", color: Color(red: 0.00, green: 0.66, blue: 0.59))
                    welcomeCard(icon: "同", name: "创建合同", desc: "法律模板", color: Color(red: 0.96, green: 0.47, blue: 0.18))
                    welcomeCard(icon: "网", name: "创建网站", desc: "快速搭建", color: Color(red: 0.96, green: 0.25, blue: 0.42))
                    welcomeCard(icon: "旅", name: "旅行规划", desc: "行程安排", color: Color(red: 0.18, green: 0.74, blue: 0.35))
                }
                .padding(.top, 30)
                .padding(.horizontal, 16)
            }
            .padding(.bottom, 16)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    // 2.1.8：欢迎区功能卡片（品牌色加深底 + 顶部色条 + 图标单字 + 名称/描述）
    private func welcomeCard(icon: String, name: String, desc: String, color: Color) -> some View {
        Button {
            sendQuickTask(name)
        } label: {
            ZStack(alignment: .top) {
                RoundedRectangle(cornerRadius: 16)
                    .fill(color.opacity(0.55))
                RoundedRectangle(cornerRadius: 16)
                    .fill(color)
                    .frame(height: 3)
                HStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.black.opacity(0.35))
                        .frame(width: 44, height: 44)
                        .overlay(
                            Text(icon).font(.system(size: 19, weight: .bold)).foregroundColor(.white)
                        )
                    VStack(alignment: .leading, spacing: 4) {
                        Text(name).font(.system(size: 15, weight: .semibold)).foregroundColor(.white)
                        Text(desc).font(.system(size: 11)).foregroundColor(Color.white.opacity(0.72))
                    }
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 18)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(PlainButtonStyle())
    }

    // 2.1.8：欢迎区卡片点击 → 直接发起任务（上屏用户消息 + 模拟 AI 回复）
    private func sendQuickTask(_ task: String) {
        guard !task.isEmpty else { return }
        inputFocused = false
        messages.append(ChatMessage(text: task, isUser: true))
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            messages.append(ChatMessage(text: "收到，我马上帮你处理「\(task)」（演示回复，接入接口后自动替换）", isUser: false))
        }
    }

    // 2.1.30：对话页输入框 = 左侧＋(拍照/相册/文件/视频横排卡片) + 输入 + 发送；无定时任务/模型标签（标签只在首页）
    private var inputBar: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                // 左侧 + 号附件按钮 → 展开输入栏下方横排四卡片（拍照/相册/文件/视频，再点收起）
                Button(action: { withAnimation(.easeInOut(duration: 0.2)) { showAttachment.toggle() } }) {
                    Image(systemName: showAttachment ? "xmark.circle.fill" : "plus.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(Constants.primaryPurple)
                }
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
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Constants.bgTertiary)
            .cornerRadius(24)

            // 2.1.30：＋号展开 → 横排四卡片，宽度自适应屏幕（四卡片均分）
            if showAttachment {
                HStack(spacing: 8) {
                    attachmentCard(icon: "camera", title: "拍照") { showAttachment = false }
                    attachmentCard(icon: "photo", title: "相册") { showAttachment = false }
                    attachmentCard(icon: "doc", title: "文件") { showAttachment = false }
                    attachmentCard(icon: "video", title: "视频") { showAttachment = false }
                }
                .padding(.horizontal, 14)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .frame(maxWidth: .infinity)
    }

    // 2.1.30：＋附件横排小卡片（拍照/相册/文件/视频，宽度自适应屏幕均分）
    private func attachmentCard(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(Constants.primaryPurple)
                Text(title)
                    .font(.system(size: 13))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Constants.bgTertiary)
            .cornerRadius(14)
        }
        .buttonStyle(PlainButtonStyle())
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

    // 2.1.10：＋ 添加新页面 = 新开会话（清空消息回欢迎区，标题变"新对话"）；✕ 直接回首页（onClose）
    private func newConversation() {
        inputFocused = false
        messages = []
        inputText = ""
        currentTitle = nil
    }

    // 2.1.10：⋯ 下拉菜单项（占位：轻提示后关闭）
    private func moreMenuItem(_ title: String, _ icon: String) -> some View {
        Button {
            showMoreMenu = false
            showToast("「\(title)」功能开发中")
        } label: {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(Constants.textSecondary)
                    .frame(width: 20)
                Text(title).font(.system(size: 14)).foregroundColor(.white)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }

    // 2.1.10：占位 toast
    private func showToast(_ text: String) {
        withAnimation { toastText = text }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation { toastText = nil }
        }
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
