//
//  AddMedicationView.swift
//  mmr
//
//  Created by doff on 2025/9/24.
//

import SwiftUI
import Foundation
import Combine
import Supabase

// 新增藥物的步驟
enum AddMedicationStep: Int, CaseIterable {
    case basicInfo = 0
    case schedule = 1
    case notifications = 2
    case confirmation = 3
    
    var title: String {
        switch self {
        case .basicInfo:
            return "基本資訊"
        case .schedule:
            return "服用時間"
        case .notifications:
            return "提醒設定"
        case .confirmation:
            return "確認資訊"
        }
    }
    
    var description: String {
        switch self {
        case .basicInfo:
            return "請輸入藥物的基本資訊"
        case .schedule:
            return "設定每日服用時間"
        case .notifications:
            return "設定提醒通知"
        case .confirmation:
            return "確認所有資訊無誤"
        }
    }
}

// 排程類型
enum ScheduleType: String, CaseIterable {
    case daily = "daily"
    case weekly = "weekly"
    case asNeeded = "as_needed"
    case custom = "custom"
    
    var displayName: String {
        switch self {
        case .daily:
            return "每日"
        case .weekly:
            return "每週"
        case .asNeeded:
            return "需要時"
        case .custom:
            return "自訂"
        }
    }
}

@MainActor
class AddMedicationViewModel: ObservableObject {
    @Published var currentStep: AddMedicationStep = .basicInfo
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // 基本資訊
    @Published var medicationName = ""
    @Published var dosage = ""
    @Published var scheduleType: ScheduleType = .daily
    
    // 服用時間
    @Published var notificationTimes: [Date] = []
    @Published var selectedTime = Date()
    
    // 提醒設定
    @Published var enableNotifications = true
    @Published var reminderMinutesBefore = 5
    
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
    
    var canProceedToNext: Bool {
        switch currentStep {
        case .basicInfo:
            return !medicationName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                   !dosage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .schedule:
            return !notificationTimes.isEmpty
        case .notifications:
            return true
        case .confirmation:
            return true
        }
    }
    
    var isLastStep: Bool {
        currentStep == AddMedicationStep.allCases.last
    }
    
    func nextStep() {
        guard canProceedToNext else { return }
        
        if let nextStep = AddMedicationStep(rawValue: currentStep.rawValue + 1) {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentStep = nextStep
            }
        }
    }
    
    func previousStep() {
        if let previousStep = AddMedicationStep(rawValue: currentStep.rawValue - 1) {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentStep = previousStep
            }
        }
    }
    
    func addNotificationTime() {
        // 檢查是否已存在相同時間
        let timeString = timeFormatter.string(from: selectedTime)
        let existingTimeStrings = notificationTimes.map { timeFormatter.string(from: $0) }
        
        if !existingTimeStrings.contains(timeString) {
            notificationTimes.append(selectedTime)
            notificationTimes.sort()
        }
    }
    
    func removeNotificationTime(at index: Int) {
        guard index < notificationTimes.count else { return }
        notificationTimes.remove(at: index)
    }
    
    func saveMedication() async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            // 獲取當前用戶 ID
            guard let userId = await SupabaseManager.shared.getCurrentUserId() else {
                await MainActor.run {
                    self.errorMessage = "無法獲取用戶資訊"
                    self.isLoading = false
                }
                return false
            }
            
            // 準備要儲存的藥物資料
            struct MedicationData: Encodable {
                let user_id: String
                let name: String
                let dosage: String
                let schedule_type: String
                let notification_times: [String]
                let is_active: Bool
            }
            
            let medicationData = MedicationData(
                user_id: userId,
                name: medicationName,
                dosage: dosage,
                schedule_type: scheduleType.rawValue,
                notification_times: notificationTimes.map { timeFormatter.string(from: $0) },
                is_active: true
            )
            
            // 儲存到 Supabase
            _ = try await SupabaseManager.shared.client
                .from("medications")
                .insert(medicationData)
                .execute()
            
            print("✅ 藥物資料已成功儲存")
            
            await MainActor.run {
                self.isLoading = false
            }
            
            return true
        } catch {
            print("❌ 儲存藥物資料失敗: \(error)")
            await MainActor.run {
                self.errorMessage = "儲存藥物失敗：\(error.localizedDescription)"
                self.isLoading = false
            }
            return false
        }
    }
    
    func reset() {
        currentStep = .basicInfo
        medicationName = ""
        dosage = ""
        scheduleType = .daily
        notificationTimes = []
        selectedTime = Date()
        enableNotifications = true
        reminderMinutesBefore = 5
        errorMessage = nil
    }
}

