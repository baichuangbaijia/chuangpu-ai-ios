import SwiftUI

/// 技能页面
struct SkillView: View {
    @State private var skills: [Skill] = []
    @State private var categories: [String] = ["all"]
    @State private var activeTab = "all"
    @State private var mainView = "market"
    @State private var searchText = ""
    @State private var isLoading = false
    @State private var currentPage = 1
    @State private var totalCount = 0
    @State private var installedCount = 0
    @State private var favoriteSkills: [String] = []
    @State private var showDetail = false
    @State private var selectedSkill: Skill?
    
    var body: some View {
        NavigationStack {
            ZStack {
                Constants.bgPrimary.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Tab切换
                    tabHeader
                    
                    // 搜索栏
                    searchBar
                    
                    // 分类标签
                    if mainView == "market" {
                        categoryTabs
                    }
                    
                    // 统计信息
                    statsBar
                    
                    // 内容列表
                    if isLoading && skills.isEmpty {
                        Spacer()
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: Constants.primaryPurple))
                        Spacer()
                    } else if skills.isEmpty {
                        emptyState
                    } else {
                        skillsList
                    }
                }
            }
            .navigationTitle("")
            .navigationBarHidden(true)
            .sheet(isPresented: $showDetail) {
                if let skill = selectedSkill {
                    SkillDetailSheet(skill: skill)
                }
            }
            .onAppear {
                loadCategories()
                loadSkills()
                loadInstalledCount()
                loadFavorites()
            }
        }
    }
    
    private var tabHeader: some View {
        HStack(spacing: 0) {
            Button(action: {
                mainView = "market"
                loadSkills()
            }) {
                Text("技能市场")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(mainView == "market" ? .white : Constants.textSecondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(mainView == "market" ? Constants.primaryPurple : Color.clear)
                    .cornerRadius(8)
            }
            
            Button(action: {
                mainView = "favorites"
                loadFavorites()
            }) {
                Text("我的收藏")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(mainView == "favorites" ? .white : Constants.textSecondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(mainView == "favorites" ? Constants.primaryPurple : Color.clear)
                    .cornerRadius(8)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(Constants.textSecondary)
            
            TextField("搜索技能...", text: $searchText)
                .foregroundColor(.white)
                .onChange(of: searchText) { _ in
                    currentPage = 1
                    loadSkills()
                }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Constants.bgTertiary)
        .cornerRadius(10)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    private var categoryTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(categories, id: \.self) { category in
                    categoryTab(category)
                }
            }
            .padding(.horizontal, 16)
        }
        .frame(height: 44)
    }
    
    private func categoryTab(_ category: String) -> some View {
        Button(action: {
            activeTab = category
            currentPage = 1
            loadSkills()
        }) {
            Text(category == "all" ? "全部" : category)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(activeTab == category ? .white : Constants.textSecondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(activeTab == category ? Constants.primaryPurple : Constants.bgTertiary)
                .cornerRadius(16)
        }
    }
    
    private var statsBar: some View {
        Text("技能市场共 \(totalCount) 个技能 | 已安装 \(installedCount) 个")
            .font(.system(size: 12))
            .foregroundColor(Constants.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: "wand.and.stars")
                .font(.system(size: 50))
                .foregroundColor(Constants.textSecondary)
            
            Text(mainView == "favorites" ? "暂无收藏技能" : "没有找到技能")
                .font(.system(size: 15))
                .foregroundColor(Constants.textSecondary)
            
            Spacer()
        }
    }
    
    private var skillsList: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(skills) { skill in
                    SkillRow(skill: skill)
                        .onTapGesture {
                            selectedSkill = skill
                            showDetail = true
                        }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 20)
        }
    }
    
    private func loadCategories() {
        Task {
            do {
                let cats = try await APIService.shared.getCategories()
                await MainActor.run {
                    categories = ["all"] + cats
                }
            } catch {
                print("加载分类失败: \(error)")
            }
        }
    }
    
    private func loadSkills() {
        isLoading = true
        Task {
            do {
                var params: [String: Any] = ["page": currentPage, "limit": 20]
                if activeTab != "all" {
                    params["category"] = activeTab
                }
                if !searchText.isEmpty {
                    params["q"] = searchText
                }
                
                let result = try await APIService.shared.searchSkills(params: params)
                await MainActor.run {
                    if currentPage > 1 {
                        skills += result.data?.list ?? []
                    } else {
                        skills = result.data?.list ?? []
                    }
                    totalCount = result.data?.total ?? 0
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                }
            }
        }
    }
    
    private func loadInstalledCount() {
        Task {
            do {
                let result = try await APIService.shared.getServerInstalled()
                await MainActor.run {
                    installedCount = result.data?.total ?? 0
                }
            } catch {
                print("加载已安装数量失败: \(error)")
            }
        }
    }
    
    private func loadFavorites() {
        Task {
            do {
                let result = try await APIService.shared.getMySkills()
                await MainActor.run {
                    favoriteSkills = result.data?.learned ?? []
                    if mainView == "favorites" {
                        skills = favoriteSkills.map { Skill(name: $0, description: "", category: nil, slug: nil, version: nil, downloads: 0, isInstalled: false) }
                    }
                }
            } catch {
                print("加载收藏失败: \(error)")
            }
        }
    }
}

