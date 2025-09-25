//
//  InvitationFlow.swift
//  mmr
//
//  Created by doff on 2025/9/24.
//

import SwiftUI
import Foundation
import Combine
import Supabase
import PostgREST

@MainActor
class InvitationFlowViewModel: ObservableObject {
    @Published var inviteCode: String = ""
    @Published var isGenerating = false
    @Published var isSharing = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var showingShareSheet = false
    
    private let supabaseManager = SupabaseManager.shared
    
    func generateInviteCode() async {
        isGenerating = true
        errorMessage = nil
        successMessage = nil
        
        do {
            guard let currentUserId = await supabaseManager.getCurrentUserId() else {
                throw AuthError.supabaseAuthError
            }
            
            // 生成新的邀請碼
            let newInviteCode = generateRandomCode()
            
            // 創建邀請記錄
            let careLink = [
                "caregiver_id": currentUserId,
                "invite_code": newInviteCode,
                "status": "pending"
            ]
            
            let _: [CareLink] = try await supabaseManager.client
                .from("care_links")
                .insert(careLink)
                .select()
                .execute()
                .value
            
            inviteCode = newInviteCode
            successMessage = "邀請碼已生成！"
            
        } catch {
            errorMessage = "生成邀請碼失敗：\(error.localizedDescription)"
        }
        
        isGenerating = false
    }
    
    func shareInviteCode() {
        guard !inviteCode.isEmpty else { return }
        showingShareSheet = true
    }
    
    private func generateRandomCode() -> String {
        let chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<8).map { _ in chars.randomElement()! })
    }
    
    var shareText: String {
        """
        您好！我想邀請您使用 MedicationButler 來管理用藥。
        
        請下載 MedicationButler App，並在設定頁面輸入以下邀請碼：
        
        邀請碼：\(inviteCode)
        
        這樣我就能關懷您的用藥狀況了！
        """
    }
}

