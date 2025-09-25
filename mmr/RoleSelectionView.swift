//
//  RoleSelectionView.swift
//  mmr
//
//  Created by doff on 2025/9/24.
//

import SwiftUI

struct RoleSelectionView: View {
    @ObservedObject var authViewModel: AuthViewModel
    
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
            
            VStack(spacing: Theme.Spacing.xl) {
                Spacer()
                
                // Logo and Title Section
                VStack(spacing: Theme.Spacing.lg) {
                    // App Logo/Icon
                    Image(systemName: "heart.text.square.fill")
                        .font(.system(size: 80))
                        .foregroundColor(Theme.Colors.primary)
                        .shadow(color: Theme.Colors.primary.opacity(0.3), radius: 20, x: 0, y: 10)
                    
                    VStack(spacing: Theme.Spacing.sm) {
                        Text("MedicationButler")
                            .font(Theme.Typography.customFont(size: Theme.Typography.largeTitle, weight: Theme.Typography.bold))
                            .foregroundColor(Theme.Colors.textPrimary)
                        
                        Text("您的貼心用藥管家")
                            .font(Theme.Typography.customFont(size: Theme.Typography.title3))
                            .foregroundColor(Theme.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                }
                
                Spacer()
                
                // Role Selection Section
                VStack(spacing: Theme.Spacing.lg) {
                    VStack(spacing: Theme.Spacing.sm) {
                        Text("請選擇您的身份")
                            .font(Theme.Typography.customFont(size: Theme.Typography.title2, weight: Theme.Typography.semibold))
                            .foregroundColor(Theme.Colors.textPrimary)
                        
                        Text("選擇最適合您的使用方式")
                            .font(Theme.Typography.customFont(size: Theme.Typography.subheadline))
                            .foregroundColor(Theme.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .glassCard()
                    
                    // Role Buttons
                    VStack(spacing: Theme.Spacing.md) {
                        ForEach(UserRole.allCases, id: \.self) { role in
                            RoleButton(
                                role: role,
                                isSelected: authViewModel.selectedRole == role
                            ) {
                                withAnimation(Theme.Animation.smooth) {
                                    authViewModel.selectRole(role)
                                }
                            }
                        }
                    }
                }
                
                Spacer()
                
                // Footer
                VStack(spacing: Theme.Spacing.xs) {
                    Text("繼續即表示您同意我們的")
                        .font(Theme.Typography.customFont(size: Theme.Typography.caption1))
                        .foregroundColor(Theme.Colors.textTertiary)
                    
                    HStack(spacing: 4) {
                        Button("服務條款") {
                            // TODO: 顯示服務條款
                        }
                        .font(Theme.Typography.customFont(size: Theme.Typography.caption1))
                        .foregroundColor(Theme.Colors.primary)
                        
                        Text("和")
                            .font(Theme.Typography.customFont(size: Theme.Typography.caption1))
                            .foregroundColor(Theme.Colors.textTertiary)
                        
                        Button("隱私政策") {
                            // TODO: 顯示隱私政策
                        }
                        .font(Theme.Typography.customFont(size: Theme.Typography.caption1))
                        .foregroundColor(Theme.Colors.primary)
                    }
                }
                .padding(.bottom, Theme.Spacing.lg)
            }
            .padding(Theme.Spacing.lg)
        }
    }
}

struct RoleButton: View {
    let role: UserRole
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.md) {
                // Role Icon
                Image(systemName: roleIcon)
                    .font(.title2)
                    .foregroundColor(isSelected ? Theme.Colors.primary : Theme.Colors.textSecondary)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(role.displayName)
                        .font(Theme.Typography.customFont(size: Theme.Typography.headline, weight: Theme.Typography.medium))
                        .foregroundColor(Theme.Colors.textPrimary)
                    
                    Text(roleDescription)
                        .font(Theme.Typography.customFont(size: Theme.Typography.caption1))
                        .foregroundColor(Theme.Colors.textSecondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                // Selection Indicator
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(isSelected ? Theme.Colors.primary : Theme.Colors.textTertiary)
            }
            .padding(Theme.Spacing.lg)
            .frame(maxWidth: .infinity)
        }
        .glassmorphism(cornerRadius: Theme.CornerRadius.large)
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(Theme.Animation.smooth, value: isSelected)
    }
    
    private var roleIcon: String {
        switch role {
        case .user:
            return "person.fill"
        case .caregiver:
            return "heart.fill"
        }
    }
    
    private var roleDescription: String {
        switch role {
        case .user:
            return "我需要管理自己的用藥"
        case .caregiver:
            return "我要關懷家人的用藥狀況"
        }
    }
}

#Preview {
    RoleSelectionView(authViewModel: AuthViewModel())
}