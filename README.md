# ConvenientPass - 智能密码管理箱
> My first vibe coding iOS app. A local user password manager that is secure, convenient, and has no cloud dependency.

> 一款面向大众的本地加密密码管理器，安全、便捷、无云端依赖

## 📱 应用简介

ConvenientPass 帮助用户解决现代数字生活中的密码管理难题：
- ✅ 本地加密存储，隐私安全有保障
- ✅ 智能分类管理，内置主流平台预设
- ✅ 场景化密码生成，自动匹配平台规则
- ✅ 系统级自动填充，一键登录各平台
- ✅ 安全检测与提醒，守护账户安全

## 🛠 技术栈

- **UI框架**: SwiftUI
- **最低系统**: iOS 15.0+
- **架构模式**: MVVM + Repository Pattern
- **数据加密**: CryptoKit (AES-256-GCM)
- **本地存储**: CoreData + Keychain
- **生物认证**: LocalAuthentication

## 📂 项目结构

```
ConvenientPass/
├── ConvenientPass/
│   ├── App/                           # 应用入口
│   │   ├── ConvenientPassApp.swift    # App入口
│   │   └── AppState.swift             # 全局状态管理
│   │
│   ├── Core/                          # 核心模块
│   │   ├── Security/                  # 安全相关
│   │   │   ├── CryptoManager.swift    # 加密管理器
│   │   │   ├── KeychainManager.swift  # Keychain管理
│   │   │   └── BiometricAuth.swift    # 生物认证
│   │   │
│   │   ├── Storage/                   # 存储相关
│   │   │   ├── CoreDataManager.swift  # CoreData管理
│   │   │   └── PasswordRepository.swift # 密码数据仓库
│   │   │
│   │   └── PasswordGenerator/         # 密码生成器
│   │       ├── PasswordGenerator.swift # 密码生成逻辑
│   │       └── PlatformRules.swift    # 平台规则引擎
│   │
│   ├── Features/                      # 功能模块
│   │   ├── Auth/                      # 认证模块
│   │   │   ├── Views/
│   │   │   │   ├── LockScreenView.swift
│   │   │   │   └── SetupMasterPasswordView.swift
│   │   │   └── ViewModels/
│   │   │       └── AuthViewModel.swift
│   │   │
│   │   ├── PasswordList/              # 密码列表
│   │   │   ├── Views/
│   │   │   │   ├── PasswordListView.swift
│   │   │   │   └── PasswordRowView.swift
│   │   │   └── ViewModels/
│   │   │       └── PasswordListViewModel.swift
│   │   │
│   │   ├── PasswordDetail/            # 密码详情
│   │   │   ├── Views/
│   │   │   │   ├── PasswordDetailView.swift
│   │   │   │   └── AddEditPasswordView.swift
│   │   │   └── ViewModels/
│   │   │       └── PasswordDetailViewModel.swift
│   │   │
│   │   ├── Generator/                 # 密码生成
│   │   │   ├── Views/
│   │   │   │   └── GeneratorView.swift
│   │   │   └── ViewModels/
│   │   │       └── GeneratorViewModel.swift
│   │   │
│   │   ├── SecurityCheck/             # 安全检测
│   │   │   ├── Views/
│   │   │   │   └── SecurityCheckView.swift
│   │   │   └── ViewModels/
│   │   │       └── SecurityCheckViewModel.swift
│   │   │
│   │   ├── Dashboard/                 # 统计看板
│   │   │   ├── Views/
│   │   │   │   └── DashboardView.swift
│   │   │   └── ViewModels/
│   │   │       └── DashboardViewModel.swift
│   │   │
│   │   └── Settings/                  # 设置
│   │       ├── Views/
│   │       │   └── SettingsView.swift
│   │       └── ViewModels/
│   │           └── SettingsViewModel.swift
│   │
│   ├── Models/                        # 数据模型
│   │   ├── PasswordEntry.swift        # 密码条目模型
│   │   ├── Category.swift             # 分类模型
│   │   ├── PlatformRule.swift         # 平台规则模型
│   │   └── SecurityScore.swift        # 安全评分模型
│   │
│   ├── Resources/                     # 资源文件
│   │   ├── Assets.xcassets            # 图片资源
│   │   ├── PlatformRules.json         # 平台密码规则库
│   │   ├── Categories.json            # 预设分类库
│   │   └── Localizable.strings        # 本地化
│   │
│   ├── Extensions/                    # 扩展
│   │   ├── String+Extensions.swift
│   │   ├── Date+Extensions.swift
│   │   └── View+Extensions.swift
│   │
│   └── Components/                    # 通用UI组件
│       ├── SecureTextField.swift      # 安全输入框
│       ├── PasswordStrengthView.swift # 密码强度指示器
│       ├── CategoryIcon.swift         # 分类图标
│       └── SearchBar.swift            # 搜索栏
│
├── ConvenientPassAutoFill/            # AutoFill Extension
│   ├── CredentialProviderViewController.swift
│   └── Info.plist
│
├── ConvenientPassTests/               # 单元测试
└── ConvenientPassUITests/             # UI测试
```

