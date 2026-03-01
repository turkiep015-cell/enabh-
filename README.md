# إنابة المستقبل - Inabah Real Estate Platform

منصة عقارية متكاملة لإدارة العقارات والصفقات والعمولات

## 🚀 المميزات

- **نظام مصادقة متكامل**: تسجيل دخول وإنشاء حسابات مع صلاحيات متعددة
- **إدارة المستخدمين**: سوبر أدمن، أدمن، وسطاء، عملاء، مطورين، ملاك
- **إدارة العقارات**: إضافة، تعديل، حذف، الموافقة على العقارات
- **إدارة الصفقات**: تتبع الصفقات من البداية حتى الإتمام
- **نظام العمولات**: حساب تلقائي للعمولات مع قواعد قابلة للتخصيص
- **التقارير**: تقارير أداء الوسطاء، صفقات، إيرادات
- **تعيين العملاء**: تعيين العملاء للوسطاء لإدارة أفضل
- **الإعلانات**: إدارة حملات إعلانية

## 🛠️ التقنيات المستخدمة

### Frontend
- React 19 + TypeScript
- Vite
- Tailwind CSS
- shadcn/ui
- React Router
- Recharts

### Backend
- Node.js + Express
- Sequelize ORM
- PostgreSQL
- JWT Authentication
- bcrypt

## 📁 هيكل المشروع

```
inabah-platform/
├── backend/              # Node.js + Express API
│   ├── src/
│   │   ├── config/       # Database & constants
│   │   ├── controllers/  # API controllers
│   │   ├── middleware/   # Auth & validation
│   │   ├── models/       # Database models
│   │   ├── routes/       # API routes
│   │   └── server.js     # Main server file
│   ├── database/         # Migrations & seeds
│   ├── uploads/          # File uploads
│   ├── Dockerfile
│   └── package.json
│
├── frontend/             # React + TypeScript
│   ├── src/
│   │   ├── components/   # UI components
│   │   ├── pages/        # Page components
│   │   ├── hooks/        # Custom hooks
│   │   ├── data/         # Mock data
│   │   └── types/        # TypeScript types
│   ├── public/
│   └── package.json
│
├── package.json          # Root package.json
├── docker-compose.yml    # Docker compose for local dev
└── README.md
```

## 🚀 التشغيل المحلي

### المتطلبات
- Node.js 18+
- PostgreSQL 14+

### خطوات التشغيل

1. **نسخ المشروع**
```bash
cd inabah-platform
```

2. **تثبيت الاعتماديات**
```bash
npm run install:all
```

3. **إعداد قاعدة البيانات**
```bash
# أنشئ قاعدة بيانات PostgreSQL باسم inabah_db
# عدل ملف backend/.env بإعدادات قاعدة البيانات
```

4. **تشغيل seed البيانات**
```bash
npm run db:seed
```

5. **تشغيل المشروع**
```bash
npm run dev
```

- Frontend: http://localhost:5173
- Backend API: http://localhost:5000

## 🔐 بيانات الدخول الافتراضية

| الدور | البريد | كلمة المرور |
|-------|--------|-------------|
| Super Admin | admin@inabah.com | admin123 |
| Broker | broker@inabah.com | broker123 |
| Client | client@inabah.com | client123 |
| Developer | developer@inabah.com | developer123 |

## 🐳 التشغيل بـ Docker

```bash
docker-compose up -d
```

## 🚂 النشر على Railway

1. أنشئ مشروع جديد على Railway
2. اربط مستودع GitHub
3. أضف متغيرات البيئة:
   - `DATABASE_URL`
   - `JWT_SECRET`
   - `JWT_EXPIRES_IN`
   - `NODE_ENV=production`

## 📚 API Documentation

### المصادقة
- `POST /api/auth/register` - تسجيل مستخدم جديد
- `POST /api/auth/login` - تسجيل الدخول
- `GET /api/auth/me` - بيانات المستخدم الحالي
- `POST /api/auth/refresh-token` - تجديد التوكن

### المستخدمين
- `GET /api/users` - قائمة المستخدمين
- `GET /api/users/:id` - بيانات مستخدم
- `POST /api/users` - إنشاء مستخدم
- `PUT /api/users/:id` - تحديث مستخدم
- `DELETE /api/users/:id` - حذف مستخدم
- `GET /api/users/:id/permissions` - صلاحيات المستخدم
- `PUT /api/users/:id/permissions` - تحديث الصلاحيات

### العقارات
- `GET /api/properties` - قائمة العقارات
- `GET /api/properties/:id` - بيانات عقار
- `POST /api/properties` - إنشاء عقار
- `PUT /api/properties/:id` - تحديث عقار
- `DELETE /api/properties/:id` - حذف عقار
- `PATCH /api/properties/:id/approve` - موافقة على عقار

### الصفقات
- `GET /api/deals` - قائمة الصفقات
- `GET /api/deals/:id` - بيانات صفقة
- `POST /api/deals` - إنشاء صفقة
- `PUT /api/deals/:id` - تحديث صفقة
- `PATCH /api/deals/:id/approve` - موافقة على صفقة
- `PATCH /api/deals/:id/complete` - إتمام صفقة

### العمولات
- `GET /api/commissions` - قائمة العمولات
- `GET /api/commissions/rules` - قواعد العمولة
- `POST /api/commissions/rules` - إنشاء قاعدة عمولة
- `PATCH /api/commissions/:id/pay` - دفع عمولة

## 📄 الترخيص

MIT License
