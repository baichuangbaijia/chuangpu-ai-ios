import SwiftUI

/// 我的页面
struct MyView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var conversationsCount = 0
    @State private var messagesCount = 0
    @State private var credits = 0
    @State private var showLogoutAlert = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Constants.bgPrimary.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // VIP Banner
                        vipBanner
                        
                        // 用户信息卡片
                        userInfoCard
                        
                        // 统计数据
                        statsSection
                        
                        // 功能菜单
                        menuSection
                        
                        // 版本信息
                        versionInfo
                        
                        // 退出登录
                        logoutButton
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 30)
                }
            }
            .navigationTitle("")
            .navigationBarHidden(true)
            .onAppear {
                loadData()
            }
            .alert("退出登录", isPresented: $showLogoutAlert) {
                Button("取消", role: .cancel) {}
                Button("确定", role: .destructive) {
                    authManager.logout()
                }
            } message: {
                Text("确定要退出登录吗？")
            }
        }
    }
    
    private var vipBanner: some View {
        NavigationLink(destination: VipView()) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Constants.accentOrange.opacity(0.3), Constants.accentPink.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: "crown.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Constants.accentOrange, Constants.accentPink],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(authManager.isVip ? "VIP会员" : "开通会员")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text(authManager.isVip ? "会员有效期至永久" : "解锁全部功能")
                        .font(.system(size: 13))
                        .foregroundColor(Constants.textSecondary)
                }
                
                Spacer()
                
                if !authManager.isVip {
                    HStack(spacing: 4) {
                        Text("立即开通")
                            .font(.system(size: 13, weight: .medium))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(Constants.accentOrange)
                }
            }
            .padding(16)
            .background(
                LinearGradient(
                    colors: [Constants.bgSecondary, Constants.bgTertiary],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        authManager.isVip ?
                        Constants.accentOrange.opacity(0.5) :
                        LinearGradient(colors: [Constants.accentOrange.opacity(0.3), Constants.accentPink.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing),
                        lineWidth: authManager.isVip ? 2 : 1
                    )
            )
        }
    }
    
    private var userInfoCard: some View {
        HStack(spacing: 16) {
            // 头像
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Constants.primaryPurple, Constants.secondaryPurple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)
                
                Image(systemName: "person.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(authManager.currentUser?.nickname ?? authManager.nickname)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                
                Text("ID: \(authManager.userId)")
                    .font(.system(size: 13))
                    .foregroundColor(Constants.textSecondary)
            }
            
            Spacer()
            
            if authManager.isVip {
                Image(systemName: "crown.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Constants.accentOrange, Constants.accentPink],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
        }
        .padding(16)
        .background(Constants.bgSecondary)
        .cornerRadius(16)
    }
    
    private var statsSection: some View {
        HStack(spacing: 0) {
            statItem(value: "\(conversationsCount)", label: "对话数")
            Divider()
                .frame(height: 40)
                .background(Constants.bgTertiary)
            statItem(value: "\(messagesCount)", label: "消息数")
            Divider()
                .frame(height: 40)
                .background(Constants.bgTertiary)
            statItem(value: "\(credits)", label: "积分")
        }
        .padding(.vertical, 16)
        .background(Constants.bgSecondary)
        .cornerRadius(16)
    }
    
    private func statItem(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
            Text(label)
                .font(.system(size: 13))
                .foregroundColor(Constants.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
    
    private var menuSection: some View {
        VStack(spacing: 1) {
            menuItem(icon: "clock.arrow.circlepath", title: "历史记录", action: {})
            menuItem(icon: "brain", title: "记忆库", action: {})
            menuItem(icon: "list.bullet.rectangle", title: "定时任务", action: {})
            menuItem(icon: "star", title: "我的技能", action: {})
            menuItem(icon: "gearshape", title: "设置", action: {})
            menuItem(icon: "info.circle", title: "关于我们", action: {})
        }
        .background(Constants.bgSecondary)
        .cornerRadius(16)
    }
    
    private func menuItem(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(Constants.primaryPurple)
                    .frame(width: 28)
                
                Text(title)
                    .font(.system(size: 15))
                    .foregroundColor(.white)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 13))
                    .foregroundColor(Constants.textSecondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Constants.bgSecondary)
        }
    }
    
    private var versionInfo: some View {
        VStack(spacing: 4) {
            Text("创普AI")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Constants.textSecondary)
            
            Text("v2.0.42")
                .font(.system(size: 12))
                .foregroundColor(Constants.textSecondary.opacity(0.7))
        }
        .padding(.top, 10)
    }
    
    private var logoutButton: some View {
        Button(action: { showLogoutAlert = true }) {
            Text("退出登录")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.red)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(Constants.bgSecondary)
                .cornerRadius(12)
        }
        .padding(.top, 10)
    }
    
    private func loadData() {
        if !authManager.isVip {
            conversationsCount = 0
            messagesCount = 0
            credits = 0
            return
        }
        
        Swift.Task {
            do {
                let convs = try await APIService.shared.getConversations()
                let creditResult = try await APIService.shared.getCreditBalance()
                
                await MainActor.run {
                    conversationsCount = convs.count
                    messagesCount = convs.reduce(0) { $0 + $1.messageCount }
                    credits = creditResult.data?.credits ?? 0
                }
            } catch {
                print("加载数据失败: \(error)")
            }
        }
    }
}

#Preview {
    MyView()
        .environmentObject(AuthManager.shared)
}
