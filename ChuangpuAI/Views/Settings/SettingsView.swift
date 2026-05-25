import SwiftUI

/// 设置页面
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authManager: AuthManager
    @State private var currentModel = "deepseek-v3"
    @State private var notificationsEnabled = true
    @State private var showChangePassword = false
    @State private var showAbout = false
    
    var body: some View {
        ZStack {
            Constants.bgPrimary.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // 顶部导航
                    navBar
                    
                    // 模型选择
                    modelSection
                    
                    // 通知设置
                    notificationSection
                    
                    // 账号安全
                    securitySection
                    
                    // 其他设置
                    otherSection
                    
                    // 关于
                    aboutSection
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 30)
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showChangePassword) {
            changePasswordSheet
        }
        .sheet(isPresented: $showAbout) {
            aboutSheet
        }
        .onAppear {
            currentModel = authManager.getCurrentModel()
        }
    }
    
    private var navBar: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            Text("设置")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            
            Spacer()
            
            Color.clear.frame(width: 20)
        }
        .padding(.vertical, 16)
    }
    
    private var modelSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("AI模型")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Constants.textSecondary)
            
            VStack(spacing: 1) {
                ForEach(Constants.availableModels, id: \.0) { model in
                    modelRow(id: model.0, name: model.1, available: model.2)
                }
            }
            .background(Constants.bgSecondary)
            .cornerRadius(12)
        }
    }
    
    private func modelRow(id: String, name: String, available: Bool) -> some View {
        Button(action: {
            if available {
                currentModel = id
                authManager.setCurrentModel(id)
            }
        }) {
            HStack {
                Text(name)
                    .font(.system(size: 15))
                    .foregroundColor(available ? .white : Constants.textSecondary)
                
                if !available {
                    Text("即将上线")
                        .font(.system(size: 12))
                        .foregroundColor(Constants.accentOrange)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Constants.accentOrange.opacity(0.2))
                        .cornerRadius(4)
                }
                
                Spacer()
                
                if id == currentModel {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Constants.primaryPurple)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Constants.bgSecondary)
            .opacity(available ? 1 : 0.6)
        }
        .disabled(!available)
    }
    
    private var notificationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("通知")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Constants.textSecondary)
            
            HStack {
                Image(systemName: "bell.fill")
                    .font(.system(size: 18))
                    .foregroundColor(Constants.primaryPurple)
                    .frame(width: 28)
                
                Text("消息通知")
                    .font(.system(size: 15))
                    .foregroundColor(.white)
                
                Spacer()
                
                Toggle("", isOn: $notificationsEnabled)
                    .tint(Constants.primaryPurple)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Constants.bgSecondary)
            .cornerRadius(12)
        }
    }
    
    private var securitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("账号安全")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Constants.textSecondary)
            
            VStack(spacing: 1) {
                settingsItem(icon: "lock.fill", title: "修改密码", action: { showChangePassword = true })
                settingsItem(icon: "key.fill", title: "修改手机号", action: {})
            }
            .background(Constants.bgSecondary)
            .cornerRadius(12)
        }
    }
    
    private var otherSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("其他")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Constants.textSecondary)
            
            VStack(spacing: 1) {
                settingsItem(icon: "doc.text", title: "用户协议", action: {})
                settingsItem(icon: "hand.raised.fill", title: "隐私政策", action: {})
                settingsItem(icon: "trash", title: "清除缓存", action: clearCache)
            }
            .background(Constants.bgSecondary)
            .cornerRadius(12)
        }
    }
    
    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("关于")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Constants.textSecondary)
            
            VStack(spacing: 1) {
                settingsItem(icon: "info.circle.fill", title: "关于我们", action: { showAbout = true })
                settingsItem(icon: "star.fill", title: "给我们评分", action: rateApp)
                settingsItem(icon: "square.and.arrow.up", title: "分享给朋友", action: shareApp)
            }
            .background(Constants.bgSecondary)
            .cornerRadius(12)
            
            Text("创普AI v2.0.42")
                .font(.system(size: 13))
                .foregroundColor(Constants.textSecondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 10)
        }
    }
    
    private func settingsItem(icon: String, title: String, action: @escaping () -> Void) -> some View {
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
    
    private var changePasswordSheet: some View {
        NavigationStack {
            ZStack {
                Constants.bgPrimary.ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Text("修改密码功能开发中...")
                        .font(.system(size: 15))
                        .foregroundColor(Constants.textSecondary)
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("修改密码")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        showChangePassword = false
                    }
                    .foregroundColor(Constants.textSecondary)
                }
            }
        }
        .presentationDetents([.medium])
    }
    
    private var aboutSheet: some View {
        NavigationStack {
            ZStack {
                Constants.bgPrimary.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Logo
                        ZStack {
                            Circle()
                                .fill(Constants.primaryPurple.opacity(0.2))
                                .frame(width: 100, height: 100)
                            
                            Image(systemName: "brain")
                                .font(.system(size: 44))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Constants.primaryPurple, Constants.secondaryPurple],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }
                        .padding(.top, 40)
                        
                        VStack(spacing: 8) {
                            Text("创普AI")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("v2.0.42")
                                .font(.system(size: 14))
                                .foregroundColor(Constants.textSecondary)
                        }
                        
                        Text("智能对话 · 无限可能\n\n越用越懂你的专属AI助手")
                            .font(.system(size: 15))
                            .foregroundColor(Constants.textSecondary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(6)
                        
                        VStack(spacing: 12) {
                            Text("联系我们")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Constants.textSecondary)
                            
                            Text("support@chuangpu-ai.com")
                                .font(.system(size: 15))
                                .foregroundColor(Constants.primaryPurple)
                        }
                        .padding(.top, 20)
                        
                        Spacer()
                    }
                    .padding()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        showAbout = false
                    }
                    .foregroundColor(Constants.primaryPurple)
                }
            }
        }
    }
    
    private func clearCache() {
        // 清除缓存
        URLCache.shared.removeAllCachedResponses()
    }
    
    private func rateApp() {
        // 评分
    }
    
    private func shareApp() {
        // 分享
    }
}

#Preview {
    SettingsView()
        .environmentObject(AuthManager.shared)
}
