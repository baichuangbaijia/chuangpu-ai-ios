import SwiftUI

/// 技能页面 - 对照安卓SkillFragment
/// 2.1.17: 顶部双tab(技能市场/我的收藏) + 搜索 + 21分类横滑(全部+20) + 统计条 + 单列大卡片 + 学习按钮(假数据占位)
struct SkillView: View {
    @State private var searchText = ""
    @State private var selectedCategory = "全部"
    @State private var skills: [Skill] = SkillView.placeholderSkills()
    @State private var showInstalled = false
    @State private var categories: [String] = [
        "全部", "AI写作文案", "AI图像生成", "AI对话聊天", "AI搜索问答", "AI智能体",
        "AI编程辅助", "AI视频音频", "健康医疗", "内容创作", "办公效率", "安全合规",
        "开发工具", "教育学习", "数据分析", "电商工具", "社交媒体", "翻译语言",
        "营销推广", "设计创意", "金融理财"
    ]
    
    var body: some View {
        ZStack {
            Constants.bgPrimary.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 顶部双tab：技能市场 / 我的收藏（2.1.17 对照安卓顶栏）
                HStack(spacing: 0) {
                    topTab(title: "技能市场", isActive: !showInstalled) { showInstalled = false }
                    topTab(title: "我的收藏", isActive: showInstalled) { showInstalled = true }
                }
                .padding(.top, 12)
                .padding(.bottom, 10)
                .padding(.horizontal, 20)
                
                // 搜索框（对照安卓etSearch）
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(Constants.textSecondary)
                    TextField("搜索你想要的技能...", text: $searchText)
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
                
                if !showInstalled {
                    // 分类标签栏（水平滚动，21个：全部+20分类）
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
                    
                    // 统计条（对照安卓：共技能数/已安装数）
                    HStack {
                        Text("技能市场共 32231 个技能 · 已安装 \(installedCount) 个")
                            .font(.system(size: 12))
                            .foregroundColor(Constants.textSecondary)
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 10)
                } else {
                    // 我的收藏 tab 提示条
                    HStack {
                        Text("已收藏 \(installedCount) 个技能")
                            .font(.system(size: 12))
                            .foregroundColor(Constants.textSecondary)
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                }
                
                // 技能列表（单列大卡片）
                ScrollView(showsIndicators: false) {
                    if filteredSkills().isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: showInstalled ? "star" : "magnifyingglass")
                                .font(.system(size: 40))
                                .foregroundColor(Constants.textSecondary)
                            Text(showInstalled ? "还没有收藏的技能" : "没有找到相关技能")
                                .font(.system(size: 14))
                                .foregroundColor(Constants.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 80)
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredSkills(), id: \.name) { skill in
                                SkillRow(skill: skill) { learnSkill(skill) }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 4)
                        .padding(.bottom, 20)
                    }
                }
            }
        }
    }
    
    /// 顶部 tab（技能市场/我的收藏）
    private func topTab(title: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) { action() }
        }) {
            VStack(spacing: 6) {
                Text(title)
                    .font(.system(size: 17, weight: isActive ? .bold : .regular))
                    .foregroundColor(isActive ? .white : Constants.textSecondary)
                Rectangle()
                    .fill(isActive ? Constants.primaryPurple : Color.clear)
                    .frame(width: 44, height: 3)
                    .cornerRadius(1.5)
            }
            .frame(maxWidth: .infinity)
        }
    }
    
    /// 已安装/已收藏数量
    private var installedCount: Int {
        skills.filter { $0.isInstalled }.count
    }
    
    /// 学习按钮（假数据占位：本地标记已安装，进"我的收藏"）
    private func learnSkill(_ skill: Skill) {
        guard let idx = skills.firstIndex(where: { $0.name == skill.name }) else { return }
        skills[idx].isInstalled = true
    }
    
    /// 过滤：收藏tab / 分类 / 搜索
    private func filteredSkills() -> [Skill] {
        var list = skills
        if showInstalled {
            list = list.filter { $0.isInstalled }
        } else if selectedCategory != "全部" {
            list = list.filter { $0.category == selectedCategory }
        }
        if !searchText.isEmpty {
            list = list.filter { $0.name.contains(searchText) || $0.description.contains(searchText) }
        }
        return list
    }
    
    private static func placeholderSkills() -> [Skill] {
        [
            Skill(name: "自我改进智能体", description: "捕获经验教训、错误和纠正建议，持续优化自身行为", category: "AI智能体", slug: "self-improve-agent", version: "1.0", downloads: 636755, isInstalled: false),
            Skill(name: "摘要", description: "使用summarize CLI总结URL内容", category: "开发工具", slug: "summarize", version: "2.0", downloads: 459857, isInstalled: false),
            Skill(name: "查找技能", description: "当用户询问如何做某事时，查找并推荐合适技能", category: "AI搜索问答", slug: "find-skill", version: "1.2", downloads: 432405, isInstalled: false),
            Skill(name: "GitHub", description: "使用gh CLI与GitHub交互，管理仓库和Issue", category: "开发工具", slug: "github", version: "3.1", downloads: 290767, isInstalled: false),
            Skill(name: "自我改进+主动智能体", description: "自我反思+自我批评+自我学习，主动提出改进建议", category: "AI智能体", slug: "self-improve-pro", version: "1.0", downloads: 278000, isInstalled: false),
            Skill(name: "文案创作", description: "生成优质营销文案和创意内容", category: "AI写作文案", slug: "copywriting", version: "3.0", downloads: 3456, isInstalled: false),
            Skill(name: "图像生成", description: "AI生成精美图像和插画", category: "AI图像生成", slug: "image-gen", version: "2.1", downloads: 5678, isInstalled: false),
            Skill(name: "周报生成", description: "一键生成工作周报和总结", category: "办公效率", slug: "weekly-report", version: "1.8", downloads: 3200, isInstalled: false),
        ]
    }
}

#Preview { SkillView() }
