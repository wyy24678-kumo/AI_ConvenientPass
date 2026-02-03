//
//  GeneratorView.swift
//  ConvenientPass
//
//  密码生成器视图
//

import SwiftUI
import UIKit

struct GeneratorView: View {
    
    // MARK: - 状态
    
    @State private var generatedPassword: String = ""
    @State private var passwordLength: Double = 16
    @State private var includeUppercase: Bool = true
    @State private var includeLowercase: Bool = true
    @State private var includeNumbers: Bool = true
    @State private var includeSpecialChars: Bool = true
    @State private var excludeAmbiguous: Bool = false
    @State private var selectedPlatform: Platform?
    @State private var showPlatformPicker: Bool = false
    @State private var isCopied: Bool = false
    @State private var passwordHistory: [String] = []
    
    // MARK: - 计算属性
    
    private var passwordStrength: SecurityLevel {
        CryptoManager.shared.getPasswordStrengthLevel(generatedPassword)
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // 生成的密码展示
                    passwordDisplayCard
                    
                    // 平台选择
                    platformSelector
                    
                    // 配置选项
                    configurationCard
                    
                    // 历史记录
                    if !passwordHistory.isEmpty {
                        historyCard
                    }
                }
                .padding()
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("密码生成器")
        }
        .onAppear {
            generatePassword()
        }
    }
    
    // MARK: - 密码展示卡片
    
    private var passwordDisplayCard: some View {
        VStack(spacing: 16) {
            // 密码文本
            Text(generatedPassword)
                .font(.system(size: 22, weight: .medium, design: .monospaced))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .padding()
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(UIColor.systemBackground))
                )
            
            // 密码强度指示器
            VStack(spacing: 8) {
                HStack {
                    Text("密码强度")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(passwordStrength.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color(hex: passwordStrength.color) ?? .gray)
                }
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.secondary.opacity(0.2))
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(hex: passwordStrength.color) ?? .gray)
                            .frame(width: geometry.size.width * CGFloat(passwordStrength.rawValue + 1) / 5)
                            .animation(.easeInOut, value: passwordStrength)
                    }
                }
                .frame(height: 8)
            }
            
            // 操作按钮
            HStack(spacing: 16) {
                // 刷新按钮
                Button {
                    withAnimation {
                        generatePassword()
                    }
                } label: {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("重新生成")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            colors: [
                                Color(hex: "#e94560") ?? .red,
                                Color(hex: "#ff6b6b") ?? .pink
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                }
                
                // 复制按钮
                Button {
                    copyPassword()
                } label: {
                    HStack {
                        Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                        Text(isCopied ? "已复制" : "复制")
                    }
                    .font(.headline)
                    .foregroundColor(isCopied ? .white : .primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(isCopied ? Color.green : Color(UIColor.systemBackground))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.secondary.opacity(0.3), lineWidth: isCopied ? 0 : 1)
                    )
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
        )
    }
    
    // MARK: - 平台选择器
    
    private var platformSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("平台预设")
                .font(.headline)
            
            Button {
                showPlatformPicker = true
            } label: {
                HStack {
                    if let platform = selectedPlatform {
                        Image(systemName: platform.iconName)
                            .foregroundColor(.blue)
                        Text(platform.name)
                        Spacer()
                        Button {
                            selectedPlatform = nil
                            generatePassword()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    } else {
                        Image(systemName: "apps.iphone")
                            .foregroundColor(.secondary)
                        Text("选择平台以自动匹配规则")
                            .foregroundColor(.secondary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(UIColor.secondarySystemGroupedBackground))
                )
            }
            .foregroundColor(.primary)
            .sheet(isPresented: $showPlatformPicker) {
                PlatformPickerSheet(selectedPlatform: $selectedPlatform) {
                    if let platform = selectedPlatform {
                        applyPlatformRule(platform)
                    }
                }
            }
        }
    }
    
    // MARK: - 配置卡片
    
    private var configurationCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("自定义设置")
                .font(.headline)
            
            VStack(spacing: 16) {
                // 长度滑块
                VStack(spacing: 8) {
                    HStack {
                        Text("密码长度")
                        Spacer()
                        Text("\(Int(passwordLength)) 位")
                            .fontWeight(.semibold)
                            .foregroundColor(Color(hex: "#e94560") ?? .red)
                    }
                    
                    Slider(value: $passwordLength, in: 6...64, step: 1)
                        .tint(Color(hex: "#e94560") ?? .red)
                        .onChange(of: passwordLength) { _, _ in
                            generatePassword()
                        }
                }
                
                Divider()
                
                // 字符选项
                VStack(spacing: 12) {
                    ToggleRow(
                        icon: "textformat.abc",
                        title: "大写字母",
                        subtitle: "A-Z",
                        isOn: $includeUppercase
                    ) { generatePassword() }
                    
                    ToggleRow(
                        icon: "textformat.abc",
                        title: "小写字母",
                        subtitle: "a-z",
                        isOn: $includeLowercase
                    ) { generatePassword() }
                    
                    ToggleRow(
                        icon: "number",
                        title: "数字",
                        subtitle: "0-9",
                        isOn: $includeNumbers
                    ) { generatePassword() }
                    
                    ToggleRow(
                        icon: "character.textbox",
                        title: "特殊字符",
                        subtitle: "!@#$%^&*",
                        isOn: $includeSpecialChars
                    ) { generatePassword() }
                    
                    ToggleRow(
                        icon: "eye.slash",
                        title: "排除易混淆字符",
                        subtitle: "0, O, l, 1, I",
                        isOn: $excludeAmbiguous
                    ) { generatePassword() }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(UIColor.secondarySystemGroupedBackground))
            )
        }
    }
    
    // MARK: - 历史记录卡片
    
    private var historyCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("最近生成")
                    .font(.headline)
                
                Spacer()
                
                Button("清除") {
                    passwordHistory.removeAll()
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
            }
            
            VStack(spacing: 8) {
                ForEach(passwordHistory.prefix(5), id: \.self) { pwd in
                    HStack {
                        Text(pwd)
                            .font(.system(.subheadline, design: .monospaced))
                            .lineLimit(1)
                        
                        Spacer()
                        
                        Button {
                            UIPasteboard.general.string = pwd
                        } label: {
                            Image(systemName: "doc.on.doc")
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(UIColor.systemBackground))
                    )
                }
            }
        }
    }
    
    // MARK: - 方法
    
    private func generatePassword() {
        let config = PasswordGenerator.Configuration(
            length: Int(passwordLength),
            includeUppercase: includeUppercase,
            includeLowercase: includeLowercase,
            includeNumbers: includeNumbers,
            includeSpecialChars: includeSpecialChars,
            excludeAmbiguous: excludeAmbiguous
        )
        
        let newPassword = PasswordGenerator.shared.generate(config: config)
        
        // 添加到历史记录
        if !generatedPassword.isEmpty && generatedPassword != newPassword {
            passwordHistory.insert(generatedPassword, at: 0)
            if passwordHistory.count > 10 {
                passwordHistory.removeLast()
            }
        }
        
        generatedPassword = newPassword
    }
    
    private func applyPlatformRule(_ platform: Platform) {
        let rule = platform.passwordRule
        
        passwordLength = Double(rule.minLength)
        includeUppercase = rule.requireUppercase
        includeLowercase = rule.requireLowercase
        includeNumbers = rule.requireNumbers
        includeSpecialChars = rule.requireSpecialChars
        
        generatePassword()
    }
    
    private func copyPassword() {
        UIPasteboard.general.string = generatedPassword
        
        withAnimation {
            isCopied = true
        }
        
        // 30秒后清除剪贴板
        DispatchQueue.main.asyncAfter(deadline: .now() + 30) {
            if UIPasteboard.general.string == generatedPassword {
                UIPasteboard.general.string = ""
            }
        }
        
        // 重置复制状态
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                isCopied = false
            }
        }
    }
}

// MARK: - 开关行组件

struct ToggleRow: View {
    let icon: String
    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    let onChange: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.secondary)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(Color(hex: "#e94560") ?? .red)
                .onChange(of: isOn) { _, _ in
                    onChange()
                }
        }
    }
}

// MARK: - 平台选择器弹窗

struct PlatformPickerSheet: View {
    @Binding var selectedPlatform: Platform?
    let onSelect: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(Platform.presets) { platform in
                    Button {
                        selectedPlatform = platform
                        onSelect()
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: platform.iconName)
                                .foregroundColor(.blue)
                                .frame(width: 30)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(platform.name)
                                    .foregroundColor(.primary)
                                
                                if let desc = platform.passwordRule.description {
                                    Text(desc)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            if selectedPlatform?.id == platform.id {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
            .navigationTitle("选择平台")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    GeneratorView()
}

