//
//  SecurityCheckView.swift
//  ConvenientPass
//
//  安全检测视图
//

import SwiftUI

struct SecurityCheckView: View {
    
    // MARK: - 状态
    
    @State private var securityScore: Int = 0
    @State private var weakPasswords: [PasswordEntry] = []
    @State private var duplicateGroups: [[PasswordEntry]] = []
    @State private var oldPasswords: [PasswordEntry] = []
    @State private var isLoading: Bool = true
    @State private var isAnimating: Bool = false
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // 安全评分卡片
                    scoreCard
                    
                    // 问题摘要
                    if !isLoading {
                        issuesSummary
                        
                        // 弱密码列表
                        if !weakPasswords.isEmpty {
                            issueSection(
                                title: "弱密码",
                                icon: "lock.open.fill",
                                color: "#FF3B30",
                                description: "这些密码强度较低，容易被破解",
                                passwords: weakPasswords
                            )
                        }
                        
                        // 重复密码
                        if !duplicateGroups.isEmpty {
                            duplicateSection
                        }
                        
                        // 长期未更新
                        if !oldPasswords.isEmpty {
                            issueSection(
                                title: "长期未更新",
                                icon: "clock.fill",
                                color: "#FFCC00",
                                description: "这些密码超过90天未更新",
                                passwords: oldPasswords
                            )
                        }
                        
                        // 全部安全提示
                        if weakPasswords.isEmpty && duplicateGroups.isEmpty && oldPasswords.isEmpty {
                            allSecureView
                        }
                    }
                }
                .padding()
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("安全检测")
            .onAppear {
                performSecurityCheck()
            }
        }
    }
    
    // MARK: - 安全评分卡片
    
    private var scoreCard: some View {
        VStack(spacing: 20) {
            // 评分圆环
            ZStack {
                // 背景圆环
                Circle()
                    .stroke(
                        Color.secondary.opacity(0.2),
                        lineWidth: 12
                    )
                    .frame(width: 160, height: 160)
                
                // 进度圆环
                Circle()
                    .trim(from: 0, to: isAnimating ? CGFloat(securityScore) / 100 : 0)
                    .stroke(
                        LinearGradient(
                            colors: scoreColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .frame(width: 160, height: 160)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 1.5), value: isAnimating)
                
                // 评分数字
                VStack(spacing: 4) {
                    Text("\(securityScore)")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(scoreColor)
                    
                    Text("安全评分")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            // 安全等级
            Text(securityLevel.title)
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(scoreColor)
                .cornerRadius(20)
            
            // 上次检测时间
            Text("上次检测: 刚刚")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
        )
    }
    
    // MARK: - 问题摘要
    
    private var issuesSummary: some View {
        HStack(spacing: 12) {
            IssueBadge(
                icon: "lock.open.fill",
                count: weakPasswords.count,
                label: "弱密码",
                color: Color(hex: "#FF3B30") ?? .red
            )
            
            IssueBadge(
                icon: "doc.on.doc.fill",
                count: duplicateGroups.count,
                label: "重复密码",
                color: Color(hex: "#FF9500") ?? .orange
            )
            
            IssueBadge(
                icon: "clock.fill",
                count: oldPasswords.count,
                label: "待更新",
                color: Color(hex: "#FFCC00") ?? .yellow
            )
        }
    }
    
    // MARK: - 问题分区
    
    private func issueSection(
        title: String,
        icon: String,
        color: String,
        description: String,
        passwords: [PasswordEntry]
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(Color(hex: color) ?? .red)
                
                Text(title)
                    .font(.headline)
                
                Spacer()
                
                Text("\(passwords.count) 个")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                ForEach(passwords.prefix(5)) { password in
                    NavigationLink {
                        PasswordDetailView(password: password)
                    } label: {
                        IssuePasswordRow(password: password, issueColor: color)
                    }
                }
                
                if passwords.count > 5 {
                    Text("还有 \(passwords.count - 5) 个...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 4)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
        )
    }
    
    // MARK: - 重复密码分区
    
    private var duplicateSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "doc.on.doc.fill")
                    .foregroundColor(Color(hex: "#FF9500") ?? .orange)
                
                Text("重复密码")
                    .font(.headline)
                
                Spacer()
                
                Text("\(duplicateGroups.count) 组")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Text("这些账号使用了相同的密码，存在连锁风险")
                .font(.caption)
                .foregroundColor(.secondary)
            
            VStack(spacing: 12) {
                ForEach(Array(duplicateGroups.prefix(3).enumerated()), id: \.offset) { index, group in
                    VStack(alignment: .leading, spacing: 8) {
                        Text("第 \(index + 1) 组 (\(group.count) 个)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        ForEach(group.prefix(3)) { password in
                            HStack {
                                Text(password.title)
                                    .font(.subheadline)
                                Spacer()
                                Text(password.username)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 6)
                            .padding(.horizontal, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(UIColor.systemBackground))
                            )
                        }
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
        )
    }
    
    // MARK: - 全部安全视图
    
    private var allSecureView: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.shield.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)
            
            Text("太棒了！")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("您的所有密码都很安全")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
        )
    }
    
    // MARK: - 计算属性
    
    private var scoreColor: Color {
        Color(hex: securityLevel.colorHex) ?? .gray
    }
    
    private var scoreColors: [Color] {
        [scoreColor, scoreColor.opacity(0.7)]
    }
    
    private var securityLevel: SecurityReportLevel {
        switch securityScore {
        case 0..<40: return .critical
        case 40..<60: return .warning
        case 60..<80: return .good
        default: return .excellent
        }
    }
    
    // MARK: - 方法
    
    private func performSecurityCheck() {
        isLoading = true
        
        // 模拟加载延迟
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let repository = PasswordRepository.shared
            let passwords = repository.fetchAll()
            
            // 检查弱密码
            weakPasswords = passwords.filter {
                $0.securityLevel == .veryWeak || $0.securityLevel == .weak
            }
            
            // 检查长期未更新
            oldPasswords = passwords.filter { $0.isOldPassword }
            
            // 检查重复密码（简化实现）
            // 实际应该比较加密后的哈希值
            duplicateGroups = []
            
            // 计算安全评分
            let totalIssues = weakPasswords.count + duplicateGroups.count + oldPasswords.count
            let totalPasswords = max(passwords.count, 1)
            
            if passwords.isEmpty {
                securityScore = 100
            } else {
                let issueRatio = Double(totalIssues) / Double(totalPasswords)
                securityScore = max(0, min(100, Int(100 - issueRatio * 100)))
            }
            
            isLoading = false
            
            // 触发动画
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isAnimating = true
            }
        }
    }
}

// MARK: - 问题徽章组件

struct IssueBadge: View {
    let icon: String
    let count: Int
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 50, height: 50)
                
                Image(systemName: icon)
                    .foregroundColor(color)
            }
            
            Text("\(count)")
                .font(.title3)
                .fontWeight(.semibold)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
        )
    }
}

// MARK: - 问题密码行组件

struct IssuePasswordRow: View {
    let password: PasswordEntry
    let issueColor: String
    
    var body: some View {
        HStack {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(hex: issueColor)?.opacity(0.2) ?? .clear)
                    .frame(width: 36, height: 36)
                
                Text(password.title.prefix(1).uppercased())
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color(hex: issueColor) ?? .red)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(password.title)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                
                Text(password.username)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(UIColor.systemBackground))
        )
    }
}

// MARK: - Preview

#Preview {
    SecurityCheckView()
}

