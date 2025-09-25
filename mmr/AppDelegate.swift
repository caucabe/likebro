//
//  AppDelegate.swift
//  mmr
//
//  Created by doff on 2025/9/24.
//

import UIKit
import UserNotifications
import Foundation
import Supabase

class AppDelegate: NSObject, UIApplicationDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // 初始化 Supabase 客戶端
        // 客戶端已在 SupabaseClient.swift 中配置
        
        // 設定通知中心的代理
        UNUserNotificationCenter.current().delegate = LocalNotificationManager.shared
        
        // 請求通知權限
        Task {
            await LocalNotificationManager.shared.requestAuthorization()
        }
        
        // 設定應用程式圖示徽章數字
        Task {
            try? await UNUserNotificationCenter.current().setBadgeCount(0)
        }
        
        print("AppDelegate: 應用程式啟動完成")
        return true
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        // 處理 Supabase OAuth 回調
        return true
    }
    
    // MARK: - 背景處理
    
    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        // 背景更新處理
        print("AppDelegate: 執行背景更新")
        
        Task {
            // 這裡可以執行背景資料同步
            // 例如：同步服藥記錄、更新通知等
            await syncMedicationData()
            completionHandler(.newData)
        }
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        print("AppDelegate: 應用程式進入背景")
        
        // 設定背景任務
        var backgroundTask: UIBackgroundTaskIdentifier = .invalid
        
        backgroundTask = application.beginBackgroundTask(withName: "SyncMedicationData") {
            // 背景任務即將結束時的清理工作
            application.endBackgroundTask(backgroundTask)
            backgroundTask = .invalid
        }
        
        Task {
            // 執行必要的背景同步
            await syncMedicationData()
            
            // 結束背景任務
            application.endBackgroundTask(backgroundTask)
            backgroundTask = .invalid
        }
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        print("AppDelegate: 應用程式即將進入前景")
        
        // 清除應用程式徽章 - 使用版本兼容處理
        if #available(iOS 16.0, *) {
            Task {
                do {
                    try await UNUserNotificationCenter.current().setBadgeCount(0)
                } catch {
                    print("清除徽章失敗: \(error)")
                }
            }
        } else {
            application.applicationIconBadgeNumber = 0
        }
        
        // 檢查通知權限狀態
        LocalNotificationManager.shared.checkAuthorizationStatus()
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        print("AppDelegate: 應用程式已變為活躍狀態")
        
        // 同步資料
        Task {
            await syncMedicationData()
        }
    }
    
    // MARK: - 通知處理
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        print("AppDelegate: 收到遠端通知")
        
        Task {
            // 處理遠端通知
            await handleRemoteNotification(userInfo: userInfo)
            completionHandler(.newData)
        }
    }
    
    // MARK: - 資料同步
    
    private func syncMedicationData() async {
        print("AppDelegate: 開始同步用藥資料")
        
        // 這裡應該實作與 Supabase 的資料同步
        // 1. 同步用戶的藥物清單
        // 2. 同步服藥記錄
        // 3. 更新本地通知排程
        
        // 模擬 API 呼叫
        do {
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1秒
            print("AppDelegate: 資料同步完成")
        } catch {
            print("AppDelegate: 資料同步失敗 - \(error)")
        }
    }
    
    private func handleRemoteNotification(userInfo: [AnyHashable: Any]) async {
        print("AppDelegate: 處理遠端通知內容")
        
        // 解析通知內容
        if let notificationType = userInfo["type"] as? String {
            switch notificationType {
            case "medication_reminder":
                await handleMedicationReminderNotification(userInfo: userInfo)
            case "adherence_update":
                await handleAdherenceUpdateNotification(userInfo: userInfo)
            default:
                print("未知的通知類型: \(notificationType)")
            }
        }
    }
    
    private func handleMedicationReminderNotification(userInfo: [AnyHashable: Any]) async {
        print("AppDelegate: 處理用藥提醒通知")
        
        // 這裡可以更新本地資料或觸發特定動作
        // 例如：更新 UI、發送本地通知等
    }
    
    private func handleAdherenceUpdateNotification(userInfo: [AnyHashable: Any]) async {
        print("AppDelegate: 處理服藥記錄更新通知")
        
        // 同步服藥記錄
        await syncMedicationData()
    }
}

