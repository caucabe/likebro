//
//  HomeView.swift
//  mmr
//
//  Created by doff on 2025/9/24.
//

import SwiftUI
import Foundation
import Combine

// 藥物資料模型
struct Medication: Identifiable, Codable {
    let id: UUID
    let userId: UUID
    let name: String
    let dosage: String
    let scheduleType: String
    let notificationTimes: [String] // JSON 格式的時間陣列
    let isActive: Bool
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case name
        case dosage
        case scheduleType = "schedule_type"
        case notificationTimes = "notification_times"
        case isActive = "is_active"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// 服藥記錄模型
struct AdherenceLog: Identifiable, Codable {
    let id: UUID
    let medicationId: UUID
    let userId: UUID
    let status: String // "taken", "missed", "skipped"
    let scheduledTime: Date
    let loggedAt: Date
    let notes: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case medicationId = "medication_id"
        case userId = "user_id"
        case status
        case scheduledTime = "scheduled_time"
        case loggedAt = "logged_at"
        case notes
    }
}

// 今日用藥排程項目
struct TodayMedicationSchedule: Identifiable {
    let id = UUID()
    let medication: Medication
    let scheduledTime: Date
    var status: MedicationStatus
    
    enum MedicationStatus {
        case pending
        case taken
        case missed
        
        var color: Color {
            switch self {
            case .pending:
                return Theme.Colors.primary
            case .taken:
                return Theme.Colors.success
            case .missed:
                return Theme.Colors.error
            }
        }
        
        var icon: String {
            switch self {
            case .pending:
                return "clock"
            case .taken:
                return "checkmark.circle.fill"
            case .missed:
                return "exclamationmark.triangle.fill"
            }
        }
        
        var displayText: String {
            switch self {
            case .pending:
                return "待服用"
            case .taken:
                return "已服用"
            case .missed:
                return "已錯過"
            }
        }
    }
}

@MainActor
class HomeViewModel: ObservableObject {
    @Published var todaySchedules: [TodayMedicationSchedule] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showingAddMedication = false
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
    
