//
//  SupabaseClient.swift
//  mmr
//
//  Created by doff on 2025/9/24.
//

import Foundation
import Supabase
import Network
import Combine

struct SupabaseConfig {
    static var supabaseURL: String {
        guard let path = Bundle.main.path(forResource: "Config", ofType: "plist") else {
            fatalError("❌ Config.plist 檔案未找到！請確保 Config.plist 檔案已正確添加到專案中。")
        }
        
        guard let plist = NSDictionary(contentsOfFile: path) else {
            fatalError("❌ 無法讀取 Config.plist 檔案！請檢查檔案格式是否正確。")
        }
        
        guard let url = plist["SUPABASE_URL"] as? String, !url.isEmpty else {
            fatalError("❌ Config.plist 中缺少 SUPABASE_URL 或值為空！請設定正確的 Supabase 專案 URL。")
        }
        
        // 驗證 URL 格式
        guard url.hasPrefix("https://") && url.contains(".supabase.co") else {
            fatalError("❌ SUPABASE_URL 格式錯誤！應為：https://your-project.supabase.co")
        }
        
        return url
    }
    
    static var supabaseKey: String {
        guard let path = Bundle.main.path(forResource: "Config", ofType: "plist") else {
            fatalError("❌ Config.plist 檔案未找到！請確保 Config.plist 檔案已正確添加到專案中。")
        }
        
        guard let plist = NSDictionary(contentsOfFile: path) else {
            fatalError("❌ 無法讀取 Config.plist 檔案！請檢查檔案格式是否正確。")
        }
        
        guard let key = plist["SUPABASE_ANON_KEY"] as? String, !key.isEmpty else {
            fatalError("❌ Config.plist 中缺少 SUPABASE_ANON_KEY 或值為空！請設定正確的 Supabase Anon Key。")
        }
        
        // 驗證 Key 格式（JWT token 應該以 eyJ 開頭）
        guard key.hasPrefix("eyJ") else {
            fatalError("❌ SUPABASE_ANON_KEY 格式錯誤！應為有效的 JWT token（以 eyJ 開頭）。")
        }
        
        return key
    }
    
    // 添加配置驗證方法
    static func validateConfiguration() -> Bool {
        // 檢查 Config.plist 是否存在
        guard let path = Bundle.main.path(forResource: "Config", ofType: "plist") else {
            print("❌ Config.plist 檔案未找到")
            return false
        }
        
        guard let plist = NSDictionary(contentsOfFile: path) else {
            print("❌ 無法讀取 Config.plist 檔案")
            return false
        }
        
        // 檢查 SUPABASE_URL
        guard let url = plist["SUPABASE_URL"] as? String, !url.isEmpty else {
            print("❌ Config.plist 中缺少 SUPABASE_URL 或值為空")
            return false
        }
        
        guard url.hasPrefix("https://") && url.contains(".supabase.co") else {
            print("❌ SUPABASE_URL 格式錯誤")
            return false
        }
        
        // 檢查 SUPABASE_ANON_KEY
        guard let key = plist["SUPABASE_ANON_KEY"] as? String, !key.isEmpty else {
            print("❌ Config.plist 中缺少 SUPABASE_ANON_KEY 或值為空")
            return false
        }
        
        guard key.hasPrefix("eyJ") else {
            print("❌ SUPABASE_ANON_KEY 格式錯誤")
            return false
        }
        
        return true
    }
}

import Network

class SupabaseManager: ObservableObject {
    static let shared = SupabaseManager()
    
    let client: Supabase.SupabaseClient
    private let networkMonitor = NWPathMonitor()
    private let networkQueue = DispatchQueue(label: "NetworkMonitor")
    @Published var isNetworkAvailable = true
    @Published var isDatabaseConfigured = false
    @Published var configurationError: String?
    
    private init() {
        print("🔧 Supabase Configuration:")
        
        // 首先驗證配置
        guard SupabaseConfig.validateConfiguration() else {
            self.isDatabaseConfigured = false
            self.configurationError = "Supabase 配置驗證失敗"
            // 創建一個假的客戶端以避免崩潰
            self.client = Supabase.SupabaseClient(
                supabaseURL: URL(string: "https://placeholder.supabase.co")!,
                supabaseKey: "placeholder-key"
            )
            return
        }
        
        print("📍 URL: \(SupabaseConfig.supabaseURL)")
        print("🔑 Key: \(SupabaseConfig.supabaseKey.prefix(10))...")
        
        // 添加測試代碼
        guard let url = URL(string: SupabaseConfig.supabaseURL) else {
            self.isDatabaseConfigured = false
            self.configurationError = "無效的 Supabase URL: \(SupabaseConfig.supabaseURL)"
            self.client = Supabase.SupabaseClient(
                supabaseURL: URL(string: "https://placeholder.supabase.co")!,
                supabaseKey: "placeholder-key"
            )
            return
        }
        
        print("URL: `https://nrywmiipclxrgtivyzdc.supabase.co` ", url.absoluteString)
        print("Key prefix:eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5yeXdtaWlwY2x4cmd0aXZ5emRjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTg2ODA4NjQsImV4cCI6MjA3NDI1Njg2NH0._LYZbDntt678dxIj0joYzrpNueN4YkBJcnJ4FkRZbvs", SupabaseConfig.supabaseKey.prefix(8))
        
        // 配置 Supabase 客戶端，增加超時設定
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30.0
        configuration.timeoutIntervalForResource = 60.0
        configuration.waitsForConnectivity = true
        
        let session = URLSession(configuration: configuration)
        
        self.client = Supabase.SupabaseClient(
            supabaseURL: url,
            supabaseKey: SupabaseConfig.supabaseKey,
            options: SupabaseClientOptions(
                auth: SupabaseClientOptions.AuthOptions(
                    redirectToURL: URL(string: "oqe.mmr.app://auth/callback")
                ),
                global: SupabaseClientOptions.GlobalOptions(
                    session: session,
                    logger: SupabaseLogger()
                )
            )
        )
        
        print("✅ Supabase client initialized successfully")
        self.isDatabaseConfigured = true
        
        // 開始監控網路狀態
        startNetworkMonitoring()
        
        // 測試資料庫連接
        Task {
            await testDatabaseConnection()
        }
    }
    
