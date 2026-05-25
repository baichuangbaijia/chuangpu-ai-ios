import Foundation
import SwiftUI

/// 常量定义
enum Constants {
    // MARK: - UserDefaults Keys
    static let tokenKey = "auth_token"
    static let userIdKey = "user_id"
    static let userNameKey = "user_name"
    static let userNicknameKey = "user_nickname"
    static let isVipKey = "is_vip"
    static let currentModelKey = "current_model"
    static let appConfigKey = "app_config"
    
    // MARK: - API URLs
    static let baseURL = "https://ai.xianbaba188.cn/api/"
    static let agentBaseURL = "https://ai.xianbaba188.cn/agent/api/"
    static let uploadBaseURL = "https://ai.xianbaba188.cn/upload-api/"
    
    // MARK: - 可用模型
    static let availableModels = [
        ("deepseek-v3", "DeepSeek V3", true),
        ("kimi-2.5", "Kimi 2.5", false),
        ("glm-5", "GLM-5", false),
        ("minimax-m2.5", "MiniMax M2.5", false),
        ("doubao-2.0", "豆包 2.0", false)
    ]
    
    // MARK: - 主题颜色
    static let primaryPurple = Color(hex: "7C3AED")
    static let secondaryPurple = Color(hex: "8B5CF6")
    static let accentPink = Color(hex: "EC4899")
    static let accentOrange = Color(hex: "F97316")
    static let accentGreen = Color(hex: "10B981")
    static let accentBlue = Color(hex: "3B82F6")
    static let textPrimary = Color(hex: "FFFFFF")
    static let textSecondary = Color(hex: "A0A0A0")
    static let bgPrimary = Color(hex: "0F0F1A")
    static let bgSecondary = Color(hex: "1A1A2E")
    static let bgTertiary = Color(hex: "252540")
}

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - 技能分类颜色映射
enum SkillCategoryColors {
    static let gradientMap: [String: String] = [
        "AI智能体": "#7c3aed",
        "AI对话聊天": "#8b5cf6",
        "AI写作文案": "#a855f7",
        "AI图像生成": "#ec4899",
        "AI视频音频": "#f43f5e",
        "AI编程辅助": "#6366f1",
        "AI搜索问答": "#8b5cf6",
        "开发工具": "#3b82f6",
        "数据分析": "#f97316",
        "办公效率": "#10b981",
        "内容创作": "#ec4899",
        "设计创意": "#8b5cf6",
        "社交媒体": "#f43f5e",
        "营销推广": "#ef4444",
        "电商工具": "#f97316",
        "教育学习": "#eab308",
        "翻译语言": "#0ea5e9",
        "金融理财": "#22c55e",
        "健康医疗": "#ef4444",
        "安全合规": "#6366f1",
        "生活服务": "#14b8a6"
    ]
    
    static func getColor(for category: String?) -> Color {
        guard let category = category,
              let hex = gradientMap[category] else {
            return Constants.primaryPurple
        }
        return Color(hex: hex.replacingOccurrences(of: "#", with: ""))
    }
}
