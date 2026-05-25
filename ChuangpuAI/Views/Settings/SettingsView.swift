import SwiftUI

/// 设置页面 - 对照安卓SettingsActivity
/// 安卓要素: 返回按钮、昵称修改、密码修改(旧密码+新密码+确认)、消息通知开关、清除缓存、检查更新、用户协议、隐私政策、主题选择(4个)、退出登录
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authManager: AuthManager
    @State private var nickname = ""
    @State private var showEditNickname = false
    @State private var showChangePassword = false
    @State private var notificationsEnabled = true
    @State private var showPrivacy = false
    @State private var showAgreement = false
    @State private var showLogoutAlert = false
    @State private var selectedTheme = "default"
    
    var body: some View {
        ZStack {
            Constants.bgPrimary.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // 顶部导航
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "chevron.left").font(.system(size: 20, weight: .medium)).foregroundColor(.white)
                        }
                        Spacer()
                        Text("设置").font(.system(size: 18, weight: .semibold)).foregroundColor(.white)
                        Spacer()
                        Color.clear.frame(width: 20)
                    }.padding(.vertical, 16)
                    
                    // 账号信息
                    VStack(alignment: .leading, spacing: 12) {
                        Text("账号").font(.system(size: 14, weight: .medium)).foregroundColor(Constants.textSecondary)
                        VStack(spacing: 1) {
                            // 修改昵称（对照安卓itemNickname）
                            Button(action: { showEditNickname = true }) {
                                HStack(spacing: 12) {
                                    Image(systemName: "person.fill").font(.system(size: 18)).foregroundColor(Constants.primaryPurple).frame(width: 28)
                                    Text("修改昵称").font(.system(size: 15)).foregroundColor(.white)
                                    Spacer()
                                    Text(nickname.isEmpty ? "未设置" : nickname).font(.system(size: 14)).foregroundColor(Constants.textSecondary)
                                    Image(systemName: "chevron.right").font(.system(size: 13)).foregroundColor(Constants.textSecondary)
                                }.padding(.horizontal, 16).padding(.vertical, 14).background(Constants.bgSecondary)
                            }
                            // 修改密码（对照安卓itemPassword）
                            Button(action: { showChangePassword = true }) {
                                HStack(spacing: 12) {
                                    Image(systemName: "lock.fill").font(.system(size: 18)).foregroundColor(Constants.primaryPurple).frame(width: 28)
                                    Text("修改密码").font(.system(size: 15)).foregroundColor(.white)
                                    Spacer()
                                    Image(systemName: "chevron.right").font(.system(size: 13)).foregroundColor(Constants.textSecondary)
                                }.padding(.horizontal, 16).padding(.vertical, 14).background(Constants.bgSecondary)
                            }
                        }.cornerRadius(12)
                    }
                    
                    // 通知设置
                    VStack(alignment: .leading, spacing: 12) {
                        Text("通知").font(.system(size: 14, weight: .medium)).foregroundColor(Constants.textSecondary)
                        HStack(spacing: 12) {
                            Image(systemName: "bell.fill").font(.system(size: 18)).foregroundColor(Constants.primaryPurple).frame(width: 28)
                            Text("消息通知").font(.system(size: 15)).foregroundColor(.white)
                            Spacer()
                            Toggle("", isOn: $notificationsEnabled).tint(Constants.primaryPurple)
                        }.padding(.horizontal, 16).padding(.vertical, 14).background(Constants.bgSecondary).cornerRadius(12)
                    }
                    
                    // 其他
                    VStack(alignment: .leading, spacing: 12) {
                        Text("其他").font(.system(size: 14, weight: .medium)).foregroundColor(Constants.textSecondary)
                        VStack(spacing: 1) {
                            settingsRow(icon: "trash", title: "清除缓存", showArrow: true)
                            settingsRow(icon: "arrow.down.circle.fill", title: "检查更新", showArrow: true)
                            Button(action: { showAgreement = true }) {
                                settingsRow(icon: "doc.text", title: "用户协议", showArrow: true)
                            }
                            Button(action: { showPrivacy = true }) {
                                settingsRow(icon: "hand.raised.fill", title: "隐私政策", showArrow: true)
                            }
                        }.background(Constants.bgSecondary).cornerRadius(12)
                    }
                    
                    // 主题选择（对照安卓4个主题球）
                    VStack(alignment: .leading, spacing: 12) {
                        Text("主题").font(.system(size: 14, weight: .medium)).foregroundColor(Constants.textSecondary)
                        HStack(spacing: 16) {
                            themeCircle(id: "default", name: "默认", color1: "1A1A2E", color2: "0F0F1A")
                            themeCircle(id: "deep-space", name: "深空", color1: "0A0A2E", color2: "000020")
                            themeCircle(id: "dark-blue", name: "暗蓝", color1: "0A1628", color2: "061020")
                            themeCircle(id: "star-purple", name: "星紫", color1: "1A0A2E", color2: "100020")
                        }
                    }
                    
                    // 退出登录（对照安卓btnLogout）
                    Button(action: { showLogoutAlert = true }) {
                        Text("退出登录").font(.system(size: 16, weight: .medium)).foregroundColor(.red)
                            .frame(maxWidth: .infinity).frame(height: 50).background(Constants.bgSecondary).cornerRadius(12)
                    }
                    
                    Text("v2.0.44").font(.system(size: 13)).foregroundColor(Constants.textSecondary).frame(maxWidth: .infinity, alignment: .center).padding(.top, 10)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 30)
            }
        }
        .navigationBarHidden(true)
        .alert("退出登录", isPresented: $showLogoutAlert) {
            Button("取消", role: .cancel) {}
            Button("确定", role: .destructive) { authManager.logout(); dismiss() }
        } message: { Text("确定要退出登录吗？") }
        .sheet(isPresented: $showEditNickname) { EditNicknameSheet(nickname: $nickname) }
        .sheet(isPresented: $showChangePassword) { ChangePasswordSheet() }
        .sheet(isPresented: $showAgreement) { AgreementSheet(title: "用户协议", content: agreementText) }
        .sheet(isPresented: $showPrivacy) { AgreementSheet(title: "隐私政策", content: privacyText) }
        .onAppear { nickname = authManager.currentUser?.nickname ?? "" }
    }
    
    private func settingsRow(icon: String, title: String, showArrow: Bool) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon).font(.system(size: 18)).foregroundColor(Constants.primaryPurple).frame(width: 28)
            Text(title).font(.system(size: 15)).foregroundColor(.white)
            Spacer()
            if showArrow { Image(systemName: "chevron.right").font(.system(size: 13)).foregroundColor(Constants.textSecondary) }
        }.padding(.horizontal, 16).padding(.vertical, 14).background(Constants.bgSecondary)
    }
    
    private func themeCircle(id: String, name: String, color1: String, color2: String) -> some View {
        Button(action: { selectedTheme = id }) {
            VStack(spacing: 6) {
                Circle()
                    .fill(LinearGradient(colors: [Color(hex: color1), Color(hex: color2)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 48, height: 48)
                    .overlay(Circle().stroke(selectedTheme == id ? Constants.primaryPurple : Color.clear, lineWidth: 2))
                Text(name).font(.system(size: 12)).foregroundColor(selectedTheme == id ? .white : Constants.textSecondary)
            }
        }
    }
    
    private var agreementText: String { """
一、服务说明
创普AI是一款由创普科技运营的人工智能对话助手产品。本服务通过AI技术为用户提供智能聊天、技能服务、定时任务管理等功能。

二、账号注册与使用
您可以通过手机号注册的方式创建创普AI账号。在注册时，您需要提供真实、准确、有效的个人信息，并设置安全的登录密码。

三、用户行为规范
· 遵守中华人民共和国法律法规，不得利用本服务从事违法活动
· 不得发布或传播违反公序良俗、损害社会公共利益的内容
· 不得攻击、侵入、干扰本服务的正常运行或破坏系统安全
· 不得利用AI服务生成、传播违法信息、虚假信息或有害内容

四、AI生成内容说明
创普AI生成的内容仅供参考之用，不构成任何形式的专业建议。

五、知识产权
您通过本服务输入的内容，其知识产权归您所有。创普AI的产品名称、界面设计、程序代码的知识产权归创普科技所有。

六、免责声明
· AI可能因技术限制产生不准确、不适当的内容，您需自行判断并承担使用风险
· 因不可抗力导致的服务中断或数据丢失，我们不承担责任

联系邮箱：support@chuangpu-ai.com
""" }
    
    private var privacyText: String { """
一、我们收集的信息
· 账号信息：手机号码、昵称、头像
· 聊天记录：您与创普AI的对话内容
· AI记忆数据：AI从对话中提取并存储的关键信息
· 设备信息：设备型号、操作系统版本等基本信息

二、信息的用途
我们收集您的信息主要用于：提供AI对话服务、个性化服务、安全防护、产品改进、法律法规要求。

三、信息存储
您的个人信息存储在位于中国境内的服务器上。我们采用数据加密、访问控制、安全审计等措施保护您的信息安全。

四、AI记忆说明
创普AI具备记忆功能，可以从您的对话中提取关键信息并存储。您可以随时在"我的记忆"页面查看、编辑或删除记忆内容。

五、您的权利
您享有知情权、访问权、更正权、删除权、撤回同意、账号注销等权利。

联系邮箱：support@chuangpu-ai.com
""" }
}

// MARK: - 修改昵称弹窗
struct EditNicknameSheet: View {
    @Binding var nickname: String
    @State private var newNickname = ""
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Constants.bgPrimary.ignoresSafeArea()
                VStack(spacing: 20) {
                    TextField("请输入新昵称", text: $newNickname)
                        .font(.system(size: 16)).foregroundColor(.white).padding(16)
                        .background(Constants.bgTertiary).cornerRadius(12)
                    Spacer()
                }.padding(20)
            }
            .navigationTitle("修改昵称").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { Button("取消") { dismiss() }.foregroundColor(Constants.textSecondary) }
                ToolbarItem(placement: .navigationBarTrailing) { Button("确定") { nickname = newNickname; dismiss() }.foregroundColor(Constants.primaryPurple).disabled(newNickname.isEmpty) }
            }
        }.presentationDetents([.medium])
        .onAppear { newNickname = nickname }
    }
}

