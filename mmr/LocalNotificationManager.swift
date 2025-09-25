//
//  LocalNotificationManager.swift
//  mmr
//
//  Created by doff on 2025/9/24.
//

import Foundation
import UserNotifications
import UIKit
import Combine

// 通知動作類型
enum NotificationAction: String, CaseIterable {
    case taken = "TAKEN_ACTION"
    case remindLater = "REMIND_LATER_ACTION"
    
    var title: String {
        switch self {
        case .taken:
            return "我吃了 ✓"
        case .remindLater:
            return "晚點提醒我"
        }
    }
    
    var identifier: String {
        return self.rawValue
    }
}

// 通知類別
enum NotificationCategory: String {
    case medicationReminder = "MEDICATION_REMINDER"
    
    var identifier: String {
        return self.rawValue
    }
}

// 通知資料模型
struct MedicationNotification {
    let medicationId: UUID
    let medicationName: String
    let dosage: String
    let scheduledTime: Date
    let reminderMinutesBefore: Int
    
    var notificationIdentifier: String {
        return "medication_\(medicationId.uuidString)_\(Int(scheduledTime.timeIntervalSince1970))"
    }
    
    var triggerDate: Date {
        return Calendar.current.date(byAdding: .minute, value: -reminderMinutesBefore, to: scheduledTime) ?? scheduledTime
    }
}

@MainActor
class LocalNotificationManager: NSObject, ObservableObject {
    static let shared = LocalNotificationManager()
    
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @Published var isEnabled = false
    
    private let center = UNUserNotificationCenter.current()
    
    override init() {
        super.init()
        center.delegate = self
        setupNotificationCategories()
        checkAuthorizationStatus()
    }
    
