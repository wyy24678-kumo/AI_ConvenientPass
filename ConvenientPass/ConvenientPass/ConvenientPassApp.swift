//
//  ConvenientPassApp.swift
//  ConvenientPass
//
//  Created by kumo.wang on 2025/12/11.
//

import SwiftUI

@main
struct ConvenientPassApp: App {
    
    // MARK: - 状态
    
    @StateObject private var appState = AppState.shared
    @Environment(\.scenePhase) private var scenePhase
    
    // MARK: - Body
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .onChange(of: scenePhase) { _, newPhase in
                    handleScenePhaseChange(newPhase)
                }
        }
    }
    
    // MARK: - 场景变化处理
    
    private func handleScenePhaseChange(_ phase: ScenePhase) {
        switch phase {
        case .background:
            // 进入后台时锁定应用
            if appState.settings.autoLockTimeout == 0 {
                appState.lockApp()
            }
        case .inactive:
            break
        case .active:
            break
        @unknown default:
            break
        }
    }
}

// MARK: - 根视图

struct RootView: View {
    
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        Group {
            if !appState.hasMasterPassword {
                // 首次使用，设置主密码
                SetupMasterPasswordView()
            } else if !appState.isUnlocked {
                // 需要解锁
                LockScreenView()
            } else {
                // 已解锁，显示主界面
                MainTabView()
            }
        }
        .animation(.easeInOut, value: appState.isUnlocked)
        .animation(.easeInOut, value: appState.hasMasterPassword)
    }
}

// MARK: - Preview

#Preview {
    RootView()
        .environmentObject(AppState.shared)
}
