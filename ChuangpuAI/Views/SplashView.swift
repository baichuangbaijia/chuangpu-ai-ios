import SwiftUI

/// 启动页面
struct SplashView: View {
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0
    
    var body: some View {
        ZStack {
            // 背景渐变
            LinearGradient(
                colors: [
                    Color(hex: "0F0F1A"),
                    Color(hex: "1A1A2E"),
                    Color(hex: "0F0F1A")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Logo圆环
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Constants.primaryPurple.opacity(0.3), Color.clear],
                                center: .center,
                                startRadius: 40,
                                endRadius: 120
                            )
                        )
                        .frame(width: 200, height: 200)
                        .scaleEffect(scale)
                        .opacity(opacity)
                    
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [Constants.primaryPurple, Constants.secondaryPurple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 3
                        )
                        .frame(width: 120, height: 120)
                        .scaleEffect(scale)
                        .opacity(opacity)
                    
                    Image(systemName: "brain")
                        .font(.system(size: 50, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Constants.primaryPurple, Constants.secondaryPurple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .scaleEffect(scale)
                        .opacity(opacity)
                }
                
                // App名称
                VStack(spacing: 8) {
                    Text("创普AI")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, Constants.secondaryPurple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .opacity(opacity)
                    
                    Text("智能对话 · 无限可能")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(Constants.textSecondary)
                        .opacity(opacity)
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.0)) {
                scale = 1.0
                opacity = 1.0
            }
        }
    }
}

#Preview {
    SplashView()
}
