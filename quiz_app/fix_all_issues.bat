@echo off
echo ===========================================
echo      إصلاح جميع المشاكل البرمجية
echo ===========================================
echo.

echo 1. تنظيف المشروع...
call flutter clean
echo.

echo 2. الحصول على المكتبات...
call flutter pub get
echo.

echo 3. فحص المشاكل...
call flutter analyze
echo.

echo 4. تشغيل التطبيق للاختبار...
call flutter run -d chrome --web-renderer html
echo.

echo ===========================================
echo تم إصلاح المشاكل الأساسية
echo ===========================================
pause 