import SwiftUI

/// 2.1.23：A 方案——按老板指令清空页面内容，只保留页面壳（标题栏 + 返回按钮）
struct AboutView: View {
    // 2.1.20：覆盖层模式（由 MainTabView 传入 onClose，默认空）替代 @Environment(\.dismiss)
    var onClose: () -> Void = {}

    var body: some View {
        ZStack {
            Constants.bgPrimary.ignoresSafeArea()

            // 2.1.25：ScrollView 撑满机制（与设置页同款，真机验证过可靠）→ 标题栏钉顶
            // 根因复盘：覆盖层转场容器给"理想尺寸提案"→ frame(maxHeight:.infinity) 撑满失效
            // → 页面缩成内容高度被外层居中；ScrollView 无视提案天生撑满，根治
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // 顶部导航（返回 + 标题"关于我们"）
                    HStack {
                        Button(action: { onClose() }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(.white)
                        }
                        Spacer()
                        Text("关于我们")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                        Spacer()
                        Color.clear.frame(width: 20)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    NavigationStack {
        AboutView()
    }
}
