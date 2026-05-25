import SwiftUI

/// 技能页面 - 对照安卓SkillFragment
/// 安卓要素: 搜索框、分类标签栏(全部/数据分析/办公效率/生活助手/创意设计/学习教育)、技能卡片网格(名称+描述+下载量)、已安装Tab
struct SkillView: View {
    @State private var searchText = ""
    @State private var selectedCategory = "全部"
    @State private var skills: [Skill] = []
    @State private var showInstalled = false
    @State private var categories: [String] = ["全部", "数据分析", "办公效率", "生活助手", "创意设计", "学习教育"]
    
    var body: some View {
        ZStack {
            Constants.bgPrimary.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 标题
                HStack {
                    Text("技能商店")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                    // 已安装按钮（对照安卓tab切换）
                    Button(action: { showInstalled.toggle() }) {
                        Text(showInstalled ? "全部技能" : "已安装")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Constants.primaryPurple)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Constants.primaryPurple.opacity(0.15))
                            .cornerRadius(16)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                
                // 搜索框（对照安卓etSearch）
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(Constants.textSecondary)
                    TextField("搜索技能...", text: $searchText)
                        .font(.system(size: 15))
                        .foregroundColor(.white)
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(Constants.textSecondary)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Constants.bgTertiary)
                .cornerRadius(12)
                .padding(.horizontal, 20)
                
                // 分类标签栏（对照安卓categoryTabs，水平滚动）
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(categories, id: \.self) { cat in
                            Button(action: { selectedCategory = cat }) {
                                Text(cat)
                                    .font(.system(size: 14, weight: selectedCategory == cat ? .semibold : .regular))
                                    .foregroundColor(selectedCategory == cat ? .white : Constants.textSecondary)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(selectedCategory == cat ? Constants.primaryPurple : Constants.bgTertiary)
                                    .cornerRadius(20)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.vertical, 12)
                
                // 技能列表
                ScrollView(showsIndicators: false) {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        // 占位数据，展示UI
                        ForEach(placeholderSkills(), id: \.name) { skill in
                            SkillRow(skill: skill)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
        }
    }
    
    private func placeholderSkills() -> [Skill] {
        [
            Skill(name: "市场调研", description: "快速进行市场调研，分析竞争对手情况", category: "数据分析", slug: "market-research", version: "1.0", downloads: 1234, isInstalled: true),
            Skill(name: "合同生成", description: "根据模板快速生成各类合同文档", category: "办公效率", slug: "contract-gen", version: "2.1", downloads: 5678, isInstalled: false),
            Skill(name: "旅行规划", description: "智能规划旅行路线和行程安排", category: "生活助手", slug: "travel-plan", version: "1.2", downloads: 890, isInstalled: false),
            Skill(name: "文案创作", description: "生成优质营销文案和创意内容", category: "创意设计", slug: "copywriting", version: "3.0", downloads: 3456, isInstalled: true),
            Skill(name: "数据报表", description: "自动生成数据分析和可视化报表", category: "数据分析", slug: "data-report", version: "1.5", downloads: 2100, isInstalled: false),
            Skill(name: "英语学习", description: "AI英语对话练习和语法纠正", category: "学习教育", slug: "english-learn", version: "2.0", downloads: 4500, isInstalled: false),
            Skill(name: "周报生成", description: "一键生成工作周报和总结", category: "办公效率", slug: "weekly-report", version: "1.8", downloads: 3200, isInstalled: true),
            Skill(name: "菜谱推荐", description: "根据食材推荐美味菜谱", category: "生活助手", slug: "recipe", version: "1.0", downloads: 670, isInstalled: false),
        ]
    }
}

#Preview { SkillView() }
