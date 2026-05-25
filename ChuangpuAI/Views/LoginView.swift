import SwiftUI

/// 登录/注册页面
struct LoginView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var mode: LoginMode = .sms
    @State private var phone = ""
    @State private var code = ""
    @State private var password = ""
    @State private var countdown = 0
    @State private var isLoading = false
    @State private var isSending = false
    @State private var errorMessage: String?
    @State private var countdownTimer: Timer?
    
    enum LoginMode {
        case sms, pwd, register
    }
    
    var body: some View {
        ZStack {
            // 背景
            Constants.bgPrimary.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 0) {
                    // 顶部装饰
                    VStack {
                        Spacer().frame(height: 80)
                        
                        // Logo
                        ZStack {
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [Constants.primaryPurple.opacity(0.4), Color.clear],
                                        center: .center,
                                        startRadius: 20,
                                        endRadius: 80
                                    )
                                )
                                .frame(width: 160, height: 160)
                            
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        colors: [Constants.primaryPurple.opacity(0.5), Constants.secondaryPurple.opacity(0.3)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 2
                                )
                                .frame(width: 100, height: 100)
                            
                            Image(systemName: "brain")
                                .font(.system(size: 40))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Constants.primaryPurple, Constants.secondaryPurple],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }
                        
                        Spacer().frame(height: 30)
                        
                        Text("创普AI")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.white, Constants.secondaryPurple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        
                        Text("越用越懂你的专属AI助手")
                            .font(.system(size: 14))
                            .foregroundColor(Constants.textSecondary)
                            .padding(.top, 4)
                    }
                    
                    Spacer().frame(height: 50)
                    
                    // Tab切换
                    HStack(spacing: 0) {
                        tabButton("验证码登录", mode: .sms)
                        tabButton("密码登录", mode: .pwd)
                    }
                    .padding(.horizontal, 40)
                    
                    Spacer().frame(height: 30)
                    
                    // 输入框
                    VStack(spacing: 16) {
                        // 手机号
                        HStack {
                            Text("+86")
                                .foregroundColor(Constants.textSecondary)
                                .padding(.leading, 16)
                            
                            TextField("请输入手机号", text: $phone)
                                .keyboardType(.phonePad)
                                .foregroundColor(.white)
                        }
                        .frame(height: 56)
                        .background(Constants.bgTertiary)
                        .cornerRadius(12)
                        .padding(.horizontal, 24)
                        
                        // 验证码
                        if mode == .sms || mode == .register {
                            HStack {
                                TextField("请输入验证码", text: $code)
                                    .keyboardType(.numberPad)
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                Button(action: sendCode) {
                                    Text(countdown > 0 ? "\(countdown)s" : "获取验证码")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(countdown > 0 ? Constants.textSecondary : Constants.primaryPurple)
                                }
                                .disabled(countdown > 0 || isSending)
                                .padding(.trailing, 16)
                            }
                            .frame(height: 56)
                            .background(Constants.bgTertiary)
                            .cornerRadius(12)
                            .padding(.horizontal, 24)
                        }
                        
                        // 密码
                        if mode == .pwd || mode == .register {
                            SecureField("请输入密码", text: $password)
                                .foregroundColor(.white)
                                .frame(height: 56)
                                .background(Constants.bgTertiary)
                                .cornerRadius(12)
                                .padding(.horizontal, 24)
                        }
                    }
                    
                    // 错误提示
                    if let error = errorMessage {
                        Text(error)
                            .font(.system(size: 13))
                            .foregroundColor(.red)
                            .padding(.top, 12)
                    }
                    
                    Spacer().frame(height: 30)
                    
                    // 登录/注册按钮
                    Button(action: handleLogin) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text(mode == .register ? "注册" : "登录")
                                    .font(.system(size: 17, weight: .semibold))
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            LinearGradient(
                                colors: [Constants.primaryPurple, Constants.secondaryPurple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                        .padding(.horizontal, 24)
                    }
                    .disabled(isLoading || phone.count != 11)
                    .opacity(phone.count == 11 ? 1 : 0.6)
                    
                    // 切换注册/登录
                    Button(action: toggleMode) {
                        Text(mode == .register ? "已有账号？立即登录" : "还没有账号？立即注册")
                            .font(.system(size: 14))
                            .foregroundColor(Constants.secondaryPurple)
                            .padding(.top, 16)
                    }
                    
                    // 协议
                    if mode != .register {
                        Text("登录即表示同意《用户协议》和《隐私政策》")
                            .font(.system(size: 12))
                            .foregroundColor(Constants.textSecondary)
                            .padding(.top, 20)
                    }
                    
                    Spacer().frame(height: 40)
                }
            }
        }
        .onDisappear {
            countdownTimer?.invalidate()
        }
    }
    
    private func tabButton(_ title: String, mode tabMode: LoginMode) -> some View {
        Button(action: {
            mode = tabMode
            errorMessage = nil
        }) {
            Text(title)
                .font(.system(size: 15, weight: .medium))
                    Group {
                        if mode == tabMode {
                            LinearGradient(colors: [Constants.primaryPurple, Constants.secondaryPurple], startPoint: .leading, endPoint: .trailing)
                        } else {
                            Color.clear
                        }
                    }
                )
                .cornerRadius(8)
        }
    }
    
    private func toggleMode() {
        mode = mode == .register ? .sms : .register
        errorMessage = nil
    }
    
    private func sendCode() {
        guard phone.count == 11 else {
            errorMessage = "请输入正确的手机号"
            return
        }
        
        isSending = true
        let type = mode == .register ? "register" : "login"
        
        Task {
            do {
                let result = try await APIService.shared.sendSmsCode(phone: phone, type: type)
                await MainActor.run {
                    isSending = false
                    if result.code == 0 {
                        startCountdown()
                    } else {
                        errorMessage = result.message ?? "发送失败"
                    }
                }
            } catch {
                await MainActor.run {
                    isSending = false
                    errorMessage = "网络错误"
                }
            }
        }
    }
    
    private func startCountdown() {
        countdown = 60
        countdownTimer?.invalidate()
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            countdown -= 1
            if countdown <= 0 {
                timer.invalidate()
            }
        }
    }
    
    private func handleLogin() {
        guard phone.count == 11 else {
            errorMessage = "请输入正确的手机号"
            return
        }
        
        if mode == .sms && code.isEmpty {
            errorMessage = "请输入验证码"
            return
        }
        
        if mode == .pwd && password.count < 6 {
            errorMessage = "密码至少6位"
            return
        }
        
        if mode == .register && (code.isEmpty || password.count < 6) {
            errorMessage = "请输入验证码和密码"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let success: Bool
                if mode == .register {
                    success = try await authManager.register(phone: phone, password: password, code: code)
                } else {
                    success = try await authManager.login(
                        phone: phone,
                        code: mode == .sms ? code : nil,
                        password: mode == .pwd ? password : nil,
                        loginType: mode == .sms ? "sms" : "pwd"
                    )
                }
                
                await MainActor.run {
                    isLoading = false
                    if !success {
                        errorMessage = "操作失败"
                    }
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthManager.shared)
}