struct AddMedicationView: View {
    @StateObject private var viewModel = AddMedicationViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                // 背景漸層
                LinearGradient(
                    gradient: Gradient(colors: [
                        Theme.Colors.background,
                        Theme.Colors.backgroundSecondary
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // 進度指示器
                    ProgressIndicator(
                        currentStep: viewModel.currentStep.rawValue,
                        totalSteps: AddMedicationStep.allCases.count
                    )
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    
                    // 步驟標題
                    VStack(alignment: .leading, spacing: 8) {
                        Text(viewModel.currentStep.title)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(Theme.Colors.textPrimary)
                        
                        Text(viewModel.currentStep.description)
                            .font(.body)
                            .foregroundColor(Theme.Colors.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 20)
                    
                    // 步驟內容
                    ScrollView {
                        VStack(spacing: 24) {
                            switch viewModel.currentStep {
                            case .basicInfo:
                                BasicInfoStep(viewModel: viewModel)
                            case .schedule:
                                ScheduleStep(viewModel: viewModel)
                            case .notifications:
                                NotificationsStep(viewModel: viewModel)
                            case .confirmation:
                                ConfirmationStep(viewModel: viewModel)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 100) // 為底部按鈕留空間
                    }
                    
                    Spacer()
                }
                
                // 底部按鈕
                VStack {
                    Spacer()
                    
                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(Theme.Colors.error)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                            .padding(.bottom, 8)
                    }
                    
                    HStack(spacing: 16) {
                        // 上一步按鈕
                        if viewModel.currentStep != .basicInfo {
                            Button(action: {
                                viewModel.previousStep()
                            }) {
                                Text("上一步")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(Theme.Colors.primary)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Theme.Colors.primary, lineWidth: 2)
                                    )
                            }
                        }
                        
                        // 下一步/完成按鈕
                        Button(action: {
                            if viewModel.isLastStep {
                                Task {
                                    let success = await viewModel.saveMedication()
                                    if success {
                                        dismiss()
                                    }
                                }
                            } else {
                                viewModel.nextStep()
                            }
                        }) {
                            HStack {
                                if viewModel.isLoading {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .tint(.white)
                                } else {
                                    Text(viewModel.isLastStep ? "完成" : "下一步")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                }
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(viewModel.canProceedToNext ? Theme.Colors.primary : Theme.Colors.textTertiary)
                            )
                        }
                        .disabled(!viewModel.canProceedToNext || viewModel.isLoading)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 34)
                }
            }
            .navigationTitle("新增藥物")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                    .foregroundColor(Theme.Colors.textSecondary)
                }
            }
        }
    }
}

// 進度指示器
struct ProgressIndicator: View {
    let currentStep: Int
    let totalSteps: Int
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalSteps, id: \.self) { step in
                RoundedRectangle(cornerRadius: 2)
                    .fill(step <= currentStep ? Theme.Colors.primary : Theme.Colors.textTertiary.opacity(0.3))
                    .frame(height: 4)
                    .animation(.easeInOut(duration: 0.3), value: currentStep)
            }
        }
    }
}

// 基本資訊步驟
struct BasicInfoStep: View {
    @ObservedObject var viewModel: AddMedicationViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            // 藥物名稱
            VStack(alignment: .leading, spacing: 8) {
                Text("藥物名稱")
                    .font(.headline)
                    .foregroundColor(Theme.Colors.textPrimary)
                
                TextField("請輸入藥物名稱", text: $viewModel.medicationName)
                    .textFieldStyle(GlassTextFieldStyle())
            }
            
            // 劑量
            VStack(alignment: .leading, spacing: 8) {
                Text("劑量")
                    .font(.headline)
                    .foregroundColor(Theme.Colors.textPrimary)
                
                TextField("例如：5mg、1顆、10ml", text: $viewModel.dosage)
                    .textFieldStyle(GlassTextFieldStyle())
            }
            
            // 排程類型
            VStack(alignment: .leading, spacing: 8) {
                Text("服用頻率")
                    .font(.headline)
                    .foregroundColor(Theme.Colors.textPrimary)
                
                Picker("排程類型", selection: $viewModel.scheduleType) {
                    ForEach(ScheduleType.allCases, id: \.self) { type in
                        Text(type.displayName).tag(type)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }
        }
    }
}

// 服用時間步驟
struct ScheduleStep: View {
    @ObservedObject var viewModel: AddMedicationViewModel
    
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
    
