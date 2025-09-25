//
//  CaregiverHomeView.swift
//  mmr
//
//  Created by doff on 2025/9/24.
//

import SwiftUI
import Foundation
import Combine
import Supabase

// 關懷連結模型
struct CareLink: Identifiable, Codable {
    let id: UUID
    let caregiverId: UUID
    let userId: UUID
    let status: String
    let inviteCode: String
    let createdAt: Date
    let updatedAt: Date
    let expiresAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case caregiverId = "caregiver_id"
        case userId = "user_id"
        case status
        case inviteCode = "invite_code"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case expiresAt = "expires_at"
    }
}

// 被關懷者資料模型
struct CareRecipient: Identifiable, Codable {
    let id: UUID
    let fullName: String
    let phone: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case fullName = "full_name"
        case phone
    }
}

@MainActor
class CaregiverHomeViewModel: ObservableObject {
    @Published var careLinks: [CareLink] = []
    @Published var careRecipients: [CareRecipient] = []
    @Published var selectedRecipientSchedules: [TodayMedicationSchedule] = []
    @Published var selectedRecipient: CareRecipient?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showingInvitationFlow = false
    
    private let supabaseManager = SupabaseManager.shared
    private var cancellables = Set<AnyCancellable>()
    
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
    
    var todayDateString: String {
        todayDateFormatter.string(from: Date())
    }
    
    init() {
        setupRealtimeSubscription()
    }
    
    deinit {
        // RealtimeV2 channels are automatically cleaned up
    }
    
    func loadCareLinks() async {
        isLoading = true
        errorMessage = nil
        
        do {
            guard let currentUserId = await supabaseManager.getCurrentUserId() else {
                throw AuthError.supabaseAuthError
            }
            
            // 載入關懷連結
            let careLinksResponse: [CareLink] = try await supabaseManager.client
                .from("care_links")
                .select()
                .eq("caregiver_id", value: currentUserId)
                .eq("status", value: "accepted")
                .execute()
                .value
            
            careLinks = careLinksResponse
            
            // 載入被關懷者資料
            if !careLinks.isEmpty {
                let userIds = careLinks.map { $0.userId }
                let recipientsResponse: [CareRecipient] = try await supabaseManager.client
                    .from("profiles")
                    .select("id, full_name, phone")
                    .in("id", values: userIds)
                    .execute()
                    .value
                
                careRecipients = recipientsResponse
                
                // 如果有被關懷者，預設選擇第一個
                if selectedRecipient == nil, let firstRecipient = careRecipients.first {
                    selectedRecipient = firstRecipient
                    await loadRecipientSchedules(for: firstRecipient)
                }
            }
            
        } catch {
            errorMessage = "載入關懷資料失敗：\(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func loadRecipientSchedules(for recipient: CareRecipient) async {
        do {
            // 載入被關懷者的藥物
            let medications: [Medication] = try await supabaseManager.client
                .from("medications")
                .select()
                .eq("user_id", value: recipient.id)
                .eq("is_active", value: true)
                .execute()
                .value
            
            // 載入今日的服藥記錄
            let today = Date()
            let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
            
            let iso8601Formatter = ISO8601DateFormatter()
            let todayString = iso8601Formatter.string(from: today)
            let tomorrowString = iso8601Formatter.string(from: tomorrow)
            
            let adherenceLogs: [AdherenceLog] = try await supabaseManager.client
                .from("adherence_logs")
                .select()
                .eq("user_id", value: recipient.id)
                .gte("scheduled_time", value: todayString)
                .lt("scheduled_time", value: tomorrowString)
                .execute()
                .value
            
            // 生成今日排程
            selectedRecipientSchedules = generateTodaySchedules(medications: medications, adherenceLogs: adherenceLogs)
            
        } catch {
            errorMessage = "載入用藥排程失敗：\(error.localizedDescription)"
        }
    }
    
    private func generateTodaySchedules(medications: [Medication], adherenceLogs: [AdherenceLog]) -> [TodayMedicationSchedule] {
        var schedules: [TodayMedicationSchedule] = []
        let today = Date()
        let calendar = Calendar.current
        
        for medication in medications {
            // 解析通知時間
            for timeString in medication.notificationTimes {
                let components = timeString.split(separator: ":")
                if components.count == 2,
                   let hour = Int(components[0]),
                   let minute = Int(components[1]) {
                    
                    var dateComponents = calendar.dateComponents([.year, .month, .day], from: today)
                    dateComponents.hour = hour
                    dateComponents.minute = minute
                    
                    if let scheduledTime = calendar.date(from: dateComponents) {
                        // 檢查是否有對應的服藥記錄
                        let log = adherenceLogs.first { log in
                            log.medicationId == medication.id &&
                            calendar.isDate(log.scheduledTime, equalTo: scheduledTime, toGranularity: .minute)
                        }
                        
                        let status: TodayMedicationSchedule.MedicationStatus
                        if let log = log {
                            switch log.status {
                            case "taken":
                                status = .taken
                            case "missed":
                                status = .missed
                            default:
                                status = .pending
                            }
                        } else {
                            // 判斷是否已過時間
                            status = scheduledTime < Date() ? .missed : .pending
                        }
                        
                        schedules.append(TodayMedicationSchedule(
                            medication: medication,
                            scheduledTime: scheduledTime,
                            status: status
                        ))
                    }
                }
            }
        }
        
        return schedules.sorted { $0.scheduledTime < $1.scheduledTime }
    }
    
    private func setupRealtimeSubscription() {
        Task {
            guard let currentUserId = await supabaseManager.getCurrentUserId() else { return }
            
            do {
                // 使用 RealtimeV2 API
                let channel = supabaseManager.client.realtimeV2.channel("caregiver_adherence_logs")
                
                // 監聽服藥記錄的變動
                Task {
                    for await change in channel.postgresChange(AnyAction.self, table: "adherence_logs") {
                        await MainActor.run {
                            // 檢查變動的記錄是否屬於當前關懷的對象
                            if let recipient = self.selectedRecipient {
                                var shouldUpdate = false
                                
                                switch change {
                                case .insert(let action):
                                    if let record = try? action.decodeRecord(as: [String: AnyJSON].self, decoder: JSONDecoder()),
                                       let userId = record["user_id"]?.stringValue,
                                       userId == recipient.id.uuidString {
                                        shouldUpdate = true
                                    }
                                case .update(let action):
                                    if let record = try? action.decodeRecord(as: [String: AnyJSON].self, decoder: JSONDecoder()),
                                       let userId = record["user_id"]?.stringValue,
                                       userId == recipient.id.uuidString {
                                        shouldUpdate = true
                                    }
                                case .delete(let action):
                                    if let record = try? action.decodeOldRecord(as: [String: AnyJSON].self, decoder: JSONDecoder()),
                                       let userId = record["user_id"]?.stringValue,
                                       userId == recipient.id.uuidString {
                                        shouldUpdate = true
                                    }
                                }
                                
                                if shouldUpdate {
                                    Task {
                                        await self.loadRecipientSchedules(for: recipient)
                                    }
                                }
                            }
                        }
                    }
                }
                
                // 監聽關懷連結的變動
                Task {
                    for await change in channel.postgresChange(AnyAction.self, table: "care_links") {
                        await MainActor.run {
                            var shouldUpdate = false
                            
                            switch change {
                             case .insert(let action):
                                 if let record = try? action.decodeRecord(as: [String: AnyJSON].self, decoder: JSONDecoder()),
                                    let caregiverId = record["caregiver_id"]?.stringValue,
                                    caregiverId == currentUserId {
                                     shouldUpdate = true
                                 }
                             case .update(let action):
                                 if let record = try? action.decodeRecord(as: [String: AnyJSON].self, decoder: JSONDecoder()),
                                    let caregiverId = record["caregiver_id"]?.stringValue,
                                    caregiverId == currentUserId {
                                     shouldUpdate = true
                                 }
                             case .delete(let action):
                                 if let record = try? action.decodeOldRecord(as: [String: AnyJSON].self, decoder: JSONDecoder()),
                                    let caregiverId = record["caregiver_id"]?.stringValue,
                                    caregiverId == currentUserId {
                                     shouldUpdate = true
                                 }
                             }
                            
                            if shouldUpdate {
                                Task {
                                    await self.loadCareLinks()
                                }
                            }
                        }
                    }
                }
                
                // 訂閱頻道
                try await channel.subscribeWithError()
                
                // 監聽訂閱狀態
                Task {
                    for await status in channel.statusChange {
                        print("Realtime subscription status: \(status)")
                        if case .subscribed = status {
                            print("✅ Realtime subscription established for caregiver")
                        }
                    }
                }
                
            } catch {
                print("Realtime subscription error: \(error)")
                await MainActor.run {
                    self.errorMessage = "即時同步連接失敗：\(error.localizedDescription)"
                }
            }
        }
    }
    
    func selectRecipient(_ recipient: CareRecipient) {
        selectedRecipient = recipient
        Task {
            await loadRecipientSchedules(for: recipient)
        }
    }
}

struct CaregiverHomeView: View {
    @StateObject private var viewModel = CaregiverHomeViewModel()
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        Theme.Colors.background,
                        Theme.Colors.backgroundSecondary
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                if viewModel.careRecipients.isEmpty {
                    // 顯示邀請流程
                    InvitationPromptView {
                        viewModel.showingInvitationFlow = true
                    }
                } else {
                    // 顯示被關懷者的用藥狀況
                    VStack(spacing: 0) {
                        // Header Section
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("關懷模式")
                                        .font(.title2)
                                        .fontWeight(.medium)
                                        .foregroundColor(Theme.Colors.textPrimary)
                                    
                                    Text(viewModel.todayDateString)
                                        .font(.title)
                                        .fontWeight(.bold)
                                        .foregroundColor(Theme.Colors.primary)
                                }
                                
                                Spacer()
                                
                                // 邀請按鈕
                                Button(action: {
                                    viewModel.showingInvitationFlow = true
                                }) {
                                    Image(systemName: "person.badge.plus")
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
                            
                            // 被關懷者選擇器
                            if viewModel.careRecipients.count > 1 {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(viewModel.careRecipients) { recipient in
                                            RecipientSelectorButton(
                                                recipient: recipient,
                                                isSelected: viewModel.selectedRecipient?.id == recipient.id
                                            ) {
                                                viewModel.selectRecipient(recipient)
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 24)
                                }
                                .padding(.bottom, 8)
                            }
                        }
                        
                        // Content Section
                        if viewModel.isLoading {
                            Spacer()
                            ProgressView()
                                .scaleEffect(1.2)
                                .tint(Theme.Colors.primary)
                            Spacer()
                        } else if viewModel.selectedRecipientSchedules.isEmpty {
                            Spacer()
                            VStack(spacing: 16) {
                                Image(systemName: "pills")
                                    .font(.system(size: 48))
                                    .foregroundColor(Theme.Colors.textSecondary)
                                
                                if let recipient = viewModel.selectedRecipient {
                                    Text("\(recipient.fullName) 今天沒有用藥排程")
                                        .font(.headline)
                                        .foregroundColor(Theme.Colors.textSecondary)
                                } else {
                                    Text("今天沒有用藥排程")
                                        .font(.headline)
                                        .foregroundColor(Theme.Colors.textSecondary)
                                }
                            }
                            .padding(.horizontal, 32)
                            Spacer()
                        } else {
                            ScrollView {
                                LazyVStack(spacing: 16) {
                                    ForEach(viewModel.selectedRecipientSchedules) { schedule in
                                        CaregiverMedicationCard(schedule: schedule)
                                    }
                                }
                                .padding(.horizontal, 24)
                                .padding(.vertical, 16)
                            }
                        }
                        
                        // Error Message
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
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $viewModel.showingInvitationFlow) {
            InvitationFlowView()
        }
        .task {
            await viewModel.loadCareLinks()
        }
    }
}

// 邀請提示視圖
struct InvitationPromptView: View {
    let onInvite: () -> Void
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            VStack(spacing: 24) {
                Image(systemName: "heart.text.square")
                    .font(.system(size: 80))
                    .foregroundColor(Theme.Colors.primary)
                    .shadow(color: Theme.Colors.primary.opacity(0.3), radius: 20, x: 0, y: 10)
                
                VStack(spacing: 16) {
                    Text("開始關懷家人")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(Theme.Colors.textPrimary)
                    
                    Text("邀請家人加入，即時掌握他們的用藥狀況")
                        .font(.body)
                        .foregroundColor(Theme.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
            }
            
            Button(action: onInvite) {
                HStack(spacing: 12) {
                    Image(systemName: "person.badge.plus")
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    Text("邀請家人")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Theme.Colors.primary)
                        .shadow(color: Theme.Colors.primary.opacity(0.3), radius: 12, x: 0, y: 6)
                )
            }
            .padding(.horizontal, 32)
            
            Spacer()
        }
    }
}

// 被關懷者選擇按鈕
struct RecipientSelectorButton: View {
    let recipient: CareRecipient
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(recipient.fullName)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : Theme.Colors.textPrimary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? Theme.Colors.primary : Theme.Colors.glassBackground.opacity(0.3))
                        .overlay(
                            Capsule()
                                .stroke(isSelected ? Color.clear : Theme.Colors.glassBorder, lineWidth: 1)
                        )
                )
        }
    }
}

// 關懷者用藥卡片（只顯示，不能操作）
struct CaregiverMedicationCard: View {
    let schedule: TodayMedicationSchedule
    
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
    
    var body: some View {
        HStack(spacing: 16) {
            // Status Icon
            Image(systemName: schedule.status.icon)
                .font(.title2)
                .foregroundColor(schedule.status.color)
                .frame(width: 32, height: 32)
            
            // Medication Info
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
    CaregiverHomeView()
}