//
//  mmrApp.swift
//  mmr
//
//  Created by doff on 2025/9/24.
//

import SwiftUI
import UserNotifications
import Supabase

@main
struct mmrApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var notificationManager = LocalNotificationManager.shared
    
    init() {
        // 初始化 SupabaseManager 以觸發配置日誌
        _ = SupabaseManager.shared
    }
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authViewModel)
                .environmentObject(notificationManager)
                .onOpenURL { url in
                    // 處理 Supabase OAuth 回調
                    print("收到 URL: \(url)")
                    SupabaseManager.shared.client.handle(url)
                }
        }
    }
}
