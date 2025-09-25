//
//  AuthViewModel.swift
//  mmr
//
//  Created by doff on 2025/9/24.
//

import SwiftUI
import Foundation
import Combine
import Supabase

// 用戶角色枚舉
enum UserRole: String, CaseIterable {
    case user = "user"
    case caregiver = "caregiver"
    
    var displayName: String {
        switch self {
        case .user:
            return "我是主要使用者"
        case .caregiver:
            return "我是關懷者"
        }
    }
}

// 認證錯誤枚舉
enum AuthError: Error, LocalizedError {
    case invalidCredentials
    case networkError
    case unknownError
    case supabaseAuthError
    
    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "無效的憑證"
        case .networkError:
            return "網路連接錯誤"
        case .unknownError:
            return "未知錯誤"
        case .supabaseAuthError:
            return "Supabase 認證錯誤"
        }
    }
}

// 認證狀態枚舉
enum AuthState {
    case unauthenticated
    case roleSelection
    case phoneInput
    case otpVerification
    case emailRegistration
    case profileSetup
    case authenticated
    case loading
}

// 用戶資料模型
struct UserProfile {
    let id: String
    let phone: String?
    let email: String?
    let fullName: String
    let role: UserRole
}

@MainActor
class AuthViewModel: ObservableObject {
    @Published var authState: AuthState = .roleSelection  // 設為角色選擇狀態進行測試
    @Published var selectedRole: UserRole? = nil  // 清空預設角色以測試選擇功能
    @Published var phoneNumber: String = ""
    @Published var otpCode: String = ""
    @Published var fullName: String = ""
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var currentUser: UserProfile? = nil  // 清空用戶資料以測試完整流程
    @Published var isAuthenticated: Bool = false
    
    private let supabaseManager = SupabaseManager.shared
    
    // MARK: - Role Selection
    func selectRole(_ role: UserRole) {
        selectedRole = role
        authState = .phoneInput
    }
    
    func navigateToEmailRegistration() {
        authState = .emailRegistration
    }
    
    // MARK: - Phone Authentication
    func sendOTP() async {
        guard isPhoneNumberValid else {
            errorMessage = "請輸入有效的手機號碼"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let formattedPhone = formatToE164(phoneNumber)
            let _ = try await self.supabaseManager.performWithRetry {
                try await self.supabaseManager.client.auth.signInWithOTP(
                    phone: formattedPhone
                )
            }
            
            DispatchQueue.main.async {
                self.authState = .otpVerification
                self.isLoading = false
            }
        } catch {
            DispatchQueue.main.async {
                self.handleAuthError(error)
                self.isLoading = false
            }
        }
    }
    
    // MARK: - Email Registration
    func register() {
        guard isEmailValid && isPasswordValid else {
            errorMessage = "請輸入有效的電子郵件和密碼（至少6個字符）"
            return
        }
        
        guard selectedRole != nil else {
            errorMessage = "請選擇用戶角色"
            return
        }
        
        Task {
            isLoading = true
            errorMessage = nil
            
            do {
                let response = try await self.supabaseManager.performWithRetry {
                    try await self.supabaseManager.client.auth.signUp(
                        email: self.email,
                        password: self.password
                    )
                }
                
                if response.user != nil {
                    // 檢查是否需要電子郵件驗證
                    if response.session == nil {
                        // 需要電子郵件驗證
                        DispatchQueue.main.async {
                            self.errorMessage = "請檢查您的電子郵件並點擊驗證連結以完成註冊"
                            self.isLoading = false
                        }
                    } else {
                        // 註冊成功，直接進入已認證狀態
                        DispatchQueue.main.async {
                            self.isAuthenticated = true
                            self.authState = .authenticated
                            self.isLoading = false
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        self.errorMessage = "註冊失敗，請稍後再試"
                        self.isLoading = false
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.handleAuthError(error)
                    self.isLoading = false
                }
            }
        }
    }
    
    func signInWithGoogle() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let _ = try await self.supabaseManager.performWithRetry {
                try await self.supabaseManager.client.auth.signInWithOAuth(provider: .google)
            }
            
            DispatchQueue.main.async {
                self.isAuthenticated = true
                self.authState = .authenticated
                self.isLoading = false
            }
        } catch {
            DispatchQueue.main.async {
                self.handleAuthError(error)
                self.isLoading = false
            }
        }
    }
    
    func verifyOTP() async {
        guard isOTPValid else {
            errorMessage = "請輸入6位數驗證碼"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await self.supabaseManager.performWithRetry {
                try await self.supabaseManager.client.auth.verifyOTP(
                    phone: self.formatToE164(self.phoneNumber),
                    token: self.otpCode,
                    type: .sms
                )
            }
            
            DispatchQueue.main.async {
                if response.user != nil {
                    self.isAuthenticated = true
                    self.authState = .authenticated
                } else {
                    self.errorMessage = "驗證失敗，請重試"
                }
                self.isLoading = false
            }
        } catch {
            DispatchQueue.main.async {
                self.handleAuthError(error)
                self.isLoading = false
            }
        }
    }
    
