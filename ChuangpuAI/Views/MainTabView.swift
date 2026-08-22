import SwiftUI
import UIKit

/// 主Tab页 - 对照安卓MainActivity
/// 安卓要素: 底部3个Tab(首页/技能/我的)、Tab切换图标+文字、选中紫色未选中灰色
struct MainTabView: View {
    @State private var selectedTab = 0
    // 键盘弹起状态：弹起时内容区底部 padding 归零，避免输入栏与键盘之间 60pt 留白
    @State private var isKeyboardUp = false
    // Tab 栏固定高度（内容区底部留白用）
    private let tabBarHeight: CGFloat = 60
    // 2.1.9：对话页全屏时隐藏底部 TabBar（方案A：大厂二级页效果，返回首页恢复）
    @State private var hideTabBar = false
    // 2.1.20：我的页二级页覆盖层（方案A：放弃 NavigationStack push，顶层覆盖层全屏显示 → 根治系统导航栏占位顶部留白/半截）
    @State private var mySubPage: MySubPage? = nil
    // 2.1.10：3/4 宽左滑抽屉显隐（顶层盖住 TabBar）
    @State private var showDrawer = false
    // 2.1.16：渠道绑定页显隐（抽屉"渠道"入口打开，顶层盖住抽屉与 TabBar）+ 选中平台（0微信 1企业微信 2飞书 3钉钉）
    @State private var showChannelBinding = false
    @State private var channelPlatform = 0
    
    var body: some View {
        ZStack {
            Constants.bgPrimary.ignoresSafeArea()
            
            // 内容区（2.1.6：忽略键盘安全区——不被系统避让压缩，键盘位移全部由 HomeView 自身 padding 控制）
            ZStack {
                if selectedTab == 0 { HomeView(onChatPresentedChanged: { hidden in
                    withAnimation(.easeInOut(duration: 0.25)) { hideTabBar = hidden }
                }, onOpenDrawer: {
                    withAnimation(.easeInOut(duration: 0.25)) { showDrawer = true }
                }) }
                else if selectedTab == 1 { SkillView() }
                else {
                    // 2.1.18：传切 tab 回调（技能市场宫格）
                    // 2.1.20：宫格二级页改 onOpenPage 回调上抛 → MainTabView 顶层覆盖层显示（放弃 NavigationStack push，根治顶部留白）
                    MyView(onSwitchTab: { index in selectedTab = index },
                           onOpenPage: { page in
                               withAnimation(.easeInOut(duration: 0.25)) { mySubPage = page }
                           })
                }
            }
            .padding(.bottom, (isKeyboardUp || hideTabBar) ? 0 : tabBarHeight) // 键盘弹起或对话页全屏(TabBar隐藏)时不留白
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea(.keyboard)
            
            // 底部Tab栏：独立层固定在屏幕底部，键盘弹出时不随输入框弹起；对话页全屏时隐藏（2.1.9 方案A）
            if !hideTabBar {
                HStack(spacing: 0) {
                    tabItem(icon: "house.fill", title: "首页", index: 0)
                    tabItem(icon: "star.fill", title: "技能市场", index: 1)
                    tabItem(icon: "person.fill", title: "我的", index: 2)
                }
                .padding(.top, 8)
                .padding(.bottom, 4)
                .background(
                    Constants.bgSecondary
                        .ignoresSafeArea(edges: .bottom)
                )
                .overlay(
                    Rectangle().fill(Constants.bgTertiary).frame(height: 0.5),
                    alignment: .top
                )
                .frame(maxWidth: .infinity)
                .frame(maxHeight: .infinity, alignment: .bottom)
                .ignoresSafeArea(.keyboard)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            // 2.1.10：3/4 宽左滑抽屉（顶层盖住 TabBar；右侧遮罩点击关闭；选历史/渠道占位均收回）
            if showDrawer {
                ZStack(alignment: .leading) {
                    Color.black.opacity(0.45)
                        .ignoresSafeArea()
                        .onTapGesture { withAnimation(.easeInOut(duration: 0.25)) { showDrawer = false } }
                    SidebarView(onSelectConversation: { _ in
                        withAnimation(.easeInOut(duration: 0.25)) { showDrawer = false }
                    }, onClose: {
                        withAnimation(.easeInOut(duration: 0.25)) { showDrawer = false }
                    }, onOpenChannel: {
                        // 2.1.16：先收抽屉，再开渠道绑定页（默认微信 tab）
                        withAnimation(.easeInOut(duration: 0.25)) { showDrawer = false }
                        channelPlatform = 0
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) {
                            withAnimation(.easeInOut(duration: 0.25)) { showChannelBinding = true }
                        }
                    })
                    .frame(width: UIScreen.main.bounds.width * 0.75)
                    .transition(.move(edge: .leading))
                }
                .transition(.opacity)
                .zIndex(30)
            }

            // 2.1.16：渠道绑定页覆盖层（zIndex 40 高于抽屉 30，盖住 TabBar/抽屉/一切）
            if showChannelBinding {
                ChannelBindingView(initialPlatform: channelPlatform, onClose: {
                    withAnimation(.easeInOut(duration: 0.25)) { showChannelBinding = false }
                })
                .transition(.move(edge: .trailing))
                .zIndex(40)
            }

            // 2.1.20：我的页二级页覆盖层（方案A：zIndex 50 全屏盖住 TabBar/一切，无系统导航栏参与 → 根治顶部留白/半截；返回按钮 onClose 关闭）
            if let page = mySubPage {
                Group {
                    switch page {
                    case .history: HistoryView(onClose: closeMySubPage)
                    case .memory: MemoryView(onClose: closeMySubPage)
                    case .tasks: TaskView(onClose: closeMySubPage)
                    case .settings: SettingsView(onClose: closeMySubPage)
                    case .about: AboutView(onClose: closeMySubPage)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                // 2.1.25：去掉 .transition(.move) —— 转场容器可能给子视图"理想尺寸提案"，
                // 导致页面 frame(maxHeight:.infinity) 撑满失效 → 页面缩成内容高度被外层居中（标题在中间的真凶）
                .zIndex(50)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { note in
            let kbDur = (note.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double) ?? 0.25
            withAnimation(.easeOut(duration: kbDur)) { isKeyboardUp = true }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { note in
            let kbDur = (note.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double) ?? 0.25
            withAnimation(.easeOut(duration: kbDur)) { isKeyboardUp = false }
        }
    }
    
    // 2.1.20：关闭我的页二级页覆盖层
    private func closeMySubPage() {
        withAnimation(.easeInOut(duration: 0.25)) { mySubPage = nil }
    }
    
    private func tabItem(icon: String, title: String, index: Int) -> some View {
        Button(action: { selectedTab = index }) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(selectedTab == index ? Constants.primaryPurple : Constants.textSecondary)
                Text(title)
                    .font(.system(size: 11, weight: selectedTab == index ? .semibold : .regular))
                    .foregroundColor(selectedTab == index ? Constants.primaryPurple : Constants.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
        }
    }
}

#Preview { MainTabView().environmentObject(AuthManager.shared) }

// 2.1.20：我的页二级页类型（覆盖层模式：MyView 宫格 onOpenPage 回调上抛 → MainTabView 顶层 switch 显示）
enum MySubPage {
    case history, memory, tasks, settings, about
}
