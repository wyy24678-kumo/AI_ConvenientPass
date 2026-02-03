//
//  SettingsView.swift
//  ConvenientPass
//
//  设置视图
//

import SwiftUI

struct SettingsView: View {
    
    // MARK: - 环境
    
    @EnvironmentObject var appState: AppState
    
    // MARK: - 状态
    
    @State private var useBiometric: Bool = true
    @State private var autoLockTimeout: AutoLockOption = .after1Minute
    @State private var clipboardClearTimeout: ClipboardClearOption = .after30Seconds
    @State private var selectedTheme: AppTheme = .system
    @State private var showChangeMasterPassword: Bool = false
    @State private var showBackupRestore: Bool = false
    @State private var showAbout: Bool = false
    @State private var showDeleteAlert: Bool = false
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            List {
                // 安全设置
                securitySection
                
                // 自动化设置
                automationSection
                
                // 外观设置
                appearanceSection
                
                // 数据管理
                dataSection
                
                // 关于
                aboutSection
                
                // 危险操作
                dangerSection
            }
            .navigationTitle("设置")
            .sheet(isPresented: $showChangeMasterPassword) {
                ChangeMasterPasswordView()
            }
            .sheet(isPresented: $showBackupRestore) {
                BackupRestoreView()
            }
            .sheet(isPresented: $showAbout) {
                AboutView()
            }
            .alert("确认清除所有数据", isPresented: $showDeleteAlert) {
                Button("取消", role: .cancel) {}
                Button("清除", role: .destructive) {
                    clearAllData()
                }
            } message: {
                Text("此操作将删除所有密码数据并重置应用，且无法恢复。请确保已备份重要数据。")
            }
        }
    }
    
    // MARK: - 安全设置
    
    private var securitySection: some View {
        Section {
            // 生物认证
            if BiometricAuth.shared.isBiometricAvailable() {
                Toggle(isOn: $useBiometric) {
                    HStack {
                        SettingsIcon(icon: BiometricAuth.shared.biometricType().icon, color: .green)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(BiometricAuth.shared.biometricType().displayName)
                            Text("使用生物认证快速解锁")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .tint(Color(hex: "#e94560") ?? .red)
            }
            
            // 修改主密码
            Button {
                showChangeMasterPassword = true
            } label: {
                HStack {
                    SettingsIcon(icon: "key.fill", color: .orange)
                    Text("修改主密码")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .foregroundColor(.primary)
            
            // 自动锁定
            Picker(selection: $autoLockTimeout) {
                ForEach(AutoLockOption.allCases, id: \.self) { option in
                    Text(option.title).tag(option)
                }
            } label: {
                HStack {
                    SettingsIcon(icon: "lock.fill", color: .blue)
                    Text("自动锁定")
                }
            }
        } header: {
            Text("安全")
        }
    }
    
    // MARK: - 自动化设置
    
    private var automationSection: some View {
        Section {
            // 剪贴板清除
            Picker(selection: $clipboardClearTimeout) {
                ForEach(ClipboardClearOption.allCases, id: \.self) { option in
                    Text(option.title).tag(option)
                }
            } label: {
                HStack {
                    SettingsIcon(icon: "doc.on.clipboard", color: .purple)
                    Text("自动清除剪贴板")
                }
            }
        } header: {
            Text("自动化")
        } footer: {
            Text("复制密码后，剪贴板将在指定时间后自动清除")
        }
    }
    
    // MARK: - 外观设置
    
    private var appearanceSection: some View {
        Section {
            Picker(selection: $selectedTheme) {
                ForEach(AppTheme.allCases, id: \.self) { theme in
                    HStack {
                        Image(systemName: theme.icon)
                        Text(theme.title)
                    }
                    .tag(theme)
                }
            } label: {
                HStack {
                    SettingsIcon(icon: "paintbrush.fill", color: .pink)
                    Text("主题")
                }
            }
        } header: {
            Text("外观")
        }
    }
    
    // MARK: - 数据管理
    
    private var dataSection: some View {
        Section {
            Button {
                showBackupRestore = true
            } label: {
                HStack {
                    SettingsIcon(icon: "externaldrive.fill", color: .cyan)
                    Text("备份与恢复")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .foregroundColor(.primary)
            
            // 统计信息
            HStack {
                SettingsIcon(icon: "chart.bar.fill", color: .indigo)
                Text("密码数量")
                Spacer()
                Text("\(PasswordRepository.shared.passwords.count) 个")
                    .foregroundColor(.secondary)
            }
        } header: {
            Text("数据")
        }
    }
    
    // MARK: - 关于
    
    private var aboutSection: some View {
        Section {
            Button {
                showAbout = true
            } label: {
                HStack {
                    SettingsIcon(icon: "info.circle.fill", color: .gray)
                    Text("关于 ConvenientPass")
                    Spacer()
                    Text("v1.0.0")
                        .foregroundColor(.secondary)
                }
            }
            .foregroundColor(.primary)
        }
    }
    
    // MARK: - 危险操作
    
    private var dangerSection: some View {
        Section {
            Button(role: .destructive) {
                showDeleteAlert = true
            } label: {
                HStack {
                    SettingsIcon(icon: "trash.fill", color: .red)
                    Text("清除所有数据")
                }
            }
        } footer: {
            Text("此操作不可撤销，请谨慎操作")
        }
    }
    
    // MARK: - 方法
    
    private func clearAllData() {
        // 清除所有密码数据
        KeychainManager.shared.clearAll()
        // 重置应用状态
        appState.lockApp()
        appState.hasMasterPassword = false
    }
}

// MARK: - 设置图标组件

struct SettingsIcon: View {
    let icon: String
    let color: Color
    
    var body: some View {
        Image(systemName: icon)
            .font(.subheadline)
            .foregroundColor(.white)
            .frame(width: 28, height: 28)
            .background(color)
            .cornerRadius(6)
    }
}

// MARK: - 修改主密码视图

struct ChangeMasterPasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = AuthViewModel()
    
    @State private var currentPassword: String = ""
    @State private var newPassword: String = ""
    @State private var confirmPassword: String = ""
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    @State private var showSuccess: Bool = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    SecureField("当前密码", text: $currentPassword)
                } header: {
                    Text("验证身份")
                }
                
                Section {
                    SecureField("新密码", text: $newPassword)
                    SecureField("确认新密码", text: $confirmPassword)
                } header: {
                    Text("设置新密码")
                } footer: {
                    Text("密码至少8位，建议包含大小写字母、数字和特殊字符")
                }
            }
            .navigationTitle("修改主密码")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        changePassword()
                    }
                    .disabled(currentPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty)
                }
            }
            .alert("错误", isPresented: $showError) {
                Button("确定", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .alert("成功", isPresented: $showSuccess) {
                Button("确定") {
                    dismiss()
                }
            } message: {
                Text("主密码已成功修改")
            }
        }
    }
    
    private func changePassword() {
        Task {
            let success = await viewModel.changeMasterPassword(
                oldPassword: currentPassword,
                newPassword: newPassword,
                confirmNew: confirmPassword
            )
            
            if success {
                showSuccess = true
            } else {
                errorMessage = viewModel.errorMessage ?? "修改失败"
                showError = true
            }
        }
    }
}

