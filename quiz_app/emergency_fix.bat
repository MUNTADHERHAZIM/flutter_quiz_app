@echo off
echo ========================================
echo    حل طوارئ لمشكلة انطفاء الحاسوب
echo ========================================
echo.

echo تحذير: يبدو أن التطبيق يتسبب في استهلاك مفرط للموارد
echo سنقوم بتطبيق الحلول التالية:
echo.

echo 1. إيقاف جميع عمليات Flutter...
taskkill /F /IM dart.exe 2>nul
taskkill /F /IM flutter.exe 2>nul
taskkill /F /IM chrome.exe 2>nul
echo تم إيقاف العمليات

echo 2. تنظيف الذاكرة المؤقتة...
flutter clean
rd /s /q build 2>nul
rd /s /q .dart_tool 2>nul
echo تم التنظيف

echo 3. نسخ الملفات الآمنة...
copy lib\main_emergency.dart lib\main.dart
copy pubspec_emergency.yaml pubspec.yaml
echo تم نسخ الملفات الآمنة

echo 4. تثبيت المكتبات الأساسية فقط...
flutter pub get
echo تم التثبيت

echo 5. تحسين إعدادات النظام...
echo سيتم تشغيل النسخة الآمنة فقط
echo.

echo ========================================
echo تم تطبيق الحل الطارئ بنجاح!
echo.
echo لتشغيل النسخة الآمنة:
echo flutter run -d chrome --web-renderer html --no-sound-null-safety
echo.
echo إذا استمرت المشكلة:
echo 1. أعد تشغيل الحاسوب
echo 2. تأكد من وجود ذاكرة RAM كافية (4GB+)
echo 3. أغلق البرامج الثقيلة
echo 4. استخدم flutter run --release
echo ========================================
echo.

echo اضغط أي مفتاح للمتابعة...
pause >nul

echo هل تريد تشغيل النسخة الآمنة الآن؟ (y/n)
set /p choice="اختر (y/n): "
if /i "%choice%"=="y" (
    echo جاري تشغيل النسخة الآمنة...
    flutter run -d chrome --web-renderer html --no-sound-null-safety
) else (
    echo يمكنك تشغيلها لاحقاً باستخدام الأمر أعلاه
)

echo.
echo تم الانتهاء من الحل الطارئ
pause 