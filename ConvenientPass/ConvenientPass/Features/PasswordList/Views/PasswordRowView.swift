//
//  PasswordRowView.swift
//  ConvenientPass
//
//  密码列表行视图
//

import SwiftUI
import UIKit

struct PasswordRowView: View {
    
    // MARK: - 属性
    
    let password: PasswordEntry
    
    // MARK: - 状态
    
    @State private var showPassword: Bool = false
    @State private var decryptedPassword: String = "••••••••"
    @State private var isCopied: Bool = false
    
    // MARK: - Body
    
    var body: some View {
        NavigationLink {
            PasswordDetailView(password: password)
        } label: {
            HStack(spacing: 12) {
                // 分类图标
                categoryIcon
                
                // 信息区域
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(password.title)
                            .font(.headline)
                            .lineLimit(1)
                        
                        if password.isFavorite {
                            Image(systemName: "star.fill")
                                .font(.caption)
                                .foregroundColor(.yellow)
                        }
                    }
                    
                    Text(password.username)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    
                    // 安全评分和更新时间
                    HStack(spacing: 12) {
                        securityBadge
                        updateTimeBadge
                    }
                }
                
                Spacer()
                
                // 快速操作按钮
                quickCopyButton
            }
            .padding(.vertical, 4)
        }
    }
    
    // MARK: - 分类图标
    
    private var categoryIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: password.securityLevel.color)?.opacity(0.8) ?? .gray,
                            Color(hex: password.securityLevel.color)?.opacity(0.6) ?? .gray
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 44, height: 44)
            
            Text(password.title.prefix(1).uppercased())
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
        }
    }
    
    // MARK: - 安全评分徽章
    
    private var securityBadge: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(Color(hex: password.securityLevel.color) ?? .gray)
                .frame(width: 8, height: 8)
            
            Text(password.securityLevel.title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - 更新时间徽章
    
    private var updateTimeBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "clock")
                .font(.caption2)
            
            Text(formatUpdateTime(password.updatedAt))
                .font(.caption2)
        }
        .foregroundColor(password.isOldPassword ? .orange : .secondary)
    }
    
    // MARK: - 快速复制按钮
    
    private var quickCopyButton: some View {
        Button {
            copyPassword()
        } label: {
            Image(systemName: isCopied ? "checkmark.circle.fill" : "doc.on.doc")
                .font(.title3)
                .foregroundColor(isCopied ? .green : .secondary)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - 方法
    
    private func copyPassword() {
        // 解密并复制密码
        do {
            let decrypted = try CryptoManager.shared.decryptToString(password.encryptedPassword)
            UIPasteboard.general.string = decrypted
            
            withAnimation {
                isCopied = true
            }
            
            // 30秒后清除剪贴板
            DispatchQueue.main.asyncAfter(deadline: .now() + 30) {
                if UIPasteboard.general.string == decrypted {
                    UIPasteboard.general.string = ""
                }
            }
            
            // 重置复制状态
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation {
                    isCopied = false
                }
            }
        } catch {
            print("解密失败: \(error)")
        }
    }
    
    private func formatUpdateTime(_ date: Date) -> String {
        let days = Calendar.current.dateComponents([.day], from: date, to: Date()).day ?? 0
        
        if days == 0 {
            return "今天"
        } else if days == 1 {
            return "昨天"
        } else if days < 7 {
            return "\(days)天前"
        } else if days < 30 {
            return "\(days / 7)周前"
        } else if days < 365 {
            return "\(days / 30)个月前"
        } else {
            return "\(days / 365)年前"
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        List {
            PasswordRowView(password: .example)
        }
    }
}

