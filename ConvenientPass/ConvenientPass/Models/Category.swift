//
//  Category.swift
//  ConvenientPass
//
//  分类数据模型
//

import Foundation
import SwiftUI

/// 密码分类模型
struct Category: Identifiable, Codable {
    
    /// 唯一标识符
    let id: UUID
    
    /// 分类名称
    var name: String
    
    /// SF Symbol 图标名称
    var icon: String
    
    /// 分类颜色 (Hex)
    var colorHex: String
    
    /// 是否为内置分类
    let isBuiltIn: Bool
    
    /// 排序顺序
    var sortOrder: Int
    
    // MARK: - 初始化
    
    init(
        id: UUID = UUID(),
        name: String,
        icon: String,
        colorHex: String,
        isBuiltIn: Bool = false,
        sortOrder: Int = 0
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.colorHex = colorHex
        self.isBuiltIn = isBuiltIn
        self.sortOrder = sortOrder
    }
    
    // MARK: - 计算属性
    
    /// 颜色
    var color: Color {
        Color(hex: colorHex) ?? .blue
    }
}

// MARK: - Hashable & Equatable (只基于ID比较)

extension Category: Hashable, Equatable {
    
    /// 只基于 id 进行哈希计算，确保 Picker 能正确识别选中项
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    /// 只基于 id 进行相等性比较
    static func == (lhs: Category, rhs: Category) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - 预设分类ID（固定值，确保数据一致性）

extension Category {
    
    /// 预设分类的固定UUID
    enum PresetID {
        static let socialMedia = UUID(uuidString: "00000000-0000-0000-0001-000000000001")!
        static let email = UUID(uuidString: "00000000-0000-0000-0001-000000000002")!
        static let banking = UUID(uuidString: "00000000-0000-0000-0001-000000000003")!
        static let shopping = UUID(uuidString: "00000000-0000-0000-0001-000000000004")!
        static let gaming = UUID(uuidString: "00000000-0000-0000-0001-000000000005")!
        static let work = UUID(uuidString: "00000000-0000-0000-0001-000000000006")!
        static let cloud = UUID(uuidString: "00000000-0000-0000-0001-000000000007")!
        static let devTools = UUID(uuidString: "00000000-0000-0000-0001-000000000008")!
        static let lifestyle = UUID(uuidString: "00000000-0000-0000-0001-000000000009")!
        static let other = UUID(uuidString: "00000000-0000-0000-0001-000000000099")!
    }
    
    /// 预设分类列表（使用固定UUID）
    static let presets: [Category] = [
        Category(id: PresetID.socialMedia, name: "社交媒体", icon: "bubble.left.and.bubble.right.fill", colorHex: "#FF2D55", isBuiltIn: true, sortOrder: 0),
        Category(id: PresetID.email, name: "电子邮箱", icon: "envelope.fill", colorHex: "#007AFF", isBuiltIn: true, sortOrder: 1),
        Category(id: PresetID.banking, name: "银行金融", icon: "creditcard.fill", colorHex: "#34C759", isBuiltIn: true, sortOrder: 2),
        Category(id: PresetID.shopping, name: "购物网站", icon: "cart.fill", colorHex: "#FF9500", isBuiltIn: true, sortOrder: 3),
        Category(id: PresetID.gaming, name: "游戏娱乐", icon: "gamecontroller.fill", colorHex: "#AF52DE", isBuiltIn: true, sortOrder: 4),
        Category(id: PresetID.work, name: "工作办公", icon: "briefcase.fill", colorHex: "#5856D6", isBuiltIn: true, sortOrder: 5),
        Category(id: PresetID.cloud, name: "云服务", icon: "cloud.fill", colorHex: "#00C7BE", isBuiltIn: true, sortOrder: 6),
        Category(id: PresetID.devTools, name: "开发工具", icon: "chevron.left.forwardslash.chevron.right", colorHex: "#FF3B30", isBuiltIn: true, sortOrder: 7),
        Category(id: PresetID.lifestyle, name: "生活服务", icon: "house.fill", colorHex: "#FFCC00", isBuiltIn: true, sortOrder: 8),
        Category(id: PresetID.other, name: "其他", icon: "folder.fill", colorHex: "#8E8E93", isBuiltIn: true, sortOrder: 99),
    ]
    
    /// 默认"其他"分类
    static let other = presets.last!
    
    /// 示例分类
    static let example = presets[0]
}

// MARK: - Color扩展

extension Color {
    /// 从Hex字符串创建颜色
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else {
            return nil
        }
        
        let r = Double((rgb & 0xFF0000) >> 16) / 255.0
        let g = Double((rgb & 0x00FF00) >> 8) / 255.0
        let b = Double(rgb & 0x0000FF) / 255.0
        
        self.init(red: r, green: g, blue: b)
    }
}

