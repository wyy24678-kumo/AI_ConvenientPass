//
//  SecurityReport.swift
//  ConvenientPass
//
//  安全报告数据模型
//

import Foundation

/// 安全报告模型
struct SecurityReport: Identifiable, Codable {
    
    /// 唯一标识符
    let id: UUID
    
    /// 总体安全评分 (0-100)
    var overallScore: Int
    
    /// 弱密码ID列表
    var weakPasswordIds: [UUID]
    
    /// 重复密码分组（每组包含相同密码的条目ID）
    var duplicatePasswordGroups: [[UUID]]
    
    /// 长期未更新的密码ID列表（超过90天）
    var oldPasswordIds: [UUID]
    
    /// 报告生成时间
    let generatedAt: Date
    
    // MARK: - 初始化
    
    init(
        id: UUID = UUID(),
        overallScore: Int = 0,
        weakPasswordIds: [UUID] = [],
        duplicatePasswordGroups: [[UUID]] = [],
        oldPasswordIds: [UUID] = [],
        generatedAt: Date = Date()
    ) {
        self.id = id
        self.overallScore = overallScore
        self.weakPasswordIds = weakPasswordIds
        self.duplicatePasswordGroups = duplicatePasswordGroups
        self.oldPasswordIds = oldPasswordIds
        self.generatedAt = generatedAt
    }
    
    // MARK: - 计算属性
    
    /// 总问题数量
    var totalIssues: Int {
        weakPasswordIds.count + duplicatePasswordGroups.count + oldPasswordIds.count
    }
    
    /// 是否有安全问题
    var hasIssues: Bool {
        totalIssues > 0
    }
    
    /// 安全等级
    var securityLevel: SecurityReportLevel {
        switch overallScore {
        case 0..<40: return .critical
        case 40..<60: return .warning
        case 60..<80: return .good
        default: return .excellent
        }
    }
}

// MARK: - 安全报告等级

/// 安全报告等级
enum SecurityReportLevel: Int, CaseIterable, Codable {
    case critical = 0   // 危险
    case warning = 1    // 警告
    case good = 2       // 良好
    case excellent = 3  // 优秀
    
    var title: String {
        switch self {
        case .critical: return "需要立即处理"
        case .warning: return "存在安全隐患"
        case .good: return "安全状况良好"
        case .excellent: return "安全状况优秀"
        }
    }
    
    var icon: String {
        switch self {
        case .critical: return "exclamationmark.shield.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .good: return "checkmark.shield.fill"
        case .excellent: return "shield.checkered"
        }
    }
    
    var colorHex: String {
        switch self {
        case .critical: return "#FF3B30"
        case .warning: return "#FF9500"
        case .good: return "#34C759"
        case .excellent: return "#007AFF"
        }
    }
}

// MARK: - 安全问题类型

/// 安全问题类型
enum SecurityIssueType: String, CaseIterable, Codable {
    case weakPassword = "weak"
    case duplicatePassword = "duplicate"
    case oldPassword = "old"
    
    var title: String {
        switch self {
        case .weakPassword: return "弱密码"
        case .duplicatePassword: return "重复密码"
        case .oldPassword: return "长期未更新"
        }
    }
    
    var description: String {
        switch self {
        case .weakPassword: return "密码强度过低，容易被破解"
        case .duplicatePassword: return "多个账号使用相同密码，存在连锁风险"
        case .oldPassword: return "密码超过90天未更新，建议定期更换"
        }
    }
    
    var icon: String {
        switch self {
        case .weakPassword: return "lock.open.fill"
        case .duplicatePassword: return "doc.on.doc.fill"
        case .oldPassword: return "clock.fill"
        }
    }
    
    var colorHex: String {
        switch self {
        case .weakPassword: return "#FF3B30"
        case .duplicatePassword: return "#FF9500"
        case .oldPassword: return "#FFCC00"
        }
    }
}

// MARK: - 示例数据

extension SecurityReport {
    static let example = SecurityReport(
        overallScore: 72,
        weakPasswordIds: [UUID(), UUID()],
        duplicatePasswordGroups: [[UUID(), UUID()]],
        oldPasswordIds: [UUID()]
    )
}

