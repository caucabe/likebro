import SwiftUI

struct DatabaseErrorView: View {
    let errorMessage: String
    let onRetry: () async -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            // 錯誤圖示
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundColor(.orange)
            
            // 標題
            Text("資料庫連接問題")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            // 錯誤訊息
            Text(errorMessage)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // 解決方案建議
            VStack(alignment: .leading, spacing: 12) {
                Text("可能的解決方案：")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .top) {
                        Text("•")
                        Text("檢查網路連接是否正常")
                    }
                    
                    HStack(alignment: .top) {
                        Text("•")
                        Text("確認 Supabase 專案設定正確")
                    }
                    
                    HStack(alignment: .top) {
                        Text("•")
                        Text("驗證 API Key 是否有效")
                    }
                    
                    HStack(alignment: .top) {
                        Text("•")
                        Text("檢查資料庫表格是否已建立")
                    }
                }
                .font(.body)
                .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            // 重試按鈕
            Button(action: {
                Task {
                    await onRetry()
                }
            }) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("重新連接")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue)
                .cornerRadius(12)
            }
            
            // 設定指南連結
            Button(action: {
                if let url = URL(string: "https://supabase.com/docs/guides/getting-started") {
                    UIApplication.shared.open(url)
                }
            }) {
                HStack {
                    Image(systemName: "book.fill")
                    Text("查看設定指南")
                }
                .font(.body)
                .foregroundColor(.blue)
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

#Preview {
    DatabaseErrorView(
        errorMessage: "資料庫表格不存在，請執行資料庫遷移腳本",
        onRetry: {
            // 預覽用的空實作
        }
    )
}