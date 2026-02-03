//
//  AppSettings.swift
//  ConvenientPass
//
//  应用设置数据模型
//

import Foundation

/// 应用设置模型
struct AppSettings: Codable {
    
    /// 启用生物认证
    var useBiometric: Bool
    
    /// 自动锁定时间 (秒)，0表示立即锁定
    var autoLockTimeout: Int
    
    /// 剪贴板清除时间 (秒)，0表示不清除
    var clipboardClearTimeout: Int
    
    /// 列表中显示密码
    var showPasswordInList: Bool
    
    /// 默认生成密码长度
    var defaultPasswordLength: Int
    
    /// 应用主题
    var theme: AppTheme
    
    /// 默认排序方式
    var sortOrder: SortOrder
    
    /// 上次备份时间
    var lastBackupDate: Date?
    
    // MARK: - 初始化
    
    init(
        useBiometric: Bool = true,
        autoLockTimeout: Int = 60,
        clipboardClearTimeout: Int = 30,
        showPasswordInList: Bool = false,
        defaultPasswordLength: Int = 16,
        theme: AppTheme = .system,
        sortOrder: SortOrder = .dateDesc,
        lastBackupDate: Date? = nil
    ) {
        self.useBiometric = useBiometric
        self.autoLockTimeout = autoLockTimeout
        self.clipboardClearTimeout = clipboardClearTimeout
        self.showPasswordInList = showPasswordInList
        self.defaultPasswordLength = defaultPasswordLength
        self.theme = theme
        self.sortOrder = sortOrder
        self.lastBackupDate = lastBackupDate
    }
    
    // MARK: - 默认设置
    
    static let `default` = AppSettings()
}

// MARK: - 应用主题

/// 应用主题
enum AppTheme: String, CaseIterable, Codable {
    case light = "light"
    case dark = "dark"
    case system = "system"
    
    var title: String {
        switch self {
        case .light: return "浅色模式"
        case .dark: return "深色模式"
        case .system: return "跟随系统"
        }
    }
    
    var icon: String {
        switch self {
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        case .system: return "circle.lefthalf.filled"
        }
    }
}

// MARK: - 排序方式

/// 排序方式
enum SortOrder: String, CaseIterable, Codable {
    case nameAsc = "name_asc"
    case nameDesc = "name_desc"
    case dateAsc = "date_asc"
    case dateDesc = "date_desc"
    case scoreAsc = "score_asc"
    case scoreDesc = "score_desc"
    
    var title: String {
        switch self {
        case .nameAsc: return "名称 (A-Z)"
        case .nameDesc: return "名称 (Z-A)"
        case .dateAsc: return "日期 (旧→新)"
        case .dateDesc: return "日期 (新→旧)"
        case .scoreAsc: return "安全评分 (低→高)"
        case .scoreDesc: return "安全评分 (高→低)"
        }
    }
    
    var icon: String {
        switch self {
        case .nameAsc, .nameDesc: return "textformat.abc"
        case .dateAsc, .dateDesc: return "calendar"
        case .scoreAsc, .scoreDesc: return "shield.checkered"
        }
    }
}

// MARK: - 自动锁定选项

/// 自动锁定时间选项
enum AutoLockOption: Int, CaseIterable {
    case immediately = 0
    case after30Seconds = 30
    case after1Minute = 60
    case after5Minutes = 300
    case after15Minutes = 900
    case never = -1
    
    var title: String {
        switch self {
        case .immediately: return "立即"
        case .after30Seconds: return "30秒后"
        case .after1Minute: return "1分钟后"
        case .after5Minutes: return "5分钟后"
        case .after15Minutes: return "15分钟后"
        case .never: return "从不"
        }
    }
}

// MARK: - 剪贴板清除选项

/// 剪贴板清除时间选项
enum ClipboardClearOption: Int, CaseIterable {
    case never = 0
    case after10Seconds = 10
    case after30Seconds = 30
    case after1Minute = 60
    case after3Minutes = 180
    
    var title: String {
        switch self {
        case .never: return "从不"
        case .after10Seconds: return "10秒后"
        case .after30Seconds: return "30秒后"
        case .after1Minute: return "1分钟后"
        case .after3Minutes: return "3分钟后"
        }
    }
}

