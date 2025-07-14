@echo off
echo ===========================================
echo         حل مشكلة الذاكرة في Flutter
echo ===========================================
echo.

echo 1. تنظيف المشروع...
call flutter clean
echo.

echo 2. تنظيف cache...
call flutter pub cache clean
echo.

echo 3. نسخ الملفات المبسطة...
copy lib\main_simple.dart lib\main_backup.dart
copy pubspec_simple.yaml pubspec_backup.yaml
echo.

echo 4. تثبيت المكتبات...
call flutter pub get
echo.

echo 5. فحص البيئة...
call flutter doctor
echo.

echo ===========================================
echo تم تطبيق الحلول. جرب الآن:
echo flutter run -d chrome --web-renderer html
echo ===========================================
echo.

pause 