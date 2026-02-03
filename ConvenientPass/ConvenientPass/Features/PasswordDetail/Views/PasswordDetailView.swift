//
//  PasswordDetailView.swift
//  ConvenientPass
//
//  密码详情视图
//

import SwiftUI
import UIKit

struct PasswordDetailView: View {
    
    // MARK: - 属性
    
    let password: PasswordEntry
    
    // MARK: - 状态
    
    @Environment(\.dismiss) private var dismiss
    @State private var currentPassword: PasswordEntry
    @State private var showPassword: Bool = false
    @State private var decryptedPassword: String = ""
    @State private var showEditSheet: Bool = false
    @State private var showDeleteAlert: Bool = false
    @State private var isCopied: Bool = false
    @State private var copiedField: CopiedField?
    
    // MARK: - 初始化
    
    init(password: PasswordEntry) {
        self.password = password
        _currentPassword = State(initialValue: password)
    }
    
    // MARK: - Body
    
    var body: some View {
        List {
            // 头部信息
            headerSection
            
            // 账号信息
            accountSection
            
            // 密码信息
            passwordSection
            
            // 分类信息
            categorySection
            
            // 安全信息
            securitySection
            
            // 备注
            if let notes = currentPassword.notes, !notes.isEmpty {
                notesSection(notes)
            }
            
            // 时间信息
            timeSection
            
            // 危险操作
            dangerSection
        }
        .navigationTitle("密码详情")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showEditSheet = true
                } label: {
                    Text("编辑")
                }
            }
        }
        .sheet(isPresented: $showEditSheet, onDismiss: {
            // 编辑后刷新数据
            reloadPassword(source: "editDismiss")
        }) {
            AddEditPasswordView(mode: .edit(currentPassword))
        }
        .alert("确认删除", isPresented: $showDeleteAlert) {
            Button("取消", role: .cancel) {}
            Button("删除", role: .destructive) {
                deletePassword()
            }
        } message: {
            Text("删除后将无法恢复，确定要删除这条密码记录吗？")
        }
        .onAppear {
            reloadPassword(source: "onAppear")
        }
    }
    
    // MARK: - 头部区域
    
    private var headerSection: some View {
        Section {
            HStack(spacing: 16) {
                // 图标
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(hex: currentPassword.securityLevel.color)?.opacity(0.8) ?? .gray,
                                    Color(hex: currentPassword.securityLevel.color)?.opacity(0.6) ?? .gray
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 64, height: 64)
                    
                    Text(currentPassword.title.prefix(1).uppercased())
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(currentPassword.title)
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        if currentPassword.isFavorite {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                        }
                    }
                    
                    if let url = currentPassword.websiteURL {
                        Text(url)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
            }
            .padding(.vertical, 8)
        }
    }
    
    // MARK: - 账号区域
    
    private var accountSection: some View {
        Section("账号信息") {
            DetailRow(
                icon: "person.fill",
                title: "用户名",
                value: currentPassword.username,
                isCopied: copiedField == .username
            ) {
                copyToClipboard(currentPassword.username, field: .username)
            }
            
            if let url = currentPassword.websiteURL, !url.isEmpty {
                DetailRow(
                    icon: "globe",
                    title: "网站",
                    value: url,
                    isCopied: copiedField == .website
                ) {
                    copyToClipboard(url, field: .website)
                }
            }
        }
    }
    
    // MARK: - 密码区域
    
    private var passwordSection: some View {
        Section("密码") {
            HStack {
                Image(systemName: "key.fill")
                    .foregroundColor(.secondary)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("密码")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(showPassword ? decryptedPassword : "••••••••••••")
                        .font(.system(.body, design: .monospaced))
                }
                
                Spacer()
                
                // 显示/隐藏按钮
                Button {
                    showPassword.toggle()
                } label: {
                    Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                
                // 复制按钮
                Button {
                    copyToClipboard(decryptedPassword, field: .password)
                } label: {
                    Image(systemName: copiedField == .password ? "checkmark.circle.fill" : "doc.on.doc")
                        .foregroundColor(copiedField == .password ? .green : .blue)
                }
                .buttonStyle(.plain)
            }
            .padding(.vertical, 4)
        }
    }
    
    // MARK: - 分类区域
    
    private var categorySection: some View {
        Section("分类") {
            HStack {
                // 分类图标
            let category = Category.presets.first(where: { $0.id == currentPassword.categoryId }) ?? Category.other
                
                Image(systemName: category.icon)
                    .foregroundColor(category.color)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("所属分类")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(category.name)
                        .font(.body)
                }
                
                Spacer()
            }
            .padding(.vertical, 4)
        }
    }
    
    // MARK: - 安全信息区域
    
    private var securitySection: some View {
        Section("安全信息") {
            // 安全评分
            HStack {
                Image(systemName: "shield.checkered")
                    .foregroundColor(.secondary)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("安全评分")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 8) {
                        Text("\(currentPassword.securityScore)")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(Color(hex: currentPassword.securityLevel.color) ?? .gray)
                        
                        Text(currentPassword.securityLevel.title)
                            .font(.subheadline)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color(hex: currentPassword.securityLevel.color)?.opacity(0.2) ?? .clear)
                            .foregroundColor(Color(hex: currentPassword.securityLevel.color) ?? .gray)
                            .cornerRadius(4)
                    }
                }
                
                Spacer()
            }
            .padding(.vertical, 4)
            
            // 密码年龄警告
            if currentPassword.isOldPassword {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text("此密码已超过90天未更新，建议定期更换")
                        .font(.subheadline)
                        .foregroundColor(.orange)
                }
                .padding(.vertical, 4)
            }
        }
    }
    
    // MARK: - 备注区域
    
    private func notesSection(_ notes: String) -> some View {
        Section("备注") {
            Text(notes)
                .font(.body)
                .foregroundColor(.primary)
        }
    }
    
    // MARK: - 时间信息区域
    
    private var timeSection: some View {
        Section("时间信息") {
            DetailRow(
                icon: "calendar.badge.plus",
                title: "创建时间",
                value: formatDate(currentPassword.createdAt),
                isCopied: false
            ) {}
            
            DetailRow(
                icon: "calendar.badge.clock",
                title: "最后更新",
                value: formatDate(currentPassword.updatedAt),
                isCopied: false
            ) {}
            
            if let lastUsed = currentPassword.lastUsedAt {
                DetailRow(
                    icon: "clock.fill",
                    title: "最后使用",
                    value: formatDate(lastUsed),
                    isCopied: false
                ) {}
            }
        }
    }
    
    // MARK: - 危险操作区域
    
    private var dangerSection: some View {
        Section {
            Button(role: .destructive) {
                showDeleteAlert = true
            } label: {
                HStack {
                    Image(systemName: "trash.fill")
                    Text("删除此密码")
                }
            }
        }
    }
    
    // MARK: - 方法
    
    private func decryptPassword() {
        do {
            decryptedPassword = try CryptoManager.shared.decryptToString(currentPassword.encryptedPassword)
        } catch {
            decryptedPassword = "[解密失败]"
        }
    }

    private func reloadPassword(source: String) {
        if let updated = PasswordRepository.shared.fetch(byId: password.id) {
            currentPassword = updated
            decryptPassword()
        } else {
        }
    }
    
    private func copyToClipboard(_ text: String, field: CopiedField) {
        UIPasteboard.general.string = text
        
        withAnimation {
            copiedField = field
        }
        
        // 重置状态
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                if copiedField == field {
                    copiedField = nil
                }
            }
        }
        
        // 30秒后清除剪贴板（仅密码）
        if field == .password {
            DispatchQueue.main.asyncAfter(deadline: .now() + 30) {
                if UIPasteboard.general.string == text {
                    UIPasteboard.general.string = ""
                }
            }
        }
    }
    
    private func deletePassword() {
        do {
            try PasswordRepository.shared.delete(currentPassword)
            dismiss()
        } catch {
            print("删除失败: \(error)")
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }
}

// MARK: - 复制字段枚举

enum CopiedField {
    case username
    case password
    case website
}

// MARK: - 详情行组件

struct DetailRow: View {
    let icon: String
    let title: String
    let value: String
    let isCopied: Bool
    let onCopy: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.secondary)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.body)
            }
            
            Spacer()
            
            if !value.isEmpty {
                Button(action: onCopy) {
                    Image(systemName: isCopied ? "checkmark.circle.fill" : "doc.on.doc")
                        .foregroundColor(isCopied ? .green : .blue)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        PasswordDetailView(password: .example)
    }
}

