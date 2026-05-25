import SwiftUI

/// 我的页面 - 对照安卓MyFragment
/// 安卓要素: 头像+昵称+ID、VIP横幅(去开通)、统计数据(对话数/消息数/积分)、菜单(历史记录/我的记忆/定时任务/技能商店/设置/关于我们/退出登录)、版本号
struct MyView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var showLogoutAlert = false
    @State private var showAbout = false
    
    var body: some View {
        ZStack {
            Constants.bgPrimary.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // 用户信息区（头像+昵称+ID）
                    VStack(spacing: 12) {
                        // 头像
                        ZStack {
                            Circle()
                                .fill(LinearGradient(colors: [Constants.primaryPurple.opacity(0.3), Constants.secondaryPurple.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 80, height: 80)
                            Image(systemName: "person.fill")
                                .font(.system(size: 32))
                                .foregroundColor(Constants.primaryPurple)
                        }
                        
                        // 昵称
                        Text(authManager.currentUser?.nickname ?? "用户")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                        
                        // ID
                        Text("ID: \(authManager.currentUser?.id ?? 0)")
                            .font(.system(size: 13))
                            .foregroundColor(Constants.textSecondary)
                    }
                    .padding(.top, 30)
                    .padding(.bottom, 20)
                    
                    // VIP横幅（对照安卓vipBanner）
                    Button(action: {}) {
                        HStack(spacing: 12) {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 24))
                                .foregroundColor(Constants.accentOrange)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("开通VIP会员")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                Text("解锁全部功能，享受无限对话")
                                    .font(.system(size: 12))
                                    .foregroundColor(Constants.textSecondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14))
                                .foregroundColor(Constants.textSecondary)
                        }
                        .padding(16)
                        .background(
                            LinearGradient(colors: [Color(hex: "2A1A3E"), Color(hex: "1A2A3E")], startPoint: .leading, endPoint: .trailing)
                        )
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Constants.accentOrange.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .padding(.horizontal, 20)
                    
                    // 统计数据（对照安卓tvConversations/tvMessages/tvCredits）
                    HStack(spacing: 0) {
                        statItem(value: "0", label: "对话")
                        Rectangle().fill(Constants.bgTertiary).frame(width: 1, height: 40)
                        statItem(value: "0", label: "消息")
                        Rectangle().fill(Constants.bgTertiary).frame(width: 1, height: 40)
                        statItem(value: "0", label: "积分")
                    }
                    .padding(.vertical, 20)
                    .padding(.horizontal, 20)
                    
                    // 菜单列表
                    VStack(spacing: 1) {
                        menuItem(icon: "clock.arrow.circlepath", title: "历史记录", color: Constants.accentBlue)
                        menuItem(icon: "brain.head.profile", title: "我的记忆", color: Constants.accentGreen)
                        menuItem(icon: "calendar.badge.clock", title: "定时任务", color: Constants.primaryPurple)
                        menuItem(icon: "puzzlepiece.extension", title: "技能商店", color: Constants.accentOrange)
                        menuItem(icon: "gearshape.fill", title: "设置", color: Constants.textSecondary)
                        menuItem(icon: "info.circle.fill", title: "关于我们", color: Constants.accentBlue)
                    }
                    .background(Constants.bgSecondary)
                    .cornerRadius(12)
                    .padding(.horizontal, 20)
                    
                    // 退出登录按钮（对照安卓btnLogout）
                    Button(action: { showLogoutAlert = true }) {
                        Text("退出登录")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Constants.bgSecondary)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    // 版本号（对照安卓tvAboutVersion）
                    Text("v2.0.42")
                        .font(.system(size: 13))
                        .foregroundColor(Constants.textSecondary)
                        .padding(.top, 16)
                        .padding(.bottom, 30)
                }
            }
        }
        .alert("退出登录", isPresented: $showLogoutAlert) {
            Button("取消", role: .cancel) {}
            Button("确定", role: .destructive) {
                authManager.logout()
            }
        } message: {
            Text("确定要退出登录吗？")
        }
        .alert("关于我们", isPresented: $showAbout) {
            Button("确定") {}
        } message: {
            Text("创普AI v2.0.42\n\n智能对话 · 无限可能\n\n越用越懂你的专属AI助手")
        }
    }
    
    private func statItem(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.white)
            Text(label)
                .font(.system(size: 13))
                .foregroundColor(Constants.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
    
    private func menuItem(icon: String, title: String, color: Color) -> some View {
        Button(action: {}) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
                    .frame(width: 28)
                
                Text(title)
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 13))
                    .foregroundColor(Constants.textSecondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(Constants.bgSecondary)
        }
    }
}

#Preview { MyView().environmentObject(AuthManager.shared) }
