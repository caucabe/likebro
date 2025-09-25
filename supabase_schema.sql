-- MedicationButler App - Supabase Database Schema
-- 此檔案包含完整的資料庫表格創建語句和 RLS 安全策略

-- =====================================================
-- 1. PROFILES 表格 - 使用者基本資料
-- =====================================================

-- 創建 profiles 表格
CREATE TABLE public.profiles (
    id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    phone TEXT,
    full_name TEXT NOT NULL,
    role TEXT NOT NULL CHECK (role IN ('user', 'caregiver')) DEFAULT 'user',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 啟用 RLS
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- RLS 策略：使用者只能查看和編輯自己的資料
CREATE POLICY "Users can view own profile" ON public.profiles
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON public.profiles
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile" ON public.profiles
    FOR INSERT WITH CHECK (auth.uid() = id);

-- =====================================================
-- 2. MEDICATIONS 表格 - 藥物資訊
-- =====================================================

-- 創建 medications 表格
CREATE TABLE public.medications (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    name TEXT NOT NULL,
    dosage TEXT NOT NULL,
    schedule_type TEXT NOT NULL CHECK (schedule_type IN ('daily', 'weekly', 'as_needed', 'custom')) DEFAULT 'daily',
    notification_times JSONB NOT NULL DEFAULT '[]'::jsonb,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 啟用 RLS
ALTER TABLE public.medications ENABLE ROW LEVEL SECURITY;

-- RLS 策略：使用者只能存取自己的藥物資料
CREATE POLICY "Users can view own medications" ON public.medications
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own medications" ON public.medications
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own medications" ON public.medications
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own medications" ON public.medications
    FOR DELETE USING (auth.uid() = user_id);

-- =====================================================
-- 3. ADHERENCE_LOGS 表格 - 服藥記錄
-- =====================================================

-- 創建 adherence_logs 表格
CREATE TABLE public.adherence_logs (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    medication_id UUID REFERENCES public.medications(id) ON DELETE CASCADE NOT NULL,
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    status TEXT NOT NULL CHECK (status IN ('taken', 'missed', 'skipped')) DEFAULT 'taken',
    scheduled_time TIMESTAMP WITH TIME ZONE NOT NULL,
    logged_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    notes TEXT
);

-- 啟用 RLS
ALTER TABLE public.adherence_logs ENABLE ROW LEVEL SECURITY;

-- RLS 策略：使用者只能存取自己的服藥記錄
CREATE POLICY "Users can view own adherence logs" ON public.adherence_logs
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own adherence logs" ON public.adherence_logs
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own adherence logs" ON public.adherence_logs
    FOR UPDATE USING (auth.uid() = user_id);

-- =====================================================
-- 4. CARE_LINKS 表格 - 關懷連結
-- =====================================================

-- 創建 care_links 表格
CREATE TABLE public.care_links (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    caregiver_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    status TEXT NOT NULL CHECK (status IN ('pending', 'accepted', 'rejected', 'cancelled')) DEFAULT 'pending',
    invite_code TEXT UNIQUE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE DEFAULT (NOW() + INTERVAL '7 days'),
    
    -- 確保同一對關係不會重複
    UNIQUE(caregiver_id, user_id)
);

-- 啟用 RLS
ALTER TABLE public.care_links ENABLE ROW LEVEL SECURITY;

-- RLS 策略：關懷者可以查看自己發起的邀請
CREATE POLICY "Caregivers can view own invitations" ON public.care_links
    FOR SELECT USING (auth.uid() = caregiver_id);

CREATE POLICY "Caregivers can insert invitations" ON public.care_links
    FOR INSERT WITH CHECK (auth.uid() = caregiver_id);

CREATE POLICY "Caregivers can update own invitations" ON public.care_links
    FOR UPDATE USING (auth.uid() = caregiver_id);

-- 被關懷者可以查看和回應針對自己的邀請
CREATE POLICY "Users can view invitations for themselves" ON public.care_links
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can respond to invitations" ON public.care_links
    FOR UPDATE USING (auth.uid() = user_id);

-- =====================================================
-- 5. 索引優化
-- =====================================================

-- 為常用查詢創建索引
CREATE INDEX idx_medications_user_id ON public.medications(user_id);
CREATE INDEX idx_medications_active ON public.medications(user_id, is_active);
CREATE INDEX idx_adherence_logs_user_id ON public.adherence_logs(user_id);
CREATE INDEX idx_adherence_logs_medication_id ON public.adherence_logs(medication_id);
CREATE INDEX idx_adherence_logs_scheduled_time ON public.adherence_logs(scheduled_time);
CREATE INDEX idx_care_links_caregiver_id ON public.care_links(caregiver_id);
CREATE INDEX idx_care_links_user_id ON public.care_links(user_id);
CREATE INDEX idx_care_links_invite_code ON public.care_links(invite_code);
CREATE INDEX idx_care_links_status ON public.care_links(status);

-- =====================================================
-- 6. 觸發器 - 自動更新時間戳
-- =====================================================

-- 創建更新時間戳的函數
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- 為需要的表格添加觸發器
CREATE TRIGGER update_profiles_updated_at 
    BEFORE UPDATE ON public.profiles 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_medications_updated_at 
    BEFORE UPDATE ON public.medications 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_care_links_updated_at 
    BEFORE UPDATE ON public.care_links 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- 7. 邀請碼生成函數
-- =====================================================

-- 創建生成邀請碼的函數
CREATE OR REPLACE FUNCTION generate_invite_code()
RETURNS TEXT AS $$
DECLARE
    chars TEXT := 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    result TEXT := '';
    i INTEGER;
BEGIN
    FOR i IN 1..8 LOOP
        result := result || substr(chars, floor(random() * length(chars) + 1)::integer, 1);
    END LOOP;
    RETURN result;
END;
$$ LANGUAGE plpgsql;

-- 為 care_links 表格添加自動生成邀請碼的觸發器
CREATE OR REPLACE FUNCTION set_invite_code()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.invite_code IS NULL OR NEW.invite_code = '' THEN
        NEW.invite_code := generate_invite_code();
        -- 確保邀請碼唯一
        WHILE EXISTS (SELECT 1 FROM public.care_links WHERE invite_code = NEW.invite_code) LOOP
            NEW.invite_code := generate_invite_code();
        END LOOP;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_care_links_invite_code 
    BEFORE INSERT ON public.care_links 
    FOR EACH ROW EXECUTE FUNCTION set_invite_code();

-- =====================================================
-- 8. 實用視圖 (Views)
-- =====================================================

-- 創建關懷關係視圖，方便查詢
CREATE VIEW public.active_care_relationships AS
SELECT 
    cl.id,
    cl.caregiver_id,
    cp.full_name as caregiver_name,
    cl.user_id,
    up.full_name as user_name,
    cl.created_at
FROM public.care_links cl
JOIN public.profiles cp ON cl.caregiver_id = cp.id
JOIN public.profiles up ON cl.user_id = up.id
WHERE cl.status = 'accepted';

-- 創建服藥統計視圖
CREATE VIEW public.medication_adherence_stats AS
SELECT 
    m.id as medication_id,
    m.name as medication_name,
    m.user_id,
    COUNT(al.id) as total_logs,
    COUNT(CASE WHEN al.status = 'taken' THEN 1 END) as taken_count,
    COUNT(CASE WHEN al.status = 'missed' THEN 1 END) as missed_count,
    COUNT(CASE WHEN al.status = 'skipped' THEN 1 END) as skipped_count,
    ROUND(
        (COUNT(CASE WHEN al.status = 'taken' THEN 1 END)::DECIMAL / 
         NULLIF(COUNT(al.id), 0)) * 100, 2
    ) as adherence_rate
FROM public.medications m
LEFT JOIN public.adherence_logs al ON m.id = al.medication_id
WHERE m.is_active = true
GROUP BY m.id, m.name, m.user_id;

-- =====================================================
-- 10. 關懷者相關的額外 RLS 策略
-- =====================================================

-- 關懷者可以查看被關懷者的藥物資料
CREATE POLICY "Caregivers can view linked users medications" ON public.medications
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.care_links 
            WHERE caregiver_id = auth.uid() 
            AND user_id = medications.user_id 
            AND status = 'accepted'
        )
    );

-- 關懷者可以查看被關懷者的服藥記錄
CREATE POLICY "Caregivers can view linked users adherence logs" ON public.adherence_logs
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.care_links 
            WHERE caregiver_id = auth.uid() 
            AND user_id = adherence_logs.user_id 
            AND status = 'accepted'
        )
    );

-- =====================================================
-- 11. 安全策略說明
-- =====================================================

/*
RLS 安全策略總結：

1. profiles 表格：
   - 使用者只能查看、編輯和插入自己的資料

2. medications 表格：
   - 使用者可以完全管理自己的藥物資料
   - 關懷者可以查看已接受關懷關係的使用者藥物資料

3. adherence_logs 表格：
   - 使用者可以查看、插入和更新自己的服藥記錄
   - 關懷者可以查看已接受關懷關係的使用者服藥記錄

4. care_links 表格：
   - 關懷者可以管理自己發起的邀請
   - 被關懷者可以查看和回應針對自己的邀請

這些策略確保了資料的隱私性和安全性，同時允許必要的關懷功能。
*/