struct InvitationFlowView: View {
    @StateObject private var viewModel = InvitationFlowViewModel()
    @Environment(\.dismiss) private var dismiss
    
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
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Header Section
                        VStack(spacing: 16) {
                            Image(systemName: "person.badge.plus")
                                .font(.system(size: 60))
                                .foregroundColor(Theme.Colors.primary)
                                .shadow(color: Theme.Colors.primary.opacity(0.3), radius: 12, x: 0, y: 6)
                            
                            VStack(spacing: 8) {
                                Text("邀請家人")
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(Theme.Colors.textPrimary)
                                
                                Text("生成邀請碼，讓家人加入您的關懷圈")
                                    .font(.body)
                                    .foregroundColor(Theme.Colors.textSecondary)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .padding(.top, 32)
                        
                        // Invite Code Section
                        VStack(spacing: 24) {
                            if viewModel.inviteCode.isEmpty {
                                // Generate Button
                                Button(action: {
                                    Task {
                                        await viewModel.generateInviteCode()
                                    }
                                }) {
                                    HStack(spacing: 12) {
                                        if viewModel.isGenerating {
                                            ProgressView()
                                                .scaleEffect(0.8)
                                                .tint(.white)
                                        } else {
                                            Image(systemName: "plus.circle.fill")
                                                .font(.title3)
                                        }
                                        
                                        Text(viewModel.isGenerating ? "生成中..." : "生成邀請碼")
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
                                .disabled(viewModel.isGenerating)
                            } else {
                                // Invite Code Display
                                VStack(spacing: 16) {
                                    VStack(spacing: 8) {
                                        Text("您的邀請碼")
                                            .font(.subheadline)
                                            .foregroundColor(Theme.Colors.textSecondary)
                                        
                                        Text(viewModel.inviteCode)
                                            .font(.system(size: 32, weight: .bold, design: .monospaced))
                                            .foregroundColor(Theme.Colors.primary)
                                            .padding(.horizontal, 24)
                                            .padding(.vertical, 16)
                                            .background(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .fill(Theme.Colors.glassBackground.opacity(0.5))
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 12)
                                                            .stroke(Theme.Colors.primary.opacity(0.3), lineWidth: 2)
                                                    )
                                            )
                                    }
                                    
                                    // Action Buttons
                                    VStack(spacing: 12) {
                                        // Share Button
                                        Button(action: viewModel.shareInviteCode) {
                                            HStack(spacing: 12) {
                                                Image(systemName: "square.and.arrow.up")
                                                    .font(.title3)
                                                
                                                Text("分享邀請碼")
                                                    .font(.headline)
                                                    .fontWeight(.semibold)
                                            }
                                            .foregroundColor(.white)
                                            .frame(maxWidth: .infinity)
                                            .frame(height: 50)
                                            .background(
                                                RoundedRectangle(cornerRadius: 14)
                                                    .fill(Theme.Colors.success)
                                                    .shadow(color: Theme.Colors.success.opacity(0.3), radius: 8, x: 0, y: 4)
                                            )
                                        }
                                        
                                        // Copy Button
                                        Button(action: {
                                            UIPasteboard.general.string = viewModel.inviteCode
                                            viewModel.successMessage = "邀請碼已複製到剪貼簿"
                                        }) {
                                            HStack(spacing: 12) {
                                                Image(systemName: "doc.on.doc")
                                                    .font(.title3)
                                                
                                                Text("複製邀請碼")
                                                    .font(.headline)
                                                    .fontWeight(.semibold)
                                            }
                                            .foregroundColor(Theme.Colors.primary)
                                            .frame(maxWidth: .infinity)
                                            .frame(height: 50)
                                            .background(
                                                RoundedRectangle(cornerRadius: 14)
                                                    .fill(Theme.Colors.glassBackground.opacity(0.3))
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 14)
                                                            .stroke(Theme.Colors.primary, lineWidth: 1.5)
                                                    )
                                            )
                                        }
                                        
                                        // Generate New Button
                                        Button(action: {
                                            Task {
                                                await viewModel.generateInviteCode()
                                            }
                                        }) {
                                            HStack(spacing: 8) {
                                                Image(systemName: "arrow.clockwise")
                                                    .font(.subheadline)
                                                
                                                Text("重新生成")
                                                    .font(.subheadline)
                                                    .fontWeight(.medium)
                                            }
                                            .foregroundColor(Theme.Colors.textSecondary)
                                            .frame(maxWidth: .infinity)
                                            .frame(height: 44)
                                            .background(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .fill(Theme.Colors.glassBackground.opacity(0.2))
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 12)
                                                            .stroke(Theme.Colors.glassBorder, lineWidth: 1)
                                                    )
                                            )
                                        }
                                        .disabled(viewModel.isGenerating)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        
                        // Instructions Section
                        VStack(spacing: 16) {
                            Text("使用說明")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(Theme.Colors.textPrimary)
                            
                            VStack(spacing: 12) {
                                InstructionStep(
                                    number: "1",
                                    title: "分享邀請碼",
                                    description: "將邀請碼傳送給您想要關懷的家人"
                                )
                                
                                InstructionStep(
                                    number: "2",
                                    title: "家人下載 App",
                                    description: "請家人下載 MedicationButler 並完成註冊"
                                )
                                
                                InstructionStep(
                                    number: "3",
                                    title: "輸入邀請碼",
                                    description: "在設定頁面輸入邀請碼建立關懷連結"
                                )
                                
                                InstructionStep(
                                    number: "4",
                                    title: "開始關懷",
                                    description: "即時掌握家人的用藥狀況"
                                )
                            }
                        }
                        .padding(.horizontal, 24)
                        
                        // Messages
                        if let successMessage = viewModel.successMessage {
                            Text(successMessage)
                                .font(.subheadline)
                                .foregroundColor(Theme.Colors.success)
                                .padding(.horizontal, 24)
                        }
                        
                        if let errorMessage = viewModel.errorMessage {
                            Text(errorMessage)
                                .font(.subheadline)
                                .foregroundColor(Theme.Colors.error)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 24)
                        }
                    }
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("邀請家人")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                    .foregroundColor(Theme.Colors.primary)
                }
            }
        }
        .sheet(isPresented: $viewModel.showingShareSheet) {
            ShareSheet(activityItems: [viewModel.shareText])
        }
    }
}

// 說明步驟組件
struct InstructionStep: View {
    let number: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            // Step Number
            Text(number)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(Theme.Colors.primary)
                )
            
            // Step Content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(Theme.Colors.textPrimary)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(Theme.Colors.textSecondary)
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
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

// 分享功能
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    InvitationFlowView()
}