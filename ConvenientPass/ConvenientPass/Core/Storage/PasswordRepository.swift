//
//  PasswordRepository.swift
//  ConvenientPass
//
//  密码数据仓库 - 统一管理密码数据的访问
//

import Foundation
import Combine

/// 密码仓库协议
protocol PasswordRepositoryProtocol {
    func fetchAll() -> [PasswordEntry]
    func fetch(byId id: UUID) -> PasswordEntry?
    func search(keyword: String) -> [PasswordEntry]
    func save(_ entry: PasswordEntry) throws
    func delete(_ entry: PasswordEntry) throws
    func fetchByCategory(_ categoryId: UUID) -> [PasswordEntry]
    func fetchFavorites() -> [PasswordEntry]
}

/// 密码仓库实现
final class PasswordRepository: PasswordRepositoryProtocol, ObservableObject {
    
    // MARK: - 单例
    
    static let shared = PasswordRepository()
    
    // MARK: - Published 属性
    
    @Published private(set) var passwords: [PasswordEntry] = []
    @Published private(set) var categories: [Category] = []
    
    // MARK: - 依赖
    
    private let storageManager: CoreDataManager
    private let cryptoManager: CryptoManager
    
    // MARK: - 初始化
    
    init() {
        self.storageManager = CoreDataManager.shared
        self.cryptoManager = CryptoManager.shared
        
        // 初始化预设分类（同步固定UUID）
        storageManager.initializePresetCategories()
        
        // 迁移旧密码的分类ID
        storageManager.migratePasswordCategoryIds()
        
        // 加载数据
        loadCategories()
        loadPasswords()
    }
    
    // MARK: - 加载数据
    
    /// 加载所有分类
    func loadCategories() {
        let dataList = storageManager.fetchAllCategories()
        categories = dataList.map { $0.toModel() }
    }
    
    /// 加载所有密码
    func loadPasswords() {
        let dataList = storageManager.fetchAllPasswords()
        passwords = dataList.map { $0.toModel() }
        print("🔄 密码数据已重新加载，共 \(passwords.count) 条")
        for pwd in passwords {
            print("   - \(pwd.title): 分类ID=\(pwd.categoryId)")
        }
    }
    
    // MARK: - PasswordRepositoryProtocol
    
    /// 获取所有密码
    func fetchAll() -> [PasswordEntry] {
        loadPasswords()
        return passwords
    }
    
    /// 根据 ID 获取密码
    func fetch(byId id: UUID) -> PasswordEntry? {
        return passwords.first { $0.id == id }
    }
    
    /// 搜索密码
    func search(keyword: String) -> [PasswordEntry] {
        guard !keyword.isEmpty else { return passwords }
        
        let lowercasedKeyword = keyword.lowercased()
        return passwords.filter {
            $0.title.lowercased().contains(lowercasedKeyword) ||
            $0.username.lowercased().contains(lowercasedKeyword) ||
            ($0.notes?.lowercased().contains(lowercasedKeyword) ?? false)
        }
    }
    
    /// 保存密码（新增或更新）
    func save(_ entry: PasswordEntry) throws {
        let data = PasswordEntryData.from(entry)
        storageManager.savePassword(data)
        loadPasswords()
    }
    
    /// 删除密码
    func delete(_ entry: PasswordEntry) throws {
        storageManager.deletePassword(id: entry.id)
        loadPasswords()
    }
    
    /// 按分类获取密码
    func fetchByCategory(_ categoryId: UUID) -> [PasswordEntry] {
        return passwords.filter { $0.categoryId == categoryId }
    }
    
    /// 获取收藏的密码
    func fetchFavorites() -> [PasswordEntry] {
        return passwords.filter { $0.isFavorite }
    }
    
    // MARK: - 扩展方法
    
    /// 创建新密码条目
    /// - Parameters:
    ///   - title: 标题
    ///   - username: 用户名
    ///   - password: 明文密码（会被加密）
    ///   - categoryId: 分类ID
    ///   - websiteURL: 网站地址
    ///   - notes: 备注
    /// - Returns: 创建的密码条目
    func createPassword(
        title: String,
        username: String,
        password: String,
        categoryId: UUID,
        platformId: UUID? = nil,
        websiteURL: String? = nil,
        notes: String? = nil
    ) throws -> PasswordEntry {
        // 加密密码
        let encryptedPassword = try cryptoManager.encrypt(password)
        
        // 计算安全评分
        let securityScore = cryptoManager.evaluatePasswordStrength(password)
        
        let entry = PasswordEntry(
            title: title,
            username: username,
            encryptedPassword: encryptedPassword,
            websiteURL: websiteURL,
            categoryId: categoryId,
            platformId: platformId,
            notes: notes,
            securityScore: securityScore
        )
        
        try save(entry)
        return entry
    }
    
    /// 解密密码
    /// - Parameter entry: 密码条目
    /// - Returns: 明文密码
    func decryptPassword(_ entry: PasswordEntry) throws -> String {
        return try cryptoManager.decryptToString(entry.encryptedPassword)
    }
    
    /// 更新密码（完整更新所有字段）
    /// - Parameters:
    ///   - entry: 密码条目（所有需要更新的字段应在调用前设置好）
    ///   - newPassword: 新的明文密码
    func updatePassword(_ entry: inout PasswordEntry, newPassword: String) throws {
        // 更新密码相关字段
        entry.encryptedPassword = try cryptoManager.encrypt(newPassword)
        entry.securityScore = cryptoManager.evaluatePasswordStrength(newPassword)
        entry.updatedAt = Date()
        
        // 直接保存到存储层，确保所有字段都被保存
        let data = PasswordEntryData.from(entry)
        storageManager.savePassword(data)
        
        // 重新加载数据以触发 UI 更新
        loadPasswords()
    }
    
    /// 切换收藏状态
    func toggleFavorite(_ entry: inout PasswordEntry) throws {
        entry.isFavorite.toggle()
        try save(entry)
    }
    
    /// 记录使用时间
    func recordUsage(_ entry: inout PasswordEntry) throws {
        entry.lastUsedAt = Date()
        try save(entry)
    }
    
    /// 获取分类
    func getCategory(byId id: UUID) -> Category? {
        return categories.first { $0.id == id }
    }
    
    /// 获取密码统计
    func getStatistics() -> PasswordStatistics {
        let total = passwords.count
        let favorites = passwords.filter { $0.isFavorite }.count
        let weak = passwords.filter { $0.securityLevel == .veryWeak || $0.securityLevel == .weak }.count
        let old = passwords.filter { $0.isOldPassword }.count
        
        // 计算平均安全评分
        let averageScore = passwords.isEmpty ? 0 : passwords.map { $0.securityScore }.reduce(0, +) / total
        
        return PasswordStatistics(
            totalCount: total,
            favoriteCount: favorites,
            weakPasswordCount: weak,
            oldPasswordCount: old,
            averageSecurityScore: averageScore
        )
    }
}

// MARK: - 密码统计模型

/// 密码统计
struct PasswordStatistics {
    let totalCount: Int
    let favoriteCount: Int
    let weakPasswordCount: Int
    let oldPasswordCount: Int
    let averageSecurityScore: Int
}
