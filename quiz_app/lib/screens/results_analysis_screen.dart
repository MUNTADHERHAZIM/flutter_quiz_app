import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import '../services/sqlite_database_service.dart';
import '../models/user.dart';

class ResultsAnalysisScreen extends StatefulWidget {
  final User currentUser;

  const ResultsAnalysisScreen({super.key, required this.currentUser});

  @override
  State<ResultsAnalysisScreen> createState() => _ResultsAnalysisScreenState();
}

class _ResultsAnalysisScreenState extends State<ResultsAnalysisScreen>
    with TickerProviderStateMixin {
  final SQLiteDatabaseService _dbService = SQLiteDatabaseService();
  late TabController _tabController;

  Map<String, dynamic> _overallStats = {};
  List<Map<String, dynamic>> _subjectStats = [];
  List<Map<String, dynamic>> _recentActivity = [];
  List<Map<String, dynamic>> _topStudents = [];
  List<Map<String, dynamic>> _quizPerformance = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAnalysisData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAnalysisData() async {
    setState(() => _isLoading = true);
    try {
      await Future.wait([
        _loadOverallStats(),
        _loadSubjectStats(),
        _loadRecentActivity(),
        _loadTopStudents(),
        _loadQuizPerformance(),
      ]);
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في تحميل البيانات: $e')),
      );
    }
  }

  Future<void> _loadOverallStats() async {
    final db = await _dbService.database;
    
    final result = await db.rawQuery('''
      SELECT 
        COUNT(DISTINCT qr.student_id) as total_students,
        COUNT(qr.id) as total_attempts,
        AVG(qr.score) as avg_score,
        COUNT(DISTINCT q.id) as total_quizzes,
        COUNT(CASE WHEN qr.score >= 80 THEN 1 END) as excellent_results,
        COUNT(CASE WHEN qr.score >= 60 AND qr.score < 80 THEN 1 END) as good_results,
        COUNT(CASE WHEN qr.score < 60 THEN 1 END) as poor_results
      FROM quiz_results qr
      LEFT JOIN quizzes q ON qr.quiz_id = q.id
      ${widget.currentUser.role.name == 'teacher' ? 'WHERE q.teacher_id = ?' : ''}
    ''', widget.currentUser.role.name == 'teacher' ? [widget.currentUser.id] : []);

    if (result.isNotEmpty) {
      _overallStats = Map<String, dynamic>.from(result.first);
    }
  }

  Future<void> _loadSubjectStats() async {
    final db = await _dbService.database;
    
    _subjectStats = await db.rawQuery('''
      SELECT 
        s.name as subject_name,
        s.id as subject_id,
        COUNT(qr.id) as total_attempts,
        AVG(qr.score) as avg_score,
        COUNT(DISTINCT qr.student_id) as unique_students,
        COUNT(DISTINCT q.id) as quiz_count
      FROM subjects s
      LEFT JOIN quizzes q ON s.id = q.subject_id
      LEFT JOIN quiz_results qr ON q.id = qr.quiz_id
      ${widget.currentUser.role.name == 'teacher' ? 'WHERE q.teacher_id = ?' : ''}
      GROUP BY s.id, s.name
      HAVING quiz_count > 0
      ORDER BY avg_score DESC
    ''', widget.currentUser.role.name == 'teacher' ? [widget.currentUser.id] : []);
  }

  Future<void> _loadRecentActivity() async {
    final db = await _dbService.database;
    
    _recentActivity = await db.rawQuery('''
      SELECT 
        qr.*,
        q.title as quiz_title,
        s.name as subject_name,
        u.name as student_name
      FROM quiz_results qr
      LEFT JOIN quizzes q ON qr.quiz_id = q.id
      LEFT JOIN subjects s ON q.subject_id = s.id
      LEFT JOIN users u ON qr.student_id = u.id
      ${widget.currentUser.role.name == 'teacher' ? 'WHERE q.teacher_id = ?' : ''}
      ORDER BY qr.completed_at DESC
      LIMIT 20
    ''', widget.currentUser.role.name == 'teacher' ? [widget.currentUser.id] : []);
  }

  Future<void> _loadTopStudents() async {
    final db = await _dbService.database;
    
    _topStudents = await db.rawQuery('''
      SELECT 
        u.name as student_name,
        u.id as student_id,
        COUNT(qr.id) as total_attempts,
        AVG(qr.score) as avg_score,
        MAX(qr.score) as best_score,
        COUNT(CASE WHEN qr.score >= 80 THEN 1 END) as excellent_count
      FROM users u
      INNER JOIN quiz_results qr ON u.id = qr.student_id
      ${widget.currentUser.role.name == 'teacher' 
          ? 'INNER JOIN quizzes q ON qr.quiz_id = q.id WHERE q.teacher_id = ? AND' 
          : 'WHERE'} u.role = 'student'
      GROUP BY u.id, u.name
      HAVING total_attempts >= 3
      ORDER BY avg_score DESC, excellent_count DESC
      LIMIT 10
    ''', widget.currentUser.role.name == 'teacher' ? [widget.currentUser.id] : []);
  }

  Future<void> _loadQuizPerformance() async {
    final db = await _dbService.database;
    
    _quizPerformance = await db.rawQuery('''
      SELECT 
        q.title as quiz_title,
        q.id as quiz_id,
        s.name as subject_name,
        COUNT(qr.id) as total_attempts,
        AVG(qr.score) as avg_score,
        MIN(qr.score) as min_score,
        MAX(qr.score) as max_score,
        COUNT(CASE WHEN qr.score >= 80 THEN 1 END) as excellent_count,
        AVG(qr.duration_seconds) as avg_duration
      FROM quizzes q
      LEFT JOIN quiz_results qr ON q.id = qr.quiz_id
      LEFT JOIN subjects s ON q.subject_id = s.id
      ${widget.currentUser.role.name == 'teacher' ? 'WHERE q.teacher_id = ?' : ''}
      GROUP BY q.id, q.title, s.name
      HAVING total_attempts > 0
      ORDER BY total_attempts DESC
    ''', widget.currentUser.role.name == 'teacher' ? [widget.currentUser.id] : []);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildHeader(),
                _buildTabs(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildOverviewTab(),
                      _buildSubjectsTab(),
                      _buildStudentsTab(),
                      _buildActivityTab(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.teal.shade600, Colors.teal.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.analytics, color: Colors.white, size: 32),
                const SizedBox(width: 12),
                Text(
                  'تحليل النتائج',
                  style: GoogleFonts.cairo(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: _loadAnalysisData,
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  tooltip: 'تحديث',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              widget.currentUser.role.name == 'admin'
                  ? 'إحصائيات شاملة للنظام'
                  : 'إحصائيات اختباراتك',
              style: GoogleFonts.cairo(
                color: Colors.white.withOpacity(0.9),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.teal,
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey[600],
        labelStyle: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 12),
        tabs: const [
          Tab(text: 'نظرة عامة'),
          Tab(text: 'المواد'),
          Tab(text: 'الطلاب'),
          Tab(text: 'النشاط'),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    final totalAttempts = _overallStats['total_attempts'] ?? 0;
    final avgScore = (_overallStats['avg_score'] ?? 0.0).round();
    final excellentResults = _overallStats['excellent_results'] ?? 0;
    final goodResults = _overallStats['good_results'] ?? 0;
    final poorResults = _overallStats['poor_results'] ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Key metrics cards
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'إجمالي المحاولات',
                  '$totalAttempts',
                  Icons.assignment_turned_in,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  'المتوسط العام',
                  '$avgScore%',
                  Icons.trending_up,
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'إجمالي الطلاب',
                  '${_overallStats['total_students'] ?? 0}',
                  Icons.people,
                  Colors.purple,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  'إجمالي الاختبارات',
                  '${_overallStats['total_quizzes'] ?? 0}',
                  Icons.quiz,
                  Colors.orange,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Performance distribution chart
          Text(
            'توزيع الأداء',
            style: GoogleFonts.cairo(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildPerformanceChart(excellentResults, goodResults, poorResults),
          
          const SizedBox(height: 24),
          
          // Top performing quizzes
          Text(
            'أفضل الاختبارات أداءً',
            style: GoogleFonts.cairo(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ..._quizPerformance.take(5).map((quiz) => _buildQuizPerformanceCard(quiz)),
        ],
      ),
    );
  }

  Widget _buildSubjectsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'أداء المواد الدراسية',
            style: GoogleFonts.cairo(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (_subjectStats.isEmpty)
            _buildEmptyState('لا توجد بيانات للمواد')
          else
            ..._subjectStats.map((subject) => _buildSubjectCard(subject)),
        ],
      ),
    );
  }

  Widget _buildStudentsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'أفضل الطلاب أداءً',
            style: GoogleFonts.cairo(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (_topStudents.isEmpty)
            _buildEmptyState('لا توجد بيانات للطلاب')
          else
            ..._topStudents.asMap().entries.map((entry) {
              final index = entry.key;
              final student = entry.value;
              return _buildStudentRankCard(student, index + 1);
            }),
        ],
      ),
    );
  }

  Widget _buildActivityTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'النشاط الأخير',
            style: GoogleFonts.cairo(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (_recentActivity.isEmpty)
            _buildEmptyState('لا يوجد نشاط حديث')
          else
            ..._recentActivity.map((activity) => _buildActivityCard(activity)),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
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
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceChart(int excellent, int good, int poor) {
    final total = excellent + good + poor;
    if (total == 0) return _buildEmptyState('لا توجد بيانات للعرض');

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: CustomPaint(
                    size: const Size(150, 150),
                    painter: DonutChartPainter(
                      excellent: excellent,
                      good: good,
                      poor: poor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem('ممتاز (80%+)', Colors.green, excellent, total),
              const SizedBox(height: 8),
              _buildLegendItem('جيد (60-79%)', Colors.orange, good, total),
              const SizedBox(height: 8),
              _buildLegendItem('ضعيف (<60%)', Colors.red, poor, total),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, int count, int total) {
    final percentage = total > 0 ? (count / total * 100).round() : 0;
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.cairo(fontSize: 12),
            ),
            Text(
              '$count ($percentage%)',
              style: GoogleFonts.cairo(
                fontSize: 11,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuizPerformanceCard(Map<String, dynamic> quiz) {
    final avgScore = (quiz['avg_score'] ?? 0.0).round();
    final totalAttempts = quiz['total_attempts'] ?? 0;
    
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  quiz['quiz_title'] ?? 'اختبار غير محدد',
                  style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                ),
                Text(
                  quiz['subject_name'] ?? 'مادة غير محددة',
                  style: GoogleFonts.cairo(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                Text(
                  'المحاولات: $totalAttempts',
                  style: GoogleFonts.cairo(
                    color: Colors.grey[500],
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getScoreColor(avgScore).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$avgScore%',
              style: GoogleFonts.cairo(
                fontWeight: FontWeight.bold,
                color: _getScoreColor(avgScore),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectCard(Map<String, dynamic> subject) {
    final avgScore = (subject['avg_score'] ?? 0.0).round();
    final totalAttempts = subject['total_attempts'] ?? 0;
    final uniqueStudents = subject['unique_students'] ?? 0;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  subject['subject_name'] ?? 'مادة غير محددة',
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getScoreColor(avgScore),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$avgScore%',
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildSubjectStat('المحاولات', '$totalAttempts', Icons.assignment),
              const SizedBox(width: 16),
              _buildSubjectStat('الطلاب', '$uniqueStudents', Icons.people),
              const SizedBox(width: 16),
              _buildSubjectStat('الاختبارات', '${subject['quiz_count'] ?? 0}', Icons.quiz),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectStat(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          '$label: $value',
          style: GoogleFonts.cairo(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildStudentRankCard(Map<String, dynamic> student, int rank) {
    final avgScore = (student['avg_score'] ?? 0.0).round();
    final totalAttempts = student['total_attempts'] ?? 0;
    final excellentCount = student['excellent_count'] ?? 0;
    
    Color rankColor;
    if (rank == 1) rankColor = Colors.amber;
    else if (rank == 2) rankColor = Colors.grey;
    else if (rank == 3) rankColor = Colors.brown;
    else rankColor = Colors.blue;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: rankColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: rankColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$rank',
                style: GoogleFonts.cairo(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: rankColor,
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
                  student['student_name'] ?? 'طالب غير محدد',
                  style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                ),
                Text(
                  'المحاولات: $totalAttempts | الممتازة: $excellentCount',
                  style: GoogleFonts.cairo(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getScoreColor(avgScore),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$avgScore%',
              style: GoogleFonts.cairo(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard(Map<String, dynamic> activity) {
    final score = activity['score'] ?? 0;
    
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
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _getScoreColor(score).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                _getScoreIcon(score),
                color: _getScoreColor(score),
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity['student_name'] ?? 'طالب غير محدد',
                  style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                ),
                Text(
                  activity['quiz_title'] ?? 'اختبار غير محدد',
                  style: GoogleFonts.cairo(fontSize: 12),
                ),
                Text(
                  '${activity['subject_name'] ?? 'مادة غير محددة'} • ${_formatDate(activity['completed_at'])}',
                  style: GoogleFonts.cairo(
                    color: Colors.grey[600],
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '$score%',
            style: GoogleFonts.cairo(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _getScoreColor(score),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(Icons.analytics_outlined, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            message,
            style: GoogleFonts.cairo(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
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
}

class DonutChartPainter extends CustomPainter {
  final int excellent;
  final int good;
  final int poor;

  DonutChartPainter({required this.excellent, required this.good, required this.poor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 10;
    final total = excellent + good + poor;
    
    if (total == 0) return;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20;

    double startAngle = -math.pi / 2;
    
    // Excellent (Green)
    final excellentAngle = (excellent / total) * 2 * math.pi;
    paint.color = Colors.green;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      excellentAngle,
      false,
      paint,
    );
    startAngle += excellentAngle;

    // Good (Orange)
    final goodAngle = (good / total) * 2 * math.pi;
    paint.color = Colors.orange;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      goodAngle,
      false,
      paint,
    );
    startAngle += goodAngle;

    // Poor (Red)
    final poorAngle = (poor / total) * 2 * math.pi;
    paint.color = Colors.red;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      poorAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
} 