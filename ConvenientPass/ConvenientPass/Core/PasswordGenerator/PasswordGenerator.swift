//
//  PasswordGenerator.swift
//  ConvenientPass
//
//  密码生成器
//

import Foundation

/// 密码生成器
final class PasswordGenerator {
    
    // MARK: - 单例
    
    static let shared = PasswordGenerator()
    
    private init() {}
    
    // MARK: - 字符集
    
    private let lowercaseLetters = "abcdefghijklmnopqrstuvwxyz"
    private let uppercaseLetters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    private let numbers = "0123456789"
    private let defaultSpecialChars = "!@#$%^&*()_+-=[]{}|;:,.<>?"
    
    // MARK: - 生成配置
    
    /// 密码生成配置
    struct Configuration {
        var length: Int = 16
        var includeUppercase: Bool = true
        var includeLowercase: Bool = true
        var includeNumbers: Bool = true
        var includeSpecialChars: Bool = true
        var specialChars: String? = nil
        var excludeChars: String? = nil
        var excludeAmbiguous: Bool = false  // 排除易混淆字符 (0, O, l, 1, I)
        
        /// 默认配置
        static let `default` = Configuration()
        
        /// 简单配置（仅字母数字）
        static let simple = Configuration(
            includeSpecialChars: false
        )
        
        /// 强密码配置
        static let strong = Configuration(
            length: 20,
            includeSpecialChars: true
        )
        
        /// PIN码配置
        static let pin = Configuration(
            length: 6,
            includeUppercase: false,
            includeLowercase: false,
            includeNumbers: true,
            includeSpecialChars: false
        )
        
        /// 从密码规则创建配置
        static func from(rule: PasswordRule) -> Configuration {
            return Configuration(
                length: rule.minLength,
                includeUppercase: rule.requireUppercase,
                includeLowercase: rule.requireLowercase,
                includeNumbers: rule.requireNumbers,
                includeSpecialChars: rule.requireSpecialChars,
                specialChars: rule.allowedSpecialChars,
                excludeChars: rule.forbiddenChars
            )
        }
    }
    
    // MARK: - 生成方法
    
    /// 生成密码
    /// - Parameter config: 生成配置
    /// - Returns: 生成的密码
    func generate(config: Configuration = .default) -> String {
        var charPool = ""
        var requiredChars: [Character] = []
        
        // 构建字符池
        if config.includeLowercase {
            let chars = config.excludeAmbiguous 
                ? lowercaseLetters.filter { !["l"].contains($0) }
                : lowercaseLetters
            charPool += chars
            if let char = chars.randomElement() {
                requiredChars.append(char)
            }
        }
        
        if config.includeUppercase {
            let chars = config.excludeAmbiguous 
                ? uppercaseLetters.filter { !["O", "I"].contains($0) }
                : uppercaseLetters
            charPool += chars
            if let char = chars.randomElement() {
                requiredChars.append(char)
            }
        }
        
        if config.includeNumbers {
            let chars = config.excludeAmbiguous 
                ? numbers.filter { !["0", "1"].contains($0) }
                : numbers
            charPool += chars
            if let char = chars.randomElement() {
                requiredChars.append(char)
            }
        }
        
        if config.includeSpecialChars {
            let chars = config.specialChars ?? defaultSpecialChars
            charPool += chars
            if let char = chars.randomElement() {
                requiredChars.append(char)
            }
        }
        
        // 排除指定字符
        if let excludeChars = config.excludeChars {
            charPool = charPool.filter { !excludeChars.contains($0) }
        }
        
        // 确保字符池不为空
        guard !charPool.isEmpty else {
            return ""
        }
        
        // 生成密码
        let charArray = Array(charPool)
        var password: [Character] = []
        
        // 先添加必需的字符类型
        password.append(contentsOf: requiredChars)
        
        // 填充剩余长度
        let remainingLength = max(0, config.length - password.count)
        for _ in 0..<remainingLength {
            if let randomChar = charArray.randomElement() {
                password.append(randomChar)
            }
        }
        
        // 随机打乱顺序
        password.shuffle()
        
        return String(password)
    }
    
    /// 根据平台规则生成密码
    /// - Parameter platform: 平台
    /// - Returns: 生成的密码
    func generate(for platform: Platform) -> String {
        let config = Configuration.from(rule: platform.passwordRule)
        return generate(config: config)
    }
    
    /// 生成多个密码选项
    /// - Parameters:
    ///   - count: 生成数量
    ///   - config: 生成配置
    /// - Returns: 密码数组
    func generateMultiple(count: Int, config: Configuration = .default) -> [String] {
        return (0..<count).map { _ in generate(config: config) }
    }
    
    /// 生成易记忆的密码（词组+数字+符号）
    /// - Parameter wordCount: 词数
    /// - Returns: 生成的密码
    func generateMemorable(wordCount: Int = 3) -> String {
        let words = [
            "apple", "banana", "cherry", "dragon", "eagle", "forest",
            "garden", "harbor", "island", "jungle", "knight", "lemon",
            "mountain", "nature", "ocean", "palace", "queen", "river",
            "sunset", "tiger", "valley", "winter", "yellow", "zebra"
        ]
        
        var selectedWords = (0..<wordCount).compactMap { _ in words.randomElement() }
        
        // 首字母大写
        selectedWords = selectedWords.map { $0.capitalized }
        
        // 添加随机数字
        let number = String(Int.random(in: 10...99))
        
        // 添加随机符号
        let symbols = ["!", "@", "#", "$", "%", "&", "*"]
        let symbol = symbols.randomElement() ?? "!"
        
        return selectedWords.joined() + number + symbol
    }
    
    // MARK: - 验证方法
    
    /// 验证密码是否符合规则
    /// - Parameters:
    ///   - password: 密码
    ///   - rule: 密码规则
    /// - Returns: 验证结果
    func validate(password: String, against rule: PasswordRule) -> PasswordValidationResult {
        var errors: [String] = []
        
        // 检查长度
        if password.count < rule.minLength {
            errors.append("密码长度不能少于 \(rule.minLength) 位")
        }
        if password.count > rule.maxLength {
            errors.append("密码长度不能超过 \(rule.maxLength) 位")
        }
        
        // 检查大写字母
        if rule.requireUppercase {
            if password.range(of: "[A-Z]", options: .regularExpression) == nil {
                errors.append("需要包含大写字母")
            }
        }
        
        // 检查小写字母
        if rule.requireLowercase {
            if password.range(of: "[a-z]", options: .regularExpression) == nil {
                errors.append("需要包含小写字母")
            }
        }
        
        // 检查数字
        if rule.requireNumbers {
            if password.range(of: "[0-9]", options: .regularExpression) == nil {
                errors.append("需要包含数字")
            }
        }
        
        // 检查特殊字符
        if rule.requireSpecialChars {
            let specialPattern = "[!@#$%^&*()_+\\-=\\[\\]{}|;:,.<>?]"
            if password.range(of: specialPattern, options: .regularExpression) == nil {
                errors.append("需要包含特殊字符")
            }
        }
        
        // 检查禁止字符
        if let forbidden = rule.forbiddenChars {
            for char in password {
                if forbidden.contains(char) {
                    errors.append("不能包含字符: \(char)")
                    break
                }
            }
        }
        
        return PasswordValidationResult(
            isValid: errors.isEmpty,
            errors: errors
        )
    }
}

// MARK: - 验证结果

/// 密码验证结果
struct PasswordValidationResult {
    let isValid: Bool
    let errors: [String]
    
    var errorMessage: String {
        errors.joined(separator: "\n")
    }
}

