import SwiftUI

/// 主Tab页面
struct MainTabView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                HomeView()
                    .tag(0)
                
                SkillView()
                    .tag(1)
                
                MyView()
                    .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            
            // 自定义TabBar
            customTabBar
        }
        .ignoresSafeArea(.keyboard)
    }
    
    private var customTabBar: some View {
        HStack {
            tabItem(icon: "bubble.left.and.bubble.right.fill", title: "首页", index: 0)
            tabItem(icon: "wand.and.stars", title: "技能", index: 1)
            tabItem(icon: "person.fill", title: "我的", index: 2)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 30)
        .background(
            Constants.bgSecondary
                .shadow(color: .black.opacity(0.3), radius: 20, y: -10)
        )
    }
    
    private func tabItem(icon: String, title: String, index: Int) -> some View {
        Button(action: { selectedTab = index }) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(selectedTab == index ? Constants.primaryPurple : Constants.textSecondary)
                
                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(selectedTab == index ? Constants.primaryPurple : Constants.textSecondary)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(AuthManager.shared)
}