// MARK: - 修改密码弹窗
struct ChangePasswordSheet: View {
    @State private var oldPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var errorMsg: String?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Constants.bgPrimary.ignoresSafeArea()
                VStack(spacing: 16) {
                    SecureField("请输入旧密码", text: $oldPassword).font(.system(size: 16)).foregroundColor(.white).padding(16).background(Constants.bgTertiary).cornerRadius(12)
                    SecureField("请输入新密码（至少6位）", text: $newPassword).font(.system(size: 16)).foregroundColor(.white).padding(16).background(Constants.bgTertiary).cornerRadius(12)
                    SecureField("请确认新密码", text: $confirmPassword).font(.system(size: 16)).foregroundColor(.white).padding(16).background(Constants.bgTertiary).cornerRadius(12)
                    if let err = errorMsg { Text(err).font(.system(size: 13)).foregroundColor(.red) }
                    Spacer()
                }.padding(20)
            }
            .navigationTitle("修改密码").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { Button("取消") { dismiss() }.foregroundColor(Constants.textSecondary) }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("确定") {
                        if oldPassword.isEmpty { errorMsg = "请输入旧密码"; return }
                        if newPassword.count < 6 { errorMsg = "新密码至少6位"; return }
                        if newPassword != confirmPassword { errorMsg = "两次密码不一致"; return }
                        dismiss()
                    }.foregroundColor(Constants.primaryPurple)
                }
            }
        }.presentationDetents([.large])
    }
}

// MARK: - 协议弹窗
struct AgreementSheet: View {
    let title: String
    let content: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Constants.bgPrimary.ignoresSafeArea()
                ScrollView {
                    Text(content).font(.system(size: 15)).foregroundColor(Constants.textSecondary).lineSpacing(6).padding(20)
                }
            }
            .navigationTitle(title).navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .navigationBarTrailing) { Button("确定") { dismiss() }.foregroundColor(Constants.primaryPurple) } }
        }
    }
}

#Preview { SettingsView().environmentObject(AuthManager.shared) }