    private let todayDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月d日"
        return formatter
    }()
    
    func loadTodaySchedules() async {
        isLoading = true
        errorMessage = nil
        
        // 這裡應該從 Supabase 載入資料
        // 暫時使用模擬資料
        let mockSchedules = createMockSchedules()
        await MainActor.run {
            self.todaySchedules = mockSchedules
            self.isLoading = false
        }
    }
    
    func markAsTaken(_ schedule: TodayMedicationSchedule) async {
        // 更新本地狀態
        if let index = todaySchedules.firstIndex(where: { $0.id == schedule.id }) {
            todaySchedules[index].status = .taken
        }
        
        // 這裡應該將記錄寫入 Supabase adherence_logs 表格
        // 暫時省略實際的 API 呼叫
    }
    
    private func createMockSchedules() -> [TodayMedicationSchedule] {
        let mockMedication1 = Medication(
            id: UUID(),
            userId: UUID(),
            name: "維他命D",
            dosage: "1000 IU",
            scheduleType: "daily",
            notificationTimes: ["08:00", "20:00"],
            isActive: true,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        let mockMedication2 = Medication(
            id: UUID(),
            userId: UUID(),
            name: "血壓藥",
            dosage: "5mg",
            scheduleType: "daily",
            notificationTimes: ["09:00"],
            isActive: true,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        let calendar = Calendar.current
        let today = Date()
        
        return [
            TodayMedicationSchedule(
                medication: mockMedication1,
                scheduledTime: calendar.date(bySettingHour: 8, minute: 0, second: 0, of: today) ?? today,
                status: .taken
            ),
            TodayMedicationSchedule(
                medication: mockMedication2,
                scheduledTime: calendar.date(bySettingHour: 9, minute: 0, second: 0, of: today) ?? today,
                status: .pending
            ),
            TodayMedicationSchedule(
                medication: mockMedication1,
                scheduledTime: calendar.date(bySettingHour: 20, minute: 0, second: 0, of: today) ?? today,
                status: .pending
            )
        ]
    }
    
    var todayDateString: String {
        todayDateFormatter.string(from: Date())
    }
}

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    
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
                    // 頂部標題
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("今天")
                                    .font(.title2)
                                    .fontWeight(.medium)
                                    .foregroundColor(Theme.Colors.textPrimary)
                                
                                Text(viewModel.todayDateString)
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(Theme.Colors.primary)
                            }
                            
                            Spacer()
                            
                            // 新增藥物按鈕
                            Button(action: {
                                viewModel.showingAddMedication = true
                            }) {
                                Image(systemName: "plus")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .frame(width: 44, height: 44)
                                    .background(
                                        Circle()
                                            .fill(Theme.Colors.primary)
                                            .shadow(color: Theme.Colors.primary.opacity(0.3), radius: 8, x: 0, y: 4)
                                    )
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                        .padding(.bottom, 8)
                    }
                    
                    // 用藥排程列表
                    if viewModel.isLoading {
                        Spacer()
                        ProgressView()
                            .scaleEffect(1.2)
                            .tint(Theme.Colors.primary)
                        Spacer()
                    } else if viewModel.todaySchedules.isEmpty {
                        Spacer()
                        VStack(spacing: 16) {
                            Image(systemName: "pills")
                                .font(.system(size: 48))
                                .foregroundColor(Theme.Colors.textSecondary)
                            
                            Text("今天沒有用藥排程")
                                .font(.headline)
                                .foregroundColor(Theme.Colors.textSecondary)
                            
                            Text("點擊右上角的 + 按鈕新增藥物")
                                .font(.body)
                                .foregroundColor(Theme.Colors.textTertiary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.horizontal, 32)
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                ForEach(viewModel.todaySchedules) { schedule in
                                    MedicationCard(
                                        schedule: schedule,
                                        onMarkAsTaken: {
                                            Task {
                                                await viewModel.markAsTaken(schedule)
                                            }
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.vertical, 16)
                        }
                    }
                    
                    // 錯誤訊息
                    if let errorMessage = viewModel.errorMessage {
                        VStack {
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundColor(Theme.Colors.error)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 24)
                                .padding(.bottom, 16)
                        }
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $viewModel.showingAddMedication) {
            AddMedicationView()
        }
        .task {
            await viewModel.loadTodaySchedules()
        }
    }
}

struct MedicationCard: View {
    let schedule: TodayMedicationSchedule
    let onMarkAsTaken: () -> Void
    
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
    
    var body: some View {
        HStack(spacing: 16) {
            // 狀態圖示
            Image(systemName: schedule.status.icon)
                .font(.title2)
                .foregroundColor(schedule.status.color)
                .frame(width: 32, height: 32)
            
            // 藥物資訊
            VStack(alignment: .leading, spacing: 4) {
                Text(schedule.medication.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(Theme.Colors.textPrimary)
                
                Text(schedule.medication.dosage)
                    .font(.subheadline)
                    .foregroundColor(Theme.Colors.textSecondary)
                
                HStack(spacing: 8) {
                    Text(timeFormatter.string(from: schedule.scheduledTime))
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(Theme.Colors.primary)
                    
                    Text("•")
                        .font(.caption)
                        .foregroundColor(Theme.Colors.textTertiary)
                    
                    Text(schedule.status.displayText)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(schedule.status.color)
                }
            }
            
            Spacer()
            
            // 操作按鈕
            if schedule.status == .pending {
                Button(action: onMarkAsTaken) {
                    Text("已服用")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Theme.Colors.success)
                        )
                }
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
                .shadow(color: Theme.Colors.glassShadow, radius: 8, x: 0, y: 4)
        )
        .opacity(schedule.status == .taken ? 0.7 : 1.0)
    }
}

#Preview {
    HomeView()
}