import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/quiz.dart';
import '../models/question.dart';
import '../models/question_updated.dart';
import '../models/quiz_result.dart';

class PersistentStorageService {
  static const String _usersKey = 'persistent_users';
  static const String _quizzesKey = 'persistent_quizzes';
  static const String _questionsKey = 'persistent_questions';
  static const String _resultsKey = 'persistent_quiz_results';
  static const String _nextIdKey = 'persistent_next_id';
  static const String _systemStatsKey = 'system_stats';
  static const String _initializationKey = 'system_initialized';

  // Singleton pattern للتأكد من استخدام نفس البيانات
  static final PersistentStorageService _instance = PersistentStorageService._internal();
  factory PersistentStorageService() => _instance;
  PersistentStorageService._internal();

  // Cache للبيانات في الذاكرة مع إعادة تحميل تلقائية
  List<User>? _cachedUsers;
  List<Quiz>? _cachedQuizzes;
  List<QuestionUpdated>? _cachedQuestions;
  List<QuizResult>? _cachedResults;
  bool _isInitialized = false;

  // Initialize with enhanced persistence
  Future<void> initialize() async {
    if (_isInitialized) {
      await _loadCache();
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    
    // Check if system was previously initialized
    final isSystemInitialized = prefs.getBool(_initializationKey) ?? false;
    
    if (!isSystemInitialized) {
      await _createInitialData();
      await prefs.setBool(_initializationKey, true);
    }
    
    await _loadCache();
    _isInitialized = true;
    
    // Update system stats
    await _updateSystemStats();
  }

  Future<void> _createInitialData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Create default admin user
    final defaultUsers = [
      User(
        id: 1,
        name: 'مدير النظام',
        email: 'admin@quiz.com',
        password: 'admin123',
        role: UserRole.teacher, // Admin will be treated as super teacher
        createdAt: DateTime.now(),
      ),
      User(
        id: 2,
        name: 'المعلم التجريبي',
        email: 'teacher@quiz.com',
        password: '123456',
        role: UserRole.teacher,
        createdAt: DateTime.now(),
      ),
      User(
        id: 3,
        name: 'الطالب التجريبي',
        email: 'student@quiz.com',
        password: '123456',
        role: UserRole.student,
        createdAt: DateTime.now(),
      ),
    ];

    // Create sample quiz
    final sampleQuiz = Quiz(
      id: 1,
      title: 'اختبار تجريبي - أساسيات الحاسوب',
      description: 'اختبار تجريبي لتعلم أساسيات الحاسوب والبرمجة',
      teacherId: 2,
      duration: 30,
      isActive: true,
      createdAt: DateTime.now(),
    );

    // Create sample questions
    final sampleQuestions = [
      QuestionUpdated(
        id: 1,
        quizId: 1,
        question: 'ما هي لغة البرمجة المستخدمة في تطوير تطبيقات الأندرويد؟',
        type: QuestionType.multipleChoice,
        options: ['Java', 'Python', 'JavaScript', 'C++'],
        correctAnswers: [0],
        points: 2,
        explanation: 'Java هي اللغة الأساسية لتطوير تطبيقات الأندرويد',
      ),
      QuestionUpdated(
        id: 2,
        quizId: 1,
        question: 'HTML تعني HyperText Markup Language',
        type: QuestionType.trueFalse,
        options: ['صح', 'خطأ'],
        correctAnswers: [0],
        points: 1,
        explanation: 'نعم، HTML هي اختصار لـ HyperText Markup Language',
      ),
      QuestionUpdated(
        id: 3,
        quizId: 1,
        question: 'اكمل الجملة: _______ هو نظام إدارة قواعد البيانات',
        type: QuestionType.fillInBlank,
        correctText: 'MySQL',
        points: 2,
        explanation: 'MySQL هو أحد أشهر أنظمة إدارة قواعد البيانات',
      ),
      QuestionUpdated(
        id: 4,
        quizId: 1,
        question: 'ما الفرق بين الذاكرة RAM والقرص الصلب؟',
        type: QuestionType.shortAnswer,
        correctText: 'RAM ذاكرة مؤقتة سريعة، القرص الصلب تخزين دائم',
        points: 3,
        explanation: 'RAM للتخزين المؤقت السريع، القرص الصلب للتخزين الدائم',
      ),
    ];

    await _saveUsers(defaultUsers);
    await _saveQuizzes([sampleQuiz]);
    await _saveQuestions(sampleQuestions);
    await _saveResults([]);
    await prefs.setInt(_nextIdKey, 5);
  }

