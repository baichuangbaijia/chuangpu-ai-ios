import SwiftUI

/// 技能行组件 - 2.1.17 单列大卡片（左圆图标 + 名称/描述/下载量 + 右侧"学习"按钮）
struct SkillRow: View {
    let skill: Skill
    let onLearn: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // 圆形图标（分类色）
            ZStack {
                Circle()
                    .fill(SkillCategoryColors.getColor(for: skill.category).opacity(0.2))
                    .frame(width: 52, height: 52)
                Text(String(skill.name.prefix(1)))
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(SkillCategoryColors.getColor(for: skill.category))
            }
            
            // 名称 + 描述 + 下载量
            VStack(alignment: .leading, spacing: 4) {
                Text(skill.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                Text(skill.description)
                    .font(.system(size: 12))
                    .foregroundColor(Constants.textSecondary)
                    .lineLimit(2)
                HStack(spacing: 4) {
                    Image(systemName: "arrow.down.circle")
                        .font(.system(size: 11))
                    Text("\(skill.downloads)")
                        .font(.system(size: 11))
                }
                .foregroundColor(Constants.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // 学习按钮（假数据占位：点击后变"已学习"不可再点，进"我的收藏"）
            Button(action: onLearn) {
                Text(skill.isInstalled ? "已学习" : "学习")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(skill.isInstalled ? Constants.textSecondary : .white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 8)
                    .background(skill.isInstalled ? Constants.bgTertiary : Constants.primaryPurple)
                    .cornerRadius(18)
            }
            .disabled(skill.isInstalled)
        }
        .padding(14)
        .background(Constants.bgSecondary)
        .cornerRadius(16)
    }
}

#Preview {
    VStack(spacing: 12) {
        SkillRow(skill: Skill(
            name: "自我改进智能体",
            description: "捕获经验教训、错误和纠正建议，持续优化自身行为",
            category: "AI智能体",
            slug: "self-improve-agent",
            version: "1.0",
            downloads: 636755,
            isInstalled: false
        )) {}
        SkillRow(skill: Skill(
            name: "摘要",
            description: "使用summarize CLI总结URL内容",
            category: "开发工具",
            slug: "summarize",
            version: "2.0",
            downloads: 459857,
            isInstalled: true
        )) {}
    }
    .padding()
    .background(Constants.bgPrimary)
}
