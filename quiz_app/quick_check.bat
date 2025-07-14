@echo off
title Quick System Check - فحص سريع للنظام
color 0A

echo ╔══════════════════════════════════════════════════════════════╗
echo ║                    فحص سريع للنظام                           ║
echo ║              تشخيص مشكلة انطفاء الحاسوب                      ║
echo ╚══════════════════════════════════════════════════════════════╝
echo.

echo [%TIME%] بدء الفحص...
echo.

:: فحص استهلاك الذاكرة
echo ═══ فحص الذاكرة ═══
for /f "tokens=2 delims==" %%i in ('wmic OS get TotalVisibleMemorySize /value') do set total_memory=%%i
for /f "tokens=2 delims==" %%i in ('wmic OS get FreePhysicalMemory /value') do set free_memory=%%i

if defined total_memory (
    set /a used_memory=%total_memory%-%free_memory%
    set /a memory_percent=%used_memory%*100/%total_memory%
    set /a total_gb=%total_memory%/1048576
    set /a used_gb=%used_memory%/1048576
    
    echo الذاكرة الإجمالية: %total_gb% GB
    echo الذاكرة المستخدمة: %used_gb% GB (%memory_percent%^%^)
    
    if %memory_percent% GEQ 90 (
        color 0C
        echo ⚠️  تحذير: استهلاك الذاكرة مرتفع جداً ^(%memory_percent%^%^)
        echo 🔴 خطر انطفاء الحاسوب محتمل!
    ) else if %memory_percent% GEQ 70 (
        color 0E
        echo ⚠️  تحذير: استهلاك الذاكرة مرتفع ^(%memory_percent%^%^)
    ) else (
        echo ✅ استهلاك الذاكرة طبيعي ^(%memory_percent%^%^)
    )
) else (
    echo ❌ فشل في قراءة معلومات الذاكرة
)

echo.

:: فحص استهلاك المعالج
echo ═══ فحص المعالج ═══
for /f "tokens=2 delims==" %%i in ('wmic cpu get loadpercentage /value') do set cpu_usage=%%i

if defined cpu_usage (
    echo استهلاك المعالج: %cpu_usage%^%
    
    if %cpu_usage% GEQ 90 (
        color 0C
        echo ⚠️  تحذير: استهلاك المعالج مرتفع جداً ^(%cpu_usage%^%^)
        echo 🔴 خطر انطفاء الحاسوب محتمل!
    ) else if %cpu_usage% GEQ 70 (
        color 0E
        echo ⚠️  تحذير: استهلاك المعالج مرتفع ^(%cpu_usage%^%^)
    ) else (
        echo ✅ استهلاك المعالج طبيعي ^(%cpu_usage%^%^)
    )
) else (
    echo ❌ فشل في قراءة معلومات المعالج
)

echo.

:: فحص العمليات المشبوهة
echo ═══ فحص عمليات Flutter ═══
tasklist | findstr /i "dart.exe" >nul 2>&1
if %errorlevel% == 0 (
    echo 🔍 تم العثور على عملية Dart نشطة
    tasklist | findstr /i "dart.exe"
    echo ⚠️  يُنصح بإيقاف هذه العملية
) else (
    echo ✅ لا توجد عمليات Dart نشطة
)

tasklist | findstr /i "flutter.exe" >nul 2>&1
if %errorlevel% == 0 (
    echo 🔍 تم العثور على عملية Flutter نشطة
    tasklist | findstr /i "flutter.exe"
    echo ⚠️  يُنصح بإيقاف هذه العملية
) else (
    echo ✅ لا توجد عمليات Flutter نشطة
)

echo.

:: فحص المساحة المتاحة
echo ═══ فحص مساحة القرص ═══
for /f "tokens=3" %%i in ('dir C:\ ^| findstr "bytes free"') do set free_space=%%i
if defined free_space (
    echo المساحة المتاحة على القرص C: %free_space% bytes
    :: تحويل إلى GB (تقريبي)
    set /a free_gb=%free_space:~0,-9%
    if %free_gb% LSS 2 (
        echo ⚠️  تحذير: مساحة القرص منخفضة ^(%free_gb% GB^)
    ) else (
        echo ✅ مساحة القرص كافية ^(%free_gb% GB^)
    )
) else (
    echo ❌ فشل في قراءة معلومات القرص
)

echo.

:: تقييم الحالة العامة
echo ═══ التقييم الشامل ═══
set risk_level=0

if defined memory_percent if %memory_percent% GEQ 90 set /a risk_level+=3
if defined memory_percent if %memory_percent% GEQ 70 if %memory_percent% LSS 90 set /a risk_level+=1