## 📄 页面结构

| 页面/视图名称 | 用途 | 核心功能 | 技术实现 | 导航/用户流程 | 建议文件路径 |
|--------------|------|----------|----------|--------------|-------------|
| 主页面 | 应用的容器视图 | 提供标签式导航 | SwiftUI TabView | 作为应用启动后的根视图 | `Features/Main/MainTabView.swift` |
| 锁屏页 | 应用解锁认证 | 主密码输入、生物认证 | LocalAuthentication, SecureField | 应用启动/进入前台时显示 | `Features/Auth/Views/LockScreenView.swift` |
| 主密码设置页 | 首次使用设置主密码 | 密码输入、确认、强度检测 | SwiftUI Form, SecureField | 首次启动时进入 | `Features/Auth/Views/SetupMasterPasswordView.swift` |
| 密码列表主页 | 展示所有密码记录 | 分类筛选、搜索、快速复制 | SwiftUI List, Searchable | 通过Tab导航访问 | `Features/PasswordList/Views/PasswordListView.swift` |
| 密码详情页 | 查看/编辑密码详情 | 显示完整信息、编辑、删除 | SwiftUI Form, NavigationLink | 从列表页点击条目进入 | `Features/PasswordDetail/Views/PasswordDetailView.swift` |
| 添加/编辑密码页 | 创建或修改密码记录 | 输入账号、密码、选择分类、备注等 | SwiftUI Form, Picker | 从列表页点击"添加"或详情页点击"编辑"进入 | `Features/PasswordDetail/Views/AddEditPasswordView.swift` |
| 分类选择页 | 选择密码分类 | 展示预设分类、自定义分类 | SwiftUI Grid, List | 从添加/编辑页点击分类进入 | `Features/PasswordList/Views/CategorySelectionView.swift` |
| 密码生成器页 | 生成安全密码 | 平台选择、规则配置、一键生成 | SwiftUI Form, Slider, Toggle | 通过Tab导航或添加页面进入 | `Features/Generator/Views/GeneratorView.swift` |
| 安全检测主页 | 展示安全概览 | 安全评分、风险统计、弱密码列表 | SwiftUI Charts, List | 通过Tab导航访问 | `Features/SecurityCheck/Views/SecurityCheckView.swift` |
| 安全详情页 | 查看详细安全分析 | 按风险类型分类、修复建议 | SwiftUI List, NavigationLink | 从安全检测主页点击进入 | `Features/SecurityCheck/Views/SecurityDetailView.swift` |
| 统计看板页 | 展示密码统计信息 | 密码数量、分类分布、更新时长 | SwiftUI Charts, Grid | 通过Tab导航访问 | `Features/Dashboard/Views/DashboardView.swift` |
| 设置页面 | 应用设置和个性化 | 主密码修改、生物认证开关、主题切换 | SwiftUI Form, Toggle | 通过Tab导航访问 | `Features/Settings/Views/SettingsView.swift` |
| 备份恢复页 | 数据备份和恢复 | 导出/导入加密数据、清除数据 | FileManager, ShareLink | 从设置页面进入 | `Features/Settings/Views/BackupRestoreView.swift` |
| 关于页面 | 应用信息展示 | 版本信息、隐私政策、使用帮助 | SwiftUI List | 从设置页面进入 | `Features/Settings/Views/AboutView.swift` |

## 📦 数据模型

应用的核心数据模型包括：

### 1. PasswordEntry (密码条目)

| 字段 | 类型 | 说明 |
|------|------|------|
| id | UUID | 主键 |
| title | String | 标题/账号名称 |
| username | String | 用户名/账号 |
| encryptedPassword | Data | 加密后的密码数据 |
| websiteURL | String? | 网站地址 |
| category | Category | 关联的分类 |
| platform | Platform? | 关联的平台（可选） |
| notes | String? | 备注信息 |
| isFavorite | Bool | 是否收藏 |
| securityScore | Int | 安全评分 (0-100) |
| createdAt | Date | 创建时间 |
| updatedAt | Date | 最后更新时间 |
| lastUsedAt | Date? | 最后使用时间 |

### 2. Category (分类)

| 字段 | 类型 | 说明 |
|------|------|------|
| id | UUID | 主键 |
| name | String | 分类名称 |
| icon | String | SF Symbol 图标名称 |
| color | String | 分类颜色 (Hex) |
| isBuiltIn | Bool | 是否为内置分类 |
| sortOrder | Int | 排序顺序 |

### 3. Platform (平台)

