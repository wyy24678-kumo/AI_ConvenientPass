//
//  LockScreenView.swift
//  ConvenientPass
//
//  锁屏认证界面
//

import SwiftUI

struct LockScreenView: View {
    
    // MARK: - 环境
    
    @StateObject private var viewModel = AuthViewModel()
    @FocusState private var isPasswordFieldFocused: Bool
    
    // MARK: - 状态
    
    @State private var showPassword: Bool = false
    @State private var isAnimating: Bool = false
    
    // MARK: - Body
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 背景渐变
                backgroundGradient
                
                VStack(spacing: 0) {
                    Spacer()
                    
                    // Logo 和标题
                    logoSection
                        .padding(.bottom, 50)
                    
                    // 认证区域
                    authenticationSection
                        .padding(.horizontal, 32)
                    
                    Spacer()
                    
                    // 底部提示
                    bottomHint
                        .padding(.bottom, 40)
                }
            }
        }
        .ignoresSafeArea()
        .alert("错误", isPresented: $viewModel.showError) {
            Button("确定", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .onAppear {
            withAnimation {
                isAnimating = true
            }
        }
        .task {
            // 延迟后自动尝试生物认证
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5秒
            
            if viewModel.canUseBiometric && !viewModel.isFirstSetup {
                await viewModel.authenticateWithBiometric()
            }
        }
    }
    
    // MARK: - 背景
    
    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Color(hex: "#1a1a2e") ?? .black,
                Color(hex: "#16213e") ?? .black,
                Color(hex: "#0f3460") ?? .black
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay(
            // 装饰圆圈
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(hex: "#e94560")?.opacity(0.3) ?? .clear,
                            .clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 200
                    )
                )
                .frame(width: 400, height: 400)
                .offset(x: 150, y: -200)
                .blur(radius: 60)
        )
    }
    
    // MARK: - Logo 区域
    
    private var logoSection: some View {
        VStack(spacing: 16) {
            // App 图标
            ZStack {
                Circle()
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
                    .frame(width: 100, height: 100)
                    .shadow(color: Color(hex: "#e94560")?.opacity(0.5) ?? .clear, radius: 20, x: 0, y: 10)
                
                Image(systemName: "key.fill")
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundColor(.white)
                    .rotationEffect(.degrees(-45))
            }
            .scaleEffect(isAnimating ? 1.0 : 0.8)
            .opacity(isAnimating ? 1.0 : 0)
            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: isAnimating)
            
            // App 名称
            Text("ConvenientPass")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            Text("安全的密码管理器")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
        }
    }
    
    // MARK: - 认证区域
    
    private var authenticationSection: some View {
        VStack(spacing: 24) {
            // 密码输入框
            passwordField
            
            // 解锁按钮
            unlockButton
            
            // 生物认证按钮
            if viewModel.canUseBiometric && !viewModel.isFirstSetup {
                biometricButton
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
        )
    }
    
    // MARK: - 密码输入框
    
    private var passwordField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("主密码")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
            
            HStack {
                if showPassword {
                    TextField("", text: $viewModel.masterPassword)
                        .textContentType(.password)
                } else {
                    SecureField("", text: $viewModel.masterPassword)
                        .textContentType(.password)
                }
                
                Button {
                    showPassword.toggle()
                } label: {
                    Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.white.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(.white.opacity(0.2), lineWidth: 1)
            )
            .focused($isPasswordFieldFocused)
            
            // 锁定提示
            if viewModel.isLocked {
                HStack {
                    Image(systemName: "lock.fill")
                    Text("已锁定，请等待 \(viewModel.lockTimeRemaining) 秒")
                }
                .font(.caption)
                .foregroundColor(.orange)
            }
        }
    }
    
    // MARK: - 解锁按钮
    
    private var unlockButton: some View {
        Button {
            Task {
                await viewModel.verifyMasterPassword()
            }
        } label: {
            HStack {
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "lock.open.fill")
                    Text("解锁")
                }
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
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
            .shadow(color: Color(hex: "#e94560")?.opacity(0.4) ?? .clear, radius: 10, x: 0, y: 5)
        }
        .disabled(viewModel.isLoading || viewModel.isLocked || viewModel.masterPassword.isEmpty)
        .opacity(viewModel.masterPassword.isEmpty ? 0.6 : 1.0)
    }
    
    // MARK: - 生物认证按钮
    
    private var biometricButton: some View {
        Button {
            Task {
                await viewModel.authenticateWithBiometric()
            }
        } label: {
            HStack {
                Image(systemName: viewModel.biometricType.icon)
                    .font(.title2)
                Text("使用 \(viewModel.biometricType.displayName)")
            }
            .foregroundColor(.white.opacity(0.9))
            .padding(.vertical, 12)
        }
    }
    
    // MARK: - 底部提示
    
    private var bottomHint: some View {
        VStack(spacing: 8) {
            Image(systemName: "lock.shield.fill")
                .font(.title3)
            Text("您的数据已加密存储在本地")
                .font(.caption)
        }
        .foregroundColor(.white.opacity(0.5))
    }
}

// MARK: - Preview

#Preview {
    LockScreenView()
}

