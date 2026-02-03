//
//  CoreDataManager.swift
//  ConvenientPass
//
//  本地数据存储管理器（使用加密JSON文件存储）
//

import Foundation

/// 本地存储管理器
final class CoreDataManager {
    
    // MARK: - 单例
    
    static let shared = CoreDataManager()
    
    // MARK: - 存储文件路径
    
    private var passwordsFileURL: URL {
        getDocumentsDirectory().appendingPathComponent("passwords.encrypted")
    }
    
    private var categoriesFileURL: URL {
        getDocumentsDirectory().appendingPathComponent("categories.json")
    }
    
    // MARK: - 缓存
    
    private var passwordsCache: [PasswordEntryData] = []
    private var categoriesCache: [CategoryData] = []
    
    // MARK: - 初始化
    
    private init() {
        loadCategoriesFromFile()
        loadPasswordsFromFile()
    }
    
    // MARK: - 文档目录
    
    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    // MARK: - 密码数据操作
    
    /// 获取所有密码
    func fetchAllPasswords() -> [PasswordEntryData] {
        return passwordsCache.sorted { $0.updatedAt > $1.updatedAt }
    }
    
    /// 搜索密码
    func searchPasswords(keyword: String) -> [PasswordEntryData] {
        let lowercased = keyword.lowercased()
        return passwordsCache.filter {
            $0.title.lowercased().contains(lowercased) ||
            $0.username.lowercased().contains(lowercased) ||
            ($0.notes?.lowercased().contains(lowercased) ?? false)
        }
    }
    
    /// 按分类获取密码
    func fetchPasswords(byCategoryId categoryId: UUID) -> [PasswordEntryData] {
        return passwordsCache.filter { $0.categoryId == categoryId }
    }
    
    /// 获取收藏的密码
    func fetchFavoritePasswords() -> [PasswordEntryData] {
        return passwordsCache.filter { $0.isFavorite }
    }
    
    /// 根据ID获取密码
    func fetchPassword(byId id: UUID) -> PasswordEntryData? {
        return passwordsCache.first { $0.id == id }
    }
    
    /// 保存密码
    func savePassword(_ data: PasswordEntryData) {
        // 创建更新后的数据副本，确保使用最新的字段值
        var updatedData = data
        updatedData.updatedAt = Date()
        
        if let index = passwordsCache.firstIndex(where: { $0.id == updatedData.id }) {
            // 更新现有记录（保留原始创建时间）
            let existingCreatedAt = passwordsCache[index].createdAt
            updatedData.createdAt = existingCreatedAt
            passwordsCache[index] = updatedData
            print("✅ 更新密码记录: \(updatedData.title), 分类ID: \(updatedData.categoryId)")
        } else {
            // 添加新记录
            passwordsCache.append(updatedData)
            print("✅ 添加新密码记录: \(updatedData.title), 分类ID: \(updatedData.categoryId)")
        }
        savePasswordsToFile()
    }
    
    /// 删除密码
    func deletePassword(id: UUID) {
        passwordsCache.removeAll { $0.id == id }
        savePasswordsToFile()
    }
    
    /// 保存上下文（兼容接口）
    func saveContext() {
        savePasswordsToFile()
        saveCategoriesToFile()
    }
    
    // MARK: - 分类数据操作
    
    /// 获取所有分类
    func fetchAllCategories() -> [CategoryData] {
        return categoriesCache.sorted { $0.sortOrder < $1.sortOrder }
    }
    
    /// 分类计数
    func countCategories() -> Int {
        return categoriesCache.count
    }
    
    /// 初始化预设分类（始终同步固定UUID）
    func initializePresetCategories() {
        // 始终确保内置分类使用固定UUID
        var needsSave = false
        
        for preset in Category.presets {
            if let existingIndex = categoriesCache.firstIndex(where: { $0.name == preset.name && $0.isBuiltIn }) {
                // 如果ID不一致，更新为固定UUID
                if categoriesCache[existingIndex].id != preset.id {
                    categoriesCache[existingIndex] = CategoryData(
                        id: preset.id,
                        name: preset.name,
                        icon: preset.icon,
                        colorHex: preset.colorHex,
                        isBuiltIn: preset.isBuiltIn,
                        sortOrder: preset.sortOrder
                    )
                    needsSave = true
                }
            } else {
                // 添加新的预设分类
                categoriesCache.append(CategoryData(
                    id: preset.id,
                    name: preset.name,
                    icon: preset.icon,
                    colorHex: preset.colorHex,
                    isBuiltIn: preset.isBuiltIn,
                    sortOrder: preset.sortOrder
                ))
                needsSave = true
            }
        }
        
        if needsSave {
            saveCategoriesToFile()
        }
    }
    
    /// 迁移旧密码的分类ID到新的固定UUID
    func migratePasswordCategoryIds() {
        var needsSave = false
        
        // 建立旧名称到新UUID的映射
        let categoryNameToId: [String: UUID] = Dictionary(
            uniqueKeysWithValues: Category.presets.map { ($0.name, $0.id) }
        )
        
        // 检查每个密码的categoryId是否匹配任何预设分类
        for index in passwordsCache.indices {
            let password = passwordsCache[index]
            
            // 检查当前categoryId是否是有效的预设分类ID
            let isValidCategoryId = Category.presets.contains { $0.id == password.categoryId }
            
            if !isValidCategoryId {
                // 分配到"其他"分类
                passwordsCache[index].categoryId = Category.PresetID.other
                needsSave = true
            }
        }
        
        if needsSave {
            savePasswordsToFile()
        }
    }
    