    private func startNetworkMonitoring() {
        networkMonitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isNetworkAvailable = path.status == .satisfied
                print("🌐 Network status: \(path.status == .satisfied ? "Connected" : "Disconnected")")
            }
        }
        networkMonitor.start(queue: networkQueue)
    }
    
    // 網路連線檢測函數
    func checkNetworkConnection() async -> Bool {
        return await withCheckedContinuation { continuation in
            let monitor = NWPathMonitor()
            let queue = DispatchQueue(label: "NetworkCheck")
            let lock = NSLock()
            var hasResumed = false
            
            monitor.pathUpdateHandler = { path in
                monitor.cancel()
                lock.lock()
                if !hasResumed {
                    hasResumed = true
                    lock.unlock()
                    continuation.resume(returning: path.status == .satisfied)
                } else {
                    lock.unlock()
                }
            }
            
            monitor.start(queue: queue)
            
            // 5秒超時
            DispatchQueue.global().asyncAfter(deadline: .now() + 5) {
                monitor.cancel()
                lock.lock()
                if !hasResumed {
                    hasResumed = true
                    lock.unlock()
                    continuation.resume(returning: false)
                } else {
                    lock.unlock()
                }
            }
        }
    }
    
    // 帶重試機制的網路請求
    func performWithRetry<T>(
        operation: @escaping () async throws -> T,
        maxRetries: Int = 3,
        delay: TimeInterval = 2.0
    ) async throws -> T {
        var lastError: Error?
        
        for attempt in 1...maxRetries {
            do {
                print("🔄 嘗試第 \(attempt) 次請求...")
                
                // 檢查網路連線
                let isConnected = await checkNetworkConnection()
                if !isConnected {
                    throw NetworkError.noConnection
                }
                
                let result = try await operation()
                print("✅ 請求成功")
                return result
                
            } catch {
                lastError = error
                print("❌ 第 \(attempt) 次嘗試失敗: \(error.localizedDescription)")
                
                if attempt < maxRetries {
                    print("⏳ 等待 \(delay) 秒後重試...")
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
            }
        }
        
        throw lastError ?? NetworkError.maxRetriesExceeded
    }
    
    func getCurrentUserId() async -> String? {
        do {
            let session = try await client.auth.session
            return session.user.id.uuidString
        } catch {
            print("❌ 無法獲取當前用戶 ID: \(error)")
            return nil
        }
    }
    
    // 添加資料庫連接測試方法
    func testDatabaseConnection() async {
        print("🔍 開始測試資料庫連接...")
        
        // 檢查網路連接
        let hasNetwork = await checkNetworkConnection()
        if !hasNetwork {
            configurationError = "無網路連接，請檢查網路設定"
            isDatabaseConfigured = false
            return
        }
        
        do {
            // 嘗試執行一個簡單的查詢來測試連接
            _ = try await client
                .from("profiles")
                .select("id")
                .limit(1)
                .execute()
            
            print("✅ 資料庫連接測試成功")
            isDatabaseConfigured = true
            configurationError = nil
        } catch {
            print("❌ 資料庫連接測試失敗: \(error)")
            
            // 根據錯誤類型提供更詳細的診斷信息
            if let urlError = error as? URLError {
                switch urlError.code {
                case .notConnectedToInternet:
                    configurationError = "無網路連接，請檢查網路設定"
                case .timedOut:
                    configurationError = "連接超時，請檢查網路狀況或 Supabase 服務狀態"
                case .cannotFindHost:
                    configurationError = "無法找到 Supabase 伺服器，請檢查 SUPABASE_URL 設定"
                default:
                    configurationError = "網路連接錯誤：\(urlError.localizedDescription)"
                }
            } else if error.localizedDescription.contains("401") {
                configurationError = "認證失敗，請檢查 SUPABASE_ANON_KEY 是否正確"
            } else if error.localizedDescription.contains("404") {
                configurationError = "找不到資源，請檢查 Supabase 專案設定"
            } else if error.localizedDescription.contains("profiles") {
                configurationError = "資料庫表格 'profiles' 不存在，請檢查資料庫結構設定"
            } else {
                configurationError = "資料庫連接失敗：\(error.localizedDescription)"
            }
            
            isDatabaseConfigured = false
        }
    }
    
    // 添加重新測試連接的方法
    func retryDatabaseConnection() {
        configurationError = nil
        Task {
            await testDatabaseConnection()
        }
    }
}

// 自定義網路錯誤
enum NetworkError: Error, LocalizedError {
    case noConnection
    case maxRetriesExceeded
    
    var errorDescription: String? {
        switch self {
        case .noConnection:
            return "無網路連線"
        case .maxRetriesExceeded:
            return "已達到最大重試次數"
        }
    }
}

// 自定義日誌記錄器
struct SupabaseLogger: Supabase.SupabaseLogger {
    func log(message: SupabaseLogMessage) {
        print("📡 Supabase [\(message.level)]: \(message.description)")
    }
}