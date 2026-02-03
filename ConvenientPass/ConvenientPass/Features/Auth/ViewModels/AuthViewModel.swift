//
//  AuthViewModel.swift
//  ConvenientPass
//
//  认证视图模型
//

import Foundation
import SwiftUI
import Combine

/// 认证视图模型
@MainActor
final class AuthViewModel: ObservableObject {
    
    // MARK: - Published 属性
    
    /// 主密码输入
    @Published var masterPassword: String = ""
    
    /// 确认密码输入
    @Published var confirmPassword: String = ""
    
    /// 是否正在加载
    @Published var isLoading: Bool = false
    
    /// 错误信息
    @Published var errorMessage: String?
    
    /// 是否显示错误
    @Published var showError: Bool = false
    
    /// 密码强度
    @Published var passwordStrength: SecurityLevel = .veryWeak
    
    /// 是否已通过认证
    @Published var isAuthenticated: Bool = false
    
    /// 是否首次设置
    @Published var isFirstSetup: Bool = false
    
    /// 生物认证类型
    @Published var biometricType: BiometricAuth.BiometricType = .none
    
    /// 是否可以使用生物认证
    @Published var canUseBiometric: Bool = false
    
    /// 密码输入尝试次数
    @Published var attemptCount: Int = 0
    
    /// 是否锁定
    @Published var isLocked: Bool = false
    
    /// 锁定剩余时间
    @Published var lockTimeRemaining: Int = 0
    
    // MARK: - 常量
    
    private let maxAttempts = 5
    private let lockDuration = 60  // 锁定60秒
    
    // MARK: - 依赖
    
    private let keychainManager: KeychainManager
    private let biometricAuth: BiometricAuth
    private let cryptoManager: CryptoManager
    private var lockTimer: Timer?
    
    // MARK: - 初始化
    
    init() {
        self.keychainManager = KeychainManager.shared
        self.biometricAuth = BiometricAuth.shared
        self.cryptoManager = CryptoManager.shared
        
        checkSetupStatus()
        checkBiometricAvailability()
    }
    
    // MARK: - 公开方法
    
    /// 检查设置状态
    func checkSetupStatus() {
        isFirstSetup = !keychainManager.hasMasterPassword()
    }
    
    /// 检查生物认证可用性
    func checkBiometricAvailability() {
        biometricType = biometricAuth.biometricType()
        canUseBiometric = biometricAuth.isBiometricAvailable()
    }
    
    /// 设置主密码
    func setupMasterPassword() async -> Bool {
        // 验证输入
        guard validatePasswordInput() else {
            return false
        }
        
        isLoading = true
        defer { isLoading = false }
        
        // 设置主密码
        let success = keychainManager.setMasterPassword(masterPassword)
        
        if success {
            isAuthenticated = true
            isFirstSetup = false
            AppState.shared.hasMasterPassword = true
            AppState.shared.unlockApp()
            clearInputs()
            return true
        } else {
            showError("设置主密码失败，请重试")
            return false
        }
    }
    
    /// 验证主密码
    func verifyMasterPassword() async -> Bool {
        guard !masterPassword.isEmpty else {
            showError("请输入主密码")
            return false
        }
        
        // 检查是否锁定
        guard !isLocked else {
            showError("账户已锁定，请等待 \(lockTimeRemaining) 秒后重试")
            return false
        }
        
        isLoading = true
        defer { isLoading = false }
        
        let isValid = keychainManager.verifyMasterPassword(masterPassword)
        
        if isValid {
            isAuthenticated = true
            attemptCount = 0
            AppState.shared.unlockApp()
            clearInputs()
            return true
        } else {
            attemptCount += 1
            
            if attemptCount >= maxAttempts {
                startLockTimer()
                showError("密码错误次数过多，账户已锁定 \(lockDuration) 秒")
            } else {
                let remaining = maxAttempts - attemptCount
                showError("密码错误，还剩 \(remaining) 次尝试机会")
            }
            return false
        }
    }
    
    /// 使用生物认证
    func authenticateWithBiometric() async -> Bool {
        guard canUseBiometric else {
            showError("生物认证不可用")
            return false
        }
        
        isLoading = true
        defer { isLoading = false }
        
        let result = await biometricAuth.authenticate(reason: "请验证身份以访问密码库")
        
        switch result {
        case .success(let authenticated):
            if authenticated {
                isAuthenticated = true
                AppState.shared.unlockApp()
                return true
            } else {
                showError("认证失败")
                return false
            }
        case .failure(let error):
            switch error {
            case .userCancelled, .userFallback:
                // 用户取消或选择使用密码，不显示错误
                break
            default:
                showError(error.localizedDescription)
            }
            return false
        }
    }
    
    /// 修改主密码
    func changeMasterPassword(oldPassword: String, newPassword: String, confirmNew: String) async -> Bool {
        // 验证新密码
        guard newPassword == confirmNew else {
            showError("两次输入的新密码不一致")
            return false
        }
        
        guard newPassword.count >= 8 else {
            showError("新密码长度不能少于8位")
            return false
        }
        
        isLoading = true
        defer { isLoading = false }
        
        let success = keychainManager.changeMasterPassword(from: oldPassword, to: newPassword)
        
        if success {
            return true
        } else {
            showError("原密码错误或修改失败")
            return false
        }
    }
    
    /// 登出（锁定应用）
    func logout() {
        isAuthenticated = false
        AppState.shared.lockApp()
        clearInputs()
    }
    
    /// 更新密码强度
    func updatePasswordStrength() {
        passwordStrength = cryptoManager.getPasswordStrengthLevel(masterPassword)
    }
    
    // MARK: - 私有方法
    
    /// 验证密码输入
    private func validatePasswordInput() -> Bool {
        // 检查密码长度
        guard masterPassword.count >= 8 else {
            showError("密码长度不能少于8位")
            return false
        }
        
        // 检查两次密码是否一致
        guard masterPassword == confirmPassword else {
            showError("两次输入的密码不一致")
            return false
        }
        
        // 检查密码强度
        let strength = cryptoManager.getPasswordStrengthLevel(masterPassword)
        guard strength.rawValue >= SecurityLevel.medium.rawValue else {
            showError("密码强度过低，请使用更复杂的密码")
            return false
        }
        
        return true
    }
    
    /// 显示错误
    private func showError(_ message: String) {
        errorMessage = message
        showError = true
    }
    
    /// 清除输入
    private func clearInputs() {
        masterPassword = ""
        confirmPassword = ""
        errorMessage = nil
    }
    
    /// 开始锁定计时
    private func startLockTimer() {
        isLocked = true
        lockTimeRemaining = lockDuration
        
        lockTimer?.invalidate()
        lockTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                
                self.lockTimeRemaining -= 1
                
                if self.lockTimeRemaining <= 0 {
                    self.isLocked = false
                    self.attemptCount = 0
                    self.lockTimer?.invalidate()
                    self.lockTimer = nil
                }
            }
        }
    }
}