    // MARK: - Profile Setup
    func completeProfileSetup() async {
        guard isFullNameValid && selectedRole != nil else {
            errorMessage = "請填寫所有必要資訊"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // 使用 Supabase 的 profiles 表來儲存用戶資料
            let _ = try await self.supabaseManager.performWithRetry {
                try await self.supabaseManager.client
                    .from("profiles")
                    .insert([
                        "full_name": AnyJSON.string(self.fullName),
                        "role": AnyJSON.string(self.selectedRole?.rawValue ?? "user")
                    ])
                    .execute()
            }
            
            DispatchQueue.main.async {
                self.isAuthenticated = true
                self.authState = .authenticated
                self.isLoading = false
            }
        } catch {
            DispatchQueue.main.async {
                self.handleAuthError(error)
                self.isLoading = false
            }
        }
    }
    
    // MARK: - Helper Methods
    private func isValidPhoneNumber(_ phone: String) -> Bool {
        // 嚴格的 E.164 格式驗證 - Supabase 要求
        // 必須以 + 開頭，後接國碼和號碼，總長度 7-15 位數字
        let e164Regex = "^\\+[1-9]\\d{6,14}$"
        let phonePredicate = NSPredicate(format: "SELF MATCHES %@", e164Regex)
        return phonePredicate.evaluate(with: phone)
    }
    
    // 輔助方法：將台灣本地號碼轉換為 E.164 格式
    private func formatToE164(_ phone: String) -> String {
        var cleanPhone = phone.replacingOccurrences(of: " ", with: "")
                              .replacingOccurrences(of: "-", with: "")
        
        // 如果是台灣本地格式 (09xxxxxxxx)，轉換為 +886 格式
        if cleanPhone.hasPrefix("09") && cleanPhone.count == 10 {
            cleanPhone = "+886" + String(cleanPhone.dropFirst())
        }
        // 如果已經是 +886 格式但沒有 +，補上 +
        else if cleanPhone.hasPrefix("886") && cleanPhone.count == 12 {
            cleanPhone = "+" + cleanPhone
        }
        
        return cleanPhone
    }
    
    private func handleAuthError(_ error: Error) {
        print("❌ 認證錯誤: \(error)")
        
        if let authError = error as? AuthError {
            switch authError {
            case .invalidCredentials:
                errorMessage = "帳號或密碼錯誤"
            case .networkError:
                errorMessage = "網路連接失敗，請檢查網路設定"
            case .unknownError:
                errorMessage = "發生未知錯誤，請稍後再試"
            case .supabaseAuthError:
                errorMessage = "Supabase 認證錯誤"
            }
        } else {
            // 處理其他類型的錯誤
            let errorDescription = error.localizedDescription
            if errorDescription.contains("network") || errorDescription.contains("connection") {
                errorMessage = "網路連接失敗，請檢查網路設定"
            } else if errorDescription.contains("timeout") {
                errorMessage = "請求超時，請檢查網路連接後重試"
            } else if errorDescription.contains("invalid_grant") {
                errorMessage = "驗證碼錯誤或已過期"
            } else if errorDescription.contains("email_address_invalid") {
                errorMessage = "電子郵件格式不正確"
            } else if errorDescription.contains("signup_disabled") {
                errorMessage = "註冊功能暫時停用"
            } else {
                errorMessage = "操作失敗：\(errorDescription)"
            }
        }
    }
    
    private func checkIfNewUser() async -> Bool {
        // TODO: 實際檢查 Supabase 資料庫
        // 檢查 profiles 表格中是否已存在此手機號碼的用戶
        return true // 暫時返回 true，表示新用戶
    }
    
    private func loadUserProfile() async {
        // TODO: 從 Supabase 載入用戶資料
        // 從 profiles 表格載入用戶資料
    }
    
    func signOut() {
        currentUser = nil
        authState = .roleSelection
        selectedRole = nil
        phoneNumber = ""
        otpCode = ""
        fullName = ""
        email = ""
        password = ""
        errorMessage = nil
        
        // 登出 Supabase
        Task {
            try? await supabaseManager.client.auth.signOut()
        }
    }
    
    func clearError() {
        errorMessage = nil
    }
    
    // MARK: - Validation
    var isPhoneNumberValid: Bool {
        // 簡單的手機號碼驗證
        phoneNumber.count >= 10 && phoneNumber.allSatisfy { $0.isNumber }
    }
    
    var isOTPValid: Bool {
        otpCode.count == 6 && otpCode.allSatisfy { $0.isNumber }
    }
    
    var isFullNameValid: Bool {
        !fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var isEmailValid: Bool {
        let emailRegex = "^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    var isPasswordValid: Bool {
        // 簡化密碼要求：只需要至少6個字元
        return password.count >= 6
    }
}