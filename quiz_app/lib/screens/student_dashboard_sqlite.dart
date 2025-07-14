import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/sqlite_database_service.dart';
import '../models/user.dart';
import 'quiz_taking_sqlite.dart';
import 'student_profile_screen.dart';

class StudentDashboardSQLite extends StatefulWidget {
  final User student;

  const StudentDashboardSQLite({super.key, required this.student});

  @override
  State<StudentDashboardSQLite> createState() => _StudentDashboardSQLiteState();
}

class _StudentDashboardSQLiteState extends State<StudentDashboardSQLite> {
  final SQLiteDatabaseService _dbService = SQLiteDatabaseService();
  
  List<Map<String, dynamic>> _availableQuizzes = [];
  List<Map<String, dynamic>> _myResults = [];
  Map<String, int> _stats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final db = await _dbService.database;

      // Get available quizzes
      final quizzes = await db.rawQuery('''
        SELECT q.*, s.name as subject_name, u.name as teacher_name,
               COUNT(DISTINCT qr.id) as total_attempts,
               AVG(qr.score) as avg_score,
               (SELECT COUNT(*) FROM quiz_results WHERE quiz_id = q.id AND student_id = ?) as student_attempts
        FROM quizzes q
        LEFT JOIN subjects s ON q.subject_id = s.id
        LEFT JOIN users u ON q.teacher_id = u.id
        LEFT JOIN quiz_results qr ON q.id = qr.quiz_id
        WHERE q.is_active = 1
        GROUP BY q.id
        ORDER BY q.created_at DESC
      ''', [widget.student.id]);

      // Get student's results
      final results = await db.rawQuery('''
        SELECT qr.*, q.title as quiz_title, s.name as subject_name
        FROM quiz_results qr
        LEFT JOIN quizzes q ON qr.quiz_id = q.id
        LEFT JOIN subjects s ON q.subject_id = s.id
        WHERE qr.student_id = ?
        ORDER BY qr.completed_at DESC
        LIMIT 10
      ''', [widget.student.id]);

      // Get statistics
      final statsResult = await db.rawQuery('''
        SELECT 
          COUNT(*) as total_completed,
          AVG(score) as avg_score,
          MAX(score) as best_score,
          COUNT(CASE WHEN score >= 80 THEN 1 END) as excellent_count
        FROM quiz_results 
        WHERE student_id = ?
      ''', [widget.student.id]);

      final stats = statsResult.isNotEmpty ? statsResult.first : {};

