import SwiftUI

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
    @State private var logoPulse = false
    
    enum LoginMode { case sms, pwd, register }
    
    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: "0F0F1A"), Color(hex: "1A1A2E"), Color(hex: "0F0F1A")], startPoint: .topLeading, endPoint: .bottomTrailing).ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    Spacer().frame(height: 80)
                    ZStack {
                        Circle().fill(RadialGradient(colors: [Constants.primaryPurple.opacity(0.3), Color.clear], center: .center, startRadius: 20, endRadius: 80)).frame(width: 160, height: 160).scaleEffect(logoPulse ? 1.05 : 0.95).animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: logoPulse)
                        Circle().stroke(LinearGradient(colors: [Constants.primaryPurple, Constants.secondaryPurple], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 2).frame(width: 100, height: 100)
                        Image(systemName: "brain").font(.system(size: 40)).foregroundStyle(LinearGradient(colors: [Constants.primaryPurple, Constants.secondaryPurple], startPoint: .topLeading, endPoint: .bottomTrailing))
                    }
                    Spacer().frame(height: 16)
                    Text("创普AI").font(.system(size: 32, weight: .bold)).foregroundStyle(LinearGradient(colors: [.white, Constants.secondaryPurple], startPoint: .leading, endPoint: .trailing))
                    Text("越用越懂你的专属AI助手").font(.system(size: 14)).foregroundColor(Constants.textSecondary)
                    Spacer().frame(height: 50)
                    HStack(spacing: 0) {
                        tabBtn(title: "验证码登录", target: .sms, sel: mode == .sms)
                        tabBtn(title: "密码登录", target: .pwd, sel: mode == .pwd)
                    }.padding(.horizontal, 40)
                    Spacer().frame(height: 30)
                    phoneField
                    if mode == .sms || mode == .register { codeField }
                    if mode == .pwd || mode == .register { pwdField }
                    if let err = errorMessage { Text(err).font(.system(size: 13)).foregroundColor(.red).padding(.top, 12).padding(.horizontal, 24).frame(maxWidth: .infinity, alignment: .leading) }
                    Spacer().frame(height: 30)
                    Button(action: handleLogin) {
                        HStack(spacing: 8) {
                            if isLoading { ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white)) }
                            Text(mode == .register ? (isLoading ? "注册中..." : "注册") : (isLoading ? "登录中..." : "登录")).font(.system(size: 17, weight: .semibold)).foregroundColor(.white)
                        }.frame(maxWidth: .infinity).frame(height: 56).background(LinearGradient(colors: [Constants.primaryPurple, Constants.secondaryPurple], startPoint: .leading, endPoint: .trailing)).cornerRadius(12)
                    }.disabled(isLoading || phone.count != 11).opacity(phone.count == 11 ? 1 : 0.6).padding(.horizontal, 24)
                    Button(action: { withAnimation(.easeInOut(duration: 0.25)) { mode = mode == .register ? .sms : .register }; errorMessage = nil }) {
                        Text(mode == .register ? "已有账号？立即登录" : "还没有账号？立即注册").font(.system(size: 14)).foregroundColor(Constants.secondaryPurple)
                    }.padding(.top, 16)
                    Text("登录即表示同意《用户协议》和《隐私政策》").font(.system(size: 12)).foregroundColor(Constants.textSecondary).padding(.top, 20)
                    Spacer().frame(height: 40)
                }
            }
        }.onAppear { logoPulse = true }.onDisappear { countdownTimer?.invalidate() }
    }
    
    private func tabBtn(title: String, target: LoginMode, sel: Bool) -> some View {
        Button(action: { withAnimation(.easeInOut(duration: 0.25)) { mode = target }; errorMessage = nil }) {
            VStack(spacing: 8) {
                Text(title).font(.system(size: 15, weight: sel ? .semibold : .medium)).foregroundColor(sel ? .white : Constants.textSecondary)
                Rectangle().fill(sel ? Constants.primaryPurple : Color.clear).frame(height: 3).cornerRadius(1.5)
            }.frame(maxWidth: .infinity).padding(.vertical, 8)
        }
    }
    
    private var phoneField: some View {
        HStack(spacing: 0) {
            Text("+86").font(.system(size: 16)).foregroundColor(Constants.textSecondary).padding(.leading, 16)
            Rectangle().fill(Constants.textSecondary.opacity(0.3)).frame(width: 1, height: 20).padding(.horizontal, 12)
            TextField("请输入手机号", text: $phone).keyboardType(.phonePad).font(.system(size: 16)).foregroundColor(.white)
        }.frame(height: 56).background(Constants.bgTertiary).cornerRadius(12).padding(.horizontal, 24)
    }
    
    private var codeField: some View {
        HStack(spacing: 0) {
            TextField("请输入验证码", text: $code).keyboardType(.numberPad).font(.system(size: 16)).foregroundColor(.white).padding(.leading, 16)
            Spacer()
            Button(action: sendCode) { Text(countdown > 0 ? "\(countdown)s" : "获取验证码").font(.system(size: 14, weight: .medium)).foregroundColor(countdown > 0 ? Constants.textSecondary : Constants.primaryPurple) }.disabled(countdown > 0 || isSending).padding(.trailing, 16)
        }.frame(height: 56).background(Constants.bgTertiary).cornerRadius(12).padding(.horizontal, 24).padding(.top, 16)
    }
    
    private var pwdField: some View {
        SecureField(mode == .register ? "设置密码（至少6位）" : "请输入密码", text: $password).font(.system(size: 16)).foregroundColor(.white).padding(.horizontal, 16)
            .frame(height: 56).background(Constants.bgTertiary).cornerRadius(12).padding(.horizontal, 24).padding(.top, 16)
    }
    
    private func sendCode() {
        guard phone.count == 11 else { errorMessage = "请输入正确的手机号"; return }
        if isSending { return }; isSending = true
        let type = mode == .register ? "register" : "login"
        Task { do { let r = try await APIService.shared.sendSmsCode(phone: phone, type: type); await MainActor.run { isSending = false; if r.code == 0 { countdown = 60; countdownTimer?.invalidate(); countdownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { t in countdown -= 1; if countdown <= 0 { t.invalidate(); isSending = false } } } else { errorMessage = r.message ?? "发送失败" } } } catch { await MainActor.run { isSending = false; errorMessage = "网络错误" } } }
    }
    
    private func handleLogin() {
        guard phone.count == 11 else { errorMessage = "请输入正确的手机号"; return }
        if mode == .sms && code.count < 4 { errorMessage = "请输入验证码"; return }
        if mode == .pwd && password.count < 6 { errorMessage = "密码至少6位"; return }
        if mode == .register && (code.count < 4 || password.count < 6) { errorMessage = "请输入验证码和密码"; return }
        isLoading = true; errorMessage = nil
        Task { do { let ok: Bool; if mode == .register { ok = try await authManager.register(phone: phone, password: password, code: code) } else { ok = try await authManager.login(phone: phone, code: mode == .sms ? code : nil, password: mode == .pwd ? password : nil, loginType: mode == .sms ? "sms" : "pwd") }; await MainActor.run { isLoading = false; if !ok { errorMessage = "操作失败" } } } catch { await MainActor.run { isLoading = false; errorMessage = error.localizedDescription } } }
    }
}