  Future<void> _loadCache() async {
    try {
      _cachedUsers = await _getUsers();
      _cachedQuizzes = await _getQuizzes();
      _cachedQuestions = await _getQuestions();
      _cachedResults = await _getResults();
    } catch (e) {
      print('Error loading cache: $e');
      // If loading fails, reset the system
      await _resetSystem();
    }
  }

  Future<void> _resetSystem() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    _isInitialized = false;
    await initialize();
  }

  Future<void> _updateSystemStats() async {
    final prefs = await SharedPreferences.getInstance();
    final stats = {
      'last_access': DateTime.now().toIso8601String(),
      'total_users': _cachedUsers?.length ?? 0,
      'total_quizzes': _cachedQuizzes?.length ?? 0,
      'total_questions': _cachedQuestions?.length ?? 0,
      'total_results': _cachedResults?.length ?? 0,
    };
    await prefs.setString(_systemStatsKey, jsonEncode(stats));
  }

  Future<int> _getNextId() async {
    final prefs = await SharedPreferences.getInstance();
    final nextId = prefs.getInt(_nextIdKey) ?? 1;
    await prefs.setInt(_nextIdKey, nextId + 1);
    return nextId;
  }

  // User operations with enhanced persistence
  Future<List<User>> _getUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getStringList(_usersKey) ?? [];
    return usersJson.map((json) => User.fromMap(jsonDecode(json))).toList();
  }

  Future<void> _saveUsers(List<User> users) async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = users.map((user) => jsonEncode(user.toMap())).toList();
    await prefs.setStringList(_usersKey, usersJson);
    _cachedUsers = users;
    await _updateSystemStats();
  }

  Future<int> insertUser(User user) async {
    final users = await _getUsers();
    final id = await _getNextId();
    final newUser = user.copyWith(id: id);
    users.add(newUser);
    await _saveUsers(users);
    return id;
  }

  Future<User?> getUserByEmail(String email) async {
    final users = await _getUsers();
    try {
      return users.firstWhere((user) => user.email == email);
    } catch (e) {
      return null;
    }
  }

  Future<List<User>> getAllUsers() async {
    return await _getUsers();
  }

  Future<void> updateUser(User user) async {
    final users = await _getUsers();
    final index = users.indexWhere((u) => u.id == user.id);
    if (index != -1) {
      users[index] = user;
      await _saveUsers(users);
    }
  }

  Future<void> deleteUser(int id) async {
    final users = await _getUsers();
    users.removeWhere((user) => user.id == id);
    await _saveUsers(users);
  }

  // Quiz operations with enhanced persistence
  Future<List<Quiz>> _getQuizzes() async {
    final prefs = await SharedPreferences.getInstance();
    final quizzesJson = prefs.getStringList(_quizzesKey) ?? [];
    return quizzesJson.map((json) => Quiz.fromMap(jsonDecode(json))).toList();
  }

  Future<void> _saveQuizzes(List<Quiz> quizzes) async {
    final prefs = await SharedPreferences.getInstance();
    final quizzesJson = quizzes.map((quiz) => jsonEncode(quiz.toMap())).toList();
    await prefs.setStringList(_quizzesKey, quizzesJson);
    _cachedQuizzes = quizzes;
    await _updateSystemStats();
  }

  Future<int> insertQuiz(Quiz quiz) async {
    final quizzes = await _getQuizzes();
    final id = await _getNextId();
    final newQuiz = quiz.copyWith(id: id);
    quizzes.add(newQuiz);
    await _saveQuizzes(quizzes);
    return id;
  }

  Future<List<Quiz>> getQuizzesByTeacher(int teacherId) async {
    final quizzes = await _getQuizzes();
    return quizzes.where((quiz) => quiz.teacherId == teacherId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<List<Quiz>> getActiveQuizzes() async {
    final quizzes = await _getQuizzes();
    final activeQuizzes = quizzes.where((quiz) => quiz.isActive).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    
    final updatedQuizzes = <Quiz>[];
    for (final quiz in activeQuizzes) {
      final questions = await getQuestionsByQuiz(quiz.id!);
      if (questions.isNotEmpty) {
        updatedQuizzes.add(quiz.copyWith(questions: questions.map((q) => 
          Question(
            id: q.id,
            quizId: q.quizId,
            question: q.question,
            options: q.options,
            correctAnswer: q.correctAnswers.isNotEmpty ? q.correctAnswers.first : 0,
          )
        ).toList()));
      }
    }
    
    return updatedQuizzes;
  }

  Future<Quiz?> getQuizById(int id) async {
    final quizzes = await _getQuizzes();
    try {
      final quiz = quizzes.firstWhere((quiz) => quiz.id == id);
      final questions = await getQuestionsByQuiz(id);
      return quiz.copyWith(questions: questions.map((q) => 
        Question(
          id: q.id,
          quizId: q.quizId,
          question: q.question,
          options: q.options,
          correctAnswer: q.correctAnswers.isNotEmpty ? q.correctAnswers.first : 0,
        )
      ).toList());
    } catch (e) {
      return null;
    }
  }

  Future<void> updateQuiz(Quiz quiz) async {
    final quizzes = await _getQuizzes();
    final index = quizzes.indexWhere((q) => q.id == quiz.id);
    if (index != -1) {
      quizzes[index] = quiz;
      await _saveQuizzes(quizzes);
    }
  }

  Future<void> deleteQuiz(int id) async {
    final quizzes = await _getQuizzes();
    quizzes.removeWhere((quiz) => quiz.id == id);
    await _saveQuizzes(quizzes);

    // Also delete related questions
    final questions = await _getQuestions();
    questions.removeWhere((question) => question.quizId == id);
    await _saveQuestions(questions);
  }

  // Question operations with enhanced persistence
  Future<List<QuestionUpdated>> _getQuestions() async {
    final prefs = await SharedPreferences.getInstance();
    final questionsJson = prefs.getStringList(_questionsKey) ?? [];
    return questionsJson.map((json) => QuestionUpdated.fromMap(jsonDecode(json))).toList();
  }

  Future<void> _saveQuestions(List<QuestionUpdated> questions) async {
    final prefs = await SharedPreferences.getInstance();
    final questionsJson = questions.map((question) => jsonEncode(question.toMap())).toList();
    await prefs.setStringList(_questionsKey, questionsJson);
    _cachedQuestions = questions;
    await _updateSystemStats();
  }

  Future<int> insertQuestion(QuestionUpdated question) async {
    final questions = await _getQuestions();
    final id = await _getNextId();
    final newQuestion = question.copyWith(id: id);
    questions.add(newQuestion);
    await _saveQuestions(questions);
    return id;
  }

  Future<List<QuestionUpdated>> getQuestionsByQuiz(int quizId) async {
    final questions = await _getQuestions();
    return questions.where((question) => question.quizId == quizId).toList();
  }

  Future<void> deleteQuestion(int id) async {
    final questions = await _getQuestions();
    questions.removeWhere((question) => question.id == id);
    await _saveQuestions(questions);
  }

  Future<void> updateQuestion(QuestionUpdated question) async {
    final questions = await _getQuestions();
    final index = questions.indexWhere((q) => q.id == question.id);
    if (index != -1) {
      questions[index] = question;
      await _saveQuestions(questions);
    }
  }

  // Quiz result operations with enhanced persistence
  Future<List<QuizResult>> _getResults() async {
    final prefs = await SharedPreferences.getInstance();
    final resultsJson = prefs.getStringList(_resultsKey) ?? [];
    return resultsJson.map((json) => QuizResult.fromMap(jsonDecode(json))).toList();
  }

  Future<void> _saveResults(List<QuizResult> results) async {
    final prefs = await SharedPreferences.getInstance();
    final resultsJson = results.map((result) => jsonEncode(result.toMap())).toList();
    await prefs.setStringList(_resultsKey, resultsJson);
    _cachedResults = results;
    await _updateSystemStats();
  }

  Future<int> insertQuizResult(QuizResult result) async {
    final results = await _getResults();
    final id = await _getNextId();
    final newResult = QuizResult(
      id: id,
      studentId: result.studentId,
      quizId: result.quizId,
      score: result.score,
      totalQuestions: result.totalQuestions,
      timeSpent: result.timeSpent,
      completedAt: result.completedAt,
    );
    results.add(newResult);
    await _saveResults(results);
    return id;
  }

  Future<List<QuizResult>> getResultsByStudent(int studentId) async {
    final results = await _getResults();
    return results.where((result) => result.studentId == studentId).toList()
      ..sort((a, b) => b.completedAt.compareTo(a.completedAt));
  }

  Future<List<QuizResult>> getResultsByQuiz(int quizId) async {
    final results = await _getResults();
    return results.where((result) => result.quizId == quizId).toList()
      ..sort((a, b) => b.completedAt.compareTo(a.completedAt));
  }

  Future<bool> hasStudentTakenQuiz(int studentId, int quizId) async {
    final results = await _getResults();
    return results.any((result) => result.studentId == studentId && result.quizId == quizId);
  }

  // Admin operations
  Future<Map<String, dynamic>> getSystemStats() async {
    await _loadCache();
    
    final users = _cachedUsers ?? [];
    final quizzes = _cachedQuizzes ?? [];
    final questions = _cachedQuestions ?? [];
    final results = _cachedResults ?? [];

    final teachers = users.where((u) => u.role == UserRole.teacher).length;
    final students = users.where((u) => u.role == UserRole.student).length;
    final activeQuizzes = quizzes.where((q) => q.isActive).length;

    // Calculate average score
    double averageScore = 0;
    if (results.isNotEmpty) {
      averageScore = results.map((r) => r.percentage).reduce((a, b) => a + b) / results.length;
    }

    return {
      'total_users': users.length,
      'teachers': teachers,
      'students': students,
      'total_quizzes': quizzes.length,
      'active_quizzes': activeQuizzes,
      'total_questions': questions.length,
      'total_results': results.length,
      'average_score': averageScore,
      'last_updated': DateTime.now().toIso8601String(),
    };
  }

  Future<void> resetAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    _cachedUsers = null;
    _cachedQuizzes = null;
    _cachedQuestions = null;
    _cachedResults = null;
    _isInitialized = false;
    await initialize();
  }

  Future<Map<String, dynamic>> exportData() async {
    await _loadCache();
    return {
      'users': _cachedUsers?.map((u) => u.toMap()).toList() ?? [],
      'quizzes': _cachedQuizzes?.map((q) => q.toMap()).toList() ?? [],
      'questions': _cachedQuestions?.map((q) => q.toMap()).toList() ?? [],
      'results': _cachedResults?.map((r) => r.toMap()).toList() ?? [],
      'export_date': DateTime.now().toIso8601String(),
    };
  }

  // مساعد لإعادة تحميل البيانات
  Future<void> refreshCache() async {
    await _loadCache();
  }

  // Check if user is admin
  bool isAdmin(User user) {
    return user.email == 'admin@quiz.com';
  }
} 