      setState(() {
        _availableQuizzes = quizzes;
        _myResults = results;
        _stats = {
          'total_completed': stats['total_completed'] ?? 0,
          'avg_score': (stats['avg_score'] ?? 0.0).round(),
          'best_score': stats['best_score'] ?? 0,
          'excellent_count': stats['excellent_count'] ?? 0,
        };
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في تحميل البيانات: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('لوحة تحكم الطالب', style: GoogleFonts.cairo()),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => StudentProfileScreen(student: widget.student),
                ),
              );
            },
            tooltip: 'الملف الشخصي',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(),
            tooltip: 'تسجيل الخروج',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildWelcomeCard(),
                    const SizedBox(height: 20),
                    _buildStatsCards(),
                    const SizedBox(height: 20),
                    _buildAvailableQuizzes(),
                    const SizedBox(height: 20),
                    _buildRecentResults(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade600, Colors.blue.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.white.withOpacity(0.2),
                child: Icon(
                  Icons.person,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'مرحباً ${widget.student.name}',
                      style: GoogleFonts.cairo(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'جاهز لاختبار جديد؟',
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.trending_up, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                'متوسط درجاتك: ${_stats['avg_score']}%',
                style: GoogleFonts.cairo(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'الاختبارات المكتملة',
            '${_stats['total_completed']}',
            Icons.assignment_turned_in,
            Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'أفضل درجة',
            '${_stats['best_score']}%',
            Icons.star,
            Colors.orange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'درجات ممتازة',
            '${_stats['excellent_count']}',
            Icons.emoji_events,
            Colors.purple,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.cairo(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: GoogleFonts.cairo(
              fontSize: 11,
              color: color,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildAvailableQuizzes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'الاختبارات المتاحة',
          style: GoogleFonts.cairo(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        if (_availableQuizzes.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(Icons.assignment, size: 48, color: Colors.grey.shade400),
                const SizedBox(height: 12),
                Text(
                  'لا توجد اختبارات متاحة حالياً',
                  style: GoogleFonts.cairo(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          )
        else
          ...List.generate(_availableQuizzes.length, (index) {
            final quiz = _availableQuizzes[index];
            return _buildQuizCard(quiz);
          }),
      ],
    );
  }

  Widget _buildQuizCard(Map<String, dynamic> quiz) {
    final hasAttempted = (quiz['student_attempts'] ?? 0) > 0;
    final avgScore = quiz['avg_score'] != null 
        ? (quiz['avg_score'] as double).round() 
        : 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: hasAttempted ? null : () => _startQuiz(quiz),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            quiz['title'],
                            style: GoogleFonts.cairo(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (quiz['description'] != null && 
                              quiz['description'].toString().isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                quiz['description'],
                                style: GoogleFonts.cairo(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (hasAttempted)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'مكتمل',
                          style: GoogleFonts.cairo(
                            fontSize: 10,
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildInfoChip(
                      quiz['subject_name'] ?? 'غير محدد',
                      Icons.subject,
                      Colors.blue,
                    ),
                    const SizedBox(width: 8),
                    _buildInfoChip(
                      '${quiz['duration']} دقيقة',
                      Icons.timer,
                      Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    _buildInfoChip(
                      quiz['teacher_name'] ?? 'غير محدد',
                      Icons.person,
                      Colors.purple,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.people, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      'المشاركين: ${quiz['total_attempts'] ?? 0}',
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    if (avgScore > 0) ...[
                      const SizedBox(width: 16),
                      Icon(Icons.analytics, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        'المتوسط: $avgScore%',
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                    const Spacer(),
                    if (!hasAttempted)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'ابدأ الاختبار',
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.cairo(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentResults() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'النتائج الأخيرة',
          style: GoogleFonts.cairo(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        if (_myResults.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(Icons.assessment, size: 48, color: Colors.grey.shade400),
                const SizedBox(height: 12),
                Text(
                  'لا توجد نتائج بعد',
                  style: GoogleFonts.cairo(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'ابدأ أول اختبار لك لترى النتائج هنا',
                  style: GoogleFonts.cairo(
                    color: Colors.grey.shade500,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          )
        else
          ...List.generate(_myResults.length, (index) {
            final result = _myResults[index];
            return _buildResultCard(result);
          }),
      ],
    );
  }

  Widget _buildResultCard(Map<String, dynamic> result) {
    final score = result['score'] ?? 0;
    final scoreColor = _getScoreColor(score);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: scoreColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$score%',
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: scoreColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result['quiz_title'] ?? 'اختبار غير محدد',
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  result['subject_name'] ?? 'مادة غير محددة',
                  style: GoogleFonts.cairo(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                Text(
                  _formatDate(result['completed_at']),
                  style: GoogleFonts.cairo(
                    color: Colors.grey[500],
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            _getScoreIcon(score),
            color: scoreColor,
            size: 24,
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  IconData _getScoreIcon(int score) {
    if (score >= 80) return Icons.emoji_events;
    if (score >= 60) return Icons.thumb_up;
    return Icons.sentiment_dissatisfied;
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'غير محدد';
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        return 'اليوم';
      } else if (difference.inDays == 1) {
        return 'أمس';
      } else if (difference.inDays < 7) {
        return 'منذ ${difference.inDays} أيام';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return 'غير محدد';
    }
  }

  void _startQuiz(Map<String, dynamic> quiz) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('بدء الاختبار', style: GoogleFonts.cairo()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'أنت على وشك بدء اختبار: ${quiz['title']}',
              style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('المدة المتاحة: ${quiz['duration']} دقيقة', style: GoogleFonts.cairo()),
            Text('المادة: ${quiz['subject_name']}', style: GoogleFonts.cairo()),
            const SizedBox(height: 8),
            Text(
              'تأكد من اتصال الإنترنت وأنك في مكان هادئ.',
              style: GoogleFonts.cairo(color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء', style: GoogleFonts.cairo()),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => QuizTakingSQLite(
                    quiz: quiz,
                    student: widget.student,
                  ),
                ),
              ).then((_) => _loadData()); // Refresh data after quiz
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: Text('ابدأ الآن', style: GoogleFonts.cairo()),
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
        content: Text('هل تريد تسجيل الخروج؟', style: GoogleFonts.cairo()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء', style: GoogleFonts.cairo()),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/',
                (route) => false,
              );
            },
            child: Text('خروج', style: GoogleFonts.cairo()),
          ),
        ],
      ),
    );
  }
} 