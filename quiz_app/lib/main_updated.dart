import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'models/question_updated.dart';
import 'services/persistent_storage_service.dart';
import 'models/user.dart';
import 'models/quiz.dart';
import 'screens/enhanced_quiz_builder.dart';
import 'screens/admin_dashboard.dart';

void main() {
  runApp(const EnhancedQuizApp());
}

class EnhancedQuizApp extends StatelessWidget {
  const EnhancedQuizApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'نظام الاختبارات الاحترافي المطور',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        fontFamily: GoogleFonts.cairo().fontFamily,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
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
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _storage = PersistentStorageService(); // إصلاح اسم الكلاس
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() => _isLoading = true);
    
    try {
      await _storage.initialize();
      final user = await _storage.getUserByEmail(_emailController.text.trim());
      
      if (user != null && user.password == _passwordController.text) {
        if (mounted) {
          if (user.role == UserRole.teacher) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => TeacherDashboard(user: user)),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => StudentDashboard(user: user)),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('خطأ في تسجيل الدخول'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e')),
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
              padding: const EdgeInsets.all(24.0),
              child: Card(
                elevation: 12,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.quiz,
                        size: 80,
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'نظام الاختبارات الاحترافي المطور',
                        style: GoogleFonts.cairo(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      
                      TextField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'البريد الإلكتروني',
                          prefixIcon: const Icon(Icons.email),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'كلمة المرور',
                          prefixIcon: const Icon(Icons.lock),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onSubmitted: (_) => _login(),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                )
                              : Text(
                                  'تسجيل الدخول',
                                  style: GoogleFonts.cairo(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'حسابات تجريبية:',
                              style: GoogleFonts.cairo(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[800],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'معلم: teacher@quiz.com | 123456\nطالب: student@quiz.com | 123456',
                              style: GoogleFonts.cairo(
                                fontSize: 12,
                                color: Colors.blue[600],
                              ),
                              textAlign: TextAlign.center,
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
}

class TeacherDashboard extends StatefulWidget {
  final User user;
  
  const TeacherDashboard({super.key, required this.user});

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  final _storage = PersistentStorageService(); // إصلاح اسم الكلاس
  List<Quiz> _quizzes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadQuizzes();
  }

  Future<void> _loadQuizzes() async {
    try {
      await _storage.initialize();
      final quizzes = await _storage.getQuizzesByTeacher(widget.user.id!);
      setState(() {
        _quizzes = quizzes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في تحميل البيانات: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'مرحباً ${widget.user.name}',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadQuizzes,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          children: [
                            Icon(
                              Icons.dashboard,
                              size: 48,
                              color: Colors.deepPurple,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'لوحة تحكم المعلم المطورة',
                              style: GoogleFonts.cairo(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800],
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'دعم لأنواع مختلفة من الأسئلة وإدارة متطورة',
                              style: GoogleFonts.cairo(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _StatCard(
                                  title: 'إجمالي الاختبارات',
                                  value: _quizzes.length.toString(),
                                  icon: Icons.quiz,
                                  color: Colors.blue,
                                ),
                                _StatCard(
                                  title: 'الاختبارات النشطة',
                                  value: _quizzes.where((q) => q.isActive).length.toString(),
                                  icon: Icons.check_circle,
                                  color: Colors.green,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () async {
                                final result = await Navigator.push<bool>(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EnhancedQuizBuilder(teacherId: widget.user.id!),
                                  ),
                                );
                                if (result == true) {
                                  _loadQuizzes();
                                }
                              },
                              icon: const Icon(Icons.add),
                              label: Text('إنشاء اختبار جديد', style: GoogleFonts.cairo()),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepPurple,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: _quizzes.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.quiz_outlined,
                                    size: 64,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'لا توجد اختبارات حتى الآن',
                                    style: GoogleFonts.cairo(
                                      fontSize: 18,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'ابدأ بإنشاء اختبارك الأول',
                                    style: GoogleFonts.cairo(
                                      fontSize: 14,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: _quizzes.length,
                              itemBuilder: (context, index) {
                                final quiz = _quizzes[index];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.all(16),
                                    leading: CircleAvatar(
                                      backgroundColor: quiz.isActive ? Colors.green : Colors.orange,
                                      child: Icon(
                                        quiz.isActive ? Icons.play_arrow : Icons.pause,
                                        color: Colors.white,
                                      ),
                                    ),
                                    title: Text(
                                      quiz.title,
                                      style: GoogleFonts.cairo(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        if (quiz.description.isNotEmpty)
                                          Text(
                                            quiz.description,
                                            style: GoogleFonts.cairo(fontSize: 12),
                                          ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(Icons.timer, size: 16, color: Colors.grey[600]),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${quiz.duration} دقيقة',
                                              style: GoogleFonts.cairo(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            Icon(Icons.help_outline, size: 16, color: Colors.grey[600]),
                                            const SizedBox(width: 4),
                                            FutureBuilder<List<QuestionUpdated>>(
                                              future: _storage.getQuestionsByQuiz(quiz.id!),
                                              builder: (context, snapshot) {
                                                final questionCount = snapshot.data?.length ?? 0;
                                                return Text(
                                                  '$questionCount سؤال',
                                                  style: GoogleFonts.cairo(
                                                    fontSize: 12,
                                                    color: Colors.grey[600],
                                                  ),
                                                );
                                              },
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    trailing: PopupMenuButton(
                                      itemBuilder: (context) => [
                                        PopupMenuItem(
                                          value: 'edit',
                                          child: Row(
                                            children: [
                                              const Icon(Icons.edit, size: 20),
                                              const SizedBox(width: 8),
                                              Text('تعديل', style: GoogleFonts.cairo()),
                                            ],
                                          ),
                                        ),
                                        PopupMenuItem(
                                          value: 'delete',
                                          child: Row(
                                            children: [
                                              const Icon(Icons.delete, size: 20, color: Colors.red),
                                              const SizedBox(width: 8),
                                              Text('حذف', style: GoogleFonts.cairo(color: Colors.red)),
                                            ],
                                          ),
                                        ),
                                      ],
                                      onSelected: (value) async {
                                        if (value == 'edit') {
                                          final result = await Navigator.push<bool>(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => EnhancedQuizBuilder(
                                                teacherId: widget.user.id!,
                                                quiz: quiz,
                                              ),
                                            ),
                                          );
                                          if (result == true) {
                                            _loadQuizzes();
                                          }
                                        } else if (value == 'delete') {
                                          final confirmed = await showDialog<bool>(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: Text('تأكيد الحذف', style: GoogleFonts.cairo()),
                                              content: Text('هل أنت متأكد من حذف الاختبار "${quiz.title}"؟', style: GoogleFonts.cairo()),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.pop(context, false),
                                                  child: Text('إلغاء', style: GoogleFonts.cairo()),
                                                ),
                                                TextButton(
                                                  onPressed: () => Navigator.pop(context, true),
                                                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                                                  child: Text('حذف', style: GoogleFonts.cairo()),
                                                ),
                                              ],
                                            ),
                                          );
                                          if (confirmed == true) {
                                            try {
                                              await _storage.deleteQuiz(quiz.id!);
                                              _loadQuizzes();
                                              if (mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(content: Text('تم حذف الاختبار بنجاح')),
                                                );
                                              }
                                            } catch (e) {
                                              if (mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(content: Text('خطأ في حذف الاختبار: $e')),
                                                );
                                              }
                                            }
                                          }
                                        }
                                      },
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class StudentDashboard extends StatefulWidget {
  final User user;
  
  const StudentDashboard({super.key, required this.user});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  final _storage = PersistentStorageService(); // إصلاح اسم الكلاس
  List<Quiz> _availableQuizzes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadQuizzes();
  }

  Future<void> _loadQuizzes() async {
    try {
      await _storage.initialize();
      final quizzes = await _storage.getActiveQuizzes();
      setState(() {
        _availableQuizzes = quizzes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في تحميل البيانات: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'مرحباً ${widget.user.name}',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadQuizzes,
              child: _availableQuizzes.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.quiz_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'لا توجد اختبارات متاحة حالياً',
                            style: GoogleFonts.cairo(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _availableQuizzes.length,
                      itemBuilder: (context, index) {
                        final quiz = _availableQuizzes[index];
                        return FutureBuilder<bool>(
                          future: _storage.hasStudentTakenQuiz(widget.user.id!, quiz.id!),
                          builder: (context, snapshot) {
                            final hasTaken = snapshot.data ?? false;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Card(
                                elevation: 4,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: hasTaken
                                      ? null
                                      : () async {
                                          final result = await Navigator.push<bool>(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => EnhancedQuizTaking(
                                                quiz: quiz,
                                                student: widget.user,
                                              ),
                                            ),
                                          );
                                          if (result == true) {
                                            _loadQuizzes();
                                          }
                                        },
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              width: 60,
                                              height: 60,
                                              decoration: BoxDecoration(
                                                color: hasTaken ? Colors.green : Colors.teal,
                                                borderRadius: BorderRadius.circular(30),
                                              ),
                                              child: Icon(
                                                hasTaken ? Icons.check_circle : Icons.play_arrow,
                                                color: Colors.white,
                                                size: 30,
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    quiz.title,
                                                    style: GoogleFonts.cairo(
                                                      fontSize: 18,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                  if (quiz.description.isNotEmpty) ...[
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      quiz.description,
                                                      style: GoogleFonts.cairo(
                                                        fontSize: 14,
                                                        color: Colors.grey[600],
                                                      ),
                                                    ),
                                                  ],
                                                  const SizedBox(height: 8),
                                                  Row(
                                                    children: [
                                                      Icon(Icons.timer, size: 16, color: Colors.grey[600]),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        '${quiz.duration} دقيقة',
                                                        style: GoogleFonts.cairo(
                                                          fontSize: 12,
                                                          color: Colors.grey[600],
                                                        ),
                                                      ),
                                                      const SizedBox(width: 16),
                                                      Icon(Icons.help_outline, size: 16, color: Colors.grey[600]),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        '${quiz.questions.length} سؤال',
                                                        style: GoogleFonts.cairo(
                                                          fontSize: 12,
                                                          color: Colors.grey[600],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        if (hasTaken)
                                          Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: Colors.green[50],
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: Colors.green),
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(Icons.check_circle, color: Colors.green, size: 20),
                                                const SizedBox(width: 8),
                                                Text(
                                                  'تم إنجاز هذا الاختبار',
                                                  style: GoogleFonts.cairo(
                                                    color: Colors.green[700],
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )
                                        else
                                          Container(
                                            width: double.infinity,
                                            height: 40,
                                            decoration: BoxDecoration(
                                              gradient: const LinearGradient(
                                                colors: [Colors.teal, Colors.tealAccent],
                                              ),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Center(
                                              child: Text(
                                                'ابدأ الاختبار',
                                                style: GoogleFonts.cairo(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 8),
              Text(
                value,
                style: GoogleFonts.cairo(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                title,
                style: GoogleFonts.cairo(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Enhanced Quiz Builder is now imported from screens/enhanced_quiz_builder.dart

class EnhancedQuizTaking extends StatelessWidget {
  final Quiz quiz;
  final User student;

  const EnhancedQuizTaking({super.key, required this.quiz, required this.student});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(quiz.title, style: GoogleFonts.cairo()),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text('سيتم تطوير هذه الواجهة قريباً'),
      ),
    );
  }
} 