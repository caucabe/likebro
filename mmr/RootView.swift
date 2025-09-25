//
//  RootView.swift
//  mmr
//
//  Created by doff on 2025/9/24.
//

import SwiftUI

struct RootView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var supabaseManager = SupabaseManager.shared
    
    var body: some View {
        Group {
            // 首先檢查資料庫配置
            if !supabaseManager.isDatabaseConfigured {
                DatabaseErrorView(
                    errorMessage: supabaseManager.configurationError ?? "資料庫配置錯誤",
                    onRetry: {
                        supabaseManager.retryDatabaseConnection()
                    }
                )
            } else {
                // 資料庫配置正常，顯示正常的應用程式流程
                switch authViewModel.authState {
                case .unauthenticated:
                    RoleSelectionView(authViewModel: authViewModel)
                    
                case .roleSelection:
                    RoleSelectionView(authViewModel: authViewModel)
                    
                case .phoneInput, .otpVerification:
                    AuthView(authViewModel: authViewModel)
                    
                case .emailRegistration:
                    EmailRegistrationView(authViewModel: authViewModel)
                    
                case .profileSetup:
                    ProfileSetupView(authViewModel: authViewModel)
                    
                case .authenticated:
                    MainAppView()
                        .environmentObject(authViewModel)
                    
                case .loading:
                    LoadingView()
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: authViewModel.authState)
        .animation(.easeInOut(duration: 0.3), value: supabaseManager.isDatabaseConfigured)
    }
}

struct MainAppView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        TabView {
            // Home Tab - 根據角色顯示不同內容
            Group {
                if authViewModel.currentUser?.role == .caregiver {
                    CaregiverHomeView()
                } else {
                    HomeView()
                }
            }
            .tabItem {
                Image(systemName: "house.fill")
                Text("首頁")
            }
            
            // Medications Tab - 整合 AddMedicationView 功能
            MedicationsView()
                .tabItem {
                    Image(systemName: "pills.fill")
                    Text("用藥")
                }
            
            // Care Links Tab (for caregivers only) - 移除此標籤頁，因為功能已整合到 CaregiverHomeView
            // if authViewModel.currentUser?.role == .caregiver {
            //     CareLinksView()
            //         .tabItem {
            //             Image(systemName: "heart.fill")
            //             Text("關懷")
            //         }
            // }
            
            // Profile Tab
            ProfileView()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("個人")
                }
        }
        .accentColor(Theme.Colors.primary)
    }
}

struct LoadingView: View {
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color.blue.opacity(0.3),
                    Color.purple.opacity(0.3),
                    Color.black
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: Theme.Spacing.lg) {
                // App Logo
                Image(systemName: "pills.fill")
                    .font(.system(size: 80))
                    .foregroundColor(Theme.Colors.primary)
                    .shadow(color: Theme.Colors.primary.opacity(0.3), radius: 15, x: 0, y: 8)
                
                Text("MedicationButler")
                    .font(Theme.Typography.customFont(size: Theme.Typography.largeTitle, weight: Theme.Typography.bold))
                    .foregroundColor(Theme.Colors.textPrimary)
                
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: Theme.Colors.primary))
                    .scaleEffect(1.2)
            }
            .glassCard()
        }
    }
}

// 用藥管理視圖 - 整合 AddMedicationView 功能
struct MedicationsView: View {
    @State private var showingAddMedication = false
    @State private var medications: [Medication] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    
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
                    if isLoading {
                        Spacer()
                        ProgressView()
                            .scaleEffect(1.2)
                            .tint(Theme.Colors.primary)
                        Spacer()
                    } else if medications.isEmpty {
                        Spacer()
                        VStack(spacing: 16) {
                            Image(systemName: "pills.fill")
                                .font(.system(size: 48))
                                .foregroundColor(Theme.Colors.textSecondary)
                            
                            Text("尚未新增任何藥物")
                                .font(.headline)
                                .foregroundColor(Theme.Colors.textSecondary)
                            
                            Text("點擊右上角的 + 按鈕開始新增藥物")
                                .font(.body)
                                .foregroundColor(Theme.Colors.textTertiary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.horizontal, 32)
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                ForEach(medications) { medication in
                                    MedicationListCard(medication: medication)
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.vertical, 16)
                        }
                    }
                    
                    // 錯誤訊息
                    if let errorMessage = errorMessage {
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
            .navigationTitle("用藥管理")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddMedication = true
                    }) {
                        Image(systemName: "plus")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(Theme.Colors.primary)
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddMedication) {
            AddMedicationView()
        }
        .task {
            await loadMedications()
        }
    }
    
    private func loadMedications() async {
        isLoading = true
        errorMessage = nil
        
        // 這裡應該從 Supabase 載入資料
        // 暫時使用模擬資料
        let mockMedications = createMockMedications()
        await MainActor.run {
            self.medications = mockMedications
            self.isLoading = false
        }
    }
    
    private func createMockMedications() -> [Medication] {
        return [
            Medication(
                id: UUID(),
                userId: UUID(),
                name: "維他命D",
                dosage: "1000 IU",
                scheduleType: "daily",
                notificationTimes: ["08:00", "20:00"],
                isActive: true,
                createdAt: Date(),
                updatedAt: Date()
            ),
            Medication(
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
        ]
    }
}

// 藥物清單卡片
struct MedicationListCard: View {
    let medication: Medication
    
    var body: some View {
        HStack(spacing: 16) {
            // 藥物圖示
            Image(systemName: "pills.fill")
                .font(.title2)
                .foregroundColor(Theme.Colors.primary)
                .frame(width: 32, height: 32)
            
            // 藥物資訊
            VStack(alignment: .leading, spacing: 4) {
                Text(medication.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(Theme.Colors.textPrimary)
                
                Text(medication.dosage)
                    .font(.subheadline)
                    .foregroundColor(Theme.Colors.textSecondary)
                
                HStack(spacing: 8) {
                    Text(medication.scheduleType == "daily" ? "每日" : medication.scheduleType)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(Theme.Colors.primary)
                    
                    Text("•")
                        .font(.caption)
                        .foregroundColor(Theme.Colors.textTertiary)
                    
                    Text("\(medication.notificationTimes.count) 次提醒")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(Theme.Colors.textSecondary)
                }
            }
            
            Spacer()
            
            // 狀態指示器
            Circle()
                .fill(medication.isActive ? Theme.Colors.success : Theme.Colors.textTertiary)
                .frame(width: 8, height: 8)
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
    }
}

struct CareLinksView: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("關懷連結")
                    .font(.largeTitle)
                    .padding()
                Text("此功能正在開發中...")
                    .foregroundColor(.secondary)
            }
            .navigationTitle("關懷")
        }
    }
}

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if let profile = authViewModel.currentUser {
                    VStack(spacing: 10) {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(Theme.Colors.primary)
                        
                        Text(profile.fullName)
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text(profile.role.displayName)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text(profile.phone ?? profile.email ?? "")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                }
                
                Button("登出") {
                    authViewModel.signOut()
                }
                .foregroundColor(.red)
                .padding()
                
                Spacer()
            }
            .navigationTitle("個人資料")
        }
    }
}

#Preview {
    RootView()
        .environmentObject(AuthViewModel())
}