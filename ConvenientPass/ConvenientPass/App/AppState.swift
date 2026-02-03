//
//  AppState.swift
//  ConvenientPass
//
//  全局应用状态管理
//

import SwiftUI
import Combine

/// 应用全局状态管理器
@MainActor
final class AppState: ObservableObject {
    
    // MARK: - 单例
    static let shared = AppState()
    
    // MARK: - 认证状态
    
    /// 应用是否已解锁
    @Published var isUnlocked: Bool = false
    
    /// 是否已设置主密码
    @Published var hasMasterPassword: Bool = false
    
    /// 是否正在进行生物认证
    @Published var isAuthenticating: Bool = false
    
    // MARK: - 应用设置
    
    /// 当前应用设置
    @Published var settings: AppSettings = AppSettings.default
    
    // MARK: - UI状态
    
    /// 当前选中的Tab
    @Published var selectedTab: TabItem = .passwords
    
    /// 是否显示添加密码页面
    @Published var showAddPassword: Bool = false
    
    /// 全局错误信息
    @Published var errorMessage: String?
    
    /// 是否显示错误提示
    @Published var showError: Bool = false
    
    // MARK: - 初始化
    
    private init() {
        // 检查是否已设置主密码
        checkMasterPasswordStatus()
    }
    
    // MARK: - 方法
    
    /// 检查主密码设置状态
    func checkMasterPasswordStatus() {
        hasMasterPassword = KeychainManager.shared.hasMasterPassword()
    }
    
    /// 锁定应用
    func lockApp() {
        isUnlocked = false
    }
    
    /// 解锁应用
    func unlockApp() {
        isUnlocked = true
    }
    
    /// 显示错误信息
    func showError(_ message: String) {
        errorMessage = message
        showError = true
    }
    
    /// 清除错误信息
    func clearError() {
        errorMessage = nil
        showError = false
    }
}

// MARK: - Tab枚举

/// Tab标签项
enum TabItem: String, CaseIterable {
    case passwords = "passwords"
    case generator = "generator"
    case security = "security"
    case settings = "settings"
    
    var title: String {
        switch self {
        case .passwords: return "密码库"
        case .generator: return "生成器"
        case .security: return "安全"
        case .settings: return "设置"
        }
    }
    
    var icon: String {
        switch self {
        case .passwords: return "key.fill"
        case .generator: return "wand.and.stars"
        case .security: return "shield.checkered"
        case .settings: return "gearshape.fill"
        }
    }
}

