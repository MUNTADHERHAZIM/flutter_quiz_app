import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/quiz.dart';
import '../models/question.dart';
import '../models/question_updated.dart';
import '../models/quiz_result.dart';

class StorageServiceUpdated {
  static const String _usersKey = 'users_v2';
  static const String _quizzesKey = 'quizzes_v2';
  static const String _questionsKey = 'questions_v2';
  static const String _resultsKey = 'quiz_results_v2';
  static const String _nextIdKey = 'next_id_v2';

  // Singleton pattern للتأكد من استخدام نفس البيانات
  static final StorageServiceUpdated _instance = StorageServiceUpdated._internal();
  factory StorageServiceUpdated() => _instance;
  StorageServiceUpdated._internal();

  // Cache للبيانات في الذاكرة
  List<User>? _cachedUsers;
  List<Quiz>? _cachedQuizzes;
  List<QuestionUpdated>? _cachedQuestions;
  List<QuizResult>? _cachedResults;

  // Initialize with default data
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    
    // إذا كانت البيانات موجودة، لا نعيد إنشاءها
    if (prefs.containsKey(_usersKey)) {
      await _loadCache();
      return;
    }

    // Create default users
    final defaultUsers = [
      User(
        id: 1,
        name: 'المعلم الافتراضي',
        email: 'teacher@quiz.com',
        password: '123456',
        role: UserRole.teacher,
        createdAt: DateTime.now(),
      ),
      User(
        id: 2,
        name: 'الطالب التجريبي',
        email: 'student@quiz.com',
        password: '123456',
        role: UserRole.student,
        createdAt: DateTime.now(),
      ),
    ];

    await _saveUsers(defaultUsers);
    await _saveQuizzes([]);
    await _saveQuestions([]);
    await _saveResults([]);
    await prefs.setInt(_nextIdKey, 3);
    
    await _loadCache();
  }

  Future<void> _loadCache() async {
    _cachedUsers = await _getUsers();
    _cachedQuizzes = await _getQuizzes();
    _cachedQuestions = await _getQuestions();
    _cachedResults = await _getResults();
  }

  Future<int> _getNextId() async {
    final prefs = await SharedPreferences.getInstance();
    final nextId = prefs.getInt(_nextIdKey) ?? 1;
    await prefs.setInt(_nextIdKey, nextId + 1);
    return nextId;
  }

  // User operations
  Future<List<User>> _getUsers() async {
    if (_cachedUsers != null) return _cachedUsers!;
    
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getStringList(_usersKey) ?? [];
    _cachedUsers = usersJson.map((json) => User.fromMap(jsonDecode(json))).toList();
    return _cachedUsers!;
  }

  Future<void> _saveUsers(List<User> users) async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = users.map((user) => jsonEncode(user.toMap())).toList();
    await prefs.setStringList(_usersKey, usersJson);
    _cachedUsers = users;
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

  // Quiz operations
  Future<List<Quiz>> _getQuizzes() async {
    if (_cachedQuizzes != null) return _cachedQuizzes!;
    
    final prefs = await SharedPreferences.getInstance();
    final quizzesJson = prefs.getStringList(_quizzesKey) ?? [];
    _cachedQuizzes = quizzesJson.map((json) => Quiz.fromMap(jsonDecode(json))).toList();
    return _cachedQuizzes!;
  }

  Future<void> _saveQuizzes(List<Quiz> quizzes) async {
    final prefs = await SharedPreferences.getInstance();
    final quizzesJson = quizzes.map((quiz) => jsonEncode(quiz.toMap())).toList();
    await prefs.setStringList(_quizzesKey, quizzesJson);
    _cachedQuizzes = quizzes;
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
    
    // تحديث كل كويز بالأسئلة الخاصة به
    final updatedQuizzes = <Quiz>[];
    for (final quiz in activeQuizzes) {
      final questions = await getQuestionsByQuiz(quiz.id!);
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

  // Question operations (Updated)
  Future<List<QuestionUpdated>> _getQuestions() async {
    if (_cachedQuestions != null) return _cachedQuestions!;
    
    final prefs = await SharedPreferences.getInstance();
    final questionsJson = prefs.getStringList(_questionsKey) ?? [];
    _cachedQuestions = questionsJson.map((json) => QuestionUpdated.fromMap(jsonDecode(json))).toList();
    return _cachedQuestions!;
  }

  Future<void> _saveQuestions(List<QuestionUpdated> questions) async {
    final prefs = await SharedPreferences.getInstance();
    final questionsJson = questions.map((question) => jsonEncode(question.toMap())).toList();
    await prefs.setStringList(_questionsKey, questionsJson);
    _cachedQuestions = questions;
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

  // Quiz result operations
  Future<List<QuizResult>> _getResults() async {
    if (_cachedResults != null) return _cachedResults!;
    
    final prefs = await SharedPreferences.getInstance();
    final resultsJson = prefs.getStringList(_resultsKey) ?? [];
    _cachedResults = resultsJson.map((json) => QuizResult.fromMap(jsonDecode(json))).toList();
    return _cachedResults!;
  }

  Future<void> _saveResults(List<QuizResult> results) async {
    final prefs = await SharedPreferences.getInstance();
    final resultsJson = results.map((result) => jsonEncode(result.toMap())).toList();
    await prefs.setStringList(_resultsKey, resultsJson);
    _cachedResults = results;
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

  // مساعد لإعادة تحميل البيانات
  Future<void> refreshCache() async {
    _cachedUsers = null;
    _cachedQuizzes = null;
    _cachedQuestions = null;
    _cachedResults = null;
    await _loadCache();
  }
} 