//
//  Platform.swift
//  ConvenientPass
//
//  平台数据模型
//

import Foundation

/// 平台模型
struct Platform: Identifiable, Codable, Hashable {
    
    /// 唯一标识符
    let id: UUID
    
    /// 平台名称
    var name: String
    
    /// 域名
    var domain: String?
    
    /// 平台图标名称
    var iconName: String
    
    /// 所属分类ID
    var categoryId: UUID
    
    /// 密码规则
    var passwordRule: PasswordRule
    
    // MARK: - 初始化
    
    init(
        id: UUID = UUID(),
        name: String,
        domain: String? = nil,
        iconName: String = "globe",
        categoryId: UUID,
        passwordRule: PasswordRule = .default
    ) {
        self.id = id
        self.name = name
        self.domain = domain
        self.iconName = iconName
        self.categoryId = categoryId
        self.passwordRule = passwordRule
    }
}

// MARK: - 密码规则模型

/// 密码规则
struct PasswordRule: Codable, Hashable {
    
    /// 最小长度
    var minLength: Int
    
    /// 最大长度
    var maxLength: Int
    
    /// 需要大写字母
    var requireUppercase: Bool
    
    /// 需要小写字母
    var requireLowercase: Bool
    
    /// 需要数字
    var requireNumbers: Bool
    
    /// 需要特殊字符
    var requireSpecialChars: Bool
    
    /// 允许的特殊字符集
    var allowedSpecialChars: String?
    
    /// 禁止的字符
    var forbiddenChars: String?
    
    /// 规则描述
    var description: String?
    
    // MARK: - 初始化
    
    init(
        minLength: Int = 8,
        maxLength: Int = 32,
        requireUppercase: Bool = true,
        requireLowercase: Bool = true,
        requireNumbers: Bool = true,
        requireSpecialChars: Bool = false,
        allowedSpecialChars: String? = nil,
        forbiddenChars: String? = nil,
        description: String? = nil
    ) {
        self.minLength = minLength
        self.maxLength = maxLength
        self.requireUppercase = requireUppercase
        self.requireLowercase = requireLowercase
        self.requireNumbers = requireNumbers
        self.requireSpecialChars = requireSpecialChars
        self.allowedSpecialChars = allowedSpecialChars
        self.forbiddenChars = forbiddenChars
        self.description = description
    }
    
    // MARK: - 预设规则
    
    /// 默认规则
    static let `default` = PasswordRule()
    
    /// 简单规则（仅数字字母）
    static let simple = PasswordRule(
        minLength: 6,
        maxLength: 20,
        requireUppercase: false,
        requireLowercase: true,
        requireNumbers: true,
        requireSpecialChars: false,
        description: "6-20位数字和字母"
    )
    
    /// 严格规则（含特殊字符）
    static let strict = PasswordRule(
        minLength: 12,
        maxLength: 64,
        requireUppercase: true,
        requireLowercase: true,
        requireNumbers: true,
        requireSpecialChars: true,
        allowedSpecialChars: "!@#$%^&*()_+-=[]{}|;:,.<>?",
        description: "12位以上，含大小写字母、数字和特殊字符"
    )
}

// MARK: - 预设平台

extension Platform {
    
    /// 预设平台列表（从JSON加载或使用默认值）
    static let presets: [Platform] = [
        // 社交媒体
        Platform(
            name: "微信",
            domain: "weixin.qq.com",
            iconName: "message.fill",
            categoryId: Category.presets[0].id,
            passwordRule: PasswordRule(
                minLength: 8,
                maxLength: 16,
                requireUppercase: true,
                requireLowercase: true,
                requireNumbers: true,
                requireSpecialChars: false,
                description: "8-16位，含大小写字母和数字"
            )
        ),
        Platform(
            name: "QQ",
            domain: "qq.com",
            iconName: "bubble.left.fill",
            categoryId: Category.presets[0].id,
            passwordRule: PasswordRule(
                minLength: 8,
                maxLength: 16,
                requireUppercase: false,
                requireLowercase: true,
                requireNumbers: true,
                requireSpecialChars: false,
                description: "8-16位字母和数字"
            )
        ),
        Platform(
            name: "微博",
            domain: "weibo.com",
            iconName: "at",
            categoryId: Category.presets[0].id,
            passwordRule: PasswordRule(
                minLength: 6,
                maxLength: 16,
                requireUppercase: false,
                requireLowercase: true,
                requireNumbers: true,
                description: "6-16位字母和数字"
            )
        ),
        
        // 银行金融
        Platform(
            name: "支付宝",
            domain: "alipay.com",
            iconName: "yensign.circle.fill",
            categoryId: Category.presets[2].id,
            passwordRule: PasswordRule(
                minLength: 8,
                maxLength: 20,
                requireUppercase: true,
                requireLowercase: true,
                requireNumbers: true,
                requireSpecialChars: false,
                description: "8-20位，含大小写字母和数字"
            )
        ),
        
        // 购物网站
        Platform(
            name: "淘宝",
            domain: "taobao.com",
            iconName: "bag.fill",
            categoryId: Category.presets[3].id,
            passwordRule: PasswordRule(
                minLength: 6,
                maxLength: 20,
                requireUppercase: false,
                requireLowercase: true,
                requireNumbers: true,
                description: "6-20位字母和数字"
            )
        ),
        Platform(
            name: "京东",
            domain: "jd.com",
            iconName: "cart.fill",
            categoryId: Category.presets[3].id,
            passwordRule: PasswordRule(
                minLength: 6,
                maxLength: 20,
                requireUppercase: false,
                requireLowercase: true,
                requireNumbers: true,
                description: "6-20位字母和数字"
            )
        ),
        
        // 开发工具
        Platform(
            name: "GitHub",
            domain: "github.com",
            iconName: "chevron.left.forwardslash.chevron.right",
            categoryId: Category.presets[7].id,
            passwordRule: PasswordRule(
                minLength: 8,
                maxLength: 72,
                requireUppercase: true,
                requireLowercase: true,
                requireNumbers: true,
                requireSpecialChars: false,
                description: "至少8位，含大小写字母和数字"
            )
        ),
        Platform(
            name: "Apple ID",
            domain: "apple.com",
            iconName: "apple.logo",
            categoryId: Category.presets[6].id,
            passwordRule: PasswordRule(
                minLength: 8,
                maxLength: 32,
                requireUppercase: true,
                requireLowercase: true,
                requireNumbers: true,
                requireSpecialChars: false,
                description: "至少8位，含大小写字母和数字"
            )
        ),
    ]
    
    /// 示例平台
    static let example = presets[0]
}

