//
//  AuthView.swift
//  mmr
//
//  Created by doff on 2025/9/24.
//

import SwiftUI

struct AuthView: View {
    @ObservedObject var authViewModel: AuthViewModel
    @FocusState private var isPhoneFieldFocused: Bool
    @FocusState private var isOTPFieldFocused: Bool
    
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
                        // Back Button
                        HStack {
                            Button(action: {
                                withAnimation(Theme.Animation.smooth) {
                                    authViewModel.authState = .roleSelection
                                }
                            }) {
                                HStack(spacing: Theme.Spacing.xs) {
                                    Image(systemName: "chevron.left")
                                        .font(.title3)
                                    Text("返回")
                                        .font(Theme.Typography.customFont(size: Theme.Typography.subheadline))
                                }
                                .foregroundColor(Theme.Colors.textSecondary)
                            }
                            
                            Spacer()
                        }
                        
                        // Title Section
                        VStack(spacing: Theme.Spacing.sm) {
                            Image(systemName: "phone.fill")
                                .font(.system(size: 60))
                                .foregroundColor(Theme.Colors.primary)
                                .shadow(color: Theme.Colors.primary.opacity(0.3), radius: 15, x: 0, y: 8)
                            
                            Text("手機驗證")
                                .font(Theme.Typography.customFont(size: Theme.Typography.largeTitle, weight: Theme.Typography.bold))
                                .foregroundColor(Theme.Colors.textPrimary)
                            
                            Text(authViewModel.authState == .phoneInput ? 
                                 "請輸入您的手機號碼" : "請輸入收到的驗證碼")
                                .font(Theme.Typography.customFont(size: Theme.Typography.subheadline))
                                .foregroundColor(Theme.Colors.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                        .glassCard()
                    }
                    
                    // Input Section
                    VStack(spacing: Theme.Spacing.lg) {
                        if authViewModel.authState == .phoneInput {
                            phoneInputSection
                        } else if authViewModel.authState == .otpVerification {
                            otpInputSection
                        }
                        
                        // Error Message
                        if let errorMessage = authViewModel.errorMessage {
                            ErrorMessageView(message: errorMessage) {
                                authViewModel.clearError()
                            }
                        }
                        
                        // Action Button
                        actionButton
                        
                        // Alternative Registration Options
                        alternativeRegistrationButton
                    }
                    
                    Spacer(minLength: Theme.Spacing.xl)
                }
                .padding(Theme.Spacing.lg)
            }
        }
        .onTapGesture {
            hideKeyboard()
        }
    }
    
    // MARK: - Phone Input Section
    private var phoneInputSection: some View {
        VStack(spacing: Theme.Spacing.md) {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                Text("手機號碼")
                    .font(Theme.Typography.customFont(size: Theme.Typography.headline, weight: Theme.Typography.medium))
                    .foregroundColor(Theme.Colors.textPrimary)
                
                HStack(spacing: Theme.Spacing.sm) {
                    // Country Code
                    Text("+886")
                        .font(Theme.Typography.customFont(size: Theme.Typography.body))
                        .foregroundColor(Theme.Colors.textSecondary)
                        .padding(.horizontal, Theme.Spacing.sm)
                        .padding(.vertical, Theme.Spacing.md)
                        .background(
                            RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                                .fill(Theme.Colors.glassBackground.opacity(0.3))
                        )
                    
                    // Phone Number Input
                    TextField("請輸入手機號碼", text: $authViewModel.phoneNumber)
                        .font(Theme.Typography.customFont(size: Theme.Typography.body))
                        .foregroundColor(Theme.Colors.textPrimary)
                        .keyboardType(.phonePad)
                        .focused($isPhoneFieldFocused)
                        .padding(Theme.Spacing.md)
                        .background(
                            RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                                .fill(Theme.Colors.glassBackground.opacity(0.3))
                                .stroke(
                                    isPhoneFieldFocused ? Theme.Colors.primary : Color.clear,
                                    lineWidth: 2
                                )
                        )
                }
                
                // Phone Number Hint
                Text("我們將發送驗證碼到此號碼")
                    .font(Theme.Typography.customFont(size: Theme.Typography.caption1))
                    .foregroundColor(Theme.Colors.textTertiary)
            }
            .glassCard()
        }
    }
    
    // MARK: - OTP Input Section
    private var otpInputSection: some View {
        VStack(spacing: Theme.Spacing.md) {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                Text("驗證碼")
                    .font(Theme.Typography.customFont(size: Theme.Typography.headline, weight: Theme.Typography.medium))
                    .foregroundColor(Theme.Colors.textPrimary)
                
                // OTP Input Field
                TextField("請輸入 6 位數驗證碼", text: $authViewModel.otpCode)
                    .font(Theme.Typography.customFont(size: Theme.Typography.title2, weight: Theme.Typography.medium))
                    .foregroundColor(Theme.Colors.textPrimary)
                    .keyboardType(.numberPad)
                    .focused($isOTPFieldFocused)
                    .multilineTextAlignment(.center)
                    .padding(Theme.Spacing.lg)
                    .background(
                        RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                            .fill(Theme.Colors.glassBackground.opacity(0.3))
                            .stroke(
                                isOTPFieldFocused ? Theme.Colors.primary : Color.clear,
                                lineWidth: 2
                            )
                    )
                    .onChange(of: authViewModel.otpCode) { oldValue, newValue in
                        // 限制輸入長度為 6 位數
                        if newValue.count > 6 {
                            authViewModel.otpCode = String(newValue.prefix(6))
                        }
                    }
                
                // Phone Number Display
                HStack {
                    Text("驗證碼已發送至")
                        .font(Theme.Typography.customFont(size: Theme.Typography.caption1))
                        .foregroundColor(Theme.Colors.textTertiary)
                    
                    Text("+886 \(authViewModel.phoneNumber)")
                        .font(Theme.Typography.customFont(size: Theme.Typography.caption1, weight: Theme.Typography.medium))
                        .foregroundColor(Theme.Colors.textSecondary)
                    
                    Spacer()
                    
                    Button("重新發送") {
                        Task {
                            await authViewModel.sendOTP()
                        }
                    }
                    .font(Theme.Typography.customFont(size: Theme.Typography.caption1))
                    .foregroundColor(Theme.Colors.primary)
                }
            }
            .glassCard()
        }
    }
    
    // MARK: - Action Button
    private var actionButton: some View {
        Button(action: {
            Task {
                if authViewModel.authState == .phoneInput {
                    await authViewModel.sendOTP()
                } else if authViewModel.authState == .otpVerification {
                    await authViewModel.verifyOTP()
                }
            }
        }) {
            HStack {
                if authViewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Theme.Colors.textPrimary))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: authViewModel.authState == .phoneInput ? "paperplane.fill" : "checkmark.circle.fill")
                        .font(.title3)
                }
                
                Text(authViewModel.authState == .phoneInput ? "發送驗證碼" : "驗證")
                    .font(Theme.Typography.customFont(size: Theme.Typography.headline, weight: Theme.Typography.medium))
            }
            .foregroundColor(Theme.Colors.textPrimary)
            .frame(maxWidth: .infinity)
            .padding(Theme.Spacing.lg)
        }
        .glassmorphism(cornerRadius: Theme.CornerRadius.medium)
        .disabled(authViewModel.isLoading || !isActionButtonEnabled)
        .opacity(isActionButtonEnabled ? 1.0 : 0.6)
        .animation(Theme.Animation.smooth, value: isActionButtonEnabled)
    }
    
    // MARK: - Helper Properties
    private var isActionButtonEnabled: Bool {
        if authViewModel.authState == .phoneInput {
            return authViewModel.isPhoneNumberValid
        } else if authViewModel.authState == .otpVerification {
            return authViewModel.isOTPValid
        }
        return false
    }
    
    
    private var alternativeRegistrationButton: some View {
        VStack(spacing: Theme.Spacing.md) {
            // Divider with text
            HStack {
                Rectangle()
                    .fill(Theme.Colors.textTertiary.opacity(0.3))
                    .frame(height: 1)
                
                Text("或")
                    .font(Theme.Typography.customFont(size: Theme.Typography.caption1))
                    .foregroundColor(Theme.Colors.textTertiary)
                    .padding(.horizontal, Theme.Spacing.md)
                
                Rectangle()
                    .fill(Theme.Colors.textTertiary.opacity(0.3))
                    .frame(height: 1)
            }
            
            // Alternative registration button
            Button(action: {
                withAnimation(Theme.Animation.smooth) {
                    authViewModel.authState = .emailRegistration
                }
            }) {
                HStack(spacing: Theme.Spacing.sm) {
                    Image(systemName: "envelope.fill")
                        .font(.title3)
                        .foregroundColor(Theme.Colors.textSecondary)
                    
                    Text("其他註冊方式")
                        .font(Theme.Typography.customFont(size: Theme.Typography.subheadline, weight: Theme.Typography.medium))
                        .foregroundColor(Theme.Colors.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(Theme.Spacing.md)
            }
            .glassmorphism(cornerRadius: Theme.CornerRadius.medium)
            .opacity(0.8)
        }
        .padding(.top, Theme.Spacing.lg)
    }
    
    // MARK: - Helper Methods
    private func hideKeyboard() {
        isPhoneFieldFocused = false
        isOTPFieldFocused = false
    }
}

// MARK: - Error Message View
struct ErrorMessageView: View {
    let message: String
    let onDismiss: () -> Void
    
    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title3)
                .foregroundColor(Theme.Colors.error)
            
            Text(message)
                .font(Theme.Typography.customFont(size: Theme.Typography.subheadline))
                .foregroundColor(Theme.Colors.textPrimary)
                .multilineTextAlignment(.leading)
            
            Spacer()
            
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.caption)
                    .foregroundColor(Theme.Colors.textSecondary)
            }
        }
        .padding(Theme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                .fill(Theme.Colors.error.opacity(0.1))
                .stroke(Theme.Colors.error.opacity(0.3), lineWidth: 1)
        )
    }
}

#Preview("Phone Input") {
    AuthView(authViewModel: {
        let vm = AuthViewModel()
        vm.authState = .phoneInput
        return vm
    }())
}

#Preview("OTP Verification") {
    AuthView(authViewModel: {
        let vm = AuthViewModel()
        vm.authState = .otpVerification
        vm.phoneNumber = "0912345678"
        return vm
    }())
}