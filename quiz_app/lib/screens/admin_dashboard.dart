import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/user.dart';
import '../models/quiz.dart';
import '../models/question_updated.dart';
import '../models/quiz_result.dart';
import '../services/persistent_storage_service.dart';
import '../main.dart' as main_app; // إضافة import للوصول لدالة logout

class AdminDashboard extends StatefulWidget {
  final User admin;

  const AdminDashboard({super.key, required this.admin});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> with TickerProviderStateMixin {
  late TabController _tabController;
  final _storage = PersistentStorageService();
  
  Map<String, dynamic> _systemStats = {};
  List<User> _users = [];
  List<Quiz> _quizzes = [];
  List<QuestionUpdated> _questions = [];
  List<QuizResult> _results = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      await _storage.initialize();
      
      final stats = await _storage.getSystemStats();
      final users = await _storage.getAllUsers();
      // Get all questions from all quizzes
      final allQuestions = <QuestionUpdated>[];
      for (final user in users.where((u) => u.role == UserRole.teacher)) {
        final teacherQuizzes = await _storage.getQuizzesByTeacher(user.id!);
        for (final quiz in teacherQuizzes) {
          final quizQuestions = await _storage.getQuestionsByQuiz(quiz.id!);
          allQuestions.addAll(quizQuestions);
        }
      }
      final allResults = <QuizResult>[];
      for (final user in users.where((u) => u.role == UserRole.student)) {
        final userResults = await _storage.getResultsByStudent(user.id!);
        allResults.addAll(userResults);
      }
      
      final allQuizzes = <Quiz>[];
      for (final user in users.where((u) => u.role == UserRole.teacher)) {
        final teacherQuizzes = await _storage.getQuizzesByTeacher(user.id!);
        allQuizzes.addAll(teacherQuizzes);
      }

      setState(() {
        _systemStats = stats;
        _users = users;
        _quizzes = allQuizzes;
        _questions = allQuestions;
        _results = allResults;
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
          'لوحة إدارة النظام',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color.fromARGB(255, 75, 206, 187),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          tabs: [
            Tab(icon: Icon(Icons.dashboard), text: 'الإحصائيات'),
            Tab(icon: Icon(Icons.people), text: 'المستخدمين'),
            Tab(icon: Icon(Icons.quiz), text: 'الاختبارات'),
            Tab(icon: Icon(Icons.help), text: 'الأسئلة'),
            Tab(icon: Icon(Icons.analytics), text: 'النتائج'),
            Tab(icon: Icon(Icons.settings), text: 'الإعدادات'),
            Tab(icon: Icon(Icons.question_answer), text: 'الأسئلة المطلوبة'),
          
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadData,
          ),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () => _logout(), // استخدام دالة logout محلية
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildStatsTab(),
                _buildUsersTab(),
                _buildQuizzesTab(),
                _buildQuestionsTab(),
                _buildResultsTab(),
                _buildSettingsTab(),
              ],
            ),
    );
  }

  Widget _buildStatsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'إحصائيات النظام',
            style: GoogleFonts.cairo(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          
          // Quick Stats Cards
          GridView.count(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            children: [
              _buildStatCard(
                'إجمالي المستخدمين',
                _systemStats['total_users']?.toString() ?? '0',
                Icons.people,
                Colors.blue,
              ),
              _buildStatCard(
                'الاختبارات النشطة',
                _systemStats['active_quizzes']?.toString() ?? '0',
                Icons.quiz,
                Colors.green,
              ),
              _buildStatCard(
                'إجمالي الأسئلة',
                _systemStats['total_questions']?.toString() ?? '0',
                Icons.help,
                Colors.orange,
              ),
              _buildStatCard(
                'المعدل العام',
                '${(_systemStats['average_score'] ?? 0).toStringAsFixed(1)}%',
                Icons.grade,
                Colors.purple,
              ),
            ],
          ),
          
          SizedBox(height: 24),
          
          // Detailed Stats
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'تفاصيل النظام',
                    style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16),
                  _buildDetailRow('المعلمين:', '${_systemStats['teachers'] ?? 0}'),
                  _buildDetailRow('الطلاب:', '${_systemStats['students'] ?? 0}'),
                  _buildDetailRow('إجمالي الاختبارات:', '${_systemStats['total_quizzes'] ?? 0}'),
                  _buildDetailRow('النتائج المسجلة:', '${_systemStats['total_results'] ?? 0}'),
                  _buildDetailRow('آخر تحديث:', _formatDate(_systemStats['last_updated'])),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersTab() {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'إدارة المستخدمين (${_users.length})',
                style: GoogleFonts.cairo(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: _showAddUserDialog,
                icon: Icon(Icons.add),
                label: Text('إضافة مستخدم'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _users.length,
            itemBuilder: (context, index) {
              final user = _users[index];
              return Card(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: user.role == UserRole.teacher ? Colors.blue : Colors.teal,
                    child: Icon(
                      user.role == UserRole.teacher ? Icons.school : Icons.person,
                      color: Colors.white,
                    ),
                  ),
                  title: Text(user.name, style: GoogleFonts.cairo(fontWeight: FontWeight.w600)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.email),
                      Text(
                        user.role == UserRole.teacher ? 'معلم' : 'طالب',
                        style: TextStyle(
                          color: user.role == UserRole.teacher ? Colors.blue : Colors.teal,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  trailing: user.email != 'admin@quiz.com' 
                      ? PopupMenuButton(
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit, size: 20),
                                  SizedBox(width: 8),
                                  Text('تعديل'),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, size: 20, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('حذف', style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ],
                          onSelected: (value) => _handleUserAction(value as String, user),
                        )
                      : Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'مدير',
                            style: GoogleFonts.cairo(
                              color: Colors.red[800],
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildQuizzesTab() {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'جميع الاختبارات (${_quizzes.length})',
            style: GoogleFonts.cairo(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _quizzes.length,
            itemBuilder: (context, index) {
              final quiz = _quizzes[index];
              final teacher = _users.firstWhere((u) => u.id == quiz.teacherId);
              final questionsCount = _questions.where((q) => q.quizId == quiz.id).length;
              
              return Card(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: quiz.isActive ? Colors.green : Colors.orange,
                    child: Icon(
                      quiz.isActive ? Icons.play_arrow : Icons.pause,
                      color: Colors.white,
                    ),
                  ),
                  title: Text(quiz.title, style: GoogleFonts.cairo(fontWeight: FontWeight.w600)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('المعلم: ${teacher.name}'),
                      Text('الأسئلة: $questionsCount | المدة: ${quiz.duration} دقيقة'),
                      Text('${quiz.isActive ? "نشط" : "غير نشط"}'),
                    ],
                  ),
                  trailing: PopupMenuButton(
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'toggle',
                        child: Row(
                          children: [
                            Icon(quiz.isActive ? Icons.pause : Icons.play_arrow, size: 20),
                            SizedBox(width: 8),
                            Text(quiz.isActive ? 'إيقاف' : 'تفعيل'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: Colors.red),
                            SizedBox(width: 8),
                            Text('حذف', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) => _handleQuizAction(value as String, quiz),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionsTab() {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'جميع الأسئلة (${_questions.length})',
            style: GoogleFonts.cairo(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _questions.length,
            itemBuilder: (context, index) {
              final question = _questions[index];
              final quiz = _quizzes.firstWhere((q) => q.id == question.quizId, 
                  orElse: () => Quiz(title: 'اختبار محذوف', description: '', teacherId: 0, duration: 0, createdAt: DateTime.now()));
              
              return Card(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ExpansionTile(
                  leading: CircleAvatar(
                    backgroundColor: _getQuestionTypeColor(question.type),
                    child: Icon(
                      _getQuestionTypeIcon(question.type),
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    question.question,
                    style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text('الاختبار: ${quiz.title} | النوع: ${question.getTypeDisplayName()}'),
                  children: [
                    Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (question.options.isNotEmpty) ...[
                            Text('الخيارات:', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                            ...question.options.asMap().entries.map((entry) {
                              final isCorrect = question.correctAnswers.contains(entry.key);
                              return Text(
                                '${entry.key + 1}. ${entry.value}${isCorrect ? " ✓" : ""}',
                                style: GoogleFonts.cairo(
                                  color: isCorrect ? Colors.green : Colors.black,
                                  fontWeight: isCorrect ? FontWeight.bold : FontWeight.normal,
                                ),
                              );
                            }),
                          ],
                          if (question.correctText != null) ...[
                            Text('الإجابة الصحيحة:', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                            Text(question.correctText!, style: GoogleFonts.cairo(color: Colors.green)),
                          ],
                          if (question.explanation != null) ...[
                            SizedBox(height: 8),
                            Text('الشرح:', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                            Text(question.explanation!, style: GoogleFonts.cairo()),
                          ],
                          SizedBox(height: 8),
                          Text('النقاط: ${question.points}', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildResultsTab() {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'جميع النتائج (${_results.length})',
            style: GoogleFonts.cairo(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _results.length,
            itemBuilder: (context, index) {
              final result = _results[index];
              final student = _users.firstWhere((u) => u.id == result.studentId,
                  orElse: () => User(name: 'طالب محذوف', email: '', password: '', role: UserRole.student, createdAt: DateTime.now()));
              final quiz = _quizzes.firstWhere((q) => q.id == result.quizId,
                  orElse: () => Quiz(title: 'اختبار محذوف', description: '', teacherId: 0, duration: 0, createdAt: DateTime.now()));
              
              return Card(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getGradeColor(result.percentage),
                    child: Text(
                      '${result.percentage.toStringAsFixed(0)}%',
                      style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(student.name, style: GoogleFonts.cairo(fontWeight: FontWeight.w600)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('الاختبار: ${quiz.title}'),
                      Text('النتيجة: ${result.score}/${result.totalQuestions}'),
                      Text('الوقت: ${(result.timeSpent / 60).toStringAsFixed(1)} دقيقة'),
                      Text('التاريخ: ${_formatDate(result.completedAt.toIso8601String())}'),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'إعدادات النظام',
            style: GoogleFonts.cairo(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 24),
          
          _buildSettingCard(
            'تصدير البيانات',
            'تصدير جميع بيانات النظام',
            Icons.download,
            Colors.blue,
            _exportData,
          ),
          
          _buildSettingCard(
            'إعادة تحميل البيانات',
            'إعادة تحميل جميع البيانات من التخزين',
            Icons.refresh,
            Colors.green,
            _loadData,
          ),
          
          _buildSettingCard(
            'إعادة تعيين النظام',
            'مسح جميع البيانات وإعادة التعيين',
            Icons.restore,
            Colors.orange,
            _showResetConfirmation,
          ),
          
          _buildSettingCard(
            'معلومات النظام',
            'عرض معلومات تقنية عن النظام',
            Icons.info,
            Colors.purple,
            _showSystemInfo,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.cairo(fontSize: 24, fontWeight: FontWeight.bold, color: color),
            ),
            Text(
              title,
              style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.cairo(fontWeight: FontWeight.w600)),
          Text(value, style: GoogleFonts.cairo()),
        ],
      ),
    );
  }

  Widget _buildSettingCard(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color,
          child: Icon(icon, color: Colors.white),
        ),
        title: Text(title, style: GoogleFonts.cairo(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: GoogleFonts.cairo()),
        trailing: Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }

  Color _getQuestionTypeColor(QuestionType type) {
    switch (type) {
      case QuestionType.multipleChoice: return Colors.blue;
      case QuestionType.trueFalse: return Colors.green;
      case QuestionType.fillInBlank: return Colors.orange;
      case QuestionType.shortAnswer: return Colors.purple;
    }
  }

  IconData _getQuestionTypeIcon(QuestionType type) {
    switch (type) {
      case QuestionType.multipleChoice: return Icons.radio_button_checked;
      case QuestionType.trueFalse: return Icons.check_box;
      case QuestionType.fillInBlank: return Icons.text_fields;
      case QuestionType.shortAnswer: return Icons.short_text;
    }
  }

  Color _getGradeColor(double percentage) {
    if (percentage >= 90) return Colors.green;
    if (percentage >= 80) return Colors.lightGreen;
    if (percentage >= 70) return Colors.orange;
    if (percentage >= 60) return Colors.deepOrange;
    return Colors.red;
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'غير محدد';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'غير صحيح';
    }
  }

  void _showAddUserDialog() {
    // Implement add user dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('إضافة مستخدم جديد', style: GoogleFonts.cairo()),
        content: Text('سيتم تطوير هذه الميزة قريباً', style: GoogleFonts.cairo()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('موافق', style: GoogleFonts.cairo()),
          ),
        ],
      ),
    );
  }

  void _handleUserAction(String action, User user) {
    if (action == 'delete') {
      _confirmDeleteUser(user);
    }
  }

  void _confirmDeleteUser(User user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('تأكيد الحذف', style: GoogleFonts.cairo()),
        content: Text('هل أنت متأكد من حذف المستخدم "${user.name}"؟', style: GoogleFonts.cairo()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء', style: GoogleFonts.cairo()),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _storage.deleteUser(user.id!);
                _loadData();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('تم حذف المستخدم بنجاح')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('خطأ في حذف المستخدم: $e')),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('حذف', style: GoogleFonts.cairo()),
          ),
        ],
      ),
    );
  }

  void _handleQuizAction(String action, Quiz quiz) async {
    if (action == 'toggle') {
      try {
        final updatedQuiz = quiz.copyWith(isActive: !quiz.isActive);
        await _storage.updateQuiz(updatedQuiz);
        _loadData();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم ${quiz.isActive ? "إيقاف" : "تفعيل"} الاختبار')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في تحديث الاختبار: $e')),
        );
      }
    } else if (action == 'delete') {
      _confirmDeleteQuiz(quiz);
    }
  }

  void _confirmDeleteQuiz(Quiz quiz) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('تأكيد الحذف', style: GoogleFonts.cairo()),
        content: Text('هل أنت متأكد من حذف الاختبار "${quiz.title}"؟', style: GoogleFonts.cairo()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء', style: GoogleFonts.cairo()),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _storage.deleteQuiz(quiz.id!);
                _loadData();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('تم حذف الاختبار بنجاح')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('خطأ في حذف الاختبار: $e')),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('حذف', style: GoogleFonts.cairo()),
          ),
        ],
      ),
    );
  }

  void _exportData() async {
    try {
      final data = await _storage.exportData();
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('تصدير البيانات', style: GoogleFonts.cairo()),
          content: SingleChildScrollView(
            child: Text(
              'تم تصدير البيانات بنجاح:\n\n'
              'المستخدمين: ${data['users'].length}\n'
              'الاختبارات: ${data['quizzes'].length}\n'
              'الأسئلة: ${data['questions'].length}\n'
              'النتائج: ${data['results'].length}\n\n'
              'تاريخ التصدير: ${_formatDate(data['export_date'])}',
              style: GoogleFonts.cairo(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('موافق', style: GoogleFonts.cairo()),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في تصدير البيانات: $e')),
      );
    }
  }

  void _showResetConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('تحذير!', style: GoogleFonts.cairo(color: Colors.red)),
        content: Text(
          'هذا الإجراء سيحذف جميع البيانات في النظام ولا يمكن التراجع عنه.\n\nهل أنت متأكد؟',
          style: GoogleFonts.cairo(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء', style: GoogleFonts.cairo()),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _storage.resetAllData();
              _loadData();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('تم إعادة تعيين النظام بنجاح')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('إعادة تعيين', style: GoogleFonts.cairo()),
          ),
        ],
      ),
    );
  }

  void _showSystemInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('معلومات النظام', style: GoogleFonts.cairo()),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('نظام إدارة الاختبارات الاحترافي', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('الإصدار: 2.0.0', style: GoogleFonts.cairo()),
              Text('المطور: فريق التطوير', style: GoogleFonts.cairo()),
              Text('التاريخ: ${DateTime.now().year}', style: GoogleFonts.cairo()),
              SizedBox(height: 16),
              Text('المميزات:', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
              Text('• دعم أنواع متعددة من الأسئلة', style: GoogleFonts.cairo()),
              Text('• نظام إدارة شامل', style: GoogleFonts.cairo()),
              Text('• تخزين محسن ومستقر', style: GoogleFonts.cairo()),
              Text('• واجهات سهلة الاستخدام', style: GoogleFonts.cairo()),
              Text('• إحصائيات مفصلة', style: GoogleFonts.cairo()),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('موافق', style: GoogleFonts.cairo()),
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
          TextButton(
            onPressed: () {
              Navigator.pop(context); // إغلاق الحوار
              // العودة إلى شاشة تسجيل الدخول وإزالة جميع الصفحات السابقة
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/',
                (route) => false,
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('تسجيل الخروج', style: GoogleFonts.cairo()),
          ),
        ],
      ),
    );
  }
} 