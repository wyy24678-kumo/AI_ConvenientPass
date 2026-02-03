//
//  KeychainManager.swift
//  ConvenientPass
//
//  Keychain 安全存储管理器
//

import Foundation
import Security

/// Keychain 管理器
final class KeychainManager {
    
    // MARK: - 单例
    
    static let shared = KeychainManager()
    
    private init() {}
    
    // MARK: - 常量
    
    private enum Keys {
        static let service = "com.convenientpass.keychain"
        static let masterPasswordHash = "masterPasswordHash"
        static let encryptionKey = "encryptionKey"
        static let salt = "salt"
    }
    
    // MARK: - 主密码相关
    
    /// 检查是否已设置主密码
    func hasMasterPassword() -> Bool {
        return read(key: Keys.masterPasswordHash) != nil
    }
    
    /// 设置主密码
    /// - Parameter password: 主密码明文
    /// - Returns: 是否设置成功
    @discardableResult
    func setMasterPassword(_ password: String) -> Bool {
        // 生成随机盐值
        let salt = generateSalt()
        
        // 使用 PBKDF2 派生密码哈希
        guard let passwordHash = deriveKey(from: password, salt: salt) else {
            return false
        }
        
        // 生成加密密钥
        guard let encryptionKey = generateEncryptionKey() else {
            return false
        }
        
        // 存储盐值、密码哈希和加密密钥
        let saltSaved = save(data: salt, key: Keys.salt)
        let hashSaved = save(data: passwordHash, key: Keys.masterPasswordHash)
        let keySaved = save(data: encryptionKey, key: Keys.encryptionKey)
        
        return saltSaved && hashSaved && keySaved
    }
    
    /// 验证主密码
    /// - Parameter password: 主密码明文
    /// - Returns: 是否验证通过
    func verifyMasterPassword(_ password: String) -> Bool {
        guard let storedSalt = read(key: Keys.salt),
              let storedHash = read(key: Keys.masterPasswordHash),
              let derivedHash = deriveKey(from: password, salt: storedSalt) else {
            return false
        }
        
        return storedHash == derivedHash
    }
    
    /// 修改主密码
    /// - Parameters:
    ///   - oldPassword: 旧密码
    ///   - newPassword: 新密码
    /// - Returns: 是否修改成功
    func changeMasterPassword(from oldPassword: String, to newPassword: String) -> Bool {
        // 先验证旧密码
        guard verifyMasterPassword(oldPassword) else {
            return false
        }
        
        // 生成新的盐值和哈希
        let newSalt = generateSalt()
        guard let newHash = deriveKey(from: newPassword, salt: newSalt) else {
            return false
        }
        
        // 更新存储
        let saltUpdated = update(data: newSalt, key: Keys.salt)
        let hashUpdated = update(data: newHash, key: Keys.masterPasswordHash)
        
        return saltUpdated && hashUpdated
    }
    
    /// 获取加密密钥
    func getEncryptionKey() -> Data? {
        return read(key: Keys.encryptionKey)
    }
    
    /// 清除所有密钥数据（危险操作）
    func clearAll() {
        delete(key: Keys.salt)
        delete(key: Keys.masterPasswordHash)
        delete(key: Keys.encryptionKey)
    }
    
    // MARK: - PBKDF2 密钥派生
    
    /// 使用 PBKDF2 从密码派生密钥
    private func deriveKey(from password: String, salt: Data, iterations: UInt32 = 100_000, keyLength: Int = 32) -> Data? {
        guard let passwordData = password.data(using: .utf8) else {
            return nil
        }
        
        var derivedKey = Data(count: keyLength)
        
        let result = derivedKey.withUnsafeMutableBytes { derivedKeyBytes in
            salt.withUnsafeBytes { saltBytes in
                passwordData.withUnsafeBytes { passwordBytes in
                    CCKeyDerivationPBKDF(
                        CCPBKDFAlgorithm(kCCPBKDF2),
                        passwordBytes.baseAddress?.assumingMemoryBound(to: Int8.self),
                        passwordData.count,
                        saltBytes.baseAddress?.assumingMemoryBound(to: UInt8.self),
                        salt.count,
                        CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256),
                        iterations,
                        derivedKeyBytes.baseAddress?.assumingMemoryBound(to: UInt8.self),
                        keyLength
                    )
                }
            }
        }
        
        return result == kCCSuccess ? derivedKey : nil
    }
    
    /// 生成随机盐值
    private func generateSalt(length: Int = 32) -> Data {
        var salt = Data(count: length)
        _ = salt.withUnsafeMutableBytes { bytes in
            SecRandomCopyBytes(kSecRandomDefault, length, bytes.baseAddress!)
        }
        return salt
    }
    
    /// 生成加密密钥
    private func generateEncryptionKey(length: Int = 32) -> Data? {
        var key = Data(count: length)
        let result = key.withUnsafeMutableBytes { bytes in
            SecRandomCopyBytes(kSecRandomDefault, length, bytes.baseAddress!)
        }
        return result == errSecSuccess ? key : nil
    }
    
    // MARK: - Keychain CRUD 操作
    
    /// 保存数据到 Keychain
    private func save(data: Data, key: String) -> Bool {
        // 先尝试删除已存在的
        delete(key: key)
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Keys.service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    /// 从 Keychain 读取数据
    private func read(key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Keys.service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess else {
            return nil
        }
        
        return result as? Data
    }
    
    /// 更新 Keychain 中的数据
    private func update(data: Data, key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Keys.service,
            kSecAttrAccount as String: key
        ]
        
        let attributes: [String: Any] = [
            kSecValueData as String: data
        ]
        
        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        
        // 如果不存在则创建
        if status == errSecItemNotFound {
            return save(data: data, key: key)
        }
        
        return status == errSecSuccess
    }
    
    /// 从 Keychain 删除数据
    @discardableResult
    private func delete(key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Keys.service,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
}

// MARK: - CommonCrypto 桥接

import CommonCrypto

