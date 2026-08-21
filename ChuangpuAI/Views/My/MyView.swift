import SwiftUI

/// 我的页面 - 对照安卓MyFragment
/// 安卓要素: 用户卡片(头像+昵称+ID+卡内横向3统计)、会员卡片(包年已开通+有效期+续期按钮)、更多功能宫格(4列自适应: 对话历史/我的AI记忆/定时任务/技能市场 + 积分明细/设置/关于我们)、退出登录、版本号
/// 整页撑满锁死(方案A沉底式: 退出登录+版本号贴底, Spacer吸收空隙; 小屏超高自动滚动兜底, 对标大厂智能锁死)
struct MyView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var showLogoutAlert = false
    // 2.1.18：宫格"技能市场"切底部 tab 回调（由 MainTabView 传入，默认空）
    var onSwitchTab: (Int) -> Void = { _ in }
    
    var body: some View {
        ZStack {
            Constants.bgPrimary.ignoresSafeArea()
            
            GeometryReader { geo in
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // ===== 用户卡片（对齐安卓: 头像左 + 昵称/ID右 + 卡内横向3统计）=====
                        VStack(spacing: 0) {
                            HStack(spacing: 16) {
                                // 头像 64pt
                                ZStack {
                                    Circle()
                                        .fill(LinearGradient(colors: [Constants.primaryPurple.opacity(0.3), Constants.secondaryPurple.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing))
                                        .frame(width: 64, height: 64)
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 26))
                                        .foregroundColor(Constants.primaryPurple)
                                }
                                
                                // 昵称 + ID
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(authManager.currentUser?.nickname ?? "用户")
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(.white)
                                    Text("ID: \(authManager.currentUser?.id ?? 0)")
                                        .font(.system(size: 13))
                                        .foregroundColor(Constants.textSecondary)
                                }
                                
                                Spacer()
                            }
                            .padding(.bottom, 16)
                            
                            // 卡内分隔线
                            Rectangle()
                                .fill(Constants.bgTertiary)
                                .frame(height: 1)
                            
                            // 卡内横向3统计（对话/消息/积分，对齐安卓tvConversations/tvMessages/tvCredits）
                            HStack(spacing: 0) {
                                statItem(value: "0 条", label: "对话")
                                Rectangle().fill(Constants.bgTertiary).frame(width: 1, height: 40)
                                statItem(value: "0 条", label: "消息")
                                Rectangle().fill(Constants.bgTertiary).frame(width: 1, height: 40)
                                statItem(value: "0 分", label: "积分")
                            }
                            .padding(.top, 16)
                        }
                        .padding(20)
                        .background(Constants.bgSecondary)
                        .cornerRadius(16)
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        
                        // ===== 会员卡片（对齐安卓: 深紫卡 + 包年已开通 + 有效期 + 白色续期按钮）=====
                        HStack(spacing: 12) {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 24))
                                .foregroundColor(Constants.accentOrange)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("包年会员已开通")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                Text("有效期至 2026-08-20")
                                    .font(.system(size: 12))
                                    .foregroundColor(Constants.textSecondary)
                            }
                            
                            Spacer()
                            
                            // 白色续期按钮（对齐安卓btnRenew）
                            Button(action: {}) {
                                Text("会员续期")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(Color(hex: "2A1A3E"))
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(Color.white)
                                    .cornerRadius(16)
                            }
                        }
                        .padding(16)
                        .background(
                            LinearGradient(colors: [Color(hex: "2A1A3E"), Color(hex: "1A2A3E")], startPoint: .leading, endPoint: .trailing)
                        )
                        .cornerRadius(16)
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        
                        // ===== 更多功能大卡片（左上角标题 + 全部功能项）=====
                        VStack(spacing: 0) {
                            // 左上角标题
                            HStack {
                                Text("更多功能")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 14)
                            .padding(.bottom, 6)
                            
                            // 4列自适应宫格（屏幕宽度自适应，第2行3项空1格）2.1.18：7项全部接活（4 push 页面 + 1 切tab + 1 占位 + 1 push）
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 16) {
                                gridItem(icon: "clock.arrow.circlepath", title: "对话历史", color: Constants.accentBlue, destination: AnyView(HistoryView()))
                                gridItem(icon: "brain.head.profile", title: "我的AI记忆", color: Constants.accentGreen, destination: AnyView(MemoryView()))
                                gridItem(icon: "calendar.badge.clock", title: "定时任务", color: Constants.primaryPurple, destination: AnyView(TaskView()))
                                gridItem(icon: "puzzlepiece.extension", title: "技能市场", color: Constants.accentOrange, action: { onSwitchTab(1) })
                                gridItem(icon: "creditcard.fill", title: "积分明细", color: Constants.accentOrange)
                                gridItem(icon: "gearshape.fill", title: "设置", color: Constants.textSecondary, destination: AnyView(SettingsView()))
                                gridItem(icon: "info.circle.fill", title: "关于我们", color: Constants.accentBlue, destination: AnyView(AboutView()))
                            }
                            .padding(.horizontal, 16)
                            .padding(.bottom, 16)
                        }
                        .background(Constants.bgSecondary)
                        .cornerRadius(16)
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        
                        // 弹性空隙：整页撑满锁死（方案A沉底式：退出登录+版本号贴底，Spacer吸收空隙；小屏超高自动滚动兜底）
                        Spacer(minLength: 0)
                        
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
                        
                        // 版本号（动态读取 Bundle 版本，修复写死 v2.0.44 遗留）
                        Text("v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "2.0.92")")
                            .font(.system(size: 13))
                            .foregroundColor(Constants.textSecondary)
                            .padding(.top, 16)
                            .padding(.bottom, 30)
                    }
                    .frame(minHeight: geo.size.height)
                }
                .scrollBounceBasedOnSize()
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
    
    // 2.1.18：宫格功能项双模式（图标上 + 名称下，对齐安卓更多功能区）
    // destination 非空 → NavigationLink push 页面；否则 → Button 回调（action 为空则占位无反应）
    private func gridItem(icon: String, title: String, color: Color, destination: AnyView? = nil, action: (() -> Void)? = nil) -> some View {
        let content = VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(color.opacity(0.15))
                    .frame(width: 48, height: 48)
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(color)
            }
            
            Text(title)
                .font(.system(size: 12))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        
        if let dest = destination {
            return AnyView(NavigationLink(destination: dest) { content })
        } else {
            return AnyView(Button(action: action ?? {}) { content })
        }
    }
}

// 自适配滚动：内容不满一屏不弹跳（视觉锁死），超出才原生滚动（对标大厂智能锁死）
extension View {
    @ViewBuilder
    func scrollBounceBasedOnSize() -> some View {
        if #available(iOS 16.4, *) {
            self.scrollBounceBehavior(.basedOnSize)
        } else {
            self
        }
    }
}

#Preview { MyView().environmentObject(AuthManager.shared) }