    /// 保存分类
    func saveCategory(_ data: CategoryData) {
        if let index = categoriesCache.firstIndex(where: { $0.id == data.id }) {
            categoriesCache[index] = data
        } else {
            categoriesCache.append(data)
        }
        saveCategoriesToFile()
    }
    
    // MARK: - 文件存储
    
    /// 加载密码数据
    private func loadPasswordsFromFile() {
        guard FileManager.default.fileExists(atPath: passwordsFileURL.path) else {
            passwordsCache = []
            return
        }
        
        do {
            let encryptedData = try Data(contentsOf: passwordsFileURL)
            
            // 如果有加密密钥，解密数据
            if let key = KeychainManager.shared.getEncryptionKey() {
                let decryptedData = try CryptoManager.shared.decrypt(encryptedData)
                passwordsCache = try JSONDecoder().decode([PasswordEntryData].self, from: decryptedData)
            } else {
                // 未设置密码时，直接读取（首次启动）
                passwordsCache = []
            }
        } catch {
            print("加载密码数据失败: \(error)")
            passwordsCache = []
        }
    }
    
    /// 保存密码数据
    private func savePasswordsToFile() {
        do {
            let jsonData = try JSONEncoder().encode(passwordsCache)
            
            // 如果有加密密钥，加密数据
            if KeychainManager.shared.getEncryptionKey() != nil {
                let encryptedData = try CryptoManager.shared.encrypt(jsonData)
                try encryptedData.write(to: passwordsFileURL)
                print("✅ 密码数据已加密保存到文件，共 \(passwordsCache.count) 条记录")
            } else {
                // 未设置密码时，临时明文存储（仅用于首次启动前）
                try jsonData.write(to: passwordsFileURL)
                print("✅ 密码数据已明文保存到文件，共 \(passwordsCache.count) 条记录")
            }
        } catch {
            print("❌ 保存密码数据失败: \(error)")
        }
    }
    
    /// 加载分类数据
    private func loadCategoriesFromFile() {
        guard FileManager.default.fileExists(atPath: categoriesFileURL.path) else {
            categoriesCache = []
            return
        }
        
        do {
            let data = try Data(contentsOf: categoriesFileURL)
            categoriesCache = try JSONDecoder().decode([CategoryData].self, from: data)
        } catch {
            print("加载分类数据失败: \(error)")
            categoriesCache = []
        }
    }
    
    /// 保存分类数据
    private func saveCategoriesToFile() {
        do {
            let data = try JSONEncoder().encode(categoriesCache)
            try data.write(to: categoriesFileURL)
        } catch {
            print("保存分类数据失败: \(error)")
        }
    }
    
    // MARK: - 数据清除
    
    /// 清除所有数据
    func clearAllData() {
        passwordsCache = []
        categoriesCache = []
        
        try? FileManager.default.removeItem(at: passwordsFileURL)
        try? FileManager.default.removeItem(at: categoriesFileURL)
    }
    
    /// 密码数量
    func passwordCount() -> Int {
        return passwordsCache.count
    }
}

// MARK: - 存储数据模型

/// 密码条目存储数据
struct PasswordEntryData: Codable, Identifiable {
    let id: UUID
    var title: String
    var username: String
    var encryptedPassword: Data
    var websiteURL: String?
    var categoryId: UUID
    var platformId: UUID?
    var notes: String?
    var isFavorite: Bool
    var securityScore: Int
    var createdAt: Date
    var updatedAt: Date
    var lastUsedAt: Date?
    
    /// 转换为模型
    func toModel() -> PasswordEntry {
        return PasswordEntry(
            id: id,
            title: title,
            username: username,
            encryptedPassword: encryptedPassword,
            websiteURL: websiteURL,
            categoryId: categoryId,
            platformId: platformId,
            notes: notes,
            isFavorite: isFavorite,
            securityScore: securityScore,
            createdAt: createdAt,
            updatedAt: updatedAt,
            lastUsedAt: lastUsedAt
        )
    }
    
    /// 从模型创建
    static func from(_ model: PasswordEntry) -> PasswordEntryData {
        return PasswordEntryData(
            id: model.id,
            title: model.title,
            username: model.username,
            encryptedPassword: model.encryptedPassword,
            websiteURL: model.websiteURL,
            categoryId: model.categoryId,
            platformId: model.platformId,
            notes: model.notes,
            isFavorite: model.isFavorite,
            securityScore: model.securityScore,
            createdAt: model.createdAt,
            updatedAt: model.updatedAt,
            lastUsedAt: model.lastUsedAt
        )
    }
}

/// 分类存储数据
struct CategoryData: Codable, Identifiable {
    let id: UUID
    var name: String
    var icon: String
    var colorHex: String
    var isBuiltIn: Bool
    var sortOrder: Int
    
    /// 转换为模型
    func toModel() -> Category {
        return Category(
            id: id,
            name: name,
            icon: icon,
            colorHex: colorHex,
            isBuiltIn: isBuiltIn,
            sortOrder: sortOrder
        )
    }
    
    /// 从模型创建
    static func from(_ model: Category) -> CategoryData {
        return CategoryData(
            id: model.id,
            name: model.name,
            icon: model.icon,
            colorHex: model.colorHex,
            isBuiltIn: model.isBuiltIn,
            sortOrder: model.sortOrder
        )
    }
}
