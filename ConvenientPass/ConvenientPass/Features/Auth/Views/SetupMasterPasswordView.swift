//
//  SetupMasterPasswordView.swift
//  ConvenientPass
//
//  首次设置主密码界面
//

import SwiftUI

struct SetupMasterPasswordView: View {
    
    // MARK: - 环境
    
    @StateObject private var viewModel = AuthViewModel()
    
    // MARK: - 状态
    
    @State private var currentStep: SetupStep = .welcome
    @State private var showPassword: Bool = false
    @State private var showConfirmPassword: Bool = false
    @State private var agreedToTerms: Bool = false
    
    // MARK: - Body
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 背景
                backgroundGradient
                
                VStack(spacing: 0) {
                    // 步骤指示器
                    stepIndicator
                        .padding(.top, 60)
                        .padding(.bottom, 40)
                    
                    // 内容区域
                    TabView(selection: $currentStep) {
                        welcomeStep
                            .tag(SetupStep.welcome)
                        
                        createPasswordStep
                            .tag(SetupStep.createPassword)
                        
                        confirmPasswordStep
                            .tag(SetupStep.confirmPassword)
                        
                        completeStep
                            .tag(SetupStep.complete)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .animation(.easeInOut, value: currentStep)
                }
            }
        }
        .ignoresSafeArea()
        .alert("错误", isPresented: $viewModel.showError) {
            Button("确定", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
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
    }
    
    // MARK: - 步骤指示器
    
    private var stepIndicator: some View {
        HStack(spacing: 12) {
            ForEach(SetupStep.allCases, id: \.self) { step in
                Circle()
                    .fill(step.rawValue <= currentStep.rawValue ? Color(hex: "#e94560") ?? .red : .white.opacity(0.3))
                    .frame(width: 10, height: 10)
                    .scaleEffect(step == currentStep ? 1.2 : 1.0)
                    .animation(.spring(response: 0.3), value: currentStep)
                
                if step != SetupStep.allCases.last {
                    Rectangle()
                        .fill(step.rawValue < currentStep.rawValue ? Color(hex: "#e94560") ?? .red : .white.opacity(0.3))
                        .frame(width: 30, height: 2)
                }
            }
        }
    }
    
    // MARK: - 欢迎步骤
    
    private var welcomeStep: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // 图标
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
                    .frame(width: 120, height: 120)
                    .shadow(color: Color(hex: "#e94560")?.opacity(0.5) ?? .clear, radius: 20, x: 0, y: 10)
                
                Image(systemName: "shield.checkered")
                    .font(.system(size: 54, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 16) {
                Text("欢迎使用 ConvenientPass")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text("您的密码将使用军事级加密技术\n安全存储在本地设备中")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            
            Spacer()
            
            // 功能特性
            featuresGrid
                .padding(.horizontal, 32)
            
            Spacer()
            
            // 下一步按钮
            nextButton(title: "开始设置") {
                withAnimation {
                    currentStep = .createPassword
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 50)
        }
    }
    
    // MARK: - 功能特性网格
    
    private var featuresGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            featureCard(icon: "lock.fill", title: "AES-256 加密", color: "#34C759")
            featureCard(icon: "icloud.slash.fill", title: "无云端依赖", color: "#007AFF")
            featureCard(icon: "faceid", title: "生物认证", color: "#AF52DE")
            featureCard(icon: "shield.fill", title: "安全检测", color: "#FF9500")
        }
    }
    
    private func featureCard(icon: String, title: String, color: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(Color(hex: color) ?? .white)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.white.opacity(0.1))
        )
    }
    
    // MARK: - 创建密码步骤
    
    private var createPasswordStep: some View {
        VStack(spacing: 32) {
            Spacer()
            
            VStack(spacing: 16) {
                Image(systemName: "key.fill")
                    .font(.system(size: 50))
                    .foregroundColor(Color(hex: "#e94560") ?? .red)
                
                Text("创建主密码")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("主密码用于加密和保护您的所有数据\n请设置一个强密码并牢记")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            
            // 密码输入
            VStack(spacing: 20) {
                passwordInputField(
                    title: "主密码",
                    text: $viewModel.masterPassword,
                    showPassword: $showPassword,
                    placeholder: "至少8位，含大小写字母和数字"
                )
                .onChange(of: viewModel.masterPassword) { _, _ in
                    viewModel.updatePasswordStrength()
                }
                
                // 密码强度指示器
                passwordStrengthIndicator
            }
            .padding(.horizontal, 32)
            
            Spacer()
            
            // 密码要求提示
            passwordRequirements
                .padding(.horizontal, 32)
            
            Spacer()
            
            // 按钮组
            HStack(spacing: 16) {
                backButton {
                    withAnimation {
                        currentStep = .welcome
                    }
                }
                
                nextButton(title: "下一步") {
                    withAnimation {
                        currentStep = .confirmPassword
                    }
                }
                .disabled(viewModel.masterPassword.count < 8 || viewModel.passwordStrength.rawValue < SecurityLevel.medium.rawValue)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 50)
        }
    }
    
    // MARK: - 确认密码步骤
    
    private var confirmPasswordStep: some View {
        VStack(spacing: 32) {
            Spacer()
            
            VStack(spacing: 16) {
                Image(systemName: "checkmark.shield.fill")
                    .font(.system(size: 50))
                    .foregroundColor(Color(hex: "#34C759") ?? .green)
                
                Text("确认主密码")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("请再次输入您的主密码以确认")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            // 确认密码输入
            passwordInputField(
                title: "确认密码",
                text: $viewModel.confirmPassword,
                showPassword: $showConfirmPassword,
                placeholder: "再次输入主密码"
            )
            .padding(.horizontal, 32)
            
            // 密码匹配提示
            if !viewModel.confirmPassword.isEmpty {
                HStack {
                    Image(systemName: viewModel.masterPassword == viewModel.confirmPassword ? "checkmark.circle.fill" : "xmark.circle.fill")
                    Text(viewModel.masterPassword == viewModel.confirmPassword ? "密码匹配" : "密码不匹配")
                }
                .font(.subheadline)
                .foregroundColor(viewModel.masterPassword == viewModel.confirmPassword ? .green : .red)
            }
            
            Spacer()
            
            // 服务条款
            Toggle(isOn: $agreedToTerms) {
                Text("我已阅读并同意[服务条款]和[隐私政策]")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            .toggleStyle(CheckboxToggleStyle())
            .padding(.horizontal, 32)
            
            Spacer()
            
            // 按钮组
            HStack(spacing: 16) {
                backButton {
                    withAnimation {
                        currentStep = .createPassword
                    }
                }
                
                nextButton(title: "完成设置") {
                    Task {
                        let success = await viewModel.setupMasterPassword()
                        if success {
                            withAnimation {
                                currentStep = .complete
                            }
                        }
                    }
                }
                .disabled(
                    viewModel.masterPassword != viewModel.confirmPassword ||
                    viewModel.confirmPassword.isEmpty ||
                    !agreedToTerms ||
                    viewModel.isLoading
                )
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 50)
        }
    }
    
    // MARK: - 完成步骤
    
    private var completeStep: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // 成功动画
            ZStack {
                Circle()
                    .fill(Color(hex: "#34C759")?.opacity(0.2) ?? .clear)
                    .frame(width: 150, height: 150)
                
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hex: "#34C759") ?? .green,
                                Color(hex: "#30D158") ?? .green
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                
                Image(systemName: "checkmark")
                    .font(.system(size: 44, weight: .bold))
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 16) {
                Text("设置完成！")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("您的密码库已准备就绪\n现在可以开始安全地管理密码了")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
            
            // 提示卡片
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(.yellow)
                    Text("重要提示")
                        .fontWeight(.semibold)
                }
                
                Text("请务必牢记您的主密码。出于安全考虑，我们无法帮您找回密码。")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.orange.opacity(0.2))
            )
            .padding(.horizontal, 32)
            
            Spacer()
            
            // 开始使用按钮
            nextButton(title: "开始使用") {
                // 这里会自动触发 isAuthenticated 状态更新
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 50)
        }
    }
    
    // MARK: - 密码输入框组件
    
    private func passwordInputField(
        title: String,
        text: Binding<String>,
        showPassword: Binding<Bool>,
        placeholder: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
            
            HStack {
                if showPassword.wrappedValue {
                    TextField(placeholder, text: text)
                        .textContentType(.newPassword)
                } else {
                    SecureField(placeholder, text: text)
                        .textContentType(.newPassword)
                }
                
                Button {
                    showPassword.wrappedValue.toggle()
                } label: {
                    Image(systemName: showPassword.wrappedValue ? "eye.slash.fill" : "eye.fill")
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
        }
    }
    
    // MARK: - 密码强度指示器
    
    private var passwordStrengthIndicator: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("密码强度")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
                
                Spacer()
                
                Text(viewModel.passwordStrength.title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(Color(hex: viewModel.passwordStrength.color) ?? .white)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(.white.opacity(0.2))
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(hex: viewModel.passwordStrength.color) ?? .gray)
                        .frame(width: geometry.size.width * CGFloat(viewModel.passwordStrength.rawValue + 1) / 5)
                        .animation(.easeInOut, value: viewModel.passwordStrength)
                }
            }
            .frame(height: 6)
        }
    }
    
    // MARK: - 密码要求提示
    
    private var passwordRequirements: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("密码要求")
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
            
            requirementRow(met: viewModel.masterPassword.count >= 8, text: "至少8个字符")
            requirementRow(met: viewModel.masterPassword.range(of: "[A-Z]", options: .regularExpression) != nil, text: "包含大写字母")
            requirementRow(met: viewModel.masterPassword.range(of: "[a-z]", options: .regularExpression) != nil, text: "包含小写字母")
            requirementRow(met: viewModel.masterPassword.range(of: "[0-9]", options: .regularExpression) != nil, text: "包含数字")
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.white.opacity(0.05))
        )
    }
    
    private func requirementRow(met: Bool, text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: met ? "checkmark.circle.fill" : "circle")
                .foregroundColor(met ? .green : .white.opacity(0.4))
                .font(.caption)
            
            Text(text)
                .font(.caption)
                .foregroundColor(met ? .white : .white.opacity(0.6))
        }
    }
    
    // MARK: - 按钮组件
    
    private func nextButton(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(title)
                Image(systemName: "arrow.right")
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
        }
    }
    
    private func backButton(action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: "arrow.left")
                Text("返回")
            }
            .font(.headline)
            .foregroundColor(.white.opacity(0.8))
            .padding(.vertical, 16)
            .padding(.horizontal, 24)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.white.opacity(0.1))
            )
        }
    }
}

// MARK: - 设置步骤枚举

enum SetupStep: Int, CaseIterable {
    case welcome = 0
    case createPassword = 1
    case confirmPassword = 2
    case complete = 3
}

// MARK: - 复选框样式

struct CheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 12) {
            Image(systemName: configuration.isOn ? "checkmark.square.fill" : "square")
                .foregroundColor(configuration.isOn ? Color(hex: "#e94560") ?? .red : .white.opacity(0.5))
                .font(.title3)
                .onTapGesture {
                    configuration.isOn.toggle()
                }
            
            configuration.label
        }
    }
}

// MARK: - Preview

#Preview {
    SetupMasterPasswordView()
}

