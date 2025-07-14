import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/quiz.dart';
import '../models/quiz_result.dart';
import '../models/user.dart';
import '../services/database_service.dart';

class QuizResultsScreen extends StatefulWidget {
  final Quiz quiz;

  const QuizResultsScreen({super.key, required this.quiz});

  @override
  State<QuizResultsScreen> createState() => _QuizResultsScreenState();
}

class _QuizResultsScreenState extends State<QuizResultsScreen> {
  final DatabaseService _databaseService = DatabaseService();
  List<QuizResult> _results = [];
  List<User> _students = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadResults();
  }

  Future<void> _loadResults() async {
    try {
      final results = await _databaseService.getResultsByQuiz(widget.quiz.id!);
      final allUsers = await _databaseService.getAllUsers();
      final students = allUsers.where((user) => user.role == UserRole.student).toList();

      setState(() {
        _results = results;
        _students = students;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في تحميل النتائج: $e')),
        );
      }
    }
  }

  User? _getStudentById(int studentId) {
    try {
      return _students.firstWhere((student) => student.id == studentId);
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'نتائج: ${widget.quiz.title}',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _results.isEmpty
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
                        'لم يقم أي طالب بحل هذا الاختبار بعد',
                        style: GoogleFonts.cairo(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Statistics Card
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'إحصائيات الاختبار',
                                style: GoogleFonts.cairo(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: _StatCard(
                                      title: 'عدد المشاركين',
                                      value: _results.length.toString(),
                                      icon: Icons.people,
                                      color: Colors.blue,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _StatCard(
                                      title: 'المعدل العام',
                                      value: _results.isEmpty
                                          ? '0%'
                                          : '${(_results.map((r) => r.percentage).reduce((a, b) => a + b) / _results.length).toStringAsFixed(1)}%',
                                      icon: Icons.trending_up,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: _StatCard(
                                      title: 'أعلى درجة',
                                      value: _results.isEmpty
                                          ? '0%'
                                          : '${_results.map((r) => r.percentage).reduce((a, b) => a > b ? a : b).toStringAsFixed(1)}%',
                                      icon: Icons.star,
                                      color: Colors.amber,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _StatCard(
                                      title: 'متوسط الوقت',
                                      value: _results.isEmpty
                                          ? '0 د'
                                          : '${(_results.map((r) => r.timeSpent).reduce((a, b) => a + b) / _results.length / 60).toStringAsFixed(1)} د',
                                      icon: Icons.timer,
                                      color: Colors.orange,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Grade Distribution
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'توزيع الدرجات',
                                style: GoogleFonts.cairo(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildGradeDistribution(),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Student Results
                      Text(
                        'نتائج الطلاب',
                        style: GoogleFonts.cairo(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),

                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _results.length,
                        itemBuilder: (context, index) {
                          final result = _results[index];
                          final student = _getStudentById(result.studentId);
                          final percentage = result.percentage;

                          Color getGradeColor(double percentage) {
                            if (percentage >= 90) return Colors.green;
                            if (percentage >= 80) return Colors.lightGreen;
                            if (percentage >= 70) return Colors.orange;
                            if (percentage >= 60) return Colors.deepOrange;
                            return Colors.red;
                          }

                          String getGradeLetter(double percentage) {
                            if (percentage >= 90) return 'A';
                            if (percentage >= 80) return 'B';
                            if (percentage >= 70) return 'C';
                            if (percentage >= 60) return 'D';
                            return 'F';
                          }

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(16),
                                leading: CircleAvatar(
                                  backgroundColor: getGradeColor(percentage),
                                  child: Text(
                                    getGradeLetter(percentage),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  student?.name ?? 'طالب محذوف',
                                  style: GoogleFonts.cairo(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      student?.email ?? '',
                                      style: GoogleFonts.cairo(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${(result.timeSpent / 60).toStringAsFixed(1)} دقيقة',
                                          style: GoogleFonts.cairo(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${result.completedAt.day}/${result.completedAt.month}/${result.completedAt.year}',
                                          style: GoogleFonts.cairo(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${result.score}/${result.totalQuestions}',
                                      style: GoogleFonts.cairo(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: getGradeColor(percentage),
                                      ),
                                    ),
                                    Text(
                                      '${percentage.toStringAsFixed(1)}%',
                                      style: GoogleFonts.cairo(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildGradeDistribution() {
    final gradeRanges = {
      'A (90-100%)': _results.where((r) => r.percentage >= 90).length,
      'B (80-89%)': _results.where((r) => r.percentage >= 80 && r.percentage < 90).length,
      'C (70-79%)': _results.where((r) => r.percentage >= 70 && r.percentage < 80).length,
      'D (60-69%)': _results.where((r) => r.percentage >= 60 && r.percentage < 70).length,
      'F (<60%)': _results.where((r) => r.percentage < 60).length,
    };

    final colors = [Colors.green, Colors.lightGreen, Colors.orange, Colors.deepOrange, Colors.red];
    
    return Column(
      children: gradeRanges.entries.map((entry) {
        final index = gradeRanges.keys.toList().indexOf(entry.key);
        final percentage = _results.isEmpty ? 0.0 : (entry.value / _results.length) * 100;
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: colors[index],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  entry.key,
                  style: GoogleFonts.cairo(fontSize: 14),
                ),
              ),
              Text(
                '${entry.value} (${percentage.toStringAsFixed(1)}%)',
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      }).toList(),
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
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, size: 24, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.cairo(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: GoogleFonts.cairo(
                fontSize: 10,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
} 