| 字段 | 类型 | 说明 |
|------|------|------|
| id | UUID | 主键 |
| name | String | 平台名称 (如 "微信") |
| domain | String? | 域名 (如 "weixin.qq.com") |
| iconName | String | 平台图标名称 |
| categoryId | UUID | 所属分类ID |
| passwordRule | PasswordRule | 密码规则 |

### 4. PasswordRule (密码规则)

| 字段 | 类型 | 说明 |
|------|------|------|
| minLength | Int | 最小长度 |
| maxLength | Int | 最大长度 |
| requireUppercase | Bool | 需要大写字母 |
| requireLowercase | Bool | 需要小写字母 |
| requireNumbers | Bool | 需要数字 |
| requireSpecialChars | Bool | 需要特殊字符 |
| allowedSpecialChars | String? | 允许的特殊字符集 |
| forbiddenChars | String? | 禁止的字符 |
| description | String? | 规则描述 |

### 5. SecurityReport (安全报告)

| 字段 | 类型 | 说明 |
|------|------|------|
| id | UUID | 主键 |
| overallScore | Int | 总体安全评分 (0-100) |
| weakPasswords | [PasswordEntry] | 弱密码列表 |
| duplicatePasswords | [[PasswordEntry]] | 重复密码分组 |
| oldPasswords | [PasswordEntry] | 长期未更新的密码 |
| generatedAt | Date | 报告生成时间 |

### 6. AppSettings (应用设置)

| 字段 | 类型 | 说明 |
|------|------|------|
| useBiometric | Bool | 启用生物认证 |
| autoLockTimeout | Int | 自动锁定时间 (秒) |
| clipboardClearTimeout | Int | 剪贴板清除时间 (秒) |
| showPasswordInList | Bool | 列表中显示密码 |
| defaultPasswordLength | Int | 默认生成密码长度 |
| theme | AppTheme | 应用主题 (light/dark/system) |
| sortOrder | SortOrder | 默认排序方式 |

### 7. 枚举类型

```swift
// 应用主题
enum AppTheme: String {
    case light    // 浅色模式
    case dark     // 深色模式
    case system   // 跟随系统
}

// 排序方式
enum SortOrder: String {
    case nameAsc      // 名称升序
    case nameDesc     // 名称降序
    case dateAsc      // 日期升序
    case dateDesc     // 日期降序
    case scoreAsc     // 安全评分升序
    case scoreDesc    // 安全评分降序
}

// 密码强度等级
enum PasswordStrength: Int {
    case veryWeak = 0   // 非常弱
    case weak = 1       // 弱
    case medium = 2     // 中等
    case strong = 3     // 强
    case veryStrong = 4 // 非常强
}
```

## 🔧 技术实现细节

此部分将随着开发过程逐步添加各页面的技术方案。

## 📊 开发进度跟踪表

| 模块名称 | 技术栈 | 状态 | 优先级 | 备注 |
|----------|--------|------|--------|------|
| 项目基础架构 | SwiftUI/MVVM | ✅ 已完成 | P0 | 基础目录结构 |
| 安全认证模块 | Keychain/LocalAuth | ✅ 已完成 | P0 | 主密码+生物认证 |
| 加密存储模块 | CryptoKit/CoreData | ✅ 已完成 | P0 | AES-256加密 |
| 分类管理模块 | JSON/CoreData | ✅ 已完成 | P1 | 预设平台分类 |
| 密码列表模块 | SwiftUI | ✅ 已完成 | P1 | 列表展示与搜索 |
| 密码生成模块 | Swift | ✅ 已完成 | P1 | 规则引擎 |
| 密码详情模块 | SwiftUI | ✅ 已完成 | P1 | 新增/编辑/查看 |
| AutoFill扩展 | AuthServices | 🔲 未开始 | P2 | 系统自动填充 |
| 安全检测模块 | Swift | ✅ 已完成 | P2 | 弱密码检测 |
| 统计看板模块 | Charts | 🔲 未开始 | P3 | 数据可视化 |
| 提醒通知模块 | UserNotifications | 🔲 未开始 | P3 | 更新提醒 |
| 设置模块 | SwiftUI | ✅ 已完成 | P3 | 应用设置 |

## 🔐 安全设计

### 加密方案
- **主密钥**: 用户设置的主密码，通过 PBKDF2 派生加密密钥
- **数据加密**: AES-256-GCM 加密所有敏感数据
- **密钥存储**: 加密密钥存储在 iOS Keychain 中
- **生物认证**: 支持 Face ID / Touch ID 快速解锁

### 数据存储
- 所有密码数据加密后存储在本地 CoreData
- 无任何网络请求，数据不会上传到云端
- 支持本地加密备份与恢复

## 📝 版本规划

- **v1.0.0** - 基础功能（加密存储、分类管理、密码生成）
- **v1.1.0** - AutoFill 自动填充
- **v1.2.0** - 安全检测与评分
- **v1.3.0** - 统计看板与提醒通知

## 📄 License

Private - All Rights Reserved
