-- ==============================================================================
-- COMPOUND COFFEE - MULTI-TENANT VERİTABANI ŞEMASI & RLS GÜVENLİK KURALLARI
-- ==============================================================================
-- Bu scripti Supabase Dashboard -> SQL Editor kısmına yapıştırıp "Run" butonuna basarak
-- tüm tabloları, ilişkileri, güvenlik kurallarını ve tetikleyicileri tek seferde oluşturabilirsiniz.

-- 1. EXTENSIONS
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ==============================================================================
-- 2. TABLOLAR
-- ==============================================================================

-- 2.1. FİRMALAR (COMPANIES) TABLOSU
-- Her bir ofis, plaza, şirket veya kahve noktası ayrı bir "Firma"dır.
CREATE TABLE IF NOT EXISTS public.companies (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    company_code TEXT UNIQUE NOT NULL, -- Örn: 'CMP-34', 'TRND-MASLAK'
    allowed_domains TEXT[] DEFAULT '{}', -- Örn: ARRAY['@trendyol.com', '@getir.com']
    logo_url TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2.2. KULLANICI PROFİLLERİ (PROFILES) TABLOSU
-- Supabase Auth tablosundaki kullanıcıların uygulama içi profilleri ve rolleri
DO $$ BEGIN
    CREATE TYPE user_role AS ENUM ('customer', 'kitchen', 'admin');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    company_id UUID REFERENCES public.companies(id) ON DELETE SET NULL,
    full_name TEXT,
    email TEXT,
    avatar_url TEXT,
    phone_number TEXT,
    role user_role DEFAULT 'customer' NOT NULL,
    loyalty_stamps INT DEFAULT 0,
    free_coffees_available INT DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2.3. TESLİMAT NOKTALARI (DELIVERY LOCATIONS) TABLOSU
-- Her şirketin kendi ofisindeki teslimat noktaları (Toplantı odaları, katlar, masalar)
CREATE TABLE IF NOT EXISTS public.delivery_locations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    company_id UUID NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    icon TEXT DEFAULT '🏢',
    is_room BOOLEAN DEFAULT false,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2.4. ÜRÜNLER (PRODUCTS) TABLOSU
CREATE TABLE IF NOT EXISTS public.products (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    company_id UUID NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    base_price NUMERIC(10, 2) NOT NULL DEFAULT 0.00,
    image_url TEXT,
    category TEXT NOT NULL, -- 'drink' veya 'snack'
    is_infinite_stock BOOLEAN DEFAULT true,
    stock_quantity INT DEFAULT 0,
    is_available BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2.5. ÜRÜN OPSİYON GRUPLARI (MODIFIER GROUPS)
-- Örn: Süt Seçimi (Soya, Yulaf, Badem), Şurup Seçimi, Boyut Seçimi
CREATE TABLE IF NOT EXISTS public.modifier_groups (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    product_id UUID NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    is_required BOOLEAN DEFAULT false,
    is_multi_select BOOLEAN DEFAULT false,
    dependent_on_variant_id TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2.6. OPSİYONLAR (PRODUCT MODIFIERS)
CREATE TABLE IF NOT EXISTS public.product_modifiers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    group_id UUID NOT NULL REFERENCES public.modifier_groups(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    price NUMERIC(10, 2) DEFAULT 0.00,
    is_available BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2.7. SİPARİŞLER (ORDERS) TABLOSU
DO $$ BEGIN
    CREATE TYPE order_status AS ENUM ('received', 'preparing', 'onTheWay', 'delivered', 'cancelled');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE payment_method_type AS ENUM ('googlePay', 'payAtDoor', 'creditCard');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

CREATE TABLE IF NOT EXISTS public.orders (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    company_id UUID NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
    customer_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    customer_name TEXT NOT NULL,
    location_name TEXT NOT NULL,
    total_price NUMERIC(10, 2) NOT NULL,
    payment_method payment_method_type DEFAULT 'googlePay',
    status order_status DEFAULT 'received' NOT NULL,
    gift_note TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2.8. SİPARİŞ KALEMLERİ (ORDER ITEMS) TABLOSU
CREATE TABLE IF NOT EXISTS public.order_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id UUID NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
    product_id UUID REFERENCES public.products(id) ON DELETE SET NULL,
    product_name TEXT NOT NULL,
    quantity INT DEFAULT 1 NOT NULL,
    unit_price NUMERIC(10, 2) NOT NULL,
    selected_modifiers JSONB DEFAULT '[]'::JSONB,
    note TEXT,
    added_by TEXT DEFAULT 'Müşteri',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ==============================================================================
-- 3. ROW LEVEL SECURITY (RLS) - ÇOKLU FİRMA VERİ İZOLASYONU & GÜVENLİK
-- ==============================================================================
ALTER TABLE public.companies ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.delivery_locations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.modifier_groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.product_modifiers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_items ENABLE ROW LEVEL SECURITY;

-- 3.1. COMPANIES POLİTİKALARI
DROP POLICY IF EXISTS "Public companies viewable" ON public.companies;
CREATE POLICY "Public companies viewable" 
    ON public.companies FOR SELECT 
    USING (is_active = true);

-- 3.2. PROFILES POLİTİKALARI
DROP POLICY IF EXISTS "Users can view own profile" ON public.profiles;
CREATE POLICY "Users can view own profile" 
    ON public.profiles FOR SELECT 
    USING (auth.uid() = id);

DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
CREATE POLICY "Users can update own profile" 
    ON public.profiles FOR UPDATE 
    USING (auth.uid() = id);

DROP POLICY IF EXISTS "Staff can view company profiles" ON public.profiles;
CREATE POLICY "Staff can view company profiles" 
    ON public.profiles FOR SELECT 
    USING (
        EXISTS (
            SELECT 1 FROM public.profiles AS staff 
            WHERE staff.id = auth.uid() 
            AND (staff.role = 'admin' OR staff.role = 'kitchen')
            AND staff.company_id = profiles.company_id
        )
    );

-- 3.3. PRODUCTS & LOCATIONS POLİTİKALARI
DROP POLICY IF EXISTS "Users view company products" ON public.products;
CREATE POLICY "Users view company products" 
    ON public.products FOR SELECT 
    USING (
        company_id IN (
            SELECT company_id FROM public.profiles WHERE id = auth.uid()
        )
    );

DROP POLICY IF EXISTS "Staff can manage company products" ON public.products;
CREATE POLICY "Staff can manage company products" 
    ON public.products FOR ALL 
    USING (
        EXISTS (
            SELECT 1 FROM public.profiles 
            WHERE profiles.id = auth.uid() 
            AND (profiles.role = 'admin' OR profiles.role = 'kitchen') 
            AND profiles.company_id = products.company_id
        )
    );

DROP POLICY IF EXISTS "Users view company locations" ON public.delivery_locations;
CREATE POLICY "Users view company locations" 
    ON public.delivery_locations FOR SELECT 
    USING (
        company_id IN (
            SELECT company_id FROM public.profiles WHERE id = auth.uid()
        )
    );

DROP POLICY IF EXISTS "Public modifiers viewable" ON public.modifier_groups;
CREATE POLICY "Public modifiers viewable" 
    ON public.modifier_groups FOR SELECT 
    USING (true);

DROP POLICY IF EXISTS "Public modifier options viewable" ON public.product_modifiers;
CREATE POLICY "Public modifier options viewable" 
    ON public.product_modifiers FOR SELECT 
    USING (true);

-- 3.4. ORDERS & ORDER ITEMS POLİTİKALARI
DROP POLICY IF EXISTS "Customers view own orders" ON public.orders;
CREATE POLICY "Customers view own orders" 
    ON public.orders FOR SELECT 
    USING (
        customer_id = auth.uid()
    );

DROP POLICY IF EXISTS "Customers create orders" ON public.orders;
CREATE POLICY "Customers create orders" 
    ON public.orders FOR INSERT 
    WITH CHECK (
        company_id IN (
            SELECT company_id FROM public.profiles WHERE id = auth.uid()
        )
    );

DROP POLICY IF EXISTS "Staff view and update company orders" ON public.orders;
CREATE POLICY "Staff view and update company orders" 
    ON public.orders FOR ALL 
    USING (
        EXISTS (
            SELECT 1 FROM public.profiles 
            WHERE profiles.id = auth.uid() 
            AND (profiles.role = 'admin' OR profiles.role = 'kitchen') 
            AND profiles.company_id = orders.company_id
        )
    );

DROP POLICY IF EXISTS "Order items viewable by order owner or staff" ON public.order_items;
CREATE POLICY "Order items viewable by order owner or staff" 
    ON public.order_items FOR ALL 
    USING (
        EXISTS (
            SELECT 1 FROM public.orders 
            WHERE orders.id = order_items.order_id 
            AND (
                orders.customer_id = auth.uid() 
                OR EXISTS (
                    SELECT 1 FROM public.profiles 
                    WHERE profiles.id = auth.uid() 
                    AND (profiles.role = 'admin' OR profiles.role = 'kitchen')
                    AND profiles.company_id = orders.company_id
                )
            )
        )
    );

-- ==============================================================================
-- 4. OTOMATİK TETİKLEYİCİLER (TRIGGERS & FUNCTIONS)
-- ==============================================================================

CREATE OR REPLACE FUNCTION public.handle_new_user() 
RETURNS TRIGGER AS $$
DECLARE
    detected_company_id UUID;
    user_domain TEXT;
BEGIN
    IF NEW.email IS NOT NULL AND POSITION('@' IN NEW.email) > 0 THEN
        user_domain := SUBSTRING(NEW.email FROM POSITION('@' IN NEW.email));
        
        SELECT id INTO detected_company_id 
        FROM public.companies 
        WHERE user_domain = ANY(allowed_domains) 
        LIMIT 1;
    END IF;

    INSERT INTO public.profiles (
        id, 
        full_name, 
        email, 
        avatar_url, 
        company_id, 
        role
    )
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.raw_user_meta_data->>'name', 'Yeni Müşteri'),
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'avatar_url', NEW.raw_user_meta_data->>'picture', NULL),
        detected_company_id,
        'customer'
    )
    ON CONFLICT (id) DO UPDATE SET
        full_name = EXCLUDED.full_name,
        avatar_url = EXCLUDED.avatar_url,
        updated_at = NOW();

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ==============================================================================
-- 5. REALTIME ETKİNLEŞTİRME (Mutfak KDS & Sipariş Takibi İçin)
-- ==============================================================================
DO $$ BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.orders;
EXCEPTION
    WHEN duplicate_object THEN null;
    WHEN others THEN null;
END $$;

DO $$ BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.products;
EXCEPTION
    WHEN duplicate_object THEN null;
    WHEN others THEN null;
END $$;

-- ==============================================================================
-- 6. ÖRNEK BAŞLANGIÇ VERİLERİ (SEED DATA)
-- ==============================================================================

-- Örnek Şirketler
INSERT INTO public.companies (id, name, company_code, allowed_domains)
VALUES 
    ('a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'Compound Coffee - Maslak Hub', 'CMP-34', ARRAY['@compound.coffee', '@maslakhub.com']),
    ('b0eebc99-9c0b-4ef8-bb6d-6bb9bd380a22', 'Teknopark İstanbul İnovasyon', 'TKP-01', ARRAY['@teknopark.istanbul'])
ON CONFLICT (company_code) DO NOTHING;

-- Örnek Teslimat Noktaları
INSERT INTO public.delivery_locations (company_id, name, icon, is_room)
VALUES 
    ('a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'Masam / Açık Ofis', '🏢', false),
    ('a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'Proje Laboratuvarı', '🧪', false),
    ('a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'A1 Toplantı Odası', '🤝', true),
    ('a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'B3 Yönetim Odası', '🤝', true)
ON CONFLICT DO NOTHING;

-- Örnek Ürünler
INSERT INTO public.products (id, company_id, name, description, base_price, category, image_url, is_infinite_stock, stock_quantity)
VALUES 
    ('c0eebc99-9c0b-4ef8-bb6d-6bb9bd380001', 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'Americano', 'Sıcak su ile inceltilmiş çift shot espresso.', 65.00, 'drink', 'https://images.unsplash.com/photo-1551030173-122aabc4489c?w=500', true, 100),
    ('c0eebc99-9c0b-4ef8-bb6d-6bb9bd380002', 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'Caffe Latte', 'Espresso ve ipeksi kıvamda buharda ısıtılmış süt.', 75.00, 'drink', 'https://images.unsplash.com/photo-1534778101976-62847782c213?w=500', true, 100),
    ('c0eebc99-9c0b-4ef8-bb6d-6bb9bd380003', 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'Flat White', 'Çift shot ristretto ve mikro köpüklü süt.', 80.00, 'drink', 'https://images.unsplash.com/photo-1577968897966-3d4325b36b61?w=500', true, 100),
    ('c0eebc99-9c0b-4ef8-bb6d-6bb9bd380004', 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'Filtre Kahve', 'Günün taze demlenmiş özel harman kahvesi.', 55.00, 'drink', 'https://images.unsplash.com/photo-1514432324607-a09d9b4aefdd?w=500', true, 100),
    ('c0eebc99-9c0b-4ef8-bb6d-6bb9bd380005', 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'San Sebastian Cheesecake', 'Akışkan iç kıvam ve hafif karamelize yanık üst doku.', 110.00, 'snack', 'https://images.unsplash.com/photo-1533134242443-d4fd215305ad?w=500', false, 8),
    ('c0eebc99-9c0b-4ef8-bb6d-6bb9bd380006', 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'Kruvasan', 'Hakiki tereyağlı, kat kat çıtır Fransız kruvasanı.', 70.00, 'snack', 'https://images.unsplash.com/photo-1555507036-ab1f4038808a?w=500', false, 12)
ON CONFLICT DO NOTHING;

-- Örnek Opsiyon Grubu (Latte için Süt Seçimi)
INSERT INTO public.modifier_groups (id, product_id, name, is_required, is_multi_select)
VALUES 
    ('d0eebc99-9c0b-4ef8-bb6d-6bb9bd380001', 'c0eebc99-9c0b-4ef8-bb6d-6bb9bd380002', 'Süt Tercihi', true, false)
ON CONFLICT DO NOTHING;

INSERT INTO public.product_modifiers (group_id, name, price)
VALUES 
    ('d0eebc99-9c0b-4ef8-bb6d-6bb9bd380001', 'Tam Yağlı İnek Sütü', 0.00),
    ('d0eebc99-9c0b-4ef8-bb6d-6bb9bd380001', 'Yulaf Sütü', 15.00),
    ('d0eebc99-9c0b-4ef8-bb6d-6bb9bd380001', 'Badem Sütü', 18.00),
    ('d0eebc99-9c0b-4ef8-bb6d-6bb9bd380001', 'Laktozsuz Süt', 5.00)
ON CONFLICT DO NOTHING;