/// 技能详情页
struct SkillDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    let skill: Skill
    @State private var installCommand = ""
    @State private var isFavorite = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Constants.bgPrimary.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // 图标和名称
                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(SkillCategoryColors.getColor(for: skill.category).opacity(0.2))
                                    .frame(width: 80, height: 80)
                                
                                Text(String(skill.name.prefix(1)))
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(SkillCategoryColors.getColor(for: skill.category))
                            }
                            
                            Text(skill.name)
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                            
                            HStack(spacing: 12) {
                                if let category = skill.category {
                                    Text(category)
                                        .font(.system(size: 12))
                                        .foregroundColor(Constants.textSecondary)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 4)
                                        .background(Constants.bgTertiary)
                                        .cornerRadius(12)
                                }
                                
                                if let version = skill.version {
                                    Text("v\(version)")
                                        .font(.system(size: 12))
                                        .foregroundColor(Constants.textSecondary)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 4)
                                        .background(Constants.bgTertiary)
                                        .cornerRadius(12)
                                }
                            }
                        }
                        .padding(.top, 20)
                        
                        // 描述
                        Text(skill.description)
                            .font(.system(size: 15))
                            .foregroundColor(Constants.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                        
                        // 下载量
                        HStack {
                            Image(systemName: "arrow.down.circle")
                            Text("\(skill.downloads)")
                        }
                        .font(.system(size: 13))
                        .foregroundColor(Constants.textSecondary)
                        
                        Divider()
                            .background(Constants.bgTertiary)
                            .padding(.horizontal, 20)
                        
                        // 安装命令
                        VStack(alignment: .leading, spacing: 12) {
                            Text("安装命令")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                            
                            Text(installCommand.isEmpty ? generateInstallCommand() : installCommand)
                                .font(.system(size: 13, design: .monospaced))
                                .foregroundColor(Constants.accentOrange)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Constants.bgTertiary)
                                .cornerRadius(8)
                            
                            Button(action: copyCommand) {
                                HStack {
                                    Image(systemName: "doc.on.doc")
                                    Text("复制命令")
                                }
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                                .background(Constants.primaryPurple)
                                .cornerRadius(8)
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        Spacer(minLength: 40)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("关闭") {
                        dismiss()
                    }
                    .foregroundColor(Constants.primaryPurple)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { isFavorite.toggle() }) {
                        Text(isFavorite ? "❤️" : "🤍")
                            .font(.system(size: 20))
                    }
                }
            }
        }
    }
    
    private func generateInstallCommand() -> String {
        let slug = skill.slug ?? skill.name
        return "请先检查是否已安装SkillHub技能商店，若未安装，请根据 https://xiaolongxia-1301609358.cos.ap-guangzhou.myqcloud.com/install/skillhub.md 安装SkillHub技能商店，然后安装\(slug)技能。若已安装，则直接安装\(slug)技能。"
    }
    
    private func copyCommand() {
        UIPasteboard.general.string = installCommand.isEmpty ? generateInstallCommand() : installCommand
    }
}

#Preview {
    SkillView()
}
