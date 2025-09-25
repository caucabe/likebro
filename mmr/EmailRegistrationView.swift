//
//  EmailRegistrationView.swift
//  mmr
//
//  Created by doff on 2025/9/24.
//

import SwiftUI
import Combine

struct EmailRegistrationView: View {
    @ObservedObject var authViewModel: AuthViewModel
    @FocusState private var focusedField: FormField?
    
    enum FormField: Hashable {
        case fullName
        case email
        case password
    }
    
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
                    headerSection
                    
                    // Registration Form
                    registrationFormSection
                    
                    // Divider
                    dividerSection
                    
                    // Google Sign In
                    googleSignInSection
                    
                    Spacer(minLength: Theme.Spacing.xl)
                }
                .padding(Theme.Spacing.lg)
            }
        }
        .onTapGesture {
            hideKeyboard()
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: Theme.Spacing.lg) {
            // Back Button
            HStack {
                Button(action: {
                    withAnimation(Theme.Animation.smooth) {
                        authViewModel.authState = .phoneInput
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
                Image(systemName: "envelope.fill")
                    .font(.system(size: 60))
                    .foregroundColor(Theme.Colors.primary)
                    .shadow(color: Theme.Colors.primary.opacity(0.3), radius: 15, x: 0, y: 8)
                
                Text("電子郵件註冊")
                    .font(Theme.Typography.customFont(size: Theme.Typography.largeTitle, weight: Theme.Typography.bold))
                    .foregroundColor(Theme.Colors.textPrimary)
                
                Text("使用電子郵件建立您的帳戶")
                    .font(Theme.Typography.customFont(size: Theme.Typography.subheadline))
                    .foregroundColor(Theme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .glassCard()
        }
    }
    
    // MARK: - Registration Form Section
    private var registrationFormSection: some View {
        VStack(spacing: Theme.Spacing.lg) {
            // Full Name Field
            FormFieldView(
                title: "全名",
                placeholder: "請輸入您的全名",
                text: $authViewModel.fullName,
                isSecure: false,
                keyboardType: .default,
                focusedField: $focusedField,
                currentField: .fullName,
                errorMessage: authViewModel.fullName.count < 2 && !authViewModel.fullName.isEmpty ? "全名至少需要2個字元" : nil,
                accessibilityLabel: "全名輸入欄位"
            )
            
            // Email Field
            FormFieldView(
                title: "電子郵件",
                placeholder: "請輸入您的電子郵件",
                text: $authViewModel.email,
                isSecure: false,
                keyboardType: .emailAddress,
                focusedField: $focusedField,
                currentField: .email,
                errorMessage: !authViewModel.isEmailValid && !authViewModel.email.isEmpty ? "請輸入有效的電子郵件格式" : nil,
                accessibilityLabel: "電子郵件輸入欄位"
            )
            
            // Password Field
            PasswordFieldView(
                title: "密碼",
                placeholder: "請輸入密碼（至少6字元）",
                text: $authViewModel.password,
                focusedField: $focusedField,
                currentField: .password,
                errorMessage: !authViewModel.isPasswordValid && !authViewModel.password.isEmpty ? "密碼需至少6字元" : nil,
                accessibilityLabel: "密碼輸入欄位"
            )
            
            // Error Message
            if let errorMessage = authViewModel.errorMessage {
                ErrorMessageView(message: errorMessage) {
                    authViewModel.clearError()
                }
            }
            
            // Register Button
            registerButton
        }
    }
    
    // MARK: - Divider Section
    private var dividerSection: some View {
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
        .padding(.vertical, Theme.Spacing.md)
    }
    
    // MARK: - Google Sign In Section
    private var googleSignInSection: some View {
        VStack(spacing: Theme.Spacing.md) {
            Button(action: {
                Task {
                    await authViewModel.signInWithGoogle()
                }
            }) {
                HStack(spacing: Theme.Spacing.sm) {
                    if authViewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                        
                        Text("Google 登入中...")
                            .font(Theme.Typography.customFont(size: Theme.Typography.subheadline, weight: Theme.Typography.medium))
                            .foregroundColor(.white)
                    } else {
                        Image(systemName: "globe")
                            .font(.title3)
                            .foregroundColor(.white)
                        
                        Text("使用 Google 帳號註冊")
                            .font(Theme.Typography.customFont(size: Theme.Typography.subheadline, weight: Theme.Typography.medium))
                            .foregroundColor(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(Theme.Spacing.md)
            }
            .background(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                    .fill(Color.red.opacity(0.8))
            )
            .disabled(authViewModel.isLoading)
            .opacity(authViewModel.isLoading ? 0.6 : 1.0)
            .animation(Theme.Animation.smooth, value: authViewModel.isLoading)
        }
        .glassCard()
    }
    
    // MARK: - Register Button
    private var registerButton: some View {
        Button(action: {
            Task {
                await authViewModel.register()
            }
        }) {
            HStack {
                if authViewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Theme.Colors.textPrimary))
                        .scaleEffect(0.8)
                    
                    Text("建立帳戶中...")
                        .font(Theme.Typography.customFont(size: Theme.Typography.headline, weight: Theme.Typography.medium))
                } else {
                    Image(systemName: "person.badge.plus.fill")
                        .font(.title3)
                    
                    Text("建立帳戶")
                        .font(Theme.Typography.customFont(size: Theme.Typography.headline, weight: Theme.Typography.medium))
                }
            }
            .foregroundColor(Theme.Colors.textPrimary)
            .frame(maxWidth: .infinity)
            .padding(Theme.Spacing.lg)
        }
        .glassmorphism(cornerRadius: Theme.CornerRadius.medium)
        .disabled(authViewModel.isLoading || !isFormValid)
        .opacity(isFormValid && !authViewModel.isLoading ? 1.0 : 0.6)
        .animation(Theme.Animation.smooth, value: isFormValid)
        .animation(Theme.Animation.smooth, value: authViewModel.isLoading)
    }
    
    private var isFormValid: Bool {
        authViewModel.fullName.count >= 2 &&
        authViewModel.isEmailValid &&
        authViewModel.isPasswordValid
    }
    
    // MARK: - Helper Methods
    private func hideKeyboard() {
        focusedField = nil
    }
}

// MARK: - Form Field View
struct FormFieldView: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    let isSecure: Bool
    let keyboardType: UIKeyboardType
    @FocusState.Binding var focusedField: EmailRegistrationView.FormField?
    let currentField: EmailRegistrationView.FormField
    let errorMessage: String?
    let accessibilityLabel: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text(title)
                .font(Theme.Typography.customFont(size: Theme.Typography.headline, weight: Theme.Typography.medium))
                .foregroundColor(Theme.Colors.textPrimary)
            
            TextField(placeholder, text: $text)
                .font(Theme.Typography.customFont(size: Theme.Typography.body))
                .foregroundColor(Theme.Colors.textPrimary)
                .keyboardType(keyboardType)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .focused($focusedField, equals: currentField)
                .padding(Theme.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                        .fill(Theme.Colors.glassBackground.opacity(0.3))
                        .stroke(
                            focusedField == currentField ? Theme.Colors.primary : 
                            (errorMessage != nil ? Theme.Colors.error : Color.clear),
                            lineWidth: 2
                        )
                )
                .accessibilityLabel(accessibilityLabel)
                .accessibilityHint(errorMessage ?? "")
            
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .font(Theme.Typography.customFont(size: Theme.Typography.caption1))
                    .foregroundColor(Theme.Colors.error)
            }
        }
        .glassCard()
    }
}

