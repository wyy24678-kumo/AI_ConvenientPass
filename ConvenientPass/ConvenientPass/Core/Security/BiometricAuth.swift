//
//  BiometricAuth.swift
//  ConvenientPass
//
//  生物认证管理器
//

import Foundation
import LocalAuthentication

/// 生物认证管理器
final class BiometricAuth {
    
    // MARK: - 单例
    
    static let shared = BiometricAuth()
    
    private init() {}
    
    // MARK: - 属性
    
    /// LAContext 实例
    private var context: LAContext {
        LAContext()
    }
    
    // MARK: - 生物认证类型
    
    /// 可用的生物认证类型
    enum BiometricType {
        case none
        case touchID
        case faceID
        case opticID
        
        var displayName: String {
            switch self {
            case .none: return "无"
            case .touchID: return "Touch ID"
            case .faceID: return "Face ID"
            case .opticID: return "Optic ID"
            }
        }
        
        var icon: String {
            switch self {
            case .none: return "xmark.circle"
            case .touchID: return "touchid"
            case .faceID: return "faceid"
            case .opticID: return "opticid"
            }
        }
    }
    
    // MARK: - 错误类型
    
    enum BiometricError: Error, LocalizedError {
        case notAvailable
        case notEnrolled
        case authenticationFailed
        case userCancelled
        case userFallback
        case systemCancel
        case passcodeNotSet
        case lockout
        case unknown(Error)
        
        var errorDescription: String? {
            switch self {
            case .notAvailable:
                return "设备不支持生物认证"
            case .notEnrolled:
                return "未设置生物认证"
            case .authenticationFailed:
                return "认证失败"
            case .userCancelled:
                return "用户取消认证"
            case .userFallback:
                return "用户选择使用密码"
            case .systemCancel:
                return "系统取消认证"
            case .passcodeNotSet:
                return "设备未设置密码"
            case .lockout:
                return "生物认证已锁定，请使用密码"
            case .unknown(let error):
                return error.localizedDescription
            }
        }
    }
    
    // MARK: - 公开方法
    
    /// 获取可用的生物认证类型
    func biometricType() -> BiometricType {
        let context = LAContext()
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return .none
        }
        
        switch context.biometryType {
        case .touchID:
            return .touchID
        case .faceID:
            return .faceID
        case .opticID:
            return .opticID
        case .none:
            return .none
        @unknown default:
            return .none
        }
    }
    
    /// 检查生物认证是否可用
    func isBiometricAvailable() -> Bool {
        let context = LAContext()
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }
    
    /// 执行生物认证
    /// - Parameter reason: 认证原因描述
    /// - Returns: 认证结果
    func authenticate(reason: String = "请验证身份以访问密码库") async -> Result<Bool, BiometricError> {
        let context = LAContext()
        context.localizedCancelTitle = "取消"
        context.localizedFallbackTitle = "使用主密码"
        
        var error: NSError?
        
        // 检查生物认证是否可用
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return .failure(mapError(error))
        }
        
        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )
            return .success(success)
        } catch let authError as LAError {
            return .failure(mapLAError(authError))
        } catch {
            return .failure(.unknown(error))
        }
    }
    
    /// 执行生物认证（带回调）
    /// - Parameters:
    ///   - reason: 认证原因描述
    ///   - completion: 完成回调
    func authenticate(reason: String = "请验证身份以访问密码库", completion: @escaping (Result<Bool, BiometricError>) -> Void) {
        Task {
            let result = await authenticate(reason: reason)
            await MainActor.run {
                completion(result)
            }
        }
    }
    
    // MARK: - 私有方法
    
    /// 映射 NSError 到 BiometricError
    private func mapError(_ error: NSError?) -> BiometricError {
        guard let error = error else {
            return .notAvailable
        }
        
        switch error.code {
        case LAError.biometryNotAvailable.rawValue:
            return .notAvailable
        case LAError.biometryNotEnrolled.rawValue:
            return .notEnrolled
        case LAError.passcodeNotSet.rawValue:
            return .passcodeNotSet
        default:
            return .unknown(error)
        }
    }
    
    /// 映射 LAError 到 BiometricError
    private func mapLAError(_ error: LAError) -> BiometricError {
        switch error.code {
        case .authenticationFailed:
            return .authenticationFailed
        case .userCancel:
            return .userCancelled
        case .userFallback:
            return .userFallback
        case .systemCancel:
            return .systemCancel
        case .passcodeNotSet:
            return .passcodeNotSet
        case .biometryNotAvailable:
            return .notAvailable
        case .biometryNotEnrolled:
            return .notEnrolled
        case .biometryLockout:
            return .lockout
        default:
            return .unknown(error)
        }
    }
}

