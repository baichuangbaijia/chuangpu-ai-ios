import SwiftUI

/// 技能行组件
struct SkillRow: View {
    let skill: Skill
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 图标
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [
                                SkillCategoryColors.getColor(for: skill.category).opacity(0.3),
                                SkillCategoryColors.getColor(for: skill.category).opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 80)
                
                Text(String(skill.name.prefix(1)))
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(SkillCategoryColors.getColor(for: skill.category))
            }
            
            // 名称
            Text(skill.name)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
                .lineLimit(1)
            
            // 描述
            Text(skill.description)
                .font(.system(size: 12))
                .foregroundColor(Constants.textSecondary)
                .lineLimit(2)
                .frame(height: 32, alignment: .top)
            
            // 下载量
            HStack {
                Image(systemName: "arrow.down.circle")
                    .font(.system(size: 11))
                Text("\(skill.downloads)")
                    .font(.system(size: 11))
            }
            .foregroundColor(Constants.textSecondary)
        }
        .padding(12)
        .background(Constants.bgSecondary)
        .cornerRadius(16)
    }
}

#Preview {
    HStack {
        SkillRow(skill: Skill(
            name: "市场调研",
            description: "快速进行市场调研，分析竞争对手情况",
            category: "数据分析",
            slug: "market-research",
            version: "1.0.0",
            downloads: 1234,
            isInstalled: false
        ))
        
        SkillRow(skill: Skill(
            name: "合同生成",
            description: "根据模板快速生成各类合同文档",
            category: "办公效率",
            slug: "contract-generator",
            version: "2.1.0",
            downloads: 5678,
            isInstalled: true
        ))
    }
    .padding()
    .background(Constants.bgPrimary)
}
