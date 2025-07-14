import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../models/quiz.dart';
import '../models/quiz_result.dart';
import '../services/database_service.dart';
import 'quiz_taking_screen.dart';
import 'login_screen.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  final DatabaseService _databaseService = DatabaseService();
  List<Quiz> _availableQuizzes = [];
  List<QuizResult> _myResults = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final studentId = authProvider.currentUser!.id!;

      final quizzes = await _databaseService.getActiveQuizzes();
      final results = await _databaseService.getResultsByStudent(studentId);

      setState(() {
        _availableQuizzes = quizzes;
        _myResults = results;
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

  Future<bool> _hasStudentTakenQuiz(int quizId) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final studentId = authProvider.currentUser!.id!;
    return await _databaseService.hasStudentTakenQuiz(studentId, quizId);
  }

  // دالة تسجيل الخروج المحسنة
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
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Consumer<AuthProvider>(
            builder: (context, auth, child) => Text(
              'مرحباً ${auth.currentUser?.name}',
              style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
            ),
          ),
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
          bottom: TabBar(
            indicatorColor: Colors.white,
            tabs: [
              Tab(
                icon: const Icon(Icons.quiz),
                text: 'الاختبارات المتاحة',
              ),
              Tab(
                icon: const Icon(Icons.analytics),
                text: 'نتائجي',
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => _logout(), // استخدام دالة logout محلية
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _buildAvailableQuizzesTab(),
                  _buildMyResultsTab(),
                ],
              ),
      ),
    );
  }

  Widget _buildAvailableQuizzesTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
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
                  future: _hasStudentTakenQuiz(quiz.id!),
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
                                      builder: (context) => QuizTakingScreen(quiz: quiz),
                                    ),
                                  );
                                  if (result == true) {
                                    _loadData();
                                  }
                                },
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                if (hasTaken) ...[
                                  const SizedBox(height: 12),
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
                                  ),
                                ] else ...[
                                  const SizedBox(height: 12),
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
    );
  }

  Widget _buildMyResultsTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: _myResults.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.analytics_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'لم تقم بأي اختبارات بعد',
                    style: GoogleFonts.cairo(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'ابدأ بحل الاختبارات المتاحة لرؤية نتائجك هنا',
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Statistics Card
                Container(
                  margin: const EdgeInsets.all(16),
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Text(
                            'إحصائياتي',
                            style: GoogleFonts.cairo(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _StatItem(
                                title: 'اختبارات مكتملة',
                                value: _myResults.length.toString(),
                                icon: Icons.quiz,
                                color: Colors.blue,
                              ),
                              _StatItem(
                                title: 'المعدل العام',
                                value: _myResults.isEmpty
                                    ? '0%'
                                    : '${(_myResults.map((r) => r.percentage).reduce((a, b) => a + b) / _myResults.length).toStringAsFixed(1)}%',
                                icon: Icons.trending_up,
                                color: Colors.green,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Results List
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _myResults.length,
                    itemBuilder: (context, index) {
                      final result = _myResults[index];
                      final percentage = result.percentage;
                      
                      Color getGradeColor(double percentage) {
                        if (percentage >= 90) return Colors.green;
                        if (percentage >= 80) return Colors.lightGreen;
                        if (percentage >= 70) return Colors.orange;
                        if (percentage >= 60) return Colors.deepOrange;
                        return Colors.red;
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        color: getGradeColor(percentage),
                                        borderRadius: BorderRadius.circular(25),
                                      ),
                                      child: Center(
                                        child: Text(
                                          '${percentage.toStringAsFixed(0)}%',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          FutureBuilder<Quiz?>(
                                            future: _databaseService.getQuizById(result.quizId),
                                            builder: (context, snapshot) {
                                              final quiz = snapshot.data;
                                              return Text(
                                                quiz?.title ?? 'اختبار محذوف',
                                                style: GoogleFonts.cairo(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              );
                                            },
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'النتيجة: ${result.score} من ${result.totalQuestions}',
                                            style: GoogleFonts.cairo(
                                              fontSize: 14,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          Text(
                                            'الوقت المستغرق: ${(result.timeSpent / 60).toStringAsFixed(1)} دقيقة',
                                            style: GoogleFonts.cairo(
                                              fontSize: 12,
                                              color: Colors.grey[500],
                                            ),
                                          ),
                                          Text(
                                            'تاريخ الإنجاز: ${result.completedAt.day}/${result.completedAt.month}/${result.completedAt.year}',
                                            style: GoogleFonts.cairo(
                                              fontSize: 12,
                                              color: Colors.grey[500],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatItem({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 32, color: color),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.cairo(
            fontSize: 20,
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
    );
  }
} 