// MARK: - Supabase 整合擴展

extension AppDelegate {
    
    /// 記錄服藥到 Supabase adherence_logs 表格
    func logMedicationAdherence(medicationId: UUID, takenAt: Date, scheduledTime: Date) async throws {
        print("AppDelegate: 記錄服藥到資料庫")
        
        // 建立服藥記錄
        let adherenceLog = AdherenceLogRequest(
            medicationId: medicationId,
            scheduledTime: scheduledTime,
            actualTime: takenAt,
            status: "taken",
            notes: "透過通知動作記錄"
        )
        
        // 這裡應該實作實際的 Supabase API 呼叫
        // 目前使用模擬實作
        do {
            // 模擬 API 呼叫延遲
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5秒
            
            // 實際實作時會使用 adherenceLog 進行 API 呼叫
            // try await supabaseClient.from("adherence_logs").insert(adherenceLog)
            
            print("AppDelegate: 服藥記錄已成功儲存到資料庫")
            print("  - 藥物ID: \(adherenceLog.medicationId)")
            print("  - 預定時間: \(adherenceLog.scheduledTime)")
            print("  - 實際時間: \(adherenceLog.actualTime)")
            
            // 發送成功通知
            await sendSuccessNotification(message: "服藥記錄已更新")
            
        } catch {
            print("AppDelegate: 儲存服藥記錄失敗 - \(error)")
            throw error
        }
    }
    
    /// 發送成功通知
    private func sendSuccessNotification(message: String) async {
        let content = UNMutableNotificationContent()
        content.title = "記錄成功"
        content.body = message
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "success_\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        
        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            print("發送成功通知失敗: \(error)")
        }
    }
}

// MARK: - 資料模型

/// 服藥記錄請求模型
struct AdherenceLogRequest: Codable {
    let medicationId: UUID
    let scheduledTime: Date
    let actualTime: Date
    let status: String
    let notes: String?
    
    enum CodingKeys: String, CodingKey {
        case medicationId = "medication_id"
        case scheduledTime = "scheduled_time"
        case actualTime = "actual_time"
        case status
        case notes
    }
}

// MARK: - 通知動作處理擴展

extension AppDelegate {
    
    /// 處理「我吃了」通知動作
    func handleMedicationTakenAction(medicationId: UUID, scheduledTime: Date) async {
        print("AppDelegate: 處理「我吃了」動作")
        
        let takenAt = Date()
        
        do {
            // 記錄到資料庫
            try await logMedicationAdherence(
                medicationId: medicationId,
                takenAt: takenAt,
                scheduledTime: scheduledTime
            )
            
            // 更新應用程式徽章
            await updateAppBadge()
            
            print("AppDelegate: 「我吃了」動作處理完成")
            
        } catch {
            print("AppDelegate: 處理「我吃了」動作失敗 - \(error)")
            
            // 發送錯誤通知
            await sendErrorNotification(message: "記錄服藥失敗，請稍後再試")
        }
    }
    
    /// 處理「晚點提醒我」通知動作
    func handleRemindLaterAction(medicationId: UUID, medicationName: String, dosage: String, originalScheduledTime: Date) async {
        print("AppDelegate: 處理「晚點提醒我」動作")
        
        // 設定 15 分鐘後提醒
        let remindTime = Date().addingTimeInterval(15 * 60)
        
        let notification = MedicationNotification(
            medicationId: medicationId,
            medicationName: medicationName,
            dosage: dosage,
            scheduledTime: remindTime,
            reminderMinutesBefore: 0
        )
        
        await LocalNotificationManager.shared.scheduleNotification(notification)
        
        print("AppDelegate: 已設定 15 分鐘後再次提醒")
    }
    
    /// 更新應用程式徽章數字
    private func updateAppBadge() async {
        // 這裡可以計算未服用的藥物數量來設定徽章
        // 目前簡單設為 0
        do {
            try await UNUserNotificationCenter.current().setBadgeCount(0)
        } catch {
            print("更新應用程式徽章失敗: \(error)")
        }
    }
    
    /// 發送錯誤通知
    private func sendErrorNotification(message: String) async {
        let content = UNMutableNotificationContent()
        content.title = "操作失敗"
        content.body = message
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "error_\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        
        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            print("發送錯誤通知失敗: \(error)")
        }
    }
}