// MARK: - 备份恢复视图

struct BackupRestoreView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        // 导出备份
                    } label: {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(.blue)
                            Text("导出备份")
                        }
                    }
                    
                    Button {
                        // 导入备份
                    } label: {
                        HStack {
                            Image(systemName: "square.and.arrow.down")
                                .foregroundColor(.green)
                            Text("导入备份")
                        }
                    }
                } footer: {
                    Text("备份文件已加密，需要使用主密码才能恢复")
                }
            }
            .navigationTitle("备份与恢复")
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

// MARK: - 关于视图

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(spacing: 16) {
                        // App 图标
                        ZStack {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color(hex: "#e94560") ?? .red,
                                            Color(hex: "#ff6b6b") ?? .pink
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: "key.fill")
                                .font(.system(size: 36))
                                .foregroundColor(.white)
                                .rotationEffect(.degrees(-45))
                        }
                        
                        VStack(spacing: 4) {
                            Text("ConvenientPass")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text("版本 1.0.0")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical)
                }
                
                Section {
                    Link(destination: URL(string: "https://example.com/privacy")!) {
                        HStack {
                            Text("隐私政策")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Link(destination: URL(string: "https://example.com/terms")!) {
                        HStack {
                            Text("服务条款")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section {
                    HStack {
                        Text("开发者")
                        Spacer()
                        Text("Kumo")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("加密算法")
                        Spacer()
                        Text("AES-256-GCM")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("关于")
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
    SettingsView()
        .environmentObject(AppState.shared)
}

