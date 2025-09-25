-- 創建用戶資料表
CREATE TABLE IF NOT EXISTS public.users (
    id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    full_name TEXT,
    email TEXT UNIQUE,
    phone_number TEXT,
    role TEXT CHECK (role IN ('patient', 'doctor', 'admin')),
    avatar_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 創建更新時間觸發器
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_users_updated_at 
    BEFORE UPDATE ON public.users 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- 設置行級安全性 (RLS)
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- 創建 RLS 政策
CREATE POLICY "Users can view own profile" ON public.users
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON public.users
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile" ON public.users
    FOR INSERT WITH CHECK (auth.uid() = id);

-- 創建自動插入用戶資料的函數
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.users (id, full_name, email)
    VALUES (
        NEW.id,
        NEW.raw_user_meta_data->>'full_name',
        NEW.email
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 創建觸發器，當新用戶註冊時自動創建用戶資料
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 創建醫生資料表（如果需要）
CREATE TABLE IF NOT EXISTS public.doctors (
    id UUID REFERENCES public.users(id) ON DELETE CASCADE PRIMARY KEY,
    license_number TEXT UNIQUE,
    specialization TEXT,
    hospital_affiliation TEXT,
    years_of_experience INTEGER,
    consultation_fee DECIMAL(10,2),
    is_verified BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 為醫生表設置 RLS
ALTER TABLE public.doctors ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Doctors can view own profile" ON public.doctors
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Doctors can update own profile" ON public.doctors
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Anyone can view verified doctors" ON public.doctors
    FOR SELECT USING (is_verified = TRUE);

-- 創建患者資料表（如果需要）
CREATE TABLE IF NOT EXISTS public.patients (
    id UUID REFERENCES public.users(id) ON DELETE CASCADE PRIMARY KEY,
    date_of_birth DATE,
    gender TEXT CHECK (gender IN ('male', 'female', 'other')),
    blood_type TEXT,
    allergies TEXT[],
    medical_history TEXT,
    emergency_contact_name TEXT,
    emergency_contact_phone TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 為患者表設置 RLS
ALTER TABLE public.patients ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Patients can view own profile" ON public.patients
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Patients can update own profile" ON public.patients
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Doctors can view patient profiles" ON public.patients
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.users 
            WHERE id = auth.uid() AND role = 'doctor'
        )
    );