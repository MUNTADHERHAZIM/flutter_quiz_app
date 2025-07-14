import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/sqlite_database_service.dart';
import '../models/user.dart';

class TeacherQuizResults extends StatefulWidget {
  final User teacher;

  const TeacherQuizResults({super.key, required this.teacher});

  @override
  State<TeacherQuizResults> createState() => _TeacherQuizResultsState();
}

class _TeacherQuizResultsState extends State<TeacherQuizResults> {
  final SQLiteDatabaseService _dbService = SQLiteDatabaseService();
  List<Map<String, dynamic>> _quizResults = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadResults();
  }

  Future<void> _loadResults() async {
    setState(() => _isLoading = true);
    try {
      final db = await _dbService.database;
      final results = await db.rawQuery('''
        SELECT qr.*, q.title as quiz_title, u.name as student_name, s.name as subject_name
        FROM quiz_results qr
        LEFT JOIN quizzes q ON qr.quiz_id = q.id
        LEFT JOIN users u ON qr.student_id = u.id
        LEFT JOIN subjects s ON q.subject_id = s.id
        WHERE q.teacher_id = ?
        ORDER BY qr.completed_at DESC
      ''', [widget.teacher.id]);

      setState(() {
        _quizResults = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في تحميل النتائج: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('نتائج اختباراتي', style: GoogleFonts.cairo()),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _quizResults.isEmpty
              ? _buildEmptyState()
              : _buildResultsList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assessment, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'لا توجد نتائج بعد',
            style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(
            'ستظهر النتائج هنا بعد أن يقوم الطلاب بحل الاختبارات',
            style: GoogleFonts.cairo(color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _quizResults.length,
      itemBuilder: (context, index) {
        final result = _quizResults[index];
        return _buildResultCard(result);
      },
    );
  }

  Widget _buildResultCard(Map<String, dynamic> result) {
    final score = result['score'] ?? 0;
    final scoreColor = _getScoreColor(score);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
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
                        result['quiz_title'] ?? 'اختبار غير محدد',
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        result['student_name'] ?? 'طالب غير محدد',
                        style: GoogleFonts.cairo(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        result['subject_name'] ?? 'مادة غير محددة',
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: scoreColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$score%',
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: scoreColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.check_circle, size: 16, color: Colors.green),
                const SizedBox(width: 4),
                Text(
                  'صحيحة: ${result['correct_answers'] ?? 0}',
                  style: GoogleFonts.cairo(fontSize: 12),
                ),
                const SizedBox(width: 16),
                Icon(Icons.quiz, size: 16, color: Colors.blue),
                const SizedBox(width: 4),
                Text(
                  'المجموع: ${result['total_questions'] ?? 0}',
                  style: GoogleFonts.cairo(fontSize: 12),
                ),
                const SizedBox(width: 16),
                Icon(Icons.timer, size: 16, color: Colors.orange),
                const SizedBox(width: 4),
                Text(
                  'الوقت: ${_formatDuration(result['duration_seconds'] ?? 0)}',
                  style: GoogleFonts.cairo(fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'تاريخ الإكمال: ${_formatDate(result['completed_at'])}',
              style: GoogleFonts.cairo(
                fontSize: 11,
                color: Colors.grey.shade500,
              ),
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

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes}د ${remainingSeconds}ث';
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'غير محدد';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'غير محدد';
    }
  }
} 