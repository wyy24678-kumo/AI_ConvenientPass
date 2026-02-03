//
//  MainTabView.swift
//  ConvenientPass
//
//  主页面标签视图
//

import SwiftUI

struct MainTabView: View {
    
    // MARK: - 环境
    
    @EnvironmentObject var appState: AppState
    @State private var selectedTab: TabItem = .passwords
    
    // MARK: - Body
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // 密码库
            PasswordListView()
                .tabItem {
                    Label(TabItem.passwords.title, systemImage: TabItem.passwords.icon)
                }
                .tag(TabItem.passwords)
            
            // 密码生成器
            GeneratorView()
                .tabItem {
                    Label(TabItem.generator.title, systemImage: TabItem.generator.icon)
                }
                .tag(TabItem.generator)
            
            // 安全检测
            SecurityCheckView()
                .tabItem {
                    Label(TabItem.security.title, systemImage: TabItem.security.icon)
                }
                .tag(TabItem.security)
            
            // 设置
            SettingsView()
                .tabItem {
                    Label(TabItem.settings.title, systemImage: TabItem.settings.icon)
                }
                .tag(TabItem.settings)
        }
        .tint(Color(hex: "#e94560") ?? .red)
        .onChange(of: selectedTab) { _, newValue in
            appState.selectedTab = newValue
        }
    }
}

// MARK: - Preview

#Preview {
    MainTabView()
        .environmentObject(AppState.shared)
}

