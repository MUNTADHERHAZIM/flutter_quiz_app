import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'models/user.dart';
import 'screens/student_dashboard.dart';
import 'screens/teacher_dashboard.dart';
import 'screens/admin_dashboard.dart';
import 'screens/registration_screen.dart';

void main() {
  runApp(const QuizApp());
}

class QuizApp extends StatelessWidget {
  const QuizApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'نظام إدارة الاختبارات المتقدم',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        fontFamily: GoogleFonts.cairo().fontFamily,
        textTheme: GoogleFonts.cairoTextTheme(),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const LoginScreen(),
      debugShowCheckedModeBanner: false,
      // إضافة routes للتنقل السهل
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => RegistrationScreen(),
      },
    );
  }
}

// إضافة GlobalKey للنقل السهل للصفحة الرئيسية
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  // حسابات تجريبية مبنية مسبقاً
  final Map<String, Map<String, dynamic>> _demoUsers = {
    'admin@quiz.com': {
      'id': 1,
      'name': 'المدير العام',
      'email': 'admin@quiz.com',
      'password': 'admin123',
      'role': 'admin',
    },
    'teacher@quiz.com': {
      'id': 2,
      'name': 'أحمد المعلم',
      'email': 'teacher@quiz.com',
      'password': '123456',
      'role': 'teacher',
    },
    'student@quiz.com': {
      'id': 3,
      'name': 'فاطمة الطالبة',
      'email': 'student@quiz.com',
      'password': '123456',
      'role': 'student',
    },
  };

  // دالة تسجيل الخروج العامة - يمكن استخدامها من أي مكان
  static void logout(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('تسجيل الخروج', style: GoogleFonts.cairo()),
        content: Text('هل تريد تسجيل الخروج من النظام؟', style: GoogleFonts.cairo()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('إلغاء', style: GoogleFonts.cairo()),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext); // إغلاق الحوار
              // العودة إلى شاشة تسجيل الدخول وإزالة جميع الصفحات السابقة
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
              // إظهار رسالة تأكيد
              Future.delayed(const Duration(milliseconds: 500), () {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('تم تسجيل الخروج بنجاح', style: GoogleFonts.cairo()),
                      backgroundColor: Colors.green,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              });
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('خروج', style: GoogleFonts.cairo()),
          ),
        ],
      ),
    );
  }

  Future<void> _login() async {
    if (_emailController.text.trim().isEmpty || _passwordController.text.isEmpty) {
      _showMessage('يرجى إدخال البريد الإلكتروني وكلمة المرور', Colors.orange);
      return;
    }

    setState(() => _isLoading = true);
    
    // محاكاة تأخير التحقق
    await Future.delayed(const Duration(seconds: 1));
    
    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;
      
      if (_demoUsers.containsKey(email) && _demoUsers[email]!['password'] == password) {
        final userData = _demoUsers[email]!;
        final user = User(
          id: userData['id'],
          email: userData['email'],
          name: userData['name'],
          role: UserRole.values.firstWhere((r) => r.name == userData['role']),
          password: userData['password'],
          createdAt: DateTime.now(),
        );

        if (mounted) {
          _showMessage('تم تسجيل الدخول بنجاح!', Colors.green);
          await Future.delayed(const Duration(seconds: 1));
          
          if (!mounted) return; // فحص إضافي للـ mounted
          
          // توجيه المستخدم للشاشة المناسبة حسب دوره
          Widget targetScreen;
          switch (user.role) {
            case UserRole.admin:
              targetScreen = AdminDashboard(admin: user);
              break;
            case UserRole.teacher:
              targetScreen = const TeacherDashboard();
              break;
            case UserRole.student:
              targetScreen = const StudentDashboard();
              break;
          }
          
          // استخدام pushAndRemoveUntil لضمان عدم إمكانية العودة لشاشة تسجيل الدخول بـ back button
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => targetScreen),
            (route) => false, // إزالة جميع الصفحات السابقة
          );
        }
      } else {
        if (mounted) {
          _showMessage('خطأ في البريد الإلكتروني أو كلمة المرور', Colors.red);
        }
      }
    } catch (e) {
      if (mounted) {
        _showMessage('خطأ في النظام: $e', Colors.red);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showMessage(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.cairo()),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _fillDemoAccount(String email, String password) {
    _emailController.text = email;
    _passwordController.text = password;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF667eea),
              Color(0xFF764ba2),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Card(
                elevation: 12,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo and Title
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.indigo,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.quiz,
                          size: 60,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      Text(
                        'نظام إدارة الاختبارات الإلكترونية',
                        style: GoogleFonts.cairo(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo[800],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      Text(
                        'النسخة المتطورة مع جميع الميزات',
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Login Form
                      Text(
                        'تسجيل الدخول',
                        style: GoogleFonts.cairo(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      TextField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'البريد الإلكتروني',
                          labelStyle: GoogleFonts.cairo(),
                          prefixIcon: const Icon(Icons.email),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        style: GoogleFonts.cairo(),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),
                      
                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'كلمة المرور',
                          labelStyle: GoogleFonts.cairo(),
                          prefixIcon: const Icon(Icons.lock),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        style: GoogleFonts.cairo(),
                        onSubmitted: (_) => _login(),
                      ),
                      const SizedBox(height: 24),
                      
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : Text(
                                  'دخول',
                                  style: GoogleFonts.cairo(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Register Button
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => RegistrationScreen()),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.indigo),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.person_add, color: Colors.indigo),
                              const SizedBox(width: 8),
                              Text(
                                'إنشاء حساب جديد',
                                style: GoogleFonts.cairo(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.indigo,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Demo Accounts Section
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.account_box, color: Colors.blue),
                                const SizedBox(width: 8),
                                Text(
                                  'حسابات تجريبية - اضغط لملء البيانات',
                                  style: GoogleFonts.cairo(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue[800],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            
                            _buildDemoAccount(
                              'المدير العام',
                              'admin@quiz.com',
                              'admin123',
                              Colors.red,
                              Icons.admin_panel_settings,
                              'إدارة شاملة + لوحة إحصائيات متقدمة',
                            ),
                            const SizedBox(height: 8),
                            
                            _buildDemoAccount(
                              'أحمد المعلم',
                              'teacher@quiz.com',
                              '123456',
                              Colors.blue,
                              Icons.school,
                              'بنك أسئلة + إنشاء اختبارات + تحليل نتائج',
                            ),
                            const SizedBox(height: 8),
                            
                            _buildDemoAccount(
                              'فاطمة الطالبة',
                              'student@quiz.com',
                              '123456',
                              Colors.green,
                              Icons.person,
                              'أداء اختبارات + عرض نتائج + ملف شخصي',
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // System Features
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.verified, color: Colors.green),
                                const SizedBox(width: 8),
                                Text(
                                  'مميزات النظام المتطور',
                                  style: GoogleFonts.cairo(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green[700],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFeatureItem('✅ بنك أسئلة متطور مع تصنيفات'),
                                _buildFeatureItem('✅ أنواع أسئلة متعددة (اختياري، صح/خطأ، إملاء)'),
                                _buildFeatureItem('✅ نظام اختبارات تفاعلي مع توقيت'),
                                _buildFeatureItem('✅ تحليلات ونتائج مفصلة'),
                                _buildFeatureItem('✅ إدارة مستخدمين وصلاحيات'),
                                _buildFeatureItem('✅ لوحات تحكم منفصلة لكل فئة'),
                                _buildFeatureItem('✅ تقارير وإحصائيات شاملة'),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDemoAccount(
    String name,
    String email,
    String password,
    Color color,
    IconData icon,
    String description,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: InkWell(
        onTap: () => _fillDemoAccount(email, password),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.cairo(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    Text(
                      '$email | $password',
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      description,
                      style: GoogleFonts.cairo(
                        fontSize: 11,
                        color: color,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.touch_app, color: color, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text(
        text,
        style: GoogleFonts.cairo(
          fontSize: 12,
          color: Colors.green[700],
        ),
      ),
    );
  }
} 