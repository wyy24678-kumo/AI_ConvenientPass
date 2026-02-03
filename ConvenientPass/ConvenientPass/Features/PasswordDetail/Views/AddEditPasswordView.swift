//
//  AddEditPasswordView.swift
//  ConvenientPass
//
//  添加/编辑密码视图
//

import SwiftUI

struct AddEditPasswordView: View {
    
    // MARK: - 模式枚举
    
    enum Mode {
        case add
        case edit(PasswordEntry)
        
        var title: String {
            switch self {
            case .add: return "添加密码"
            case .edit: return "编辑密码"
            }
        }
    }
    
    // MARK: - 属性
    
    let mode: Mode
    
    // MARK: - 环境
    
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - 状态
    
    @State private var title: String = ""
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var websiteURL: String = ""
    @State private var notes: String = ""
    @State private var selectedCategoryId: UUID = Category.PresetID.socialMedia
    @State private var isFavorite: Bool = false
    
    @State private var showPassword: Bool = false
    @State private var showCategoryPicker: Bool = false
    @State private var showGeneratorSheet: Bool = false
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var showError: Bool = false
    @State private var hasLoadedExistingData: Bool = false
    
    /// 当前选中的分类（计算属性）
    private var selectedCategory: Category {
        Category.presets.first { $0.id == selectedCategoryId } ?? Category.other
    }
    
    // MARK: - 计算属性
    
    private var passwordStrength: SecurityLevel {
        CryptoManager.shared.getPasswordStrengthLevel(password)
    }
    
    private var isValid: Bool {
        !title.isEmpty && !username.isEmpty && !password.isEmpty
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            Form {
                // 基本信息
                basicInfoSection
                
                // 密码
                passwordSection
                
                // 分类
                categorySection
                
                // 其他信息
                otherInfoSection
            }
            .navigationTitle(mode.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        savePassword()
                    }
                    .disabled(!isValid || isLoading)
                    .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showGeneratorSheet) {
                GeneratorSheetView { generatedPassword in
                    password = generatedPassword
                }
            }
            .alert("错误", isPresented: $showError) {
                Button("确定", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "保存失败")
            }
            .onAppear {
                if !hasLoadedExistingData {
                    loadExistingData()
                    hasLoadedExistingData = true
                }
            }
        }
    }
    
    // MARK: - 基本信息区域
    
    private var basicInfoSection: some View {
        Section("基本信息") {
            // 标题
            HStack {
                Image(systemName: "textformat")
                    .foregroundColor(.secondary)
                TextField("标题（如：微信）", text: $title)
            }
            
            // 用户名
            HStack {
                Image(systemName: "person.fill")
                    .foregroundColor(.secondary)
                TextField("用户名/账号/邮箱", text: $username)
                    .textContentType(.username)
                    .autocapitalization(.none)
            }
            
            // 网站
            HStack {
                Image(systemName: "globe")
                    .foregroundColor(.secondary)
                TextField("网站地址（可选）", text: $websiteURL)
                    .textContentType(.URL)
                    .autocapitalization(.none)
                    .keyboardType(.URL)
            }
        }
    }
    
    // MARK: - 密码区域
    
    private var passwordSection: some View {
        Section {
            // 密码输入
            HStack {
                Image(systemName: "key.fill")
                    .foregroundColor(.secondary)
                
                if showPassword {
                    TextField("密码", text: $password)
                        .textContentType(.password)
                        .autocapitalization(.none)
                } else {
                    SecureField("密码", text: $password)
                        .textContentType(.password)
                }
                
                Button {
                    showPassword.toggle()
                } label: {
                    Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            
            // 密码强度
            if !password.isEmpty {
                HStack {
                    Text("密码强度")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(passwordStrength.title)
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color(hex: passwordStrength.color)?.opacity(0.2) ?? .clear)
                        .foregroundColor(Color(hex: passwordStrength.color) ?? .gray)
                        .cornerRadius(4)
                }
                
                // 强度条
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.secondary.opacity(0.2))
                        
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color(hex: passwordStrength.color) ?? .gray)
                            .frame(width: geometry.size.width * CGFloat(passwordStrength.rawValue + 1) / 5)
                    }
                }
                .frame(height: 4)
            }
            
            // 生成密码按钮
            Button {
                showGeneratorSheet = true
            } label: {
                HStack {
                    Image(systemName: "wand.and.stars")
                    Text("生成安全密码")
                }
            }
        } header: {
            Text("密码")
        }
    }
    
    // MARK: - 分类区域
    
    private var categorySection: some View {
        Section("分类") {
            // 自定义分类选择器（替换有问题的 Picker）
            NavigationLink {
                CategorySelectionView(selectedCategoryId: $selectedCategoryId)
            } label: {
                HStack {
                    Text("选择分类")
                    Spacer()
                    Image(systemName: selectedCategory.icon)
                        .foregroundColor(selectedCategory.color)
                    Text(selectedCategory.name)
                        .foregroundColor(.secondary)
                }
            }
            
            // 收藏开关
            Toggle(isOn: $isFavorite) {
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                    Text("添加到收藏")
                }
            }
        }
    }
    
    // MARK: - 其他信息区域
    
    private var otherInfoSection: some View {
        Section("备注") {
            TextEditor(text: $notes)
                .frame(minHeight: 100)
        }
    }
    
    // MARK: - 方法
    
    private func loadExistingData() {
        if case .edit(let entry) = mode {
            title = entry.title
            username = entry.username
            websiteURL = entry.websiteURL ?? ""
            notes = entry.notes ?? ""
            isFavorite = entry.isFavorite
            
            // 解密密码
            do {
                password = try CryptoManager.shared.decryptToString(entry.encryptedPassword)
            } catch {
                password = ""
            }
            
            // 设置分类ID
            selectedCategoryId = entry.categoryId
        }
    }
    
    private func savePassword() {
        isLoading = true
        
        do {
            switch mode {
            case .add:
                _ = try PasswordRepository.shared.createPassword(
                    title: title,
                    username: username,
                    password: password,
                    categoryId: selectedCategoryId,
                    websiteURL: websiteURL.isEmpty ? nil : websiteURL,
                    notes: notes.isEmpty ? nil : notes
                )
                
            case .edit(var entry):
                entry.title = title
                entry.username = username
                entry.websiteURL = websiteURL.isEmpty ? nil : websiteURL
                entry.notes = notes.isEmpty ? nil : notes
                entry.categoryId = selectedCategoryId
                entry.isFavorite = isFavorite
                
                try PasswordRepository.shared.updatePassword(&entry, newPassword: password)
            }
            
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        
        isLoading = false
    }
}

// MARK: - 生成器弹窗视图

struct GeneratorSheetView: View {
    let onSelect: (String) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var generatedPassword: String = ""
    @State private var length: Double = 16
    @State private var includeUppercase: Bool = true
    @State private var includeLowercase: Bool = true
    @State private var includeNumbers: Bool = true
    @State private var includeSpecial: Bool = true
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    // 生成的密码
                    HStack {
                        Text(generatedPassword)
                            .font(.system(.body, design: .monospaced))
                            .lineLimit(2)
                        
                        Spacer()
                        
                        Button {
                            generatePassword()
                        } label: {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                } header: {
                    Text("生成的密码")
                }
                
                Section {
                    // 长度滑块
                    VStack {
                        HStack {
                            Text("长度")
                            Spacer()
                            Text("\(Int(length))")
                                .foregroundColor(.secondary)
                        }
                        
                        Slider(value: $length, in: 8...64, step: 1)
                            .onChange(of: length) { _, _ in
                                generatePassword()
                            }
                    }
                    
                    Toggle("包含大写字母", isOn: $includeUppercase)
                        .onChange(of: includeUppercase) { _, _ in generatePassword() }
                    
                    Toggle("包含小写字母", isOn: $includeLowercase)
                        .onChange(of: includeLowercase) { _, _ in generatePassword() }
                    
                    Toggle("包含数字", isOn: $includeNumbers)
                        .onChange(of: includeNumbers) { _, _ in generatePassword() }
                    
                    Toggle("包含特殊字符", isOn: $includeSpecial)
                        .onChange(of: includeSpecial) { _, _ in generatePassword() }
                } header: {
                    Text("选项")
                }
            }
            .navigationTitle("生成密码")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("使用") {
                        onSelect(generatedPassword)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                generatePassword()
            }
        }
    }
    
    private func generatePassword() {
        let config = PasswordGenerator.Configuration(
            length: Int(length),
            includeUppercase: includeUppercase,
            includeLowercase: includeLowercase,
            includeNumbers: includeNumbers,
            includeSpecialChars: includeSpecial
        )
        generatedPassword = PasswordGenerator.shared.generate(config: config)
    }
}

// MARK: - 分类选择视图

struct CategorySelectionView: View {
    @Binding var selectedCategoryId: UUID
    @Environment(\.dismiss) private var dismiss
    
    /// 本地临时选中的分类ID（点击保存前不影响外部）
    @State private var tempSelectedId: UUID = UUID()
    
    /// 是否有修改
    private var hasChanges: Bool {
        tempSelectedId != selectedCategoryId
    }
    
    var body: some View {
        List {
            ForEach(Category.presets) { category in
                Button {
                    // 只更新本地临时选中状态，不立即返回
                    tempSelectedId = category.id
                } label: {
                    HStack {
                        Image(systemName: category.icon)
                            .foregroundColor(category.color)
                            .frame(width: 24)
                        
                        Text(category.name)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        // 显示选中状态（使用临时选中ID）
                        if category.id == tempSelectedId {
                            Image(systemName: "checkmark")
                                .foregroundColor(.accentColor)
                                .fontWeight(.semibold)
                        }
                    }
                }
            }
        }
        .navigationTitle("选择分类")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // 右上角：只有修改时才显示保存按钮
            ToolbarItem(placement: .navigationBarTrailing) {
                if hasChanges {
                    Button("保存") {
                        // 确认选择，更新绑定值
                        selectedCategoryId = tempSelectedId
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .onAppear {
            // 初始化临时选中ID为当前值
            tempSelectedId = selectedCategoryId
        }
    }
}

// MARK: - Preview

#Preview("添加") {
    AddEditPasswordView(mode: .add)
}

#Preview("编辑") {
    AddEditPasswordView(mode: .edit(.example))
}

