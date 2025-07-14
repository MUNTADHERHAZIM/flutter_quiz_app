# دليل حل مشاكل التشغيل

## المشكلة الحالية: Out of Memory ❌

### الأعراض:
```
error: Out of memory.
the Dart compiler exited unexpectedly.
Failed to compile application.
```

### الأسباب المحتملة:
1. **مشكلة في الذاكرة**: النظام يستهلك ذاكرة أكثر من المتاح
2. **مكتبات كثيرة**: وجود مكتبات غير ضرورية
3. **كود معقد**: ملفات كبيرة ومعقدة
4. **مشكلة في Flutter SDK**: إصدار قديم أو تالف

## الحلول المتاحة 🔧

### الحل الأول: استخدام النسخة المبسطة
```bash
# انسخ main_simple.dart إلى main.dart
cp lib/main_simple.dart lib/main.dart

# انسخ pubspec_simple.yaml إلى pubspec.yaml  
cp pubspec_simple.yaml pubspec.yaml

# نظف وأعد التثبيت
flutter clean
flutter pub get
flutter run
```

### الحل الثاني: تفعيل Developer Mode
1. اضغط `Win + I` لفتح الإعدادات
2. اذهب إلى `Update & Security` > `For developers`
3. فعّل `Developer Mode`
4. أعد تشغيل الحاسوب
5. جرب `flutter run` مرة أخرى

### الحل الثالث: زيادة الذاكرة المتاحة
```bash
# استخدم فلاتر مع ذاكرة أكبر
flutter run --verbose --dart-define=flutter.inspector.heapSnapshotMaxSize=2000000000
```

### الحل الرابعة: استخدام Chrome بدلاً من Edge
```bash
flutter run -d chrome --web-renderer canvaskit
```

### الحل الخامس: تنظيف كامل
```bash
flutter clean
flutter pub cache clean
flutter pub get
flutter doctor
flutter run
```

## اختبار التشغيل السريع ⚡

### 1. اختبار النسخة المبسطة:
```bash
# تأكد من أنك في مجلد المشروع
cd quiz_app

# انسخ الملفات المبسطة
copy lib\main_simple.dart lib\main.dart
copy pubspec_simple.yaml pubspec.yaml

# نظف وشغل
flutter clean
flutter pub get
flutter run -d chrome
```

### 2. إذا نجح الاختبار:
- النظام يعمل والمشكلة في التعقيد
- يمكن العودة للنسخة الكاملة تدريجياً
- إضافة الميزات واحدة تلو الأخرى

### 3. إذا فشل الاختبار:
- المشكلة في بيئة Flutter
- راجع تثبيت Flutter
- تأكد من متطلبات النظام

## متطلبات النظام 📋

### الحد الأدنى:
- **RAM**: 8GB (16GB مفضل)
- **Storage**: 10GB مساحة فارغة
- **OS**: Windows 10 64-bit
- **Flutter**: 3.0+

### المفضل:
- **RAM**: 16GB+
- **Storage**: SSD مع 20GB+
- **CPU**: Intel i5 أو AMD Ryzen 5+
- **Flutter**: أحدث إصدار مستقر

## خطوات التصحيح التدريجي 🔍

### المرحلة 1: التحقق الأساسي
```bash
flutter doctor -v
flutter --version
dart --version
```

### المرحلة 2: تنظيف البيئة
```bash
flutter clean
flutter pub cache clean
flutter config --clear-features
```

### المرحلة 3: إعادة التثبيت
```bash
flutter pub get
flutter precache
flutter doctor
```

### المرحلة 4: اختبار تدريجي
1. شغل النسخة المبسطة
2. أضف المكتبات واحدة تلو الأخرى
3. اختبر بعد كل إضافة
4. حدد المكتبة المسببة للمشكلة

## بدائل التشغيل 🎯

### 1. تشغيل على الويب:
```bash
flutter run -d chrome --web-renderer html
```

### 2. تشغيل مع معلومات أكثر:
```bash
flutter run --verbose --enable-software-rendering
```

### 3. تشغيل في وضع Release:
```bash
flutter run --release
```

## نصائح الأداء 💡

### 1. تقليل استهلاك الذاكرة:
- استخدم `const` للويدجت الثابتة
- تجنب إعادة بناء الويدجت غير الضروري
- استخدم `ListView.builder` للقوائم الطويلة

### 2. تحسين الكود:
- قسم الملفات الكبيرة
- استخدم `async`/`await` بحذر
- تجنب الحلقات اللانهائية

### 3. إدارة المكتبات:
- أزل المكتبات غير المستخدمة
- استخدم أحدث إصدارات مستقرة
- تجنب المكتبات التجريبية في الإنتاج

## إذا استمر الفشل 🆘

### خيارات بديلة:
1. **استخدم محرر أونلاين**: DartPad, CodePen
2. **جرب نظام آخر**: Linux VM, WSL2
3. **استخدم سحابة**: GitHub Codespaces
4. **طلب المساعدة**: مجتمع Flutter العربي

### معلومات للمساعدة:
عند طلب المساعدة، قدم:
- إصدار Flutter (`flutter --version`)
- نظام التشغيل ومواصفاته
- رسالة الخطأ كاملة
- الخطوات المتبعة

---

**تذكر: النجاح في البرمجة يأتي من حل المشاكل تدريجياً** 🚀 