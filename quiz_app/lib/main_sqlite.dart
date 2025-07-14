import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/sqlite_database_service.dart';
import 'screens/question_bank_screen.dart';
import 'screens/registration_screen.dart';
import 'screens/admin_users_management.dart';
import 'screens/quiz_management_screen.dart';
import 'screens/student_dashboard_sqlite.dart';
import 'screens/results_analysis_screen.dart';
import 'models/user.dart';

void main() {
  runApp(const SQLiteQuizApp());
}

class SQLiteQuizApp extends StatelessWidget {
  const SQLiteQuizApp({super.key});

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
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final SQLiteDatabaseService _dbService = SQLiteDatabaseService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeDatabase();
  }

  Future<void> _initializeDatabase() async {
    try {
      await _dbService.database; // This will initialize the database
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في تهيئة قاعدة البيانات: $e')),
      );
    }
  }

  Future<void> _login() async {
    setState(() => _isLoading = true);
    
    try {
      final user = await _dbService.getUserByEmail(_emailController.text.trim());
      
      if (user != null && user['password'] == _passwordController.text) {
                 final userModel = User(
           id: user['id'],
           email: user['email'],
           name: user['name'],
           role: UserRole.values.firstWhere((r) => r.name == user['role'], orElse: () => UserRole.teacher),
           password: user['password'],
           createdAt: DateTime.now(),
         );

        if (mounted) {
          Widget targetScreen;
          if (userModel.role == UserRole.student) {
            targetScreen = StudentDashboardSQLite(student: userModel);
          } else {
            targetScreen = MainDashboard(user: userModel);
          }
          
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => targetScreen),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('خطأ في تسجيل الدخول - تحقق من البريد الإلكتروني وكلمة المرور'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في النظام: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 50),
              
              // Logo and Title
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.indigo,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.quiz,
                  size: 80,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              
              Text(
                'نظام إدارة الاختبارات المتقدم',
                style: GoogleFonts.cairo(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo[800],
                ),
                textAlign: TextAlign.center,
              ),
              
              Text(
                'مع قاعدة بيانات SQLite المتطورة',
                style: GoogleFonts.cairo(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 40),
              
              // Login Form
              Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
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
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Register Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const RegistrationScreen()),
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
              
              const SizedBox(height: 40),
              
              // Demo Accounts
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        'حسابات تجريبية',
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      _buildDemoAccount(
                        'المدير',
                        'admin@quiz.com',
                        'admin123',
                        Colors.red,
                        Icons.admin_panel_settings,
                      ),
                      const SizedBox(height: 8),
                      
                      _buildDemoAccount(
                        'المعلم',
                        'teacher@quiz.com',
                        '123456',
                        Colors.blue,
                        Icons.school,
                      ),
                      const SizedBox(height: 8),
                      
                      _buildDemoAccount(
                        'الطالب',
                        'student@quiz.com',
                        '123456',
                        Colors.green,
                        Icons.person,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDemoAccount(
    String role,
    String email,
    String password,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  role,
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.bold,
                                         color: Colors.grey[700],
                  ),
                ),
                Text(
                  '$email | $password',
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                                         color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              _emailController.text = email;
              _passwordController.text = password;
            },
            icon: Icon(Icons.copy, color: color, size: 18),
            tooltip: 'نسخ بيانات تسجيل الدخول',
          ),
        ],
      ),
    );
  }
}

class MainDashboard extends StatefulWidget {
  final User user;

  const MainDashboard({super.key, required this.user});

  @override
  State<MainDashboard> createState() => _MainDashboardState();
}

