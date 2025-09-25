# MedicationButler App - Supabase 設定指南

## 📋 概述

此指南將協助您為 MedicationButler App 設定完整的 Supabase 資料庫架構。資料庫包含四個核心表格，支援使用者管理、藥物追蹤、服藥記錄和關懷者功能。

## 🗄️ 資料庫架構

### 核心表格

1. **`profiles`** - 使用者基本資料
2. **`medications`** - 藥物資訊和排程
3. **`adherence_logs`** - 服藥記錄
4. **`care_links`** - 關懷者連結關係

## 🚀 快速設定

### 步驟 1: 執行 SQL 架構

1. 登入您的 [Supabase Dashboard](https://app.supabase.com)
2. 選擇您的專案
3. 前往 **SQL Editor**
4. 複製 `supabase_schema.sql` 檔案的內容
5. 貼上並執行 SQL 語句

### 步驟 2: 驗證設定

執行以下查詢來驗證表格是否正確創建：

```sql
-- 檢查所有表格是否存在
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('profiles', 'medications', 'adherence_logs', 'care_links');

-- 檢查 RLS 是否啟用
SELECT schemaname, tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public' 
AND tablename IN ('profiles', 'medications', 'adherence_logs', 'care_links');
```

## 📊 表格詳細說明

### 1. profiles 表格

```sql
-- 欄位說明
id          UUID      -- 關聯至 auth.users(id)
phone       TEXT      -- 電話號碼
full_name   TEXT      -- 使用者全名
role        TEXT      -- 角色：'user' 或 'caregiver'
created_at  TIMESTAMP -- 創建時間
updated_at  TIMESTAMP -- 更新時間
```

**使用範例：**
```sql
-- 插入使用者資料
INSERT INTO profiles (id, full_name, phone, role) 
VALUES (auth.uid(), '張小明', '0912345678', 'user');
```

### 2. medications 表格

```sql
-- 欄位說明
id                 UUID    -- 主鍵
user_id           UUID    -- 關聯至 profiles(id)
name              TEXT    -- 藥物名稱
dosage            TEXT    -- 劑量
schedule_type     TEXT    -- 排程類型：'daily', 'weekly', 'as_needed', 'custom'
notification_times JSONB   -- 提醒時間陣列，如 ["08:00", "20:00"]
is_active         BOOLEAN -- 是否啟用
created_at        TIMESTAMP
updated_at        TIMESTAMP
```

**使用範例：**
```sql
-- 新增藥物
INSERT INTO medications (user_id, name, dosage, schedule_type, notification_times) 
VALUES (
    auth.uid(), 
    '維他命D', 
    '1000IU', 
    'daily', 
    '["08:00", "20:00"]'::jsonb
);
```

### 3. adherence_logs 表格

```sql
-- 欄位說明
id             UUID      -- 主鍵
medication_id  UUID      -- 關聯至 medications(id)
user_id        UUID      -- 關聯至 profiles(id)
status         TEXT      -- 狀態：'taken', 'missed', 'skipped'
scheduled_time TIMESTAMP -- 預定服藥時間
logged_at      TIMESTAMP -- 記錄時間
notes          TEXT      -- 備註
```

**使用範例：**
```sql
-- 記錄服藥
INSERT INTO adherence_logs (medication_id, user_id, status, scheduled_time) 
VALUES (
    'medication-uuid', 
    auth.uid(), 
    'taken', 
    '2024-01-15 08:00:00+00'
);
```

### 4. care_links 表格

```sql
-- 欄位說明
id           UUID      -- 主鍵
caregiver_id UUID      -- 關懷者 ID
user_id      UUID      -- 被關懷者 ID
status       TEXT      -- 狀態：'pending', 'accepted', 'rejected', 'cancelled'
invite_code  TEXT      -- 邀請碼（自動生成）
created_at   TIMESTAMP
updated_at   TIMESTAMP
expires_at   TIMESTAMP -- 邀請過期時間（7天）
```

**使用範例：**
```sql
-- 創建關懷邀請
INSERT INTO care_links (caregiver_id, user_id) 
VALUES (auth.uid(), 'target-user-uuid');

-- 接受邀請
UPDATE care_links 
SET status = 'accepted' 
WHERE invite_code = 'ABC12345' AND user_id = auth.uid();
```

## 🔒 安全策略 (RLS)

### 資料存取權限

- **個人資料**：使用者只能存取自己的資料
- **關懷功能**：關懷者可以查看已接受關懷關係的使用者資料
- **邀請管理**：關懷者管理發起的邀請，被關懷者可回應邀請

### 策略驗證

```sql
-- 測試 RLS 策略
SELECT * FROM profiles; -- 只會顯示當前使用者的資料
SELECT * FROM medications; -- 只會顯示當前使用者的藥物
```

## 📈 實用查詢

### 服藥統計

```sql
-- 查看個人服藥統計
SELECT * FROM medication_adherence_stats 
WHERE user_id = auth.uid();
```

### 關懷關係

```sql
-- 查看活躍的關懷關係
SELECT * FROM active_care_relationships 
WHERE caregiver_id = auth.uid() OR user_id = auth.uid();
```

### 今日服藥記錄

```sql
-- 查看今日服藥記錄
SELECT m.name, al.status, al.scheduled_time, al.logged_at
FROM adherence_logs al
JOIN medications m ON al.medication_id = m.id
WHERE al.user_id = auth.uid() 
AND DATE(al.scheduled_time) = CURRENT_DATE
ORDER BY al.scheduled_time;
```

## 🔧 維護建議

### 定期清理

```sql
-- 清理過期的邀請
DELETE FROM care_links 
WHERE status = 'pending' AND expires_at < NOW();
```

### 效能監控

- 定期檢查索引使用情況
- 監控查詢效能
- 清理舊的服藥記錄（可選）

## 📱 客戶端整合

在您的 SwiftUI 應用中，使用 Supabase Swift 客戶端：

```swift
// 初始化 Supabase 客戶端
let supabase = SupabaseClient(
    supabaseURL: URL(string: "YOUR_SUPABASE_URL")!,
    supabaseKey: "YOUR_SUPABASE_ANON_KEY"
)

// 查詢使用者藥物
let medications: [Medication] = try await supabase
    .from("medications")
    .select()
    .eq("user_id", value: user.id)
    .execute()
    .value
```

## 🆘 疑難排解

### 常見問題

1. **RLS 策略錯誤**：確保使用者已通過身份驗證
2. **外鍵約束錯誤**：檢查關聯的記錄是否存在
3. **JSON 格式錯誤**：確保 notification_times 使用正確的 JSON 格式

### 支援資源

- [Supabase 官方文檔](https://supabase.com/docs)
- [Row Level Security 指南](https://supabase.com/docs/guides/auth/row-level-security)
- [PostgreSQL JSON 函數](https://www.postgresql.org/docs/current/functions-json.html)

---

**注意**：請確保在生產環境中妥善保護您的 Supabase 金鑰和資料庫連線資訊。