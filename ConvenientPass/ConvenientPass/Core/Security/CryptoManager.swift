//
//  CryptoManager.swift
//  ConvenientPass
//
//  加密管理器 - 使用 AES-256-GCM 加密
//

import Foundation
import CryptoKit

/// 加密管理器
final class CryptoManager {
    
    // MARK: - 单例
    
    static let shared = CryptoManager()
    
    private init() {}
    
    // MARK: - 错误类型
    
    enum CryptoError: Error, LocalizedError {
        case encryptionFailed
        case decryptionFailed
        case invalidKey
        case keyNotFound
        
        var errorDescription: String? {
            switch self {
            case .encryptionFailed:
                return "加密失败"
            case .decryptionFailed:
                return "解密失败"
            case .invalidKey:
                return "无效的密钥"
            case .keyNotFound:
                return "未找到加密密钥"
            }
        }
    }
    
    // MARK: - 加密方法
    
    /// 加密字符串
    /// - Parameter plainText: 明文字符串
    /// - Returns: 加密后的数据
    func encrypt(_ plainText: String) throws -> Data {
        guard let data = plainText.data(using: .utf8) else {
            throw CryptoError.encryptionFailed
        }
        return try encrypt(data)
    }
    
    /// 加密数据
    /// - Parameter data: 明文数据
    /// - Returns: 加密后的数据（包含 nonce）
    func encrypt(_ data: Data) throws -> Data {
        guard let keyData = KeychainManager.shared.getEncryptionKey() else {
            throw CryptoError.keyNotFound
        }
        
        let key = SymmetricKey(data: keyData)
        
        do {
            let sealedBox = try AES.GCM.seal(data, using: key)
            
            // 将 nonce、密文和 tag 组合在一起
            guard let combined = sealedBox.combined else {
                throw CryptoError.encryptionFailed
            }
            
            return combined
        } catch {
            throw CryptoError.encryptionFailed
        }
    }
    
    /// 解密为字符串
    /// - Parameter encryptedData: 加密数据
    /// - Returns: 解密后的明文字符串
    func decryptToString(_ encryptedData: Data) throws -> String {
        let decryptedData = try decrypt(encryptedData)
        
        guard let string = String(data: decryptedData, encoding: .utf8) else {
            throw CryptoError.decryptionFailed
        }
        
        return string
    }
    
    /// 解密数据
    /// - Parameter encryptedData: 加密数据（包含 nonce）
    /// - Returns: 解密后的明文数据
    func decrypt(_ encryptedData: Data) throws -> Data {
        guard let keyData = KeychainManager.shared.getEncryptionKey() else {
            throw CryptoError.keyNotFound
        }
        
        let key = SymmetricKey(data: keyData)
        
        do {
            let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
            let decryptedData = try AES.GCM.open(sealedBox, using: key)
            return decryptedData
        } catch {
            throw CryptoError.decryptionFailed
        }
    }
    
    // MARK: - 密码强度评估
    
    /// 评估密码强度
    /// - Parameter password: 密码
    /// - Returns: 强度评分 (0-100)
    func evaluatePasswordStrength(_ password: String) -> Int {
        var score = 0
        
        // 长度评分 (最高30分)
        let length = password.count
        if length >= 8 { score += 10 }
        if length >= 12 { score += 10 }
        if length >= 16 { score += 10 }
        
        // 字符类型评分 (每种类型15分，最高60分)
        let hasLowercase = password.range(of: "[a-z]", options: .regularExpression) != nil
        let hasUppercase = password.range(of: "[A-Z]", options: .regularExpression) != nil
        let hasNumbers = password.range(of: "[0-9]", options: .regularExpression) != nil
        let hasSpecialChars = password.range(of: "[!@#$%^&*()_+\\-=\\[\\]{}|;:,.<>?]", options: .regularExpression) != nil
        
        if hasLowercase { score += 15 }
        if hasUppercase { score += 15 }
        if hasNumbers { score += 15 }
        if hasSpecialChars { score += 15 }
        
        // 惩罚：连续字符或重复字符
        if hasConsecutiveChars(password) { score -= 10 }
        if hasRepeatingChars(password) { score -= 10 }
        
        // 惩罚：常见密码模式
        if isCommonPattern(password) { score -= 20 }
        
        return max(0, min(100, score))
    }
    
    /// 获取密码强度等级
    /// - Parameter password: 密码
    /// - Returns: 强度等级
    func getPasswordStrengthLevel(_ password: String) -> SecurityLevel {
        let score = evaluatePasswordStrength(password)
        switch score {
        case 0..<20: return .veryWeak
        case 20..<40: return .weak
        case 40..<60: return .medium
        case 60..<80: return .strong
        default: return .veryStrong
        }
    }
    
    // MARK: - 私有辅助方法
    
    /// 检查是否包含连续字符
    private func hasConsecutiveChars(_ password: String) -> Bool {
        let chars = Array(password)
        
        // 长度小于3时，不可能有连续3个字符
        guard chars.count >= 3 else { return false }
        
        for i in 0..<(chars.count - 2) {
            let c1 = chars[i].asciiValue ?? 0
            let c2 = chars[i + 1].asciiValue ?? 0
            let c3 = chars[i + 2].asciiValue ?? 0
            
            // 检查连续递增或递减
            if (c2 == c1 + 1 && c3 == c2 + 1) || (c2 == c1 - 1 && c3 == c2 - 1) {
                return true
            }
        }
        return false
    }
    
    /// 检查是否包含重复字符
    private func hasRepeatingChars(_ password: String) -> Bool {
        let chars = Array(password)
        
        // 长度小于3时，不可能有连续3个重复字符
        guard chars.count >= 3 else { return false }
        
        for i in 0..<(chars.count - 2) {
            if chars[i] == chars[i + 1] && chars[i + 1] == chars[i + 2] {
                return true
            }
        }
        return false
    }
    
    /// 检查是否为常见密码模式
    private func isCommonPattern(_ password: String) -> Bool {
        let commonPatterns = [
            "password", "123456", "qwerty", "abc123", "letmein",
            "welcome", "admin", "login", "master", "dragon"
        ]
        
        let lowercased = password.lowercased()
        return commonPatterns.contains { lowercased.contains($0) }
    }
    
    // MARK: - 哈希计算
    
    /// 计算 SHA256 哈希
    /// - Parameter data: 输入数据
    /// - Returns: 哈希值的十六进制字符串
    func sha256Hash(_ data: Data) -> String {
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    /// 计算字符串的 SHA256 哈希
    /// - Parameter string: 输入字符串
    /// - Returns: 哈希值的十六进制字符串
    func sha256Hash(_ string: String) -> String? {
        guard let data = string.data(using: .utf8) else {
            return nil
        }
        return sha256Hash(data)
    }
}