if defined cpu_usage if %cpu_usage% GEQ 90 set /a risk_level+=3
if defined cpu_usage if %cpu_usage% GEQ 70 if %cpu_usage% LSS 90 set /a risk_level+=1

if %risk_level% GEQ 5 (
    color 0C
    echo 🚨 مستوى الخطر: عالي جداً
    echo 🔴 لا تشغل التطبيق - قد يتسبب في انطفاء الحاسوب!
    echo.
    echo الإجراءات المطلوبة:
    echo 1. أعد تشغيل الحاسوب فوراً
    echo 2. أغلق جميع البرامج غير الضرورية
    echo 3. تأكد من التبريد الكافي
    echo 4. استخدم النسخة الطارئة فقط
) else if %risk_level% GEQ 2 (
    color 0E
    echo ⚠️  مستوى الخطر: متوسط
    echo 🟡 يمكن تشغيل النسخة الآمنة بحذر
    echo.
    echo الإجراءات المُنصح بها:
    echo 1. أغلق البرامج غير الضرورية
    echo 2. اختر النسخة الآمنة
    echo 3. راقب الأداء أثناء التشغيل
) else (
    color 0A
    echo ✅ مستوى الخطر: منخفض
    echo 🟢 آمن لتشغيل التطبيق
    echo.
    echo يمكنك تشغيل التطبيق بأمان
)

echo.

:: خيارات الحل
echo ╔══════════════════════════════════════════════════════════════╗
echo ║                         خيارات الحل                          ║
echo ╚══════════════════════════════════════════════════════════════╝
echo.
echo [1] تشغيل النسخة الطارئة الآمنة
echo [2] تطبيق الحل الشامل
echo [3] إيقاف جميع عمليات Flutter
echo [4] فحص إضافي للنظام
echo [5] عرض دليل الطوارئ
echo [Q] خروج
echo.

set /p choice="اختر الإجراء المطلوب [1-5 أو Q]: "

if /i "%choice%"=="1" goto safe_mode
if /i "%choice%"=="2" goto full_fix
if /i "%choice%"=="3" goto kill_processes
if /i "%choice%"=="4" goto extended_check
if /i "%choice%"=="5" goto show_guide
if /i "%choice%"=="Q" goto end
goto invalid_choice

:safe_mode
echo.
echo ═══ تشغيل النسخة الآمنة ═══
echo جاري إعداد النسخة الآمنة...
copy lib\main_emergency.dart lib\main.dart >nul 2>&1
copy pubspec_emergency.yaml pubspec.yaml >nul 2>&1
echo ✅ تم إعداد النسخة الآمنة
echo.
echo تشغيل الآن؟ (Y/N)
set /p run_choice=""
if /i "%run_choice%"=="Y" (
    echo جاري التشغيل...
    flutter run -d chrome --web-renderer html --no-sound-null-safety
)
goto end

:full_fix
echo.
echo ═══ تطبيق الحل الشامل ═══
call emergency_fix.bat
goto end

:kill_processes
echo.
echo ═══ إيقاف عمليات Flutter ═══
echo جاري إيقاف العمليات...
taskkill /F /IM dart.exe >nul 2>&1
taskkill /F /IM flutter.exe >nul 2>&1
taskkill /F /IM chrome.exe >nul 2>&1
echo ✅ تم إيقاف جميع العمليات
echo.
pause
goto end

:extended_check
echo.
echo ═══ فحص إضافي ═══
echo فحص درجة الحرارة وحالة الهاردوير...
wmic /namespace:\\root\wmi PATH MSAcpi_ThermalZoneTemperature get CurrentTemperature 2>nul
echo.
echo فحص أخطاء النظام...
for /f "tokens=*" %%i in ('powershell "Get-EventLog System -Newest 5 -EntryType Error | Select-Object TimeGenerated, Source, Message"') do echo %%i
echo.
pause
goto end

:show_guide
echo.
echo ═══ دليل الطوارئ ═══
echo يتم فتح دليل الطوارئ...
if exist EMERGENCY_GUIDE.md (
    start notepad EMERGENCY_GUIDE.md
) else (
    echo ❌ ملف الدليل غير موجود
)
echo.
pause
goto end

:invalid_choice
echo ❌ خيار غير صحيح، حاول مرة أخرى
echo.
pause
goto end

:end
echo.
echo تم الانتهاء من الفحص.
echo للحصول على مساعدة إضافية، راجع EMERGENCY_GUIDE.md
echo.
pause 