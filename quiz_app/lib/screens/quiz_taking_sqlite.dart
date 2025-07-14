import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'dart:convert';
import '../services/sqlite_database_service.dart';
import '../models/user.dart';

class QuizTakingSQLite extends StatefulWidget {
  final Map<String, dynamic> quiz;
  final User student;

  const QuizTakingSQLite({
    super.key,
    required this.quiz,
    required this.student,
  });

  @override
  State<QuizTakingSQLite> createState() => _QuizTakingSQLiteState();
}

class _QuizTakingSQLiteState extends State<QuizTakingSQLite> {
  final SQLiteDatabaseService _dbService = SQLiteDatabaseService();
  final PageController _pageController = PageController();

  List<Map<String, dynamic>> _questions = [];
  List<dynamic> _selectedAnswers = [];
  int _currentQuestionIndex = 0;
  late int _timeLeft; // in seconds
  Timer? _timer;
  bool _isLoading = true;
  bool _isSubmitting = false;
  late DateTime _startTime;
  late DateTime _endTime;

  @override
  void initState() {
    super.initState();
    _timeLeft = (widget.quiz['duration'] as int) * 60; // Convert minutes to seconds
    _startTime = DateTime.now();
    _endTime = _startTime.add(Duration(seconds: _timeLeft));
    _loadQuestions();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadQuestions() async {
    try {
      final db = await _dbService.database;
      
      // Get questions for this quiz from question_bank
      final questions = await db.rawQuery('''
        SELECT qb.*, s.name as subject_name
        FROM question_bank qb
        LEFT JOIN subjects s ON qb.subject_id = s.id
        WHERE qb.subject_id = ?
        ORDER BY RANDOM()
        LIMIT 10
      ''', [widget.quiz['subject_id']]);

      setState(() {
        _questions = questions;
        _selectedAnswers = List.filled(questions.length, null);
        _isLoading = false;
      });
      
      _startTimer();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في تحميل الأسئلة: $e')),
        );
        Navigator.pop(context);
      }
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        setState(() => _timeLeft--);
      } else {
        _submitQuiz();
      }
    });
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Color _getTimerColor() {
    final totalTime = (widget.quiz['duration'] as int) * 60;
    final percentage = _timeLeft / totalTime;
    
    if (percentage > 0.5) return Colors.green;
    if (percentage > 0.25) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'جاري تحميل الاختبار...',
                style: GoogleFonts.cairo(fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text('خطأ', style: GoogleFonts.cairo()),
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'لا توجد أسئلة متاحة لهذا الاختبار',
                style: GoogleFonts.cairo(fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: Text('العودة', style: GoogleFonts.cairo()),
              ),
            ],
          ),
        ),
      );
    }

    return WillPopScope(
      onWillPop: () async {
        return await _showExitConfirmation();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.quiz['title'],
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
          elevation: 0,
          actions: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: _getTimerColor(),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.timer, size: 18, color: Colors.white),
                  const SizedBox(width: 4),
                  Text(
                    _formatTime(_timeLeft),
                    style: GoogleFonts.cairo(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            _buildProgressBar(),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentQuestionIndex = index);
                },
                itemCount: _questions.length,
                itemBuilder: (context, index) {
                  return _buildQuestionPage(_questions[index], index);
                },
              ),
            ),
            _buildNavigationBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.indigo.shade50,
        border: Border(
          bottom: BorderSide(color: Colors.indigo.shade100),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'السؤال ${_currentQuestionIndex + 1} من ${_questions.length}',
                style: GoogleFonts.cairo(
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo.shade700,
                ),
              ),
              Text(
                '${_getAnsweredCount()} إجابة',
                style: GoogleFonts.cairo(
                  color: Colors.indigo.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: (_currentQuestionIndex + 1) / _questions.length,
            backgroundColor: Colors.indigo.shade100,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.indigo.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionPage(Map<String, dynamic> question, int index) {
    final questionType = question['question_type'] as String;
    final options = question['options'] != null 
        ? jsonDecode(question['options']) as List<dynamic>
        : <String>[];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.indigo.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.indigo.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.indigo,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getQuestionTypeLabel(questionType),
                        style: GoogleFonts.cairo(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getDifficultyColor(question['difficulty']),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        question['difficulty'] ?? 'متوسط',
                        style: GoogleFonts.cairo(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  question['question_text'],
                  style: GoogleFonts.cairo(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo.shade800,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Answer options
          _buildAnswerOptions(questionType, options, index),
        ],
      ),
    );
  }

  Widget _buildAnswerOptions(String questionType, List<dynamic> options, int questionIndex) {
    switch (questionType) {
      case 'multiple_choice':
        return _buildMultipleChoiceOptions(options, questionIndex);
      case 'true_false':
        return _buildTrueFalseOptions(questionIndex);
      case 'short_answer':
        return _buildShortAnswerField(questionIndex);
      case 'fill_blank':
        return _buildFillBlankField(questionIndex);
      default:
        return _buildMultipleChoiceOptions(options, questionIndex);
    }
  }

  Widget _buildMultipleChoiceOptions(List<dynamic> options, int questionIndex) {
    return Column(
      children: List.generate(options.length, (optionIndex) {
        final isSelected = _selectedAnswers[questionIndex] == optionIndex;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () {
              setState(() {
                _selectedAnswers[questionIndex] = optionIndex;
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected ? Colors.indigo.shade100 : Colors.white,
                border: Border.all(
                  color: isSelected ? Colors.indigo : Colors.grey.shade300,
                  width: isSelected ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  if (isSelected)
                    BoxShadow(
                      color: Colors.indigo.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected ? Colors.indigo : Colors.transparent,
                      border: Border.all(
                        color: isSelected ? Colors.indigo : Colors.grey.shade400,
                        width: 2,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white, size: 16)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${String.fromCharCode(65 + optionIndex)}. ${options[optionIndex]}',
                      style: GoogleFonts.cairo(
                        fontSize: 16,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? Colors.indigo.shade800 : Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildTrueFalseOptions(int questionIndex) {
    return Column(
      children: [
        _buildTrueFalseOption('صحيح', true, questionIndex),
        const SizedBox(height: 12),
        _buildTrueFalseOption('خطأ', false, questionIndex),
      ],
    );
  }

  Widget _buildTrueFalseOption(String label, bool value, int questionIndex) {
    final isSelected = _selectedAnswers[questionIndex] == (value ? 1 : 0);
    
    return InkWell(
      onTap: () {
        setState(() {
          _selectedAnswers[questionIndex] = value ? 1 : 0;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.indigo.shade100 : Colors.white,
          border: Border.all(
            color: isSelected ? Colors.indigo : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: Colors.indigo.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? Colors.indigo : Colors.transparent,
                border: Border.all(
                  color: isSelected ? Colors.indigo : Colors.grey.shade400,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : null,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: GoogleFonts.cairo(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.indigo.shade800 : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShortAnswerField(int questionIndex) {
    return TextField(
      onChanged: (value) {
        setState(() {
          _selectedAnswers[questionIndex] = value;
        });
      },
      decoration: InputDecoration(
        hintText: 'اكتب إجابتك هنا...',
        hintStyle: GoogleFonts.cairo(color: Colors.grey),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.indigo, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      style: GoogleFonts.cairo(fontSize: 16),
      maxLines: 3,
    );
  }

  Widget _buildFillBlankField(int questionIndex) {
    return TextField(
      onChanged: (value) {
        setState(() {
          _selectedAnswers[questionIndex] = value;
        });
      },
      decoration: InputDecoration(
        hintText: 'املأ الفراغ...',
        hintStyle: GoogleFonts.cairo(color: Colors.grey),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.indigo, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      style: GoogleFonts.cairo(fontSize: 16),
    );
  }

  Widget _buildNavigationBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.shade300),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Previous button
          if (_currentQuestionIndex > 0)
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  _pageController.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                icon: const Icon(Icons.arrow_back),
                label: Text('السابق', style: GoogleFonts.cairo()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          
          if (_currentQuestionIndex > 0) const SizedBox(width: 12),
          
          // Next/Submit button
          Expanded(
            flex: _currentQuestionIndex == 0 ? 2 : 1,
            child: ElevatedButton.icon(
              onPressed: _isSubmitting ? null : () {
                if (_currentQuestionIndex < _questions.length - 1) {
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                } else {
                  _showSubmitConfirmation();
                }
              },
              icon: Icon(
                _currentQuestionIndex < _questions.length - 1
                    ? Icons.arrow_forward
                    : Icons.send,
              ),
              label: Text(
                _currentQuestionIndex < _questions.length - 1 ? 'التالي' : 'إرسال',
                style: GoogleFonts.cairo(),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getQuestionTypeLabel(String type) {
    switch (type) {
      case 'multiple_choice':
        return 'اختيار متعدد';
      case 'true_false':
        return 'صح/خطأ';
      case 'short_answer':
        return 'إجابة قصيرة';
      case 'fill_blank':
        return 'ملء الفراغ';
      default:
        return 'سؤال';
    }
  }

  Color _getDifficultyColor(String? difficulty) {
    switch (difficulty) {
      case 'سهل':
        return Colors.green;
      case 'متوسط':
        return Colors.orange;
      case 'صعب':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  int _getAnsweredCount() {
    return _selectedAnswers.where((answer) => answer != null).length;
  }

  Future<bool> _showExitConfirmation() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('تأكيد الخروج', style: GoogleFonts.cairo()),
        content: Text(
          'هل أنت متأكد من الخروج من الاختبار؟\nسيتم فقدان جميع الإجابات.',
          style: GoogleFonts.cairo(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('إلغاء', style: GoogleFonts.cairo()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('خروج', style: GoogleFonts.cairo()),
          ),
        ],
      ),
    ) ?? false;
  }

  void _showSubmitConfirmation() {
    final unansweredCount = _questions.length - _getAnsweredCount();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('تأكيد الإرسال', style: GoogleFonts.cairo()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'هل أنت متأكد من إرسال الاختبار؟',
              style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'الأسئلة المجابة: ${_getAnsweredCount()} من ${_questions.length}',
              style: GoogleFonts.cairo(),
            ),
            if (unansweredCount > 0) ...[
              const SizedBox(height: 4),
              Text(
                'الأسئلة غير المجابة: $unansweredCount',
                style: GoogleFonts.cairo(color: Colors.red),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              'لا يمكن التراجع بعد الإرسال.',
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
              _submitQuiz();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
            child: Text('إرسال', style: GoogleFonts.cairo()),
          ),
        ],
      ),
    );
  }

  Future<void> _submitQuiz() async {
    if (_isSubmitting) return;
    
    setState(() => _isSubmitting = true);
    _timer?.cancel();

    try {
      final db = await _dbService.database;
      final endTime = DateTime.now();
      final duration = endTime.difference(_startTime).inSeconds;

      // Calculate score
      int correctAnswers = 0;
      for (int i = 0; i < _questions.length; i++) {
        final question = _questions[i];
        final userAnswer = _selectedAnswers[i];
        final correctAnswer = question['correct_answer'];

        if (userAnswer != null && userAnswer == correctAnswer) {
          correctAnswers++;
        }
      }

      final score = (_questions.isNotEmpty) 
          ? (correctAnswers / _questions.length * 100).round()
          : 0;

      // Save quiz result
      await db.insert('quiz_results', {
        'quiz_id': widget.quiz['id'],
        'student_id': widget.student.id,
        'score': score,
        'total_questions': _questions.length,
        'correct_answers': correctAnswers,
        'duration_seconds': duration,
        'answers': jsonEncode(_selectedAnswers),
        'started_at': _startTime.toIso8601String(),
        'completed_at': endTime.toIso8601String(),
      });

      // Save quiz attempt
      await db.insert('quiz_attempts', {
        'quiz_id': widget.quiz['id'],
        'student_id': widget.student.id,
        'started_at': _startTime.toIso8601String(),
        'completed_at': endTime.toIso8601String(),
        'score': score,
        'is_completed': 1,
      });

      // Navigate to results screen
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => QuizResultScreen(
              quiz: widget.quiz,
              student: widget.student,
              score: score,
              correctAnswers: correctAnswers,
              totalQuestions: _questions.length,
              duration: duration,
              questions: _questions,
              userAnswers: _selectedAnswers,
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في إرسال الاختبار: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class QuizResultScreen extends StatelessWidget {
  final Map<String, dynamic> quiz;
  final User student;
  final int score;
  final int correctAnswers;
  final int totalQuestions;
  final int duration;
  final List<Map<String, dynamic>> questions;
  final List<dynamic> userAnswers;

  const QuizResultScreen({
    super.key,
    required this.quiz,
    required this.student,
    required this.score,
    required this.correctAnswers,
    required this.totalQuestions,
    required this.duration,
    required this.questions,
    required this.userAnswers,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('نتيجة الاختبار', style: GoogleFonts.cairo()),
        backgroundColor: _getScoreColor(),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildScoreCard(),
            const SizedBox(height: 20),
            _buildStatsCards(),
            const SizedBox(height: 20),
            _buildQuestionReview(),
            const SizedBox(height: 20),
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_getScoreColor(), _getScoreColor().withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _getScoreColor().withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            _getScoreIcon(),
            size: 64,
            color: Colors.white,
          ),
          const SizedBox(height: 12),
          Text(
            '$score%',
            style: GoogleFonts.cairo(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            _getScoreMessage(),
            style: GoogleFonts.cairo(
              fontSize: 18,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    return Row(
      children: [
        Expanded(child: _buildStatCard('الإجابات الصحيحة', '$correctAnswers', Icons.check_circle, Colors.green)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard('إجمالي الأسئلة', '$totalQuestions', Icons.quiz, Colors.blue)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard('الوقت المستغرق', _formatDuration(duration), Icons.timer, Colors.orange)),
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
          Icon(icon, color: color, size: 32),
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
              fontSize: 12,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionReview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'مراجعة الأسئلة',
          style: GoogleFonts.cairo(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...List.generate(questions.length, (index) {
          final question = questions[index];
          final userAnswer = userAnswers[index];
          final correctAnswer = question['correct_answer'];
          final isCorrect = userAnswer == correctAnswer;
          
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isCorrect ? Colors.green.shade50 : Colors.red.shade50,
              border: Border.all(
                color: isCorrect ? Colors.green.shade300 : Colors.red.shade300,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      isCorrect ? Icons.check_circle : Icons.cancel,
                      color: isCorrect ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'السؤال ${index + 1}: ${question['question_text']}',
                        style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                if (!isCorrect) ...[
                  const SizedBox(height: 8),
                  Text(
                    'إجابتك: ${_getAnswerText(question, userAnswer)}',
                    style: GoogleFonts.cairo(color: Colors.red.shade700),
                  ),
                  Text(
                    'الإجابة الصحيحة: ${_getAnswerText(question, correctAnswer)}',
                    style: GoogleFonts.cairo(color: Colors.green.shade700),
                  ),
                ],
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/',
                (route) => false,
              );
            },
            icon: const Icon(Icons.home),
            label: Text('العودة للرئيسية', style: GoogleFonts.cairo()),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  Color _getScoreColor() {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  IconData _getScoreIcon() {
    if (score >= 80) return Icons.emoji_events;
    if (score >= 60) return Icons.thumb_up;
    return Icons.sentiment_dissatisfied;
  }

  String _getScoreMessage() {
    if (score >= 90) return 'ممتاز! نتيجة رائعة';
    if (score >= 80) return 'جيد جداً! أحسنت';
    if (score >= 70) return 'جيد! يمكنك التحسن';
    if (score >= 60) return 'مقبول! حاول مرة أخرى';
    return 'تحتاج للمزيد من المراجعة';
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes}د ${remainingSeconds}ث';
  }

  String _getAnswerText(Map<String, dynamic> question, dynamic answer) {
    if (answer == null) return 'لم يتم الإجابة';
    
    final questionType = question['question_type'] as String;
    
    if (questionType == 'multiple_choice') {
      final options = jsonDecode(question['options']) as List<dynamic>;
      if (answer is int && answer >= 0 && answer < options.length) {
        return options[answer];
      }
    } else if (questionType == 'true_false') {
      return answer == 1 ? 'صحيح' : 'خطأ';
    } else {
      return answer.toString();
    }
    
    return 'إجابة غير صالحة';
  }
} 