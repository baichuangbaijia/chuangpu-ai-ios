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
    
    var body: some View {
        ZStack {
            Constants.bgPrimary.ignoresSafeArea()
            
            // 内容区（正常避让键盘；底部留出 Tab 栏高度）
            ZStack {
                if selectedTab == 0 { HomeView() }
                else if selectedTab == 1 { SkillView() }
                else { MyView() }
            }
            .padding(.bottom, isKeyboardUp ? 0 : tabBarHeight) // 键盘弹起时 Tab 栏已被键盘盖住，无需再留 60pt
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // 底部Tab栏：独立层固定在屏幕底部，键盘弹出时不随输入框弹起
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
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
            isKeyboardUp = true
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            isKeyboardUp = false
        }
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