    var body: some View {
        VStack(spacing: 20) {
            // 時間選擇器
            VStack(alignment: .leading, spacing: 8) {
                Text("選擇服用時間")
                    .font(.headline)
                    .foregroundColor(Theme.Colors.textPrimary)
                
                HStack {
                    DatePicker("", selection: $viewModel.selectedTime, displayedComponents: .hourAndMinute)
                        .datePickerStyle(WheelDatePickerStyle())
                        .labelsHidden()
                    
                    Spacer()
                    
                    Button(action: {
                        viewModel.addNotificationTime()
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(Theme.Colors.primary)
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Theme.Colors.glassBackground.opacity(0.3))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Theme.Colors.glassBorder, lineWidth: 1)
                        )
                )
            }
            
            // 已選擇的時間列表
            if !viewModel.notificationTimes.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("已設定的服用時間")
                        .font(.headline)
                        .foregroundColor(Theme.Colors.textPrimary)
                    
                    LazyVStack(spacing: 8) {
                        ForEach(Array(viewModel.notificationTimes.enumerated()), id: \.offset) { index, time in
                            HStack {
                                Image(systemName: "clock")
                                    .foregroundColor(Theme.Colors.primary)
                                
                                Text(timeFormatter.string(from: time))
                                    .font(.body)
                                    .foregroundColor(Theme.Colors.textPrimary)
                                
                                Spacer()
                                
                                Button(action: {
                                    viewModel.removeNotificationTime(at: index)
                                }) {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundColor(Theme.Colors.error)
                                }
                            }
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Theme.Colors.glassBackground.opacity(0.2))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Theme.Colors.glassBorder, lineWidth: 1)
                                    )
                            )
                        }
                    }
                }
            }
        }
    }
}

// 通知設定步驟
struct NotificationsStep: View {
    @ObservedObject var viewModel: AddMedicationViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            // 啟用通知
            VStack(alignment: .leading, spacing: 8) {
                Toggle(isOn: $viewModel.enableNotifications) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("啟用推播通知")
                            .font(.headline)
                            .foregroundColor(Theme.Colors.textPrimary)
                        
                        Text("在服用時間提醒您")
                            .font(.caption)
                            .foregroundColor(Theme.Colors.textSecondary)
                    }
                }
                .toggleStyle(SwitchToggleStyle(tint: Theme.Colors.primary))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Theme.Colors.glassBackground.opacity(0.3))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Theme.Colors.glassBorder, lineWidth: 1)
                    )
            )
            
            if viewModel.enableNotifications {
                // 提前提醒時間
                VStack(alignment: .leading, spacing: 8) {
                    Text("提前提醒")
                        .font(.headline)
                        .foregroundColor(Theme.Colors.textPrimary)
                    
                    Picker("提醒時間", selection: $viewModel.reminderMinutesBefore) {
                        Text("準時").tag(0)
                        Text("5分鐘前").tag(5)
                        Text("10分鐘前").tag(10)
                        Text("15分鐘前").tag(15)
                        Text("30分鐘前").tag(30)
                    }
                    .pickerStyle(WheelPickerStyle())
                    .frame(height: 120)
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Theme.Colors.glassBackground.opacity(0.3))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Theme.Colors.glassBorder, lineWidth: 1)
                        )
                )
            }
        }
    }
}

// 確認資訊步驟
struct ConfirmationStep: View {
    @ObservedObject var viewModel: AddMedicationViewModel
    
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
    
    var body: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 16) {
                Text("請確認以下資訊")
                    .font(.headline)
                    .foregroundColor(Theme.Colors.textPrimary)
                
                // 藥物資訊
                InfoRow(title: "藥物名稱", value: viewModel.medicationName)
                InfoRow(title: "劑量", value: viewModel.dosage)
                InfoRow(title: "服用頻率", value: viewModel.scheduleType.displayName)
                
                // 服用時間
                VStack(alignment: .leading, spacing: 8) {
                    Text("服用時間")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(Theme.Colors.textSecondary)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(viewModel.notificationTimes, id: \.self) { time in
                            Text("• \(timeFormatter.string(from: time))")
                                .font(.body)
                                .foregroundColor(Theme.Colors.textPrimary)
                        }
                    }
                }
                
                // 通知設定
                InfoRow(
                    title: "推播通知",
                    value: viewModel.enableNotifications ? "已啟用" : "已停用"
                )
                
                if viewModel.enableNotifications && viewModel.reminderMinutesBefore > 0 {
                    InfoRow(
                        title: "提前提醒",
                        value: "\(viewModel.reminderMinutesBefore)分鐘前"
                    )
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Theme.Colors.glassBackground.opacity(0.3))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Theme.Colors.glassBorder, lineWidth: 1)
                    )
            )
        }
    }
}

struct InfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(Theme.Colors.textSecondary)
            
            Text(value)
                .font(.body)
                .foregroundColor(Theme.Colors.textPrimary)
        }
    }
}

// 玻璃擬態文字輸入框樣式
struct GlassTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Theme.Colors.glassBackground.opacity(0.3))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Theme.Colors.glassBorder, lineWidth: 1)
                    )
            )
            .foregroundColor(Theme.Colors.textPrimary)
    }
}

#Preview {
    AddMedicationView()
}