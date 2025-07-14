import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../models/quiz.dart';
import '../services/storage_service.dart';
import 'quiz_builder_screen.dart';
import 'quiz_results_screen.dart';
import 'login_screen.dart';
import '../main.dart' as main_app; // إضافة import للوصول لدالة logout

class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({super.key});

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  final StorageService _storageService = StorageService();
  List<Quiz> _quizzes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadQuizzes();
  }

  Future<void> _loadQuizzes() async {
    try {
      await _storageService.initialize();
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final teacherId = authProvider.currentUser!.id!;
      final quizzes = await _storageService.getQuizzesByTeacher(teacherId);
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

  Future<void> _deleteQuiz(Quiz quiz) async {
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
        await _storageService.deleteQuiz(quiz.id!);
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

  // دالة تسجيل الخروج المحلية
  void _logout() {
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
            onPressed: () async {
              Navigator.pop(dialogContext); // إغلاق الحوار
              
              // تنظيف بيانات الجلسة
              final auth = Provider.of<AuthProvider>(context, listen: false);
              await auth.logout();
              
              // العودة إلى شاشة تسجيل الدخول وإزالة جميع الصفحات السابقة
              if (mounted) {
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
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('خروج', style: GoogleFonts.cairo()),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Consumer<AuthProvider>(
          builder: (context, auth, child) => Text(
            'مرحباً ${auth.currentUser?.name}',
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
          ),
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(), // استخدام دالة logout محلية
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadQuizzes,
              child: CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.all(16.0),
                    sliver: SliverToBoxAdapter(
                      child: Card(
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
                                'لوحة تحكم المعلم',
                                style: GoogleFonts.cairo(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[800],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'إدارة الاختبارات ومتابعة النتائج',
                                style: GoogleFonts.cairo(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
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
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    sliver: SliverToBoxAdapter(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'اختباراتي',
                            style: GoogleFonts.cairo(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () async {
                              final result = await Navigator.push<bool>(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const QuizBuilderScreen(),
                                ),
                              );
                              if (result == true) {
                                _loadQuizzes();
                              }
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('إنشاء اختبار'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SliverToBoxAdapter(child: SizedBox(height: 16)),
                  
                  _quizzes.isEmpty
                      ? SliverFillRemaining(
                          child: Center(
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
                          ),
                        )
                      : SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final quiz = _quizzes[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12.0),
                                  child: Card(
                                    elevation: 2,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.all(16),
                                      leading: CircleAvatar(
                                        backgroundColor: quiz.isActive 
                                            ? Colors.green 
                                            : Colors.orange,
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
                                              Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                                              const SizedBox(width: 4),
                                              Text(
                                                '${quiz.createdAt.day}/${quiz.createdAt.month}/${quiz.createdAt.year}',
                                                style: GoogleFonts.cairo(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      trailing: PopupMenuButton(
                                        itemBuilder: (context) => [
                                          PopupMenuItem(
                                            value: 'results',
                                            child: Row(
                                              children: [
                                                const Icon(Icons.analytics, size: 20),
                                                const SizedBox(width: 8),
                                                Text('النتائج', style: GoogleFonts.cairo()),
                                              ],
                                            ),
                                          ),
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
                                          switch (value) {
                                            case 'results':
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => QuizResultsScreen(quiz: quiz),
                                                ),
                                              );
                                              break;
                                            case 'edit':
                                              final result = await Navigator.push<bool>(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => QuizBuilderScreen(quiz: quiz),
                                                ),
                                              );
                                              if (result == true) {
                                                _loadQuizzes();
                                              }
                                              break;
                                            case 'delete':
                                              _deleteQuiz(quiz);
                                              break;
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                );
                              },
                              childCount: _quizzes.length,
                            ),
                          ),
                        ),
                ],
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