-- ============================================================
-- منصة إنابة المستقبل العقارية
-- Inabah Real Estate Platform - Database Schema
-- PostgreSQL with PostGIS Extension
-- ============================================================

-- تفعيل الإضافات المطلوبة
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "postgis";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================================
-- 1. نظام المستخدمين والصلاحيات (Users & RBAC)
-- ============================================================

-- جدول الأدوار
CREATE TABLE roles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(50) UNIQUE NOT NULL, -- super_admin, admin, broker, developer, owner, client
    name_ar VARCHAR(50) NOT NULL,
    name_en VARCHAR(50) NOT NULL,
    description TEXT,
    permissions JSONB NOT NULL DEFAULT '[]',
    hierarchy_level INTEGER NOT NULL DEFAULT 0, -- للترتيب الهرمي
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- جدول المستخدمين
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE NOT NULL,
    phone VARCHAR(20) UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    
    -- المعلومات الشخصية
    full_name_ar VARCHAR(255) NOT NULL,
    full_name_en VARCHAR(255),
    avatar_url TEXT,
    
    -- الدور والصلاحيات
    role_id UUID NOT NULL REFERENCES roles(id),
    
    -- الحالة
    is_active BOOLEAN DEFAULT true,
    is_verified BOOLEAN DEFAULT false,
    email_verified_at TIMESTAMP WITH TIME ZONE,
    phone_verified_at TIMESTAMP WITH TIME ZONE,
    
    -- الأمان
    two_factor_enabled BOOLEAN DEFAULT false,
    two_factor_secret VARCHAR(255),
    last_login_at TIMESTAMP WITH TIME ZONE,
    last_login_ip INET,
    failed_login_attempts INTEGER DEFAULT 0,
    locked_until TIMESTAMP WITH TIME ZONE,
    
    -- التفضيلات
    preferred_language VARCHAR(10) DEFAULT 'ar',
    preferred_currency VARCHAR(10) DEFAULT 'SAR',
    timezone VARCHAR(50) DEFAULT 'Asia/Riyadh',
    
    -- البيانات الوصفية
    metadata JSONB DEFAULT '{}',
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP WITH TIME ZONE -- للحذف الناعم
);

-- جدول الشركات (للمطورين والوسطاء)
CREATE TABLE companies (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- معلومات الشركة
    name_ar VARCHAR(255) NOT NULL,
    name_en VARCHAR(255),
    description TEXT,
    
    -- الترخيص
    license_number VARCHAR(100) UNIQUE,
    license_expiry_date DATE,
    commercial_registration VARCHAR(100),
    tax_number VARCHAR(100),
    
    -- التواصل
    email VARCHAR(255),
    phone VARCHAR(20),
    website VARCHAR(255),
    
    -- العنوان
    address TEXT,
    city VARCHAR(100),
    country VARCHAR(100) DEFAULT 'SA',
    
    -- الموقع الجغرافي
    location GEOGRAPHY(POINT, 4326),
    
    -- الشعار والصور
    logo_url TEXT,
    cover_image_url TEXT,
    
    -- المالك
    owner_id UUID REFERENCES users(id),
    
    -- الإحصائيات
    total_projects INTEGER DEFAULT 0,
    total_properties INTEGER DEFAULT 0,
    total_sales DECIMAL(20, 2) DEFAULT 0,
    
    -- الحالة
    is_active BOOLEAN DEFAULT true,
    is_verified BOOLEAN DEFAULT false,
    verification_status VARCHAR(50) DEFAULT 'pending', -- pending, approved, rejected
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- ربط المستخدمين بالشركات
CREATE TABLE user_companies (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    role_in_company VARCHAR(50) NOT NULL, -- owner, manager, agent
    is_primary BOOLEAN DEFAULT false,
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, company_id)
);

-- ============================================================
-- 2. المشاريع العقارية (Projects)
-- ============================================================

CREATE TABLE projects (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- المعلومات الأساسية
    name_ar VARCHAR(255) NOT NULL,
    name_en VARCHAR(255),
    slug VARCHAR(255) UNIQUE,
    description_ar TEXT,
    description_en TEXT,
    
    -- المطور
    developer_id UUID NOT NULL REFERENCES companies(id),
    developer_user_id UUID REFERENCES users(id), -- المستخدم المسؤول
    
    -- الموقع
    city VARCHAR(100) NOT NULL,
    district VARCHAR(100),
    address TEXT,
    location GEOGRAPHY(POINT, 4326),
    
    -- الملفات
    brochure_url TEXT,
    video_url TEXT,
    master_plan_url TEXT,
    
    -- التواريخ
    launch_date DATE,
    completion_date DATE,
    delivery_date DATE,
    
    -- الحالة
    status VARCHAR(50) DEFAULT 'upcoming', -- upcoming, selling, sold_out, delivered
    is_featured BOOLEAN DEFAULT false,
    is_active BOOLEAN DEFAULT true,
    
    -- الإحصائيات
    total_units INTEGER DEFAULT 0,
    available_units INTEGER DEFAULT 0,
    sold_units INTEGER DEFAULT 0,
    reserved_units INTEGER DEFAULT 0,
    
    -- الأسعار
    min_price DECIMAL(20, 2),
    max_price DECIMAL(20, 2),
    
    -- SEO
    meta_title VARCHAR(255),
    meta_description TEXT,
    meta_keywords TEXT,
    
    -- البيانات الوصفية
    amenities JSONB DEFAULT '[]',
    features JSONB DEFAULT '[]',
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id)
);

-- ============================================================
-- 3. الوحدات العقارية (Units/Properties)
-- ============================================================

CREATE TABLE properties (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- التصنيف
    property_type VARCHAR(50) NOT NULL, -- apartment, villa, land, office, shop
    listing_type VARCHAR(50) NOT NULL, -- sale, rent
    
    -- العنوان والوصف
    title_ar VARCHAR(255) NOT NULL,
    title_en VARCHAR(255),
    description_ar TEXT,
    description_en TEXT,
    slug VARCHAR(255) UNIQUE,
    
    -- الارتباط بالمشروع (اختياري للعقارات الخاصة)
    project_id UUID REFERENCES projects(id),
    
    -- المالك/الوسيط
    owner_id UUID NOT NULL REFERENCES users(id),
    owner_type VARCHAR(50) NOT NULL, -- developer, broker, private_owner
    
    -- الشركة (للمطورين والوسطاء)
    company_id UUID REFERENCES companies(id),
    
    -- الموقع
    city VARCHAR(100) NOT NULL,
    district VARCHAR(100),
    address TEXT,
    location GEOGRAPHY(POINT, 4326),
    
    -- التفاصيل
    unit_number VARCHAR(100),
    floor_number INTEGER,
    total_floors INTEGER,
    
    -- المساحات
    area DECIMAL(10, 2), -- المساحة الإجمالية
    built_up_area DECIMAL(10, 2),
    land_area DECIMAL(10, 2),
    
    -- الغرف
    bedrooms INTEGER,
    bathrooms INTEGER,
    living_rooms INTEGER,
    maid_rooms INTEGER,
    driver_rooms INTEGER,
    
    -- السعر
    price DECIMAL(20, 2) NOT NULL,
    price_per_meter DECIMAL(20, 2),
    currency VARCHAR(10) DEFAULT 'SAR',
    
    -- الحالة
    status VARCHAR(50) DEFAULT 'available', -- available, reserved, sold, rented, off_market
    availability_status VARCHAR(50) DEFAULT 'immediate', -- immediate, under_construction, future
    
    -- الموافقة
    is_approved BOOLEAN DEFAULT false,
    approved_by UUID REFERENCES users(id),
    approved_at TIMESTAMP WITH TIME ZONE,
    rejection_reason TEXT,
    
    -- المميزات
    is_featured BOOLEAN DEFAULT false,
    featured_until TIMESTAMP WITH TIME ZONE,
    is_premium BOOLEAN DEFAULT false,
    
    -- التواريخ
    year_built INTEGER,
    possession_date DATE,
    expiry_date DATE,
    
    -- المرافق والمميزات
    amenities JSONB DEFAULT '[]',
    features JSONB DEFAULT '[]',
    nearby_places JSONB DEFAULT '[]',
    
    -- SEO
    meta_title VARCHAR(255),
    meta_description TEXT,
    
    -- الإحصائيات
    view_count INTEGER DEFAULT 0,
    inquiry_count INTEGER DEFAULT 0,
    favorite_count INTEGER DEFAULT 0,
    
    -- البيانات الوصفية
    metadata JSONB DEFAULT '{}',
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id),
    deleted_at TIMESTAMP WITH TIME ZONE
);

-- جدول صور العقارات
CREATE TABLE property_images (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    property_id UUID NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
    image_url TEXT NOT NULL,
    thumbnail_url TEXT,
    is_main BOOLEAN DEFAULT false,
    caption_ar VARCHAR(255),
    caption_en VARCHAR(255),
    sort_order INTEGER DEFAULT 0,
    file_size INTEGER,
    mime_type VARCHAR(50),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- 4. نظام العمولات (Commission System)
-- ============================================================

CREATE TABLE commission_rules (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- اسم القاعدة
    name VARCHAR(255) NOT NULL,
    description TEXT,
    
    -- نسبة العمولة الأساسية
    base_rate DECIMAL(5, 2) NOT NULL DEFAULT 2.5, -- 2.5%
    
    -- توزيع العمولة
    listing_agent_share DECIMAL(5, 2) DEFAULT 20.0, -- 20% من العمولة
    selling_agent_share DECIMAL(5, 2) DEFAULT 20.0, -- 20% من العمولة
    platform_share DECIMAL(5, 2) DEFAULT 60.0, -- 60% للمنصة/الشركة
    
    -- شروط خاصة
    min_property_value DECIMAL(20, 2),
    max_property_value DECIMAL(20, 2),
    property_types JSONB,
    
    -- الضريبة
    vat_enabled BOOLEAN DEFAULT true,
    vat_rate DECIMAL(5, 2) DEFAULT 15.0,
    
    -- الحالة
    is_active BOOLEAN DEFAULT true,
    effective_from DATE NOT NULL,
    effective_until DATE,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- جدول الصفقات
CREATE TABLE deals (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- رقم الصفقة
    deal_number VARCHAR(100) UNIQUE NOT NULL,
    
    -- العقار
    property_id UUID NOT NULL REFERENCES properties(id),
    
    -- الوسطاء
    listing_agent_id UUID REFERENCES users(id), -- وسيط الإدراج
    selling_agent_id UUID REFERENCES users(id), -- وسيط البيع
    
    -- الشركات
    listing_company_id UUID REFERENCES companies(id),
    selling_company_id UUID REFERENCES companies(id),
    
    -- البائع والمشتري
    seller_id UUID NOT NULL REFERENCES users(id),
    buyer_id UUID NOT NULL REFERENCES users(id),
    
    -- تفاصيل الصفقة
    sale_price DECIMAL(20, 2) NOT NULL,
    currency VARCHAR(10) DEFAULT 'SAR',
    
    -- العمولة
    commission_rule_id UUID REFERENCES commission_rules(id),
    total_commission DECIMAL(20, 2) NOT NULL,
    commission_rate DECIMAL(5, 2) NOT NULL,
    
    -- توزيع العمولة
    listing_agent_commission DECIMAL(20, 2),
    selling_agent_commission DECIMAL(20, 2),
    platform_commission DECIMAL(20, 2),
    vat_amount DECIMAL(20, 2),
    
    -- الحالة
    status VARCHAR(50) DEFAULT 'pending', -- pending, approved, paid, cancelled, disputed
    
    -- التواريخ
    deal_date DATE NOT NULL,
    expected_payment_date DATE,
    actual_payment_date TIMESTAMP WITH TIME ZONE,
    
    -- المستندات
    contract_url TEXT,
    documents JSONB DEFAULT '[]',
    
    -- الملاحظات
    notes TEXT,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id),
    approved_by UUID REFERENCES users(id),
    approved_at TIMESTAMP WITH TIME ZONE
);

-- جدول محافظ المستخدمين
CREATE TABLE user_wallets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL UNIQUE REFERENCES users(id),
    
    -- الأرصدة
    available_balance DECIMAL(20, 2) DEFAULT 0,
    pending_balance DECIMAL(20, 2) DEFAULT 0,
    total_earned DECIMAL(20, 2) DEFAULT 0,
    total_withdrawn DECIMAL(20, 2) DEFAULT 0,
    
    -- الحدود
    min_withdrawal_amount DECIMAL(20, 2) DEFAULT 1000,
    max_withdrawal_amount DECIMAL(20, 2) DEFAULT 100000,
    
    -- الحالة
    is_active BOOLEAN DEFAULT true,
    is_frozen BOOLEAN DEFAULT false,
    freeze_reason TEXT,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- جدول معاملات المحفظة
CREATE TABLE wallet_transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    wallet_id UUID NOT NULL REFERENCES user_wallets(id),
    
    -- نوع المعاملة
    type VARCHAR(50) NOT NULL, -- commission, withdrawal, deposit, refund, adjustment
    
    -- المبلغ
    amount DECIMAL(20, 2) NOT NULL,
    currency VARCHAR(10) DEFAULT 'SAR',
    
    -- الارتباط
    deal_id UUID REFERENCES deals(id),
    reference_type VARCHAR(50),
    reference_id UUID,
    
    -- الحالة
    status VARCHAR(50) DEFAULT 'pending', -- pending, completed, failed, cancelled
    
    -- الوصف
    description_ar TEXT,
    description_en TEXT,
    
    -- التواريخ
    processed_at TIMESTAMP WITH TIME ZONE,
    
    -- البيانات الوصفية
    metadata JSONB DEFAULT '{}',
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id)
);

-- ============================================================
-- 5. نظام CRM (Customer Relationship Management)
-- ============================================================

CREATE TABLE leads (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- رقم Lead
    lead_number VARCHAR(100) UNIQUE NOT NULL,
    
    -- معلومات العميل
    full_name VARCHAR(255) NOT NULL,
    email VARCHAR(255),
    phone VARCHAR(20) NOT NULL,
    
    -- المصدر
    source VARCHAR(50) NOT NULL, -- website, phone, whatsapp, referral, advertisement, walk_in
    source_details TEXT,
    campaign_id VARCHAR(100),
    
    -- الاهتمام
    interest_type VARCHAR(50), -- buy, rent, invest
    preferred_property_types JSONB,
    budget_min DECIMAL(20, 2),
    budget_max DECIMAL(20, 2),
    preferred_city VARCHAR(100),
    preferred_district VARCHAR(100),
    
    -- الحالة
    status VARCHAR(50) DEFAULT 'new', -- new, contacted, qualified, proposal, negotiation, converted, lost
    priority VARCHAR(50) DEFAULT 'medium', -- low, medium, high, urgent
    
    -- التخصيص
    assigned_to UUID REFERENCES users(id),
    assigned_at TIMESTAMP WITH TIME ZONE,
    
    -- الملاحظات
    notes TEXT,
    
    -- التواريخ
    next_follow_up_date TIMESTAMP WITH TIME ZONE,
    converted_at TIMESTAMP WITH TIME ZONE,
    converted_to_client_id UUID REFERENCES users(id),
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(id)
);

-- جدول سجل التواصل (Timeline)
CREATE TABLE lead_activities (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    lead_id UUID NOT NULL REFERENCES leads(id) ON DELETE CASCADE,
    
    -- نوع النشاط
    activity_type VARCHAR(50) NOT NULL, -- call, email, sms, whatsapp, meeting, visit, note, document, status_change
    
    -- الاتجاه
    direction VARCHAR(50), -- inbound, outbound
    
    -- التفاصيل
    subject VARCHAR(255),
    description TEXT,
    
    -- الملحقات
    attachments JSONB DEFAULT '[]',
    
    -- المستخدم
    performed_by UUID NOT NULL REFERENCES users(id),
    
    -- التاريخ
    activity_date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    -- البيانات الوصفية
    metadata JSONB DEFAULT '{}'
);

-- ============================================================
-- 6. طلبات العملاء (Client Requests)
-- ============================================================

CREATE TABLE client_requests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- رقم الطلب
    request_number VARCHAR(100) UNIQUE NOT NULL,
    
    -- العميل
    client_id UUID NOT NULL REFERENCES users(id),
    
    -- نوع الطلب
    request_type VARCHAR(50) NOT NULL, -- buy, rent, sell, evaluate
    
    -- التفاصيل
    property_type VARCHAR(50),
    city VARCHAR(100),
    district VARCHAR(100),
    budget_min DECIMAL(20, 2),
    budget_max DECIMAL(20, 2),
    area_min DECIMAL(10, 2),
    area_max DECIMAL(10, 2),
    bedrooms_min INTEGER,
    bedrooms_max INTEGER,
    
    -- الوصف
    description TEXT,
    
    -- الحالة
    status VARCHAR(50) DEFAULT 'open', -- open, in_progress, matched, closed, cancelled
    
    -- التخصيص
    assigned_to UUID REFERENCES users(id),
    assigned_at TIMESTAMP WITH TIME ZONE,
    
    -- الملاحظات
    notes TEXT,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- 7. المفضلة والمقارنات
-- ============================================================

CREATE TABLE favorites (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    property_id UUID NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, property_id)
);

CREATE TABLE property_comparisons (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(255),
    property_ids JSONB NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- 8. الإشعارات (Notifications)
-- ============================================================

CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- المستلم
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    -- نوع الإشعار
    type VARCHAR(50) NOT NULL, -- deal, commission, property, lead, system
    
    -- العنوان والمحتوى
    title_ar VARCHAR(255) NOT NULL,
    title_en VARCHAR(255),
    body_ar TEXT,
    body_en TEXT,
    
    -- الارتباط
    entity_type VARCHAR(50),
    entity_id UUID,
    action_url TEXT,
    
    -- القنوات
    channels JSONB DEFAULT '["in_app"]', -- in_app, email, sms, push, whatsapp
    
    -- الحالة
    is_read BOOLEAN DEFAULT false,
    read_at TIMESTAMP WITH TIME ZONE,
    
    -- إرسال القنوات
    sent_via_email BOOLEAN DEFAULT false,
    sent_via_sms BOOLEAN DEFAULT false,
    sent_via_push BOOLEAN DEFAULT false,
    sent_via_whatsapp BOOLEAN DEFAULT false,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- 9. سجل التدقيق (Audit Logs)
-- ============================================================

CREATE TABLE audit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- المستخدم
    user_id UUID REFERENCES users(id),
    user_role VARCHAR(50),
    
    -- العملية
    action VARCHAR(50) NOT NULL, -- create, update, delete, login, logout, view, export
    entity_type VARCHAR(100) NOT NULL, -- user, property, deal, commission, etc.
    entity_id UUID,
    
    -- التفاصيل
    old_values JSONB,
    new_values JSONB,
    changes JSONB,
    
    -- السياق
    ip_address INET,
    user_agent TEXT,
    session_id VARCHAR(255),
    
    -- الوصف
    description TEXT,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- 10. إعدادات المنصة (Platform Settings)
-- ============================================================

CREATE TABLE platform_settings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- المفتاح والقيمة
    key VARCHAR(255) UNIQUE NOT NULL,
    value JSONB NOT NULL,
    
    -- نوع القيمة
    type VARCHAR(50) DEFAULT 'string', -- string, number, boolean, json, array
    
    -- المجموعة
    group_name VARCHAR(100) NOT NULL, -- general, appearance, security, email, etc.
    
    -- الوصف
    description TEXT,
    
    -- قابل للتحرير
    is_editable BOOLEAN DEFAULT true,
    is_public BOOLEAN DEFAULT false,
    
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_by UUID REFERENCES users(id)
);

-- ============================================================
-- 11. المستندات (Documents)
-- ============================================================

CREATE TABLE documents (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- المالك
    owner_id UUID NOT NULL REFERENCES users(id),
    owner_type VARCHAR(50) NOT NULL, -- user, property, deal, project
    
    -- نوع المستند
    document_type VARCHAR(100) NOT NULL, -- id_card, passport, deed, contract, license, etc.
    
    -- الملف
    file_name VARCHAR(255) NOT NULL,
    file_url TEXT NOT NULL,
    file_size INTEGER,
    mime_type VARCHAR(50),
    
    -- التشفير
    is_encrypted BOOLEAN DEFAULT true,
    encryption_key_id VARCHAR(255),
    
    -- الحالة
    status VARCHAR(50) DEFAULT 'pending', -- pending, approved, rejected
    verified_by UUID REFERENCES users(id),
    verified_at TIMESTAMP WITH TIME ZONE,
    
    -- الملاحظات
    notes TEXT,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP WITH TIME ZONE
);

-- ============================================================
-- الفهارس (Indexes)
-- ============================================================

-- فهارس المستخدمين
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_phone ON users(phone);
CREATE INDEX idx_users_role ON users(role_id);
CREATE INDEX idx_users_company ON users USING HASH (metadata->>'company_id');

-- فهارس العقارات
CREATE INDEX idx_properties_location ON properties USING GIST (location);
CREATE INDEX idx_properties_city ON properties(city);
CREATE INDEX idx_properties_status ON properties(status);
CREATE INDEX idx_properties_owner ON properties(owner_id);
CREATE INDEX idx_properties_project ON properties(project_id);
CREATE INDEX idx_properties_price ON properties(price);
CREATE INDEX idx_properties_type ON properties(property_type, listing_type);

-- فهارس الصفقات
CREATE INDEX idx_deals_property ON deals(property_id);
CREATE INDEX idx_deals_listing_agent ON deals(listing_agent_id);
CREATE INDEX idx_deals_selling_agent ON deals(selling_agent_id);
CREATE INDEX idx_deals_status ON deals(status);
CREATE INDEX idx_deals_date ON deals(deal_date);

-- فهارس العمولات
CREATE INDEX idx_wallet_transactions_wallet ON wallet_transactions(wallet_id);
CREATE INDEX idx_wallet_transactions_deal ON wallet_transactions(deal_id);
CREATE INDEX idx_wallet_transactions_type ON wallet_transactions(type);

-- فهارس CRM
CREATE INDEX idx_leads_assigned ON leads(assigned_to);
CREATE INDEX idx_leads_status ON leads(status);
CREATE INDEX idx_leads_phone ON leads(phone);
CREATE INDEX idx_lead_activities_lead ON lead_activities(lead_id);

-- فهارس الإشعارات
CREATE INDEX idx_notifications_user ON notifications(user_id);
CREATE INDEX idx_notifications_unread ON notifications(user_id, is_read) WHERE is_read = false;

-- فهارس Audit Logs
CREATE INDEX idx_audit_logs_user ON audit_logs(user_id);
CREATE INDEX idx_audit_logs_entity ON audit_logs(entity_type, entity_id);
CREATE INDEX idx_audit_logs_action ON audit_logs(action);
CREATE INDEX idx_audit_logs_created ON audit_logs(created_at);

-- ============================================================
-- الدوال والمحفزات (Functions & Triggers)
-- ============================================================

-- دالة لتحديث updated_at تلقائياً
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- محفزات لتحديث updated_at
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_companies_updated_at BEFORE UPDATE ON companies FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_projects_updated_at BEFORE UPDATE ON projects FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_properties_updated_at BEFORE UPDATE ON properties FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_deals_updated_at BEFORE UPDATE ON deals FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_leads_updated_at BEFORE UPDATE ON leads FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- دالة لحساب العمولة
CREATE OR REPLACE FUNCTION calculate_commission(
    p_sale_price DECIMAL,
    p_commission_rate DECIMAL,
    p_listing_agent_share DECIMAL,
    p_selling_agent_share DECIMAL,
    p_vat_rate DECIMAL
)
RETURNS TABLE (
    total_commission DECIMAL,
    listing_agent_commission DECIMAL,
    selling_agent_commission DECIMAL,
    platform_commission DECIMAL,
    vat_amount DECIMAL,
    total_with_vat DECIMAL
) AS $$
DECLARE
    v_total_commission DECIMAL;
    v_vat_amount DECIMAL;
BEGIN
    -- حساب العمولة الإجمالية
    v_total_commission := (p_sale_price * p_commission_rate) / 100;
    
    -- حساب الضريبة
    v_vat_amount := (v_total_commission * p_vat_rate) / 100;
    
    -- إرجاع النتائج
    RETURN QUERY SELECT
        v_total_commission,
        (v_total_commission * p_listing_agent_share) / 100,
        (v_total_commission * p_selling_agent_share) / 100,
        v_total_commission - ((v_total_commission * p_listing_agent_share) / 100) - ((v_total_commission * p_selling_agent_share) / 100),
        v_vat_amount,
        v_total_commission + v_vat_amount;
END;
$$ LANGUAGE plpgsql;

-- دالة لإنشاء معاملة محفظة
CREATE OR REPLACE FUNCTION create_wallet_transaction()
RETURNS TRIGGER AS $$
BEGIN
    -- إنشاء معاملة في محفظة وسيط الإدراج
    IF NEW.listing_agent_id IS NOT NULL AND NEW.listing_agent_commission > 0 THEN
        INSERT INTO wallet_transactions (
            wallet_id, type, amount, currency, deal_id, 
            description_ar, description_en, status, processed_at
        )
        SELECT 
            id, 'commission', NEW.listing_agent_commission, NEW.currency, NEW.id,
            'عمولة من صفقة ' || NEW.deal_number,
            'Commission from deal ' || NEW.deal_number,
            'completed', CURRENT_TIMESTAMP
        FROM user_wallets WHERE user_id = NEW.listing_agent_id;
        
        -- تحديث رصيد المحفظة
        UPDATE user_wallets 
        SET available_balance = available_balance + NEW.listing_agent_commission,
            total_earned = total_earned + NEW.listing_agent_commission,
            updated_at = CURRENT_TIMESTAMP
        WHERE user_id = NEW.listing_agent_id;
    END IF;
    
    -- إنشاء معاملة في محفظة وسيط البيع
    IF NEW.selling_agent_id IS NOT NULL AND NEW.selling_agent_commission > 0 THEN
        INSERT INTO wallet_transactions (
            wallet_id, type, amount, currency, deal_id,
            description_ar, description_en, status, processed_at
        )
        SELECT 
            id, 'commission', NEW.selling_agent_commission, NEW.currency, NEW.id,
            'عمولة من صفقة ' || NEW.deal_number,
            'Commission from deal ' || NEW.deal_number,
            'completed', CURRENT_TIMESTAMP
        FROM user_wallets WHERE user_id = NEW.selling_agent_id;
        
        -- تحديث رصيد المحفظة
        UPDATE user_wallets 
        SET available_balance = available_balance + NEW.selling_agent_commission,
            total_earned = total_earned + NEW.selling_agent_commission,
            updated_at = CURRENT_TIMESTAMP
        WHERE user_id = NEW.selling_agent_id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- محفز لإنشاء معاملة المحفظة عند الموافقة على الصفقة
CREATE TRIGGER trigger_create_wallet_transaction
    AFTER UPDATE OF status ON deals
    FOR EACH ROW
    WHEN (NEW.status = 'approved' AND OLD.status != 'approved')
    EXECUTE FUNCTION create_wallet_transaction();

-- دالة لإنشاء محفظة للمستخدم الجديد
CREATE OR REPLACE FUNCTION create_user_wallet()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO user_wallets (user_id) VALUES (NEW.id);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_create_user_wallet
    AFTER INSERT ON users
    FOR EACH ROW
    EXECUTE FUNCTION create_user_wallet();

-- ============================================================
-- البيانات الأولية (Seed Data)
-- ============================================================

-- إدخال الأدوار
INSERT INTO roles (name, name_ar, name_en, description, permissions, hierarchy_level) VALUES
('super_admin', 'مدير النظام', 'Super Admin', 'صلاحيات كاملة على النظام', 
 '["*"]', 100),
('admin', 'مدير', 'Admin', 'صلاحيات إدارية', 
 '["users.read", "users.create", "users.update", "properties.read", "properties.approve", "deals.read", "deals.manage", "commissions.read", "reports.read", "settings.read", "settings.update"]', 80),
('broker', 'وسيط عقاري', 'Broker', 'وسيط عقاري معتمد', 
 '["properties.own.read", "properties.own.create", "properties.own.update", "properties.own.delete", "deals.own.read", "commissions.own.read", "clients.own.read", "clients.own.manage"]', 50),
('developer', 'مطور عقاري', 'Developer', 'مطور عقاري معتمد', 
 '["projects.own.read", "projects.own.create", "projects.own.update", "properties.own.read", "properties.own.create", "properties.own.update", "sales.own.read"]', 50),
('owner', 'مالك عقار', 'Property Owner', 'مالك عقار خاص', 
 '["properties.own.read", "properties.own.create", "properties.own.update", "inquiries.own.read"]', 30),
('client', 'عميل', 'Client', 'عميل البحث عن عقار', 
 '["properties.search", "properties.view", "favorites.manage", "requests.own.manage"]', 10);

-- إدخال إعدادات المنصة الافتراضية
INSERT INTO platform_settings (key, value, type, group_name, description, is_editable, is_public) VALUES
('platform.name', '"إنابة المستقبل"', 'string', 'general', 'اسم المنصة', true, true),
('platform.name_en', '"Inabah Future"', 'string', 'general', 'اسم المنصة بالإنجليزية', true, true),
('platform.description', '"منصة العقارات الرائدة في المملكة العربية السعودية"', 'string', 'general', 'وصف المنصة', true, true),
('platform.contact_email', '"info@inabah.sa"', 'string', 'general', 'البريد الإلكتروني للتواصل', true, true),
('platform.contact_phone', '"+966 50 123 4567"', 'string', 'general', 'رقم الهاتف', true, true),
('appearance.primary_color', '"#047857"', 'string', 'appearance', 'اللون الرئيسي', true, true),
('appearance.secondary_color', '"#10b981"', 'string', 'appearance', 'اللون الثانوي', true, true),
('appearance.dark_mode', 'false', 'boolean', 'appearance', 'الوضع الليلي', true, true),
('appearance.rtl', 'true', 'boolean', 'appearance', 'اتجاه RTL', true, true),
('security.password_min_length', '8', 'number', 'security', 'الحد الأدنى لكلمة المرور', true, false),
('security.login_attempts', '5', 'number', 'security', 'محاولات تسجيل الدخول', true, false),
('security.two_factor_enabled', 'false', 'boolean', 'security', 'تفعيل 2FA', true, false),
('commission.base_rate', '2.5', 'number', 'commission', 'نسبة العمولة الأساسية', true, false),
('commission.listing_agent_share', '20', 'number', 'commission', 'نصيب وسيط الإدراج', true, false),
('commission.selling_agent_share', '20', 'number', 'commission', 'نصيب وسيط البيع', true, false),
('commission.vat_rate', '15', 'number', 'commission', 'نسبة الضريبة', true, false);

-- إدخال قاعدة العمولة الافتراضية
INSERT INTO commission_rules (
    name, description, base_rate, listing_agent_share, selling_agent_share, 
    platform_share, vat_enabled, vat_rate, is_active, effective_from
) VALUES (
    'القاعدة الافتراضية', 'نسبة العمولة الافتراضية للمنصة', 
    2.5, 20.0, 20.0, 60.0, true, 15.0, true, CURRENT_DATE
);
