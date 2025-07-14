import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import '../providers/auth_provider.dart';
import '../models/quiz.dart';
import '../models/question.dart';
import '../models/quiz_result.dart';
import '../services/database_service.dart';

class QuizTakingScreen extends StatefulWidget {
  final Quiz quiz;

  const QuizTakingScreen({super.key, required this.quiz});

  @override
  State<QuizTakingScreen> createState() => _QuizTakingScreenState();
}

class _QuizTakingScreenState extends State<QuizTakingScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final PageController _pageController = PageController();
  
  List<Question> _questions = [];
  List<int?> _selectedAnswers = [];
  int _currentQuestionIndex = 0;
  late int _timeLeft; // in seconds
  Timer? _timer;
  bool _isLoading = true;
  bool _isSubmitting = false;
  late DateTime _startTime;

  @override
  void initState() {
    super.initState();
    _timeLeft = widget.quiz.duration * 60; // Convert minutes to seconds
    _startTime = DateTime.now();
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
      final questions = await _databaseService.getQuestionsByQuiz(widget.quiz.id!);
      setState(() {
        _questions = questions;
        _selectedAnswers = List.filled(questions.length, null);
        _isLoading = false;
      });
      _startTimer();
    } catch (e) {
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
      setState(() {
        if (_timeLeft > 0) {
          _timeLeft--;
        } else {
          _submitQuiz();
        }
      });
    });
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void _selectAnswer(int answerIndex) {
    setState(() {
      _selectedAnswers[_currentQuestionIndex] = answerIndex;
    });
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() => _currentQuestionIndex++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() => _currentQuestionIndex--);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _goToQuestion(int index) {
    setState(() => _currentQuestionIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _submitQuiz() async {
    if (_isSubmitting) return;

    final shouldSubmit = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('تأكيد الإرسال', style: GoogleFonts.cairo()),
        content: Text(
          'هل أنت متأكد من إرسال الاختبار؟ لن تتمكن من تعديل إجاباتك بعد الإرسال.',
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
            child: Text('إرسال', style: GoogleFonts.cairo()),
          ),
        ],
      ),
    );

    if (shouldSubmit != true) return;

    setState(() => _isSubmitting = true);

    try {
      _timer?.cancel();

      // Calculate score
      int score = 0;
      for (int i = 0; i < _questions.length; i++) {
        if (_selectedAnswers[i] == _questions[i].correctAnswer) {
          score++;
        }
      }

      // Calculate time spent
      final timeSpent = DateTime.now().difference(_startTime).inSeconds;

      // Save result
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final studentId = authProvider.currentUser!.id!;

      final result = QuizResult(
        studentId: studentId,
        quizId: widget.quiz.id!,
        score: score,
        totalQuestions: _questions.length,
        timeSpent: timeSpent,
        completedAt: DateTime.now(),
      );

      await _databaseService.insertQuizResult(result);

      if (mounted) {
        Navigator.pop(context, true);
        _showResultDialog(result);
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في إرسال الاختبار: $e')),
        );
      }
    }
  }

  void _showResultDialog(QuizResult result) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('نتيجة الاختبار', style: GoogleFonts.cairo()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              result.percentage >= 60 ? Icons.celebration : Icons.sentiment_dissatisfied,
              size: 64,
              color: result.percentage >= 60 ? Colors.green : Colors.orange,
            ),
            const SizedBox(height: 16),
            Text(
              'لقد حصلت على ${result.score} من ${result.totalQuestions}',
              style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'النسبة المئوية: ${result.percentage.toStringAsFixed(1)}%',
              style: GoogleFonts.cairo(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'الوقت المستغرق: ${(result.timeSpent / 60).toStringAsFixed(1)} دقيقة',
              style: GoogleFonts.cairo(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text('موافق', style: GoogleFonts.cairo()),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.quiz.title, style: GoogleFonts.cairo()),
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return WillPopScope(
      onWillPop: () async {
        final shouldExit = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('تحذير', style: GoogleFonts.cairo()),
            content: Text(
              'هل أنت متأكد من الخروج؟ ستفقد كل إجاباتك.',
              style: GoogleFonts.cairo(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('إلغاء', style: GoogleFonts.cairo()),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: Text('خروج', style: GoogleFonts.cairo()),
              ),
            ],
          ),
        );
        return shouldExit ?? false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.quiz.title, style: GoogleFonts.cairo()),
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
          actions: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: _timeLeft <= 300 ? Colors.red : Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _formatTime(_timeLeft),
                style: GoogleFonts.cairo(
                  color: _timeLeft <= 300 ? Colors.white : Colors.teal,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            // Progress Bar
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'السؤال ${_currentQuestionIndex + 1} من ${_questions.length}',
                        style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '${_selectedAnswers.where((answer) => answer != null).length} مجاب',
                        style: GoogleFonts.cairo(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: (_currentQuestionIndex + 1) / _questions.length,
                    backgroundColor: Colors.grey[300],
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.teal),
                  ),
                ],
              ),
            ),

            // Question Content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentQuestionIndex = index);
                },
                itemCount: _questions.length,
                itemBuilder: (context, index) {
                  final question = _questions[index];
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Card(
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
                              question.question,
                              style: GoogleFonts.cairo(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Expanded(
                              child: ListView.builder(
                                itemCount: question.options.length,
                                itemBuilder: (context, optionIndex) {
                                  final isSelected = _selectedAnswers[index] == optionIndex;
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: InkWell(
                                      onTap: () => _selectAnswer(optionIndex),
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: isSelected ? Colors.teal : Colors.grey[300]!,
                                            width: 2,
                                          ),
                                          borderRadius: BorderRadius.circular(8),
                                          color: isSelected ? Colors.teal[50] : Colors.white,
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 24,
                                              height: 24,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: isSelected ? Colors.teal : Colors.grey[400]!,
                                                  width: 2,
                                                ),
                                                color: isSelected ? Colors.teal : Colors.white,
                                              ),
                                              child: isSelected
                                                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                                                  : null,
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                question.options[optionIndex],
                                                style: GoogleFonts.cairo(
                                                  fontSize: 16,
                                                  color: isSelected ? Colors.teal[700] : Colors.black87,
                                                ),
                                              ),
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
                      ),
                    ),
                  );
                },
              ),
            ),

            // Navigation and Submit
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Previous Button
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _currentQuestionIndex > 0 ? _previousQuestion : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text('السابق', style: GoogleFonts.cairo()),
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  // Question Numbers
                  Expanded(
                    flex: 2,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: List.generate(_questions.length, (index) {
                          final isAnswered = _selectedAnswers[index] != null;
                          final isCurrent = index == _currentQuestionIndex;
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: GestureDetector(
                              onTap: () => _goToQuestion(index),
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: isCurrent
                                      ? Colors.teal
                                      : isAnswered
                                          ? Colors.green
                                          : Colors.grey[300],
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: isCurrent ? Colors.teal : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    '${index + 1}',
                                    style: GoogleFonts.cairo(
                                      color: isCurrent || isAnswered ? Colors.white : Colors.black87,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  // Next/Submit Button
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSubmitting
                          ? null
                          : _currentQuestionIndex < _questions.length - 1
                              ? _nextQuestion
                              : _submitQuiz,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _currentQuestionIndex < _questions.length - 1
                            ? Colors.teal
                            : Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              _currentQuestionIndex < _questions.length - 1 ? 'التالي' : 'إرسال',
                              style: GoogleFonts.cairo(),
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
} 