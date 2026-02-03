//
//  PasswordListViewModel.swift
//  ConvenientPass
//
//  密码列表视图模型
//

import Foundation
import Combine

@MainActor
final class PasswordListViewModel: ObservableObject {
    
    // MARK: - Published 属性
    
    @Published var passwords: [PasswordEntry] = []
    @Published var filteredPasswords: [PasswordEntry] = []
    @Published var categories: [Category] = []
    @Published var selectedCategory: Category?
    @Published var searchKeyword: String = ""
    @Published var isLoading: Bool = false
    
    // MARK: - 计算属性
    
    /// 收藏的密码
    var favoritePasswords: [PasswordEntry] {
        filteredPasswords.filter { $0.isFavorite }
    }
    
    /// 按分类分组的密码
    var groupedPasswords: [Category: [PasswordEntry]] {
        var grouped: [Category: [PasswordEntry]] = [:]
        
        let nonFavoritePasswords = filteredPasswords.filter { !$0.isFavorite }
        
        for password in nonFavoritePasswords {
            // 尝试匹配分类，如果匹配不上则归入"其他"分类
            let category = categories.first(where: { $0.id == password.categoryId }) ?? Category.other
            if grouped[category] == nil {
                grouped[category] = []
            }
            grouped[category]?.append(password)
        }
        
        return grouped
    }
    
    // MARK: - 依赖
    
    private let repository: PasswordRepository
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - 初始化
    
    init() {
        self.repository = PasswordRepository.shared
        
        // 监听数据变化
        repository.$passwords
            .receive(on: DispatchQueue.main)
            .sink { [weak self] passwords in
                self?.passwords = passwords
                self?.applyFilters()
            }
            .store(in: &cancellables)
        
        repository.$categories
            .receive(on: DispatchQueue.main)
            .assign(to: &$categories)
    }
    
    // MARK: - 公开方法
    
    /// 加载数据
    func loadData() {
        isLoading = true
        
        passwords = repository.fetchAll()
        categories = repository.categories
        applyFilters()
        
        isLoading = false
    }
    
    /// 搜索
    func search(keyword: String) {
        searchKeyword = keyword
        applyFilters()
    }
    
    /// 按分类筛选
    func filterByCategory(_ category: Category?) {
        selectedCategory = category
        applyFilters()
    }
    
    /// 删除密码
    func deletePassword(_ password: PasswordEntry) {
        do {
            try repository.delete(password)
        } catch {
            print("删除失败: \(error)")
        }
    }
    
    /// 切换收藏状态
    func toggleFavorite(_ password: PasswordEntry) {
        var mutablePassword = password
        do {
            try repository.toggleFavorite(&mutablePassword)
        } catch {
            print("切换收藏失败: \(error)")
        }
    }
    
    // MARK: - 私有方法
    
    /// 应用筛选条件
    private func applyFilters() {
        var result = passwords
        
        // 按分类筛选
        if let category = selectedCategory {
            result = result.filter { $0.categoryId == category.id }
        }
        
        // 按关键词搜索
        if !searchKeyword.isEmpty {
            let keyword = searchKeyword.lowercased()
            result = result.filter {
                $0.title.lowercased().contains(keyword) ||
                $0.username.lowercased().contains(keyword) ||
                ($0.notes?.lowercased().contains(keyword) ?? false)
            }
        }
        
        // 排序：收藏优先，然后按更新时间
        result.sort { (a, b) -> Bool in
            if a.isFavorite != b.isFavorite {
                return a.isFavorite
            }
            return a.updatedAt > b.updatedAt
        }
        
        filteredPasswords = result
    }
}