class _MainDashboardState extends State<MainDashboard> {
  final SQLiteDatabaseService _dbService = SQLiteDatabaseService();
  int _currentIndex = 0;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'مرحباً ${widget.user.name}',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(),
            tooltip: 'تسجيل الخروج',
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildDashboardTab(),
          QuestionBankScreen(currentUser: widget.user),
          QuizManagementScreen(currentUser: widget.user),
          ResultsAnalysisScreen(currentUser: widget.user),
          widget.user.role.name == 'admin' ? AdminUsersManagement(currentAdmin: widget.user) : _buildSettingsTab(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.indigo,
        unselectedItemColor: Colors.grey,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.dashboard),
            label: 'الرئيسية',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.quiz),
            label: 'بنك الأسئلة',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.assignment),
            label: 'الاختبارات',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.analytics),
            label: 'التحليلات',
          ),
          BottomNavigationBarItem(
            icon: widget.user.role.name == 'admin' ? const Icon(Icons.people) : const Icon(Icons.settings),
            label: widget.user.role.name == 'admin' ? 'المستخدمون' : 'الإعدادات',
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardTab() {
    return FutureBuilder<Map<String, int>>(
      future: _dbService.getSystemStats(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final stats = snapshot.data!;
        
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'نظرة عامة',
                style: GoogleFonts.cairo(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              
              // Stats Grid
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildStatsCard(
                    'المستخدمون',
                    stats['users']?.toString() ?? '0',
                    Icons.people,
                    Colors.blue,
                  ),
                  _buildStatsCard(
                    'الاختبارات',
                    stats['quizzes']?.toString() ?? '0',
                    Icons.assignment,
                    Colors.green,
                  ),
                  _buildStatsCard(
                    'الأسئلة',
                    stats['questions']?.toString() ?? '0',
                    Icons.quiz,
                    Colors.orange,
                  ),
                  _buildStatsCard(
                    'النتائج',
                    stats['results']?.toString() ?? '0',
                    Icons.analytics,
                    Colors.purple,
                  ),
                ],
              ),
              
              const SizedBox(height: 30),
              
              // Quick Actions
              Text(
                'إجراءات سريعة',
                style: GoogleFonts.cairo(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
                             if (widget.user.role == UserRole.teacher) ...[
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.add_circle, color: Colors.green),
                    title: Text('إضافة سؤال جديد', style: GoogleFonts.cairo()),
                    subtitle: Text('أضف سؤالاً إلى بنك الأسئلة', style: GoogleFonts.cairo()),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () => setState(() => _currentIndex = 1),
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.assignment_add, color: Colors.blue),
                    title: Text('إنشاء اختبار جديد', style: GoogleFonts.cairo()),
                    subtitle: Text('أنشئ اختباراً من بنك الأسئلة', style: GoogleFonts.cairo()),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () => setState(() => _currentIndex = 2),
                  ),
                ),
              ],
              
              const SizedBox(height: 8),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.search, color: Colors.indigo),
                  title: Text('البحث في الأسئلة', style: GoogleFonts.cairo()),
                  subtitle: Text('ابحث في بنك الأسئلة', style: GoogleFonts.cairo()),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => setState(() => _currentIndex = 1),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatsCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 12),
            Text(
              value,
              style: GoogleFonts.cairo(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: GoogleFonts.cairo(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }



  Widget _buildSettingsTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.person),
              title: Text('الملف الشخصي', style: GoogleFonts.cairo()),
              subtitle: Text(widget.user.email, style: GoogleFonts.cairo()),
              trailing: const Icon(Icons.arrow_forward_ios),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.storage),
              title: Text('إدارة قاعدة البيانات', style: GoogleFonts.cairo()),
              subtitle: Text('نسخ احتياطي واستعادة', style: GoogleFonts.cairo()),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => _showDatabaseManagement(),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.info),
              title: Text('حول التطبيق', style: GoogleFonts.cairo()),
              subtitle: Text('الإصدار 1.0.0 - SQLite Edition', style: GoogleFonts.cairo()),
              trailing: const Icon(Icons.arrow_forward_ios),
            ),
          ),
        ],
      ),
    );
  }

  void _showDatabaseManagement() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('إدارة قاعدة البيانات', style: GoogleFonts.cairo()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.backup),
              title: Text('نسخ احتياطي', style: GoogleFonts.cairo()),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('سيتم تطوير هذه الميزة قريباً')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.restore),
              title: Text('استعادة', style: GoogleFonts.cairo()),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('سيتم تطوير هذه الميزة قريباً')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.red),
              title: Text('مسح جميع البيانات', style: GoogleFonts.cairo(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _confirmResetDatabase();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إغلاق', style: GoogleFonts.cairo()),
          ),
        ],
      ),
    );
  }

  void _confirmResetDatabase() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('تحذير!', style: GoogleFonts.cairo()),
        content: Text(
          'هل أنت متأكد من مسح جميع البيانات؟ لا يمكن التراجع عن هذا الإجراء.',
          style: GoogleFonts.cairo(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء', style: GoogleFonts.cairo()),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('سيتم تطوير هذه الميزة قريباً')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('مسح', style: GoogleFonts.cairo()),
          ),
        ],
      ),
    );
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('تسجيل الخروج', style: GoogleFonts.cairo()),
        content: Text('هل أنت متأكد من تسجيل الخروج؟', style: GoogleFonts.cairo()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء', style: GoogleFonts.cairo()),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
            child: Text('خروج', style: GoogleFonts.cairo()),
          ),
        ],
      ),
    );
  }
} 