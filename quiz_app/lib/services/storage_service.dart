import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/quiz.dart';
import '../models/question.dart';
import '../models/quiz_result.dart';

class StorageService {
  static const String _usersKey = 'users';
  static const String _quizzesKey = 'quizzes';
  static const String _questionsKey = 'questions';
  static const String _resultsKey = 'quiz_results';
  static const String _nextIdKey = 'next_id';

  // Initialize with default data
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Check if already initialized
    if (prefs.containsKey(_usersKey)) return;

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
  }

  Future<int> _getNextId() async {
    final prefs = await SharedPreferences.getInstance();
    final nextId = prefs.getInt(_nextIdKey) ?? 1;
    await prefs.setInt(_nextIdKey, nextId + 1);
    return nextId;
  }

  // User operations
  Future<List<User>> _getUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getStringList(_usersKey) ?? [];
    return usersJson.map((json) => User.fromMap(jsonDecode(json))).toList();
  }

  Future<void> _saveUsers(List<User> users) async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = users.map((user) => jsonEncode(user.toMap())).toList();
    await prefs.setStringList(_usersKey, usersJson);
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
    final prefs = await SharedPreferences.getInstance();
    final quizzesJson = prefs.getStringList(_quizzesKey) ?? [];
    return quizzesJson.map((json) => Quiz.fromMap(jsonDecode(json))).toList();
  }

  Future<void> _saveQuizzes(List<Quiz> quizzes) async {
    final prefs = await SharedPreferences.getInstance();
    final quizzesJson = quizzes.map((quiz) => jsonEncode(quiz.toMap())).toList();
    await prefs.setStringList(_quizzesKey, quizzesJson);
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
    return quizzes.where((quiz) => quiz.isActive).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<Quiz?> getQuizById(int id) async {
    final quizzes = await _getQuizzes();
    try {
      return quizzes.firstWhere((quiz) => quiz.id == id);
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

  // Question operations
  Future<List<Question>> _getQuestions() async {
    final prefs = await SharedPreferences.getInstance();
    final questionsJson = prefs.getStringList(_questionsKey) ?? [];
    return questionsJson.map((json) => Question.fromMap(jsonDecode(json))).toList();
  }

  Future<void> _saveQuestions(List<Question> questions) async {
    final prefs = await SharedPreferences.getInstance();
    final questionsJson = questions.map((question) => jsonEncode(question.toMap())).toList();
    await prefs.setStringList(_questionsKey, questionsJson);
  }

  Future<int> insertQuestion(Question question) async {
    final questions = await _getQuestions();
    final id = await _getNextId();
    final newQuestion = question.copyWith(id: id);
    questions.add(newQuestion);
    await _saveQuestions(questions);
    return id;
  }

  Future<List<Question>> getQuestionsByQuiz(int quizId) async {
    final questions = await _getQuestions();
    return questions.where((question) => question.quizId == quizId).toList();
  }

  Future<void> deleteQuestion(int id) async {
    final questions = await _getQuestions();
    questions.removeWhere((question) => question.id == id);
    await _saveQuestions(questions);
  }

  // Quiz result operations
  Future<List<QuizResult>> _getResults() async {
    final prefs = await SharedPreferences.getInstance();
    final resultsJson = prefs.getStringList(_resultsKey) ?? [];
    return resultsJson.map((json) => QuizResult.fromMap(jsonDecode(json))).toList();
  }

  Future<void> _saveResults(List<QuizResult> results) async {
    final prefs = await SharedPreferences.getInstance();
    final resultsJson = results.map((result) => jsonEncode(result.toMap())).toList();
    await prefs.setStringList(_resultsKey, resultsJson);
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
} 