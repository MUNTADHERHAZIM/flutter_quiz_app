import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/sqlite_database_service.dart';
import '../models/user.dart';

class StudentProfileScreen extends StatefulWidget {
  final User student;

  const StudentProfileScreen({super.key, required this.student});

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  final SQLiteDatabaseService _dbService = SQLiteDatabaseService();
  Map<String, dynamic> _studentStats = {};
  List<Map<String, dynamic>> _recentResults = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStudentData();
  }

  Future<void> _loadStudentData() async {
    setState(() => _isLoading = true);
    try {
      final db = await _dbService.database;

      // Load student statistics
      final statsResult = await db.rawQuery('''
        SELECT 
          COUNT(*) as total_quizzes,
          AVG(score) as avg_score,
          MAX(score) as best_score,
          MIN(score) as worst_score,
          COUNT(CASE WHEN score >= 80 THEN 1 END) as excellent_count,
          COUNT(CASE WHEN score >= 60 AND score < 80 THEN 1 END) as good_count,
          COUNT(CASE WHEN score < 60 THEN 1 END) as poor_count
        FROM quiz_results 
        WHERE student_id = ?
      ''', [widget.student.id]);

      // Load recent results
      final results = await db.rawQuery('''
        SELECT qr.*, q.title as quiz_title, s.name as subject_name
        FROM quiz_results qr
        LEFT JOIN quizzes q ON qr.quiz_id = q.id
        LEFT JOIN subjects s ON q.subject_id = s.id
        WHERE qr.student_id = ?
        ORDER BY qr.completed_at DESC
        LIMIT 10
      ''', [widget.student.id]);

      setState(() {
        _studentStats = statsResult.isNotEmpty ? statsResult.first : {};
        _recentResults = results;
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
        title: Text('ملفي الشخصي', style: GoogleFonts.cairo()),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProfileCard(),
                  const SizedBox(height: 20),
                  _buildStatsCards(),
                  const SizedBox(height: 20),
                  _buildPerformanceChart(),
                  const SizedBox(height: 20),
                  _buildRecentResults(),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.green.shade100,
              child: Icon(
                Icons.person,
                size: 40,
                color: Colors.green.shade700,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.student.name,
                    style: GoogleFonts.cairo(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    widget.student.email,
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'طالب',
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCards() {
    final totalQuizzes = _studentStats['total_quizzes'] ?? 0;
    final avgScore = (_studentStats['avg_score'] ?? 0.0).round();
    final bestScore = _studentStats['best_score'] ?? 0;
    final excellentCount = _studentStats['excellent_count'] ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'إحصائياتي',
          style: GoogleFonts.cairo(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'الاختبارات المكتملة',
                '$totalQuizzes',
                Icons.assignment_turned_in,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
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
              child: _buildStatCard(
                'أفضل درجة',
                '$bestScore%',
                Icons.star,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'درجات ممتازة',
                '$excellentCount',
                Icons.emoji_events,
                Colors.purple,
              ),
            ),
          ],
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
              fontSize: 20,
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

  Widget _buildPerformanceChart() {
    final excellentCount = _studentStats['excellent_count'] ?? 0;
    final goodCount = _studentStats['good_count'] ?? 0;
    final poorCount = _studentStats['poor_count'] ?? 0;
    final total = excellentCount + goodCount + poorCount;

    if (total == 0) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'توزيع الأداء',
          style: GoogleFonts.cairo(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildPerformanceBar('ممتاز (80%+)', excellentCount, total, Colors.green),
                const SizedBox(height: 8),
                _buildPerformanceBar('جيد (60-79%)', goodCount, total, Colors.orange),
                const SizedBox(height: 8),
                _buildPerformanceBar('ضعيف (<60%)', poorCount, total, Colors.red),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPerformanceBar(String label, int count, int total, Color color) {
    final percentage = total > 0 ? count / total : 0.0;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: GoogleFonts.cairo(fontSize: 14)),
            Text('$count', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: percentage,
          backgroundColor: color.withOpacity(0.2),
          valueColor: AlwaysStoppedAnimation(color),
        ),
      ],
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
        if (_recentResults.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.assessment, size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    Text(
                      'لا توجد نتائج بعد',
                      style: GoogleFonts.cairo(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      'ابدأ أول اختبار لك!',
                      style: GoogleFonts.cairo(color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          ..._recentResults.map((result) => _buildResultCard(result)),
      ],
    );
  }

  Widget _buildResultCard(Map<String, dynamic> result) {
    final score = result['score'] ?? 0;
    final scoreColor = _getScoreColor(score);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
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