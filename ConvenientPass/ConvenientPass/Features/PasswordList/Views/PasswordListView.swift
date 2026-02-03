//
//  PasswordListView.swift
//  ConvenientPass
//
//  密码列表视图
//

import SwiftUI

struct PasswordListView: View {
    
    // MARK: - 状态
    
    @StateObject private var viewModel = PasswordListViewModel()
    @State private var searchText: String = ""
    @State private var selectedCategory: Category?
    @State private var showAddPassword: Bool = false
    @State private var showCategoryFilter: Bool = false
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ZStack {
                // 背景色
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()
                
                if viewModel.filteredPasswords.isEmpty {
                    emptyStateView
                } else {
                    passwordList
                }
            }
            .navigationTitle("密码库")
            .searchable(text: $searchText, prompt: "搜索密码")
            .onChange(of: searchText) { _, newValue in
                viewModel.search(keyword: newValue)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    filterButton
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    addButton
                }
            }
            .sheet(isPresented: $showAddPassword, onDismiss: {
                // Sheet 关闭后刷新数据
                viewModel.loadData()
            }) {
                AddEditPasswordView(mode: .add)
            }
            .sheet(isPresented: $showCategoryFilter) {
                CategoryFilterSheet(
                    categories: viewModel.categories,
                    selectedCategory: $selectedCategory
                )
                .presentationDetents([.medium])
            }
            .onChange(of: selectedCategory) { _, newValue in
                viewModel.filterByCategory(newValue)
            }
        }
        .onAppear {
            viewModel.loadData()
        }
    }
    
    // MARK: - 密码列表
    
    private var passwordList: some View {
        List {
            // 收藏部分
            if !viewModel.favoritePasswords.isEmpty && selectedCategory == nil && searchText.isEmpty {
                Section {
                    ForEach(viewModel.favoritePasswords) { password in
                        PasswordRowView(password: password)
                    }
                } header: {
                    sectionHeader(title: "收藏", icon: "star.fill", color: .yellow)
                }
            }
            
            // 按分类分组
            ForEach(viewModel.groupedPasswords.keys.sorted(by: { $0.sortOrder < $1.sortOrder }), id: \.id) { category in
                if let passwords = viewModel.groupedPasswords[category], !passwords.isEmpty {
                    Section {
                        ForEach(passwords) { password in
                            PasswordRowView(password: password)
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        viewModel.deletePassword(password)
                                    } label: {
                                        Label("删除", systemImage: "trash")
                                    }
                                    
                                    Button {
                                        viewModel.toggleFavorite(password)
                                    } label: {
                                        Label(
                                            password.isFavorite ? "取消收藏" : "收藏",
                                            systemImage: password.isFavorite ? "star.slash" : "star"
                                        )
                                    }
                                    .tint(.yellow)
                                }
                        }
                    } header: {
                        sectionHeader(
                            title: category.name,
                            icon: category.icon,
                            color: category.color
                        )
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .refreshable {
            viewModel.loadData()
        }
    }
    
    // MARK: - 分区标题
    
    private func sectionHeader(title: String, icon: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.subheadline)
            
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - 空状态视图
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "key.slash")
                .font(.system(size: 60))
                .foregroundColor(.secondary.opacity(0.5))
            
            VStack(spacing: 8) {
                Text(searchText.isEmpty ? "暂无密码" : "无搜索结果")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(searchText.isEmpty ? "点击右上角添加您的第一个密码" : "尝试其他搜索词")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            if searchText.isEmpty {
                Button {
                    showAddPassword = true
                } label: {
                    Label("添加密码", systemImage: "plus")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color(hex: "#e94560") ?? .red)
                        .cornerRadius(12)
                }
            }
        }
        .padding()
    }
    
    // MARK: - 筛选按钮
    
    private var filterButton: some View {
        Button {
            showCategoryFilter = true
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "line.3.horizontal.decrease.circle")
                if let category = selectedCategory {
                    Text(category.name)
                        .font(.caption)
                }
            }
        }
    }
    
    // MARK: - 添加按钮
    
    private var addButton: some View {
        Button {
            showAddPassword = true
        } label: {
            Image(systemName: "plus")
        }
    }
}

// MARK: - 分类筛选表单

struct CategoryFilterSheet: View {
    let categories: [Category]
    @Binding var selectedCategory: Category?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Button {
                    selectedCategory = nil
                    dismiss()
                } label: {
                    HStack {
                        Image(systemName: "tray.full.fill")
                            .foregroundColor(.blue)
                        Text("全部")
                        Spacer()
                        if selectedCategory == nil {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
                .foregroundColor(.primary)
                
                ForEach(categories) { category in
                    Button {
                        selectedCategory = category
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: category.icon)
                                .foregroundColor(category.color)
                            Text(category.name)
                            Spacer()
                            if selectedCategory?.id == category.id {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .foregroundColor(.primary)
                }
            }
            .navigationTitle("选择分类")
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
    PasswordListView()
}

