import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import '../models/quiz.dart';
import '../models/question_updated.dart';
import '../models/user.dart';
import '../models/quiz_result.dart';
import '../services/persistent_storage_service.dart';

class EnhancedQuizTaking extends StatefulWidget {
  final Quiz quiz;
  final User student;

  const EnhancedQuizTaking({super.key, required this.quiz, required this.student});

  @override
  State<EnhancedQuizTaking> createState() => _EnhancedQuizTakingState();
}

class _EnhancedQuizTakingState extends State<EnhancedQuizTaking> {
  final PersistentStorageService _storage = PersistentStorageService();
  final PageController _pageController = PageController();
  
  List<QuestionUpdated> _questions = [];
  List<dynamic> _selectedAnswers = [];
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
      await _storage.initialize();
      final questions = await _storage.getQuestionsByQuiz(widget.quiz.id!);
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

  void _selectAnswer(dynamic answer) {
    setState(() {
      _selectedAnswers[_currentQuestionIndex] = answer;
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

  bool _isAnswerCorrect(QuestionUpdated question, dynamic answer) {
    switch (question.type) {
      case QuestionType.multipleChoice:
      case QuestionType.trueFalse:
        if (question.correctAnswers.isNotEmpty && answer != null) {
          return answer == question.correctAnswers.first;
        }
        return false;
      case QuestionType.fillInBlank:
      case QuestionType.shortAnswer:
        if (question.correctText != null && answer != null) {
          return answer.toString().toLowerCase().trim() == 
                 question.correctText!.toLowerCase().trim();
        }
        return false;
    }
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

      // Calculate score and total points
      int totalScore = 0;
      int totalPoints = 0;
      
      for (int i = 0; i < _questions.length; i++) {
        totalPoints += _questions[i].points;
        if (_isAnswerCorrect(_questions[i], _selectedAnswers[i])) {
          totalScore += _questions[i].points;
        }
      }

      // Calculate time spent
      final timeSpent = DateTime.now().difference(_startTime).inSeconds;

      // Save result
      final result = QuizResult(
        studentId: widget.student.id!,
        quizId: widget.quiz.id!,
        score: totalScore,
        totalQuestions: _questions.length,
        timeSpent: timeSpent,
        completedAt: DateTime.now(),
      );

      await _storage.insertQuizResult(result);

      if (mounted) {
        Navigator.pop(context, true);
        _showResultDialog(result, totalPoints);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في إرسال الاختبار: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showResultDialog(QuizResult result, int totalPoints) {
    final percentage = totalPoints > 0 ? (result.score / totalPoints * 100).round() : 0;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('نتيجة الاختبار', style: GoogleFonts.cairo()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              percentage >= 60 ? Icons.celebration : Icons.sentiment_dissatisfied,
              size: 64,
              color: percentage >= 60 ? Colors.green : Colors.orange,
            ),
            const SizedBox(height: 16),
            Text(
              'النقاط: ${result.score} من $totalPoints',
              style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              'النسبة المئوية: %$percentage',
              style: GoogleFonts.cairo(fontSize: 16),
            ),
            Text(
              'الوقت المستغرق: ${_formatTime(result.timeSpent)}',
              style: GoogleFonts.cairo(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: Text('موافق', style: GoogleFonts.cairo()),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionContent(QuestionUpdated question, int index) {
    switch (question.type) {
      case QuestionType.multipleChoice:
        return _buildMultipleChoice(question, index);
      case QuestionType.trueFalse:
        return _buildTrueFalse(question, index);
      case QuestionType.fillInBlank:
        return _buildFillInTheBlank(question, index);
      case QuestionType.shortAnswer:
        return _buildShortAnswer(question, index);
    }
  }

  Widget _buildMultipleChoice(QuestionUpdated question, int index) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question.question,
          style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 20),
        ...List.generate(question.options.length, (optionIndex) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () => _selectAnswer(optionIndex),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _selectedAnswers[index] == optionIndex 
                        ? Colors.teal 
                        : Colors.grey[300]!,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  color: _selectedAnswers[index] == optionIndex 
                      ? Colors.teal.withValues(alpha: 0.1)
                      : Colors.grey[50],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _selectedAnswers[index] == optionIndex 
                              ? Colors.teal 
                              : Colors.grey[400]!,
                          width: 2,
                        ),
                        color: _selectedAnswers[index] == optionIndex 
                            ? Colors.teal 
                            : Colors.white,
                      ),
                      child: _selectedAnswers[index] == optionIndex
                          ? const Icon(Icons.check, color: Colors.white, size: 16)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${String.fromCharCode(65 + optionIndex)}. ${question.options[optionIndex]}',
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          fontWeight: _selectedAnswers[index] == optionIndex 
                              ? FontWeight.w600 
                              : FontWeight.normal,
                          color: _selectedAnswers[index] == optionIndex 
                              ? Colors.teal[700] 
                              : Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildTrueFalse(QuestionUpdated question, int index) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question.question,
          style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 30),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => _selectAnswer(0),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _selectedAnswers[index] == 0 ? Colors.green : Colors.grey[300]!,
                      width: 3,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    color: _selectedAnswers[index] == 0 ? Colors.green.withValues(alpha: 0.1) : Colors.grey[50],
                    boxShadow: _selectedAnswers[index] == 0 ? [
                      BoxShadow(
                        color: Colors.green.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ] : null,
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: _selectedAnswers[index] == 0 ? Colors.green : Colors.grey[400],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.check_circle,
                          color: Colors.white,
                          size: 36,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'صحيح',
                        style: GoogleFonts.cairo(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: _selectedAnswers[index] == 0 ? Colors.green[700] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: InkWell(
                onTap: () => _selectAnswer(1),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _selectedAnswers[index] == 1 ? Colors.red : Colors.grey[300]!,
                      width: 3,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    color: _selectedAnswers[index] == 1 ? Colors.red.withValues(alpha: 0.1) : Colors.grey[50],
                    boxShadow: _selectedAnswers[index] == 1 ? [
                      BoxShadow(
                        color: Colors.red.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ] : null,
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: _selectedAnswers[index] == 1 ? Colors.red : Colors.grey[400],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.cancel,
                          color: Colors.white,
                          size: 36,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'خطأ',
                        style: GoogleFonts.cairo(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: _selectedAnswers[index] == 1 ? Colors.red[700] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFillInTheBlank(QuestionUpdated question, int index) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question.question,
          style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 24),
        Container(
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.edit, color: Colors.blue[600], size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'اكتب إجابتك في المساحة أدناه',
                  style: GoogleFonts.cairo(
                    color: Colors.blue[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          onChanged: (value) => _selectAnswer(value),
          decoration: InputDecoration(
            hintText: 'اكتب إجابتك هنا...',
            hintStyle: GoogleFonts.cairo(color: Colors.grey[500]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.teal, width: 2),
            ),
            filled: true,
            fillColor: Colors.grey[50],
            contentPadding: const EdgeInsets.all(16),
            prefixIcon: Icon(Icons.create, color: Colors.grey[600]),
          ),
          style: GoogleFonts.cairo(fontSize: 16),
          maxLines: 2,
        ),
      ],
    );
  }

  Widget _buildShortAnswer(QuestionUpdated question, int index) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question.question,
          style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 24),
        Container(
          decoration: BoxDecoration(
            color: Colors.purple[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.purple.withValues(alpha: 0.3)),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.text_fields, color: Colors.purple[600], size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'اكتب إجابة مفصلة في المساحة أدناه',
                  style: GoogleFonts.cairo(
                    color: Colors.purple[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          onChanged: (value) => _selectAnswer(value),
          maxLines: 5,
          decoration: InputDecoration(
            hintText: 'اكتب إجابتك المفصلة هنا...',
            hintStyle: GoogleFonts.cairo(color: Colors.grey[500]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.teal, width: 2),
            ),
            filled: true,
            fillColor: Colors.grey[50],
            contentPadding: const EdgeInsets.all(16),
            alignLabelWithHint: true,
          ),
          style: GoogleFonts.cairo(fontSize: 16),
          textAlignVertical: TextAlignVertical.top,
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.amber[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.tips_and_updates, color: Colors.amber[700], size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'نصيحة: كن مفصلاً ودقيقاً في إجابتك للحصول على أعلى الدرجات',
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    color: Colors.amber[700],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getQuestionTypeColor(QuestionType type) {
    switch (type) {
      case QuestionType.multipleChoice:
        return Colors.blue;
      case QuestionType.trueFalse:
        return Colors.green;
      case QuestionType.fillInBlank:
        return Colors.orange;
      case QuestionType.shortAnswer:
        return Colors.purple;
    }
  }

  IconData _getQuestionTypeIcon(QuestionType type) {
    switch (type) {
      case QuestionType.multipleChoice:
        return Icons.radio_button_checked;
      case QuestionType.trueFalse:
        return Icons.check_circle;
      case QuestionType.fillInBlank:
        return Icons.edit;
      case QuestionType.shortAnswer:
        return Icons.text_fields;
    }
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

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) return;
        
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
        
        if (shouldExit == true && context.mounted) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.quiz.title, style: GoogleFonts.cairo()),
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
          actions: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _timeLeft <= 300 ? Colors.red : Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.timer,
                      size: 16,
                      color: _timeLeft <= 300 ? Colors.white : Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatTime(_timeLeft),
                      style: GoogleFonts.cairo(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
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
                        '${_selectedAnswers.where((answer) => answer != null && answer.toString().isNotEmpty).length} مجاب',
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
                            // Question header
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getQuestionTypeColor(question.type).withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: _getQuestionTypeColor(question.type)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        _getQuestionTypeIcon(question.type),
                                        size: 16,
                                        color: _getQuestionTypeColor(question.type),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        question.getTypeDisplayName(),
                                        style: GoogleFonts.cairo(
                                          fontSize: 12,
                                          color: _getQuestionTypeColor(question.type),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${question.points} نقطة',
                                    style: GoogleFonts.cairo(
                                      fontSize: 12,
                                      color: Colors.amber[800],
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            
                            // Question content
                            Expanded(
                              child: SingleChildScrollView(
                                child: _buildQuestionContent(question, index),
                              ),
                            ),
                            
                            // Question explanation if available
                            if (question.explanation?.isNotEmpty == true) ...[
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.lightbulb_outline, 
                                         color: Colors.blue[700], size: 20),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'تلميح: ${question.explanation}',
                                        style: GoogleFonts.cairo(
                                          fontSize: 14,
                                          color: Colors.blue[700],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Navigation Bar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.2),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Previous Button
                  if (_currentQuestionIndex > 0)
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _previousQuestion,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[400],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text('السابق', style: GoogleFonts.cairo()),
                      ),
                    ),
                  
                  if (_currentQuestionIndex > 0) const SizedBox(width: 12),
                  
                  // Question Numbers
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 40,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: List.generate(_questions.length, (index) {
                            final isAnswered = _selectedAnswers[index] != null && 
                                             _selectedAnswers[index].toString().isNotEmpty;
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