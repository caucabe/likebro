//
//  ProfileSetupView.swift
//  mmr
//
//  Created by doff on 2025/9/24.
//

import SwiftUI

struct ProfileSetupView: View {
    @ObservedObject var authViewModel: AuthViewModel
    @FocusState private var isNameFieldFocused: Bool
    
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
            
            ScrollView {
                VStack(spacing: Theme.Spacing.xl) {
                    // Header Section
                    VStack(spacing: Theme.Spacing.lg) {
                        // Progress Indicator
                        HStack {
                            ForEach(0..<3) { index in
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(index == 2 ? Theme.Colors.primary : Theme.Colors.textTertiary.opacity(0.3))
                                    .frame(height: 4)
                                    .animation(Theme.Animation.smooth, value: index)
                            }
                        }
                        .padding(.horizontal, Theme.Spacing.lg)
                        
                        // Welcome Section
                        VStack(spacing: Theme.Spacing.sm) {
                            Image(systemName: "person.crop.circle.fill.badge.checkmark")
                                .font(.system(size: 60))
                                .foregroundColor(Theme.Colors.primary)
                                .shadow(color: Theme.Colors.primary.opacity(0.3), radius: 15, x: 0, y: 8)
                            
                            Text("歡迎加入！")
                                .font(Theme.Typography.customFont(size: Theme.Typography.largeTitle, weight: Theme.Typography.bold))
                                .foregroundColor(Theme.Colors.textPrimary)
                            
                            Text("請告訴我們您的稱呼")
                                .font(Theme.Typography.customFont(size: Theme.Typography.subheadline))
                                .foregroundColor(Theme.Colors.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                        .glassCard()
                    }
                    
                    // Profile Setup Section
                    VStack(spacing: Theme.Spacing.lg) {
                        // Role Display
                        roleDisplaySection
                        
                        // Name Input
                        nameInputSection
                        
                        // Error Message
                        if let errorMessage = authViewModel.errorMessage {
                            ErrorMessageView(message: errorMessage) {
                                authViewModel.clearError()
                            }
                        }
                        
                        // Complete Button
                        completeButton
                        
                        // Skip Option (Optional)
                        skipSection
                    }
                    
                    Spacer(minLength: Theme.Spacing.xl)
                }
                .padding(Theme.Spacing.lg)
            }
        }
        .onTapGesture {
            hideKeyboard()
        }
        .onAppear {
            // Auto focus on name field
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isNameFieldFocused = true
            }
        }
    }
    
    // MARK: - Role Display Section
    private var roleDisplaySection: some View {
        VStack(spacing: Theme.Spacing.sm) {
            HStack {
                Text("您選擇的身份")
                    .font(Theme.Typography.customFont(size: Theme.Typography.subheadline))
                    .foregroundColor(Theme.Colors.textSecondary)
                
                Spacer()
            }
            
            HStack(spacing: Theme.Spacing.md) {
                Image(systemName: roleIcon)
                    .font(.title2)
                    .foregroundColor(Theme.Colors.primary)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(authViewModel.selectedRole?.displayName ?? "")
                        .font(Theme.Typography.customFont(size: Theme.Typography.headline, weight: Theme.Typography.medium))
                        .foregroundColor(Theme.Colors.textPrimary)
                    
                    Text(roleDescription)
                        .font(Theme.Typography.customFont(size: Theme.Typography.caption1))
                        .foregroundColor(Theme.Colors.textSecondary)
                }
                
                Spacer()
                
                Button("更改") {
                    withAnimation(Theme.Animation.smooth) {
                        authViewModel.authState = .roleSelection
                    }
                }
                .font(Theme.Typography.customFont(size: Theme.Typography.caption1))
                .foregroundColor(Theme.Colors.primary)
            }
            .padding(Theme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                    .fill(Theme.Colors.primary.opacity(0.1))
                    .stroke(Theme.Colors.primary.opacity(0.3), lineWidth: 1)
            )
        }
        .glassCard()
    }
    
    // MARK: - Name Input Section
    private var nameInputSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("您的稱呼")
                .font(Theme.Typography.customFont(size: Theme.Typography.headline, weight: Theme.Typography.medium))
                .foregroundColor(Theme.Colors.textPrimary)
            
            TextField("請輸入您的稱呼", text: $authViewModel.fullName)
                .font(Theme.Typography.customFont(size: Theme.Typography.body))
                .foregroundColor(Theme.Colors.textPrimary)
                .focused($isNameFieldFocused)
                .padding(Theme.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                        .fill(Theme.Colors.glassBackground.opacity(0.3))
                        .stroke(
                            isNameFieldFocused ? Theme.Colors.primary : Color.clear,
                            lineWidth: 2
                        )
                )
            
            Text("這個名稱將會顯示在您的個人資料中")
                .font(Theme.Typography.customFont(size: Theme.Typography.caption1))
                .foregroundColor(Theme.Colors.textTertiary)
        }
        .glassCard()
    }
    
    // MARK: - Complete Button
    private var completeButton: some View {
        Button(action: {
            Task {
                await authViewModel.completeProfileSetup()
            }
        }) {
            HStack {
                if authViewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Theme.Colors.textPrimary))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                }
                
                Text("完成設定")
                    .font(Theme.Typography.customFont(size: Theme.Typography.headline, weight: Theme.Typography.medium))
            }
            .foregroundColor(Theme.Colors.textPrimary)
            .frame(maxWidth: .infinity)
            .padding(Theme.Spacing.lg)
        }
        .glassmorphism(cornerRadius: Theme.CornerRadius.medium)
        .disabled(authViewModel.isLoading || !authViewModel.isFullNameValid)
        .opacity(authViewModel.isFullNameValid ? 1.0 : 0.6)
        .animation(Theme.Animation.smooth, value: authViewModel.isFullNameValid)
    }
    
    // MARK: - Skip Section
    private var skipSection: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Text("或者")
                .font(Theme.Typography.customFont(size: Theme.Typography.caption1))
                .foregroundColor(Theme.Colors.textTertiary)
            
            Button("稍後再設定") {
                // Set a default name and complete setup
                authViewModel.fullName = "用戶"
                Task {
                    await authViewModel.completeProfileSetup()
                }
            }
            .font(Theme.Typography.customFont(size: Theme.Typography.subheadline))
            .foregroundColor(Theme.Colors.textSecondary)
            .disabled(authViewModel.isLoading)
        }
    }
    
    // MARK: - Helper Properties
    private var roleIcon: String {
        switch authViewModel.selectedRole {
        case .user:
            return "person.fill"
        case .caregiver:
            return "heart.fill"
        case .none:
            return "person.fill"
        }
    }
    
    private var roleDescription: String {
        switch authViewModel.selectedRole {
        case .user:
            return "管理自己的用藥"
        case .caregiver:
            return "關懷家人的用藥狀況"
        case .none:
            return ""
        }
    }
    
    // MARK: - Helper Methods
    private func hideKeyboard() {
        isNameFieldFocused = false
    }
}

#Preview {
    ProfileSetupView(authViewModel: {
        let vm = AuthViewModel()
        vm.authState = .profileSetup
        vm.selectedRole = .user
        vm.phoneNumber = "0912345678"
        return vm
    }())
}