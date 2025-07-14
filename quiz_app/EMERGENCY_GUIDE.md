# دليل الطوارئ - حل مشكلة انطفاء الحاسوب 🚨

## ⚠️ التحذير
إذا كان التطبيق يتسبب في انطفاء الحاسوب، فهذا يعني استهلاك مفرط للموارد. **لا تشغل التطبيق الأساسي** حتى تطبيق الحلول أدناه.

## 🔥 الحل السريع (خطوات فورية)

### 1. الإيقاف الفوري
```bash
# أوقف جميع عمليات Flutter
taskkill /F /IM dart.exe
taskkill /F /IM flutter.exe
taskkill /F /IM chrome.exe
```

### 2. تشغيل السكريبت الطارئ
```bash
# في مجلد المشروع
emergency_fix.bat
```

### 3. أو تطبيق الحلول يدوياً:
```bash
# 1. تنظيف المشروع
flutter clean

# 2. حذف الملفات المؤقتة
rmdir /s build
rmdir /s .dart_tool

# 3. نسخ النسخة الآمنة
copy lib\main_emergency.dart lib\main.dart
copy pubspec_emergency.yaml pubspec.yaml

# 4. إعادة التثبيت
flutter pub get

# 5. تشغيل النسخة الآمنة
flutter run -d chrome --web-renderer html --no-sound-null-safety
```

## 🛠️ الحلول المتقدمة

### إعدادات تقليل استهلاك الموارد

#### 1. إعدادات Chrome
- افتح Chrome
- اذهب إلى `Settings > Advanced > System`
- أوقف `Use hardware acceleration when available`
- قلل من علامات التبويب المفتوحة

#### 2. إعدادات Windows
```cmd
# زيادة Virtual Memory
# Control Panel > System > Advanced > Performance Settings > Advanced > Virtual Memory
# تعديل الحد الأدنى إلى 4096 MB
```

#### 3. تحسين Flutter
```bash
# استخدام Release Mode
flutter run --release -d chrome

# تقليل الذاكرة
flutter run -d chrome --web-renderer html --dart-define=FLUTTER_WEB_USE_SKIA=false
```

### تشخيص المشكلة

#### فحص استهلاك الموارد:
```bash
# فحص استهلاك الذاكرة
tasklist | findstr dart
tasklist | findstr chrome

# مراقبة الأداء
flutter run --verbose
```

## 📊 مستويات الخطورة

### 🟢 مستوى آمن
- استهلاك RAM أقل من 2GB
- استهلاك CPU أقل من 70%
- درجة حرارة عادية

### 🟡 مستوى تحذيري  
- استهلاك RAM 2-4GB
- استهلاك CPU 70-90%
- ارتفاع طفيف في درجة الحرارة

### 🔴 مستوى خطر (يسبب انطفاء الحاسوب)
- استهلاك RAM أكثر من 4GB
- استهلاك CPU أكثر من 90%
- ارتفاع كبير في درجة الحرارة

## 🏥 النسخة الطبية (Emergency Mode)

تم إنشاء `main_emergency.dart` التي تحتوي على:
- ✅ بدون مكتبات خارجية
- ✅ بدون رسوم متحركة معقدة
- ✅ استهلاك ذاكرة أدنى
- ✅ واجهة مبسطة
- ✅ اختبار أساسي للتأكد من عمل النظام

## 🔧 خطوات الاستكشاف

### 1. تحديد السبب
```bash
# فحص سجلات الأخطاء
flutter doctor -v

# فحص dependency conflicts
flutter pub deps
```

### 2. الأسباب المحتملة
- **مكتبة Google Fonts**: تحميل خطوط كثيرة
- **SQLite**: استعلامات معقدة
- **الرسوم المتحركة**: animations مفرطة
- **Memory leaks**: عدم تحرير الذاكرة
- **Infinite loops**: حلقات لا نهائية

### 3. الحلول حسب السبب

#### إذا كان السبب Google Fonts:
```yaml
# في pubspec.yaml - أزل هذا السطر
# google_fonts: ^6.1.0

# في الكود - استبدل بـ
TextStyle(fontFamily: 'Arial')  # بدلاً من GoogleFonts.cairo()
```

#### إذا كان السبب SQLite:
```dart
// تبسيط الاستعلامات
// بدلاً من استعلامات معقدة مع JOINs متعددة
// استخدم استعلامات بسيطة منفصلة
```

#### إذا كان السبب الرسوم المتحركة:
```dart
// إيقاف الرسوم المتحركة
MaterialApp(
  theme: ThemeData(
    pageTransitionsTheme: PageTransitionsTheme(
      builders: {
        TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
  ),
)
```

## 📋 قائمة فحص سريعة

### قبل تشغيل التطبيق:
- [ ] تم إغلاق البرامج الثقيلة؟
- [ ] تتوفر ذاكرة RAM كافية (4GB+)؟
- [ ] تم تنظيف cache Flutter؟
- [ ] تم اختيار النسخة الآمنة؟

### أثناء التشغيل:
- [ ] مراقبة استهلاك CPU
- [ ] مراقبة استهلاك RAM
- [ ] فحص درجة حرارة الجهاز
- [ ] مراقبة سرعة المروحة

### عند ظهور المشكلة:
- [ ] إيقاف فوري للتطبيق
- [ ] حفظ سجلات الأخطاء
- [ ] تطبيق النسخة الطارئ
- [ ] إعادة تشغيل الحاسوب

## 🆘 خطة الطوارئ الشاملة

### خطة A - الحل السريع (5 دقائق)
1. تشغيل `emergency_fix.bat`
2. استخدام `main_emergency.dart`
3. تقليل المكتبات إلى الحد الأدنى

### خطة B - الحل المتوسط (15 دقيقة)  
1. تحديد السبب الجذري
2. إصلاح المكتبات المشكلة
3. تحسين الاستعلامات
4. تقليل الرسوم المتحركة

### خطة C - إعادة البناء (30 دقيقة)
1. إنشاء مشروع جديد
2. نقل الكود تدريجياً
3. اختبار كل جزء منفصل
4. تحسين الأداء من البداية

## 📞 إذا لم تحل المشكلة

### فحص الهاردوير:
- تنظيف الغبار من المروحة
- فحص الذاكرة RAM
- فحص القرص الصلب
- التأكد من التبريد الكافي

### إعدادات النظام:
- تحديث Windows
- تحديث drivers الرسومية  
- فحص الفيروسات
- إلغاء تجزئة القرص

### طلب المساعدة:
- توفير سجلات الأخطاء
- ذكر مواصفات الجهاز
- وصف متى تحدث المشكلة
- إرفاق ملف `flutter doctor -v`

---

## ⚠️ تذكير مهم

**لا تحاول تشغيل النسخة الأساسية حتى حل المشكلة**. استخدم النسخة الطارئة أولاً لضمان سلامة جهازك.

تم إعداد هذا الدليل لضمان عدم تكرار مشكلة انطفاء الحاسوب. اتبع الخطوات بعناية ولا تتردد في طلب المساعدة إذا لزم الأمر. 