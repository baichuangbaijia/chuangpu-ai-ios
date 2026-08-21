import SwiftUI

/// 2.1.18：关于我们（我的 → 关于我们）
/// 内容（老板拍板）：标题"关于我们" / 第一行 创普AI + 版本号 / 第二行 智能对话 无限可能 / 第三行 越用越懂你的专属AI助手
struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            Constants.bgPrimary.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 顶部导航（返回 + 标题"关于我们"）
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.white)
                    }
                    Spacer()
                    Text("关于我们")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                    Spacer()
                    Color.clear.frame(width: 20)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                
                Spacer()
                
                // logo 占位（紫色渐变圆角方块 + 人像，风格同抽屉"我的AI员工"）
                RoundedRectangle(cornerRadius: 18)
                    .fill(LinearGradient(colors: [Constants.primaryPurple, Constants.secondaryPurple], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 72, height: 72)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.white)
                    )
                    .padding(.bottom, 20)
                
                // 第一行：创普AI + 版本号（动态读取 Bundle 版本）
                HStack(spacing: 8) {
                    Text("创普AI")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                    Text("v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "2.1.18")")
                        .font(.system(size: 14))
                        .foregroundColor(Constants.textSecondary)
                }
                .padding(.bottom, 10)
                
                // 第二行：智能对话 无限可能
                Text("智能对话 无限可能")
                    .font(.system(size: 15))
                    .foregroundColor(Constants.textSecondary)
                    .padding(.bottom, 8)
                
                // 第三行：越用越懂你的专属AI助手
                Text("越用越懂你的专属AI助手")
                    .font(.system(size: 13))
                    .foregroundColor(Constants.textSecondary.opacity(0.7))
                
                Spacer()
            }
        }
        .navigationBarHidden(true)
    }
}

#Preview {
    NavigationStack {
        AboutView()
    }
}
