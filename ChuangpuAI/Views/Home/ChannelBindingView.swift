import SwiftUI

// 2.1.14：渠道绑定页（聊天平台接入）——对照老板设计图
// 顶部导航：返回箭头 + 标题"聊天平台接入"
// 四个 tab：微信/企业微信/飞书/钉钉（选中白色文字 + 紫色下划线）
// 内容区：绑定文案 + 二维码占位（绿色 qrcode 图标）+ 说明文字
// 状态：未绑定（点二维码模拟扫码绑定）/ 已绑定（多红色"解绑"按钮，点解绑恢复未绑定）
// 模拟切换：点二维码=模拟绑定成功，点解绑按钮=模拟解绑（暂未接真实接口，方便老板验收）
struct ChannelBindingView: View {
    let initialPlatform: Int
    let onClose: () -> Void

    @State private var selected: Int
    // 各平台模拟绑定状态（下标对齐 platforms）
    @State private var bound: [Bool]
    @State private var toastText: String?

    // 平台数据：名称 + 品牌色（与首页平台接入区一致）
    private let platforms: [(name: String, color: Color)] = [
        ("微信", Color(red: 0.03, green: 0.76, blue: 0.38)),
        ("企业微信", Color(red: 0.00, green: 0.51, blue: 0.94)),
        ("飞书", Color(red: 0.20, green: 0.44, blue: 1.00)),
        ("钉钉", Color(red: 0.00, green: 0.54, blue: 1.00))
    ]

    init(initialPlatform: Int, onClose: @escaping () -> Void) {
        self.initialPlatform = initialPlatform
        self.onClose = onClose
        _selected = State(initialValue: initialPlatform)
        _bound = State(initialValue: [false, false, false, false])
    }

    var body: some View {
        ZStack {
            Constants.bgPrimary.ignoresSafeArea()
            VStack(spacing: 0) {
                topBar
                tabBar
                contentArea
                Spacer(minLength: 0)
            }
        }
        // 占位提示 toast（对齐 2.1.10 样式）
        .overlay(alignment: .bottom) {
            if let t = toastText {
                Text(t)
                    .font(.system(size: 13))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.black.opacity(0.8))
                    .cornerRadius(20)
                    .padding(.bottom, 60)
                    .transition(.opacity)
            }
        }
    }

    // 顶部导航：返回箭头 + 标题"聊天平台接入"（右侧占位保持标题居中）
    private var topBar: some View {
        HStack(spacing: 10) {
            Button(action: onClose) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 40, height: 44)
                    .contentShape(Rectangle())
            }
            Spacer()
            Text("聊天平台接入")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
            Spacer()
            Color.clear.frame(width: 40, height: 44)
        }
        .padding(.horizontal, 8)
        .padding(.top, 4)
        .padding(.bottom, 4)
    }

    // 四个平台 tab：未选中灰色文字，选中白色 + 底部紫色下划线
    private var tabBar: some View {
        HStack(spacing: 0) {
            ForEach(0..<platforms.count, id: \.self) { i in
                Button(action: { withAnimation(.easeInOut(duration: 0.2)) { selected = i } }) {
                    VStack(spacing: 6) {
                        Text(platforms[i].name)
                            .font(.system(size: 14, weight: selected == i ? .semibold : .regular))
                            .foregroundColor(selected == i ? .white : Constants.textSecondary)
                        Rectangle()
                            .fill(selected == i ? Constants.primaryPurple : Color.clear)
                            .frame(height: 2)
                            .frame(maxWidth: .infinity)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 6)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }

    // 内容区：绑定文案 + 二维码占位 +（已绑定）解绑按钮 + 说明文字
    private var contentArea: some View {
        VStack(spacing: 28) {
            Text("绑定\(platforms[selected].name)，让AI帮你收发消息")
                .font(.system(size: 15))
                .foregroundColor(.white)
                .padding(.top, 48)

            // 二维码占位（2.1.14：先占位，后续接真实二维码；点它模拟扫码绑定成功）
            Image(systemName: "qrcode")
                .font(.system(size: 110))
                .foregroundColor(platforms[selected].color)
                .frame(width: 180, height: 180)
                .background(Constants.bgSecondary)
                .cornerRadius(16)
                .onTapGesture { simulateBind() }

            // 已绑定状态才显示解绑按钮（老板确认：绑定后出现）
            if bound[selected] {
                Button(action: { simulateUnbind() }) {
                    Text("解绑\(platforms[selected].name)")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 44)
                        .padding(.vertical, 12)
                        .background(Color.red)
                        .cornerRadius(24)
                }
                .transition(.opacity)
            }

            Text("用\(platforms[selected].name)扫码即可绑定，扫码后请在手机上确认")
                .font(.system(size: 12))
                .foregroundColor(Constants.textSecondary)
                .multilineTextAlignment(.center)
        }
    }

    // 模拟扫码绑定：点二维码 → 已绑定（toast 提示）
    private func simulateBind() {
        withAnimation(.easeInOut(duration: 0.25)) { bound[selected] = true }
        showToast("模拟扫码绑定成功")
    }

    // 模拟解绑：点解绑按钮 → 未绑定
    private func simulateUnbind() {
        withAnimation(.easeInOut(duration: 0.25)) { bound[selected] = false }
        showToast("已解绑\(platforms[selected].name)")
    }

    private func showToast(_ text: String) {
        withAnimation { toastText = text }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation { toastText = nil }
        }
    }
}
