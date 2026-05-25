import SwiftUI

/// 主Tab页 - 对照安卓MainActivity
/// 安卓要素: 底部3个Tab(首页/技能/我的)、Tab切换图标+文字、选中紫色未选中灰色
struct MainTabView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        ZStack {
            Constants.bgPrimary.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 内容区
                ZStack {
                    if selectedTab == 0 { HomeView() }
                    else if selectedTab == 1 { SkillView() }
                    else { MyView() }
                }
                
                // 底部Tab栏（对照安卓底部导航）
                HStack(spacing: 0) {
                    tabItem(icon: "house.fill", title: "首页", index: 0)
                    tabItem(icon: "puzzlepiece.extension.fill", title: "技能", index: 1)
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
            }
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