// MARK: - Password Field View
struct PasswordFieldView: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    @FocusState.Binding var focusedField: EmailRegistrationView.FormField?
    let currentField: EmailRegistrationView.FormField
    let errorMessage: String?
    let accessibilityLabel: String
    @State private var isPasswordVisible = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text(title)
                .font(Theme.Typography.customFont(size: Theme.Typography.headline, weight: Theme.Typography.medium))
                .foregroundColor(Theme.Colors.textPrimary)
            
            HStack {
                if isPasswordVisible {
                    TextField(placeholder, text: $text)
                        .font(Theme.Typography.customFont(size: Theme.Typography.body))
                        .foregroundColor(Theme.Colors.textPrimary)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .focused($focusedField, equals: currentField)
                        .accessibilityLabel(accessibilityLabel)
                } else {
                    SecureField(placeholder, text: $text)
                        .font(Theme.Typography.customFont(size: Theme.Typography.body))
                        .foregroundColor(Theme.Colors.textPrimary)
                        .focused($focusedField, equals: currentField)
                        .accessibilityLabel(accessibilityLabel)
                }
                
                Button(action: {
                    isPasswordVisible.toggle()
                }) {
                    Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                        .font(.title3)
                        .foregroundColor(Theme.Colors.textSecondary)
                }
                .accessibilityLabel(isPasswordVisible ? "隱藏密碼" : "顯示密碼")
            }
            .padding(Theme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                    .fill(Theme.Colors.glassBackground.opacity(0.3))
                    .stroke(
                        focusedField == currentField ? Theme.Colors.primary : 
                        (errorMessage != nil ? Theme.Colors.error : Color.clear),
                        lineWidth: 2
                    )
            )
            
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .font(Theme.Typography.customFont(size: Theme.Typography.caption1))
                    .foregroundColor(Theme.Colors.error)
            }
        }
        .glassCard()
    }
}



#Preview {
    EmailRegistrationView(authViewModel: AuthViewModel())
}