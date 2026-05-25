import SwiftUI

/// VIP会员页面
struct VipView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authManager: AuthManager
    @State private var selectedPlan = 0
    @State private var isAgree = false
    @State private var isActivating = false
    @State private var showSuccess = false
    @State private var errorMessage: String?
    
    let planPrices = ["298/年", "198/月", "68/周"]
    
    var body: some View {
        ZStack {
            Constants.bgPrimary.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // 顶部返回按钮
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(.white)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    
                    // VIP标识
                    vipHeader
                    
                    // 权益列表
                    benefitsList
                    
                    // 套餐选择
                    planSelection
                    
                    // 协议
                    agreementSection
                    
                    // 开通按钮
                    activateButton
                    
                    // 其他链接
                    otherLinks
                }
                .padding(.bottom, 40)
            }
            
            // 成功弹窗
            if showSuccess {
                successOverlay
            }
        }
        .navigationBarHidden(true)
    }
    
    private var vipHeader: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Constants.accentOrange.opacity(0.4), Color.clear],
                            center: .center,
                            startRadius: 30,
                            endRadius: 80
                        )
                    )
                    .frame(width: 140, height: 140)
                
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [Constants.accentOrange, Constants.accentPink],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 3
                    )
                    .frame(width: 100, height: 100)
                
                Image(systemName: "crown.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Constants.accentOrange, Constants.accentPink],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            Text("开通创普AI会员")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
            
            Text("解锁全部高级功能")
                .font(.system(size: 14))
                .foregroundColor(Constants.textSecondary)
        }
        .padding(.top, 20)
    }
    
    private var benefitsList: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("会员特权")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                benefitItem(icon: "infinity", title: "无限对话", desc: "无限制使用AI对话功能")
                benefitItem(icon: "brain", title: "专属智能体", desc: "创建和管理专属AI智能体")
                benefitItem(icon: "bolt.fill", title: "优先响应", desc: "享受更快的响应速度")
                benefitItem(icon: "cloud.fill", title: "云端记忆", desc: "跨设备同步记忆和设置")
            }
        }
        .padding(.horizontal, 20)
    }
    
    private func benefitItem(icon: String, title: String, desc: String) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Constants.accentOrange.opacity(0.2))
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(Constants.accentOrange)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white)
                
                Text(desc)
                    .font(.system(size: 13))
                    .foregroundColor(Constants.textSecondary)
            }
            
            Spacer()
        }
        .padding(12)
        .background(Constants.bgSecondary)
        .cornerRadius(12)
    }
    
    private var planSelection: some View {
        VStack(spacing: 12) {
            ForEach(0..<3, id: \.self) { index in
                planCard(index: index)
            }
        }
        .padding(.horizontal, 20)
    }
    
    private func planCard(index: Int) -> some View {
        Button(action: { selectedPlan = index }) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(planPrices[index])
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(renewalHint(for: index))
                        .font(.system(size: 12))
                        .foregroundColor(Constants.textSecondary)
                }
                
                Spacer()
                
                Image(systemName: selectedPlan == index ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundColor(selectedPlan == index ? Constants.accentOrange : Constants.textSecondary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        selectedPlan == index ? Constants.accentOrange : Constants.bgTertiary,
                        lineWidth: selectedPlan == index ? 2 : 1
                    )
            )
        }
    }
    
    private func renewalHint(for index: Int) -> String {
        switch index {
        case 0: return "到期按298/年自动订阅，可随时取消"
        case 1: return "到期按198/月自动订阅，可随时取消"
        case 2: return "到期按68/周自动订阅，可随时取消"
        default: return ""
        }
    }
    
    private var agreementSection: some View {
        VStack(spacing: 12) {
            // 错误提示
            if let error = errorMessage {
                Text(error)
                    .font(.system(size: 13))
                    .foregroundColor(.red)
            }
            
            // 积分规则
            Button(action: showRules) {
                HStack {
                    Image(systemName: "info.circle")
                    Text("积分规则说明")
                }
                .font(.system(size: 13))
                .foregroundColor(Constants.primaryPurple)
            }
        }
        .padding(.horizontal, 20)
    }
    
    private var activateButton: some View {
        Button(action: activateVip) {
            HStack {
                if isActivating {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text("开通会员")
                        .font(.system(size: 17, weight: .semibold))
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                isAgree ?
                LinearGradient(colors: [Constants.accentOrange, Constants.accentPink], startPoint: .leading, endPoint: .trailing) :
                LinearGradient(colors: [Constants.bgTertiary], startPoint: .leading, endPoint: .trailing)
            )
            .cornerRadius(12)
        }
        .disabled(!isAgree || isActivating)
        .padding(.horizontal, 20)
    }
    
    private var otherLinks: some View {
        HStack(spacing: 24) {
            Button(action: restorePurchases) {
                Text("恢复购买")
                    .font(.system(size: 13))
                    .foregroundColor(Constants.textSecondary)
            }
            
            Button(action: showAgreement) {
                Text("用户协议")
                    .font(.system(size: 13))
                    .foregroundColor(Constants.textSecondary)
            }
            
            Button(action: showPrivacy) {
                Text("隐私政策")
                    .font(.system(size: 13))
                    .foregroundColor(Constants.textSecondary)
            }
        }
        .padding(.top, 10)
    }
    
    private var successOverlay: some View {
        ZStack {
            Color.black.opacity(0.7).ignoresSafeArea()
            
            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(Constants.accentGreen.opacity(0.2))
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(Constants.accentGreen)
                }
                
                Text("开通成功")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                
                Text("欢迎成为创普AI会员")
                    .font(.system(size: 15))
                    .foregroundColor(Constants.textSecondary)
                
                Button(action: {
                    showSuccess = false
                    dismiss()
                }) {
                    Text("开始使用")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 200, height: 50)
                        .background(Constants.primaryPurple)
                        .cornerRadius(25)
                }
            }
        }
    }
    
    private func activateVip() {
        isActivating = true
        errorMessage = nil
        
        Task {
            do {
                try await authManager.activateTestVip()
                await MainActor.run {
                    isActivating = false
                    showSuccess = true
                }
            } catch {
                await MainActor.run {
                    isActivating = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    private func showRules() {
        // 显示积分规则
    }
    
    private func restorePurchases() {
        // 恢复购买
    }
    
    private func showAgreement() {
        // 显示用户协议
    }
    
    private func showPrivacy() {
        // 显示隐私政策
    }
}

#Preview {
    VipView()
        .environmentObject(AuthManager.shared)
}