    // MARK: - 權限管理
    
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            await MainActor.run {
                self.authorizationStatus = granted ? .authorized : .denied
                self.isEnabled = granted
            }
            return granted
        } catch {
            print("通知權限請求失敗: \(error)")
            await MainActor.run {
                self.authorizationStatus = .denied
                self.isEnabled = false
            }
            return false
        }
    }
    
    func checkAuthorizationStatus() {
        center.getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.authorizationStatus = settings.authorizationStatus
                self.isEnabled = settings.authorizationStatus == .authorized
            }
        }
    }
    
    // MARK: - 通知類別設定
    
    private func setupNotificationCategories() {
        let takenAction = UNNotificationAction(
            identifier: NotificationAction.taken.identifier,
            title: NotificationAction.taken.title,
            options: [.foreground]
        )
        
        let remindLaterAction = UNNotificationAction(
            identifier: NotificationAction.remindLater.identifier,
            title: NotificationAction.remindLater.title,
            options: []
        )
        
        let medicationCategory = UNNotificationCategory(
            identifier: NotificationCategory.medicationReminder.identifier,
            actions: [takenAction, remindLaterAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        
        center.setNotificationCategories([medicationCategory])
    }
    
    // MARK: - 通知排程管理
    
    func scheduleMedicationNotifications(for medication: Medication) async {
        guard isEnabled else {
            print("通知未啟用，無法排程通知")
            return
        }
        
        // 先移除該藥物的所有現有通知
        await removeMedicationNotifications(for: medication.id)
        
        let calendar = Calendar.current
        let today = Date()
        
        // 為接下來 30 天排程通知
        for dayOffset in 0..<30 {
            guard let targetDate = calendar.date(byAdding: .day, value: dayOffset, to: today) else { continue }
            
            // 解析通知時間 (假設 notificationTimes 是 ["08:00", "20:00"] 格式)
            for timeString in medication.notificationTimes {
                if let scheduledTime = parseTimeString(timeString, for: targetDate) {
                    let notification = MedicationNotification(
                        medicationId: medication.id,
                        medicationName: medication.name,
                        dosage: medication.dosage,
                        scheduledTime: scheduledTime,
                        reminderMinutesBefore: 0 // 可以從設定中取得
                    )
                    
                    await scheduleNotification(notification)
                }
            }
        }
    }
    
    func scheduleNotification(_ notification: MedicationNotification) async {
        let content = UNMutableNotificationContent()
        content.title = "用藥提醒"
        content.body = "該服用 \(notification.medicationName) (\(notification.dosage)) 了"
        content.sound = .default
        content.categoryIdentifier = NotificationCategory.medicationReminder.identifier
        
        // 添加用戶資訊，用於處理通知動作
        content.userInfo = [
            "medicationId": notification.medicationId.uuidString,
            "medicationName": notification.medicationName,
            "dosage": notification.dosage,
            "scheduledTime": notification.scheduledTime.timeIntervalSince1970
        ]
        
        // 設定觸發時間
        let triggerDate = notification.triggerDate
        let dateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: notification.notificationIdentifier,
            content: content,
            trigger: trigger
        )
        
        do {
            try await center.add(request)
            print("已排程通知: \(notification.medicationName) at \(triggerDate)")
        } catch {
            print("排程通知失敗: \(error)")
        }
    }
    
    func removeMedicationNotifications(for medicationId: UUID) async {
        let pendingRequests = await center.pendingNotificationRequests()
        let identifiersToRemove = pendingRequests
            .filter { $0.identifier.contains(medicationId.uuidString) }
            .map { $0.identifier }
        
        center.removePendingNotificationRequests(withIdentifiers: identifiersToRemove)
        print("已移除 \(identifiersToRemove.count) 個通知，藥物ID: \(medicationId)")
    }
    
    func removeAllMedicationNotifications() async {
        center.removeAllPendingNotificationRequests()
        print("已移除所有待發送的通知")
    }
    
    // MARK: - 通知動作處理
    
    func handleNotificationAction(_ actionIdentifier: String, userInfo: [AnyHashable: Any]) async {
        guard let medicationIdString = userInfo["medicationId"] as? String,
              let medicationId = UUID(uuidString: medicationIdString),
              let medicationName = userInfo["medicationName"] as? String,
              let dosage = userInfo["dosage"] as? String,
              let scheduledTimeInterval = userInfo["scheduledTime"] as? TimeInterval else {
            print("通知用戶資訊不完整")
            return
        }
        
        let scheduledTime = Date(timeIntervalSince1970: scheduledTimeInterval)
        
        switch actionIdentifier {
        case NotificationAction.taken.identifier:
            await handleMedicationTaken(
                medicationId: medicationId,
                medicationName: medicationName,
                dosage: dosage,
                scheduledTime: scheduledTime
            )
            
        case NotificationAction.remindLater.identifier:
            await handleRemindLater(
                medicationId: medicationId,
                medicationName: medicationName,
                dosage: dosage,
                scheduledTime: scheduledTime
            )
            
        default:
            print("未知的通知動作: \(actionIdentifier)")
        }
    }
    
    private func handleMedicationTaken(medicationId: UUID, medicationName: String, dosage: String, scheduledTime: Date) async {
        print("用戶已服用藥物: \(medicationName) (\(dosage)) at \(scheduledTime)")
        
        // 實際實作時，這裡會呼叫 Supabase API
        // let adherenceLog = AdherenceLog(...)
        // await supabaseClient.insert(adherenceLog)
        
        // 暫時只是印出日誌
        print("服藥記錄已儲存到資料庫")
        
        // 發送本地通知確認
        await sendConfirmationNotification(medicationName: medicationName)
    }
    
    private func handleRemindLater(medicationId: UUID, medicationName: String, dosage: String, scheduledTime: Date) async {
        // 設定 15 分鐘後再次提醒
        let remindTime = Date().addingTimeInterval(15 * 60) // 15分鐘
        
        let notification = MedicationNotification(
            medicationId: medicationId,
            medicationName: medicationName,
            dosage: dosage,
            scheduledTime: remindTime,
            reminderMinutesBefore: 0
        )
        
        await scheduleNotification(notification)
        print("已設定 15 分鐘後再次提醒: \(medicationName)")
    }
    
    private func sendConfirmationNotification(medicationName: String) async {
        let content = UNMutableNotificationContent()
        content.title = "服藥記錄已更新"
        content.body = "已記錄您服用了 \(medicationName)"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "confirmation_\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        
        do {
            try await center.add(request)
        } catch {
            print("發送確認通知失敗: \(error)")
        }
    }
    
    // MARK: - 輔助方法
    
    private func parseTimeString(_ timeString: String, for date: Date) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        
        guard let time = formatter.date(from: timeString) else { return nil }
        
        let calendar = Calendar.current
        let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
        
        return calendar.date(bySettingHour: timeComponents.hour ?? 0,
                           minute: timeComponents.minute ?? 0,
                           second: 0,
                           of: date)
    }
    
    // MARK: - 調試方法
    
    func getPendingNotifications() async -> [UNNotificationRequest] {
        return await center.pendingNotificationRequests()
    }
    
    func printPendingNotifications() async {
        let requests = await getPendingNotifications()
        print("待發送的通知數量: \(requests.count)")
        
        for request in requests {
            if let trigger = request.trigger as? UNCalendarNotificationTrigger,
               let nextTriggerDate = trigger.nextTriggerDate() {
                print("- \(request.identifier): \(nextTriggerDate)")
            }
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension LocalNotificationManager: UNUserNotificationCenterDelegate {
    
    // 當 App 在前景時收到通知
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        // 在前景時也顯示通知
        completionHandler([.banner, .sound, .badge])
    }
    
    // 當用戶點擊通知或通知動作時
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
        let actionIdentifier = response.actionIdentifier
        let userInfo = response.notification.request.content.userInfo
        
        Task {
            await handleNotificationAction(actionIdentifier, userInfo: userInfo)
        }
        
        completionHandler()
    }
}

// MARK: - 擴展 Medication 以支援通知

extension Medication {
    func toNotifications(reminderMinutesBefore: Int = 0) -> [MedicationNotification] {
        let calendar = Calendar.current
        let today = Date()
        var notifications: [MedicationNotification] = []
        
        // 為接下來 30 天生成通知
        for dayOffset in 0..<30 {
            guard let targetDate = calendar.date(byAdding: .day, value: dayOffset, to: today) else { continue }
            
            for timeString in notificationTimes {
                if let scheduledTime = parseTimeString(timeString, for: targetDate) {
                    let notification = MedicationNotification(
                        medicationId: id,
                        medicationName: name,
                        dosage: dosage,
                        scheduledTime: scheduledTime,
                        reminderMinutesBefore: reminderMinutesBefore
                    )
                    notifications.append(notification)
                }
            }
        }
        
        return notifications
    }
    
    private func parseTimeString(_ timeString: String, for date: Date) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        
        guard let time = formatter.date(from: timeString) else { return nil }
        
        let calendar = Calendar.current
        let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
        
        return calendar.date(bySettingHour: timeComponents.hour ?? 0,
                           minute: timeComponents.minute ?? 0,
                           second: 0,
                           of: date)
    }
}