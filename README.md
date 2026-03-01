# منصة إنابة المستقبل العقارية
## Inabah Real Estate Platform - Technical Blueprint

---

## 📋 جدول المحتويات

1. [نظرة عامة](#نظرة-عامة)
2. [الهندسة التقنية](#الهندسة-التقنية)
3. [هيكلية قاعدة البيانات](#هيكلية-قاعدة-البيانات)
4. [نظام الصلاحيات](#نظام-الصلاحيات)
5. [محرك العمولات](#محرك-العمولات)
6. [الخريطة التفاعلية](#الخريطة-التفاعلية)
7. [API Documentation](#api-documentation)
8. [النشر والتشغيل](#النشر-والتشغيل)

---

## نظرة عامة

منصة "إنابة المستقبل" هي منصة عقارية رقمية متكاملة مبنية بنظام SaaS-Ready وقابلة للتوسع العالمي.

### المميزات الرئيسية

- ✅ **Microservices Architecture** - استقرار كل قسم على حدة
- ✅ **Granular RBAC** - فصل البيانات حسب الأدوار
- ✅ **Commission Engine** - توزيع آلي للعمولات
- ✅ **Interactive Map** - خريطة تفاعلية مع PostGIS
- ✅ **CRM System** - إدارة العملاء والمتابعة
- ✅ **Multi-language** - دعم اللغات مع RTL

---

## الهندسة التقنية

### Stack التقني

| الطبقة | التقنية |
|--------|---------|
| **Frontend** | Next.js 14 + Tailwind CSS + shadcn/ui |
| **Backend** | NestJS + TypeScript |
| **Database** | PostgreSQL + PostGIS |
| **Caching** | Redis |
| **Real-time** | Socket.io |
| **Storage** | AWS S3 |
| **Maps** | Mapbox GL JS |

### هيكلية المجلدات

```
inabah-platform/
├── backend/
│   ├── src/
│   │   ├── modules/
│   │   │   ├── auth/
│   │   │   ├── users/
│   │   │   ├── properties/
│   │   │   ├── commission/
│   │   │   ├── wallet/
│   │   │   ├── crm/
│   │   │   └── notifications/
│   │   ├── common/
│   │   ├── config/
│   │   └── main.ts
│   └── package.json
├── frontend/
│   ├── src/
│   │   ├── app/
│   │   ├── components/
│   │   ├── hooks/
│   │   ├── lib/
│   │   └── types/
│   └── package.json
└── database/
    └── schema.sql
```

---

## هيكلية قاعدة البيانات

### الجداول الرئيسية

| الجدول | الوصف |
|--------|-------|
| `users` | المستخدمين والأدوار |
| `roles` | الأدوار والصلاحيات |
| `companies` | الشركات (مطورين/وسطاء) |
| `projects` | المشاريع العقارية |
| `properties` | الوحدات العقارية |
| `deals` | الصفقات |
| `commission_rules` | قواعد العمولات |
| `user_wallets` | محافظ المستخدمين |
| `wallet_transactions` | معاملات المحافظ |
| `leads` | العملاء المحتملين |
| `lead_activities` | سجل التواصل |
| `notifications` | الإشعارات |
| `audit_logs` | سجل التدقيق |

### مخطط ER

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│    users    │────<│   roles     │     │  companies  │
└──────┬──────┘     └─────────────┘     └──────┬──────┘
       │                                        │
       │    ┌─────────────┐     ┌─────────────┐│
       └───>│  properties │<────│  projects   │<
            └──────┬──────┘     └─────────────┘
                   │
            ┌──────┴──────┐
            │    deals    │
            └──────┬──────┘
                   │
       ┌───────────┼───────────┐
       │           │           │
┌──────┴──────┐ ┌──┴────────┐ ┌┴─────────────┐
│user_wallets │ │commission_│ │wallet_        │
└─────────────┘ │  rules    │ │transactions   │
                └───────────┘ └──────────────┘
```

---

## نظام الصلاحيات

### الأدوار

| الدور | الصلاحيات |
|-------|-----------|
| **Super Admin** | صلاحيات إلهية - الوصول لكل شيء |
| **Admin** | صلاحيات إدارية - إدارة المستخدمين والموافقات |
| **Broker** | عقاراتي، صفقاتي، عمولاتي، عملائي |
| **Developer** | مشاريعي، وحداتي، تقارير المبيعات |
| **Owner** | عقاراتي الخاصة، الاستفسارات |
| **Client** | البحث، المفضلة، طلباتي |

### Data Silos

كل دور يرى فقط بياناته:

```
┌─────────────────────────────────────────────────────────┐
│  Super Admin (يرى كل شيء)                               │
│  ├── جميع المستخدمين                                    │
│  ├── جميع العقارات                                      │
│  ├── جميع الصفقات                                       │
│  └── جميع العمولات                                      │
├─────────────────────────────────────────────────────────┤
│  Broker (يرى فقط بياناته)                               │
│  ├── عقاراتي (اللي أدرجتها)                            │
│  ├── صفقاتي (اللي شاركت فيها)                          │
│  ├── عمولاتي (اللي استحقتها)                           │
│  └── عملائي (اللي تم تخصيصهم لي)                       │
├─────────────────────────────────────────────────────────┤
│  Developer (يرى فقط مشاريعه)                            │
│  ├── مشاريعي                                           │
│  ├── وحداتي                                            │
│  └── تقارير المبيعات                                   │
└─────────────────────────────────────────────────────────┘
```

---

## محرك العمولات

### خوارزمية التوزيع

```
┌─────────────────────────────────────────────────────────┐
│                    حساب العمولة                          │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  سعر البيع: 1,000,000 ريال                             │
│  نسبة العمولة: 2.5%                                    │
│  ─────────────────────────                             │
│  إجمالي العمولة = 1,000,000 × 2.5% = 25,000 ريال      │
│                                                         │
│  توزيع العمولة:                                        │
│  ─────────────────────────                             │
│  • وسيط الإدراج: 20% = 5,000 ريال                     │
│  • وسيط البيع: 20% = 5,000 ريال                       │
│  • المنصة: 60% = 15,000 ريال                          │
│                                                         │
│  الضريبة (15%): 3,750 ريال                            │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

### حالات خاصة

| الحالة | التوزيع |
|--------|---------|
| وسيط واحد (مدرج وبائع) | 40% للوسيط |
| بدون وسيط إدراج | 20% للبائع + 80% للمنصة |
| بدون وسيط بيع | 20% للمدرج + 80% للمنصة |

---

## الخريطة التفاعلية

### الميزات

- 🗺️ **Clusters** - تجميع العقارات القريبة
- 🔍 **فلترة فورية** - بدون إعادة تحميل
- 📍 **Popups** - تفاصيل العقار عند النقر
- 🎨 **ألوان مخصصة** - تمييز المشاريع والعقارات الخاصة
- 🌐 **RTL** - دعم اللغة العربية

### PostGIS Query

```sql
SELECT 
  id, title_ar, price, area,
  ST_X(location) as longitude,
  ST_Y(location) as latitude
FROM properties
WHERE ST_DWithin(
  location::geography,
  ST_SetSRID(ST_MakePoint(46.6753, 24.7136), 4326)::geography,
  5000  -- نصف القطر بالمتر
)
AND price BETWEEN 1000000 AND 3000000
AND status = 'available';
```

---

## API Documentation

### Endpoints الرئيسية

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/auth/login` | POST | تسجيل الدخول |
| `/auth/register` | POST | تسجيل مستخدم جديد |
| `/properties` | GET | قائمة العقارات |
| `/properties` | POST | إنشاء عقار |
| `/properties/map` | GET | البحث على الخريطة |
| `/deals` | GET | قائمة الصفقات |
| `/deals` | POST | إنشاء صفقة |
| `/deals/:id/approve` | PATCH | موافقة على صفقة |
| `/wallet/balance` | GET | رصيد المحفظة |
| `/crm/leads` | GET | قائمة Leads |
| `/admin/dashboard/stats` | GET | إحصائيات المنصة |

---

## النشر والتشغيل

### متطلبات النظام

- Node.js 18+
- PostgreSQL 15+
- Redis 7+
- AWS Account

### خطوات النشر

```bash
# 1. Clone repository
git clone https://github.com/inabah/platform.git
cd platform

# 2. Install dependencies
npm install

# 3. Setup environment variables
cp .env.example .env
# Edit .env with your credentials

# 4. Run database migrations
npm run migration:run

# 5. Seed initial data
npm run seed

# 6. Start development server
npm run dev

# 7. Build for production
npm run build

# 8. Start production server
npm run start:prod
```

### Docker Deployment

```bash
# Build images
docker-compose build

# Start services
docker-compose up -d

# View logs
docker-compose logs -f
```

---

## 📁 الملفات

| الملف | الوصف |
|-------|-------|
| `database-schema.sql` | هيكلية قاعدة البيانات الكاملة |
| `commission.service.ts` | منطق توزيع العمولات |
| `data-flow-diagram.md` | مخطط تدفق البيانات |
| `map-integration.md` | ربط الخريطة التفاعلية |
| `api-documentation.md` | توثيق API |

---

## 👥 الفريق

- **Software Architect**: [Your Name]
- **Backend Developers**: [Team]
- **Frontend Developers**: [Team]
- **DevOps Engineers**: [Team]

---

## 📄 الترخيص

Copyright © 2024 إنابة المستقبل للخدمات العقارية. جميع الحقوق محفوظة.

---

<p align="center">
  <strong>إنابة المستقبل</strong> - نربطك بعقار أحلامك
</p>
