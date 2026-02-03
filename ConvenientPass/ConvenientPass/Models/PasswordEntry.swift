//
//  PasswordEntry.swift
//  ConvenientPass
//
//  密码条目数据模型
//

import Foundation

/// 密码条目模型
struct PasswordEntry: Identifiable, Codable, Hashable {
    
    /// 唯一标识符
    let id: UUID
    
    /// 标题/账号名称
    var title: String
    
    /// 用户名/账号
    var username: String
    
    /// 加密后的密码数据
    var encryptedPassword: Data
    
    /// 网站地址
    var websiteURL: String?
    
    /// 分类ID
    var categoryId: UUID
    
    /// 平台ID（可选）
    var platformId: UUID?
    
    /// 备注信息
    var notes: String?
    
    /// 是否收藏
    var isFavorite: Bool
    
    /// 安全评分 (0-100)
    var securityScore: Int
    
    /// 创建时间
    let createdAt: Date
    
    /// 最后更新时间
    var updatedAt: Date
    
    /// 最后使用时间
    var lastUsedAt: Date?
    
    // MARK: - 初始化
    
    init(
        id: UUID = UUID(),
        title: String,
        username: String,
        encryptedPassword: Data,
        websiteURL: String? = nil,
        categoryId: UUID,
        platformId: UUID? = nil,
        notes: String? = nil,
        isFavorite: Bool = false,
        securityScore: Int = 0,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        lastUsedAt: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.username = username
        self.encryptedPassword = encryptedPassword
        self.websiteURL = websiteURL
        self.categoryId = categoryId
        self.platformId = platformId
        self.notes = notes
        self.isFavorite = isFavorite
        self.securityScore = securityScore
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.lastUsedAt = lastUsedAt
    }
    
    // MARK: - 计算属性
    
    /// 密码更新距今天数
    var daysSinceUpdate: Int {
        Calendar.current.dateComponents([.day], from: updatedAt, to: Date()).day ?? 0
    }
    
    /// 是否为旧密码（超过90天未更新）
    var isOldPassword: Bool {
        daysSinceUpdate > 90
    }
    
    /// 安全等级
    var securityLevel: SecurityLevel {
        switch securityScore {
        case 0..<20: return .veryWeak
        case 20..<40: return .weak
        case 40..<60: return .medium
        case 60..<80: return .strong
        default: return .veryStrong
        }
    }
}

// MARK: - 安全等级枚举

/// 安全等级
enum SecurityLevel: Int, CaseIterable, Codable {
    case veryWeak = 0
    case weak = 1
    case medium = 2
    case strong = 3
    case veryStrong = 4
    
    var title: String {
        switch self {
        case .veryWeak: return "非常弱"
        case .weak: return "弱"
        case .medium: return "中等"
        case .strong: return "强"
        case .veryStrong: return "非常强"
        }
    }
    
    var color: String {
        switch self {
        case .veryWeak: return "#FF3B30"  // 红色
        case .weak: return "#FF9500"       // 橙色
        case .medium: return "#FFCC00"     // 黄色
        case .strong: return "#34C759"     // 绿色
        case .veryStrong: return "#007AFF" // 蓝色
        }
    }
}

// MARK: - 示例数据

extension PasswordEntry {
    static let example = PasswordEntry(
        title: "示例账号",
        username: "user@example.com",
        encryptedPassword: Data(),
        websiteURL: "https://example.com",
        categoryId: UUID(),
        isFavorite: true,
        securityScore: 75
    )
}

