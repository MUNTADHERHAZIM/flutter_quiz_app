import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/user.dart';
import '../models/quiz.dart';
import '../models/question.dart';
import '../models/quiz_result.dart';

class DatabaseService {
  static Database? _database;
  static const String _databaseName = 'quiz_app.db';
  static const int _databaseVersion = 1;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final String path = join(await getDatabasesPath(), _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Users table
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        role TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    // Quizzes table
    await db.execute('''
      CREATE TABLE quizzes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT,
        teacher_id INTEGER NOT NULL,
        duration INTEGER NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        FOREIGN KEY (teacher_id) REFERENCES users (id)
      )
    ''');

    // Questions table
    await db.execute('''
      CREATE TABLE questions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        quiz_id INTEGER NOT NULL,
        question TEXT NOT NULL,
        options TEXT NOT NULL,
        correct_answer INTEGER NOT NULL,
        FOREIGN KEY (quiz_id) REFERENCES quizzes (id)
      )
    ''');

    // Quiz results table
    await db.execute('''
      CREATE TABLE quiz_results (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        student_id INTEGER NOT NULL,
        quiz_id INTEGER NOT NULL,
        score INTEGER NOT NULL,
        total_questions INTEGER NOT NULL,
        time_spent INTEGER NOT NULL,
        completed_at TEXT NOT NULL,
        FOREIGN KEY (student_id) REFERENCES users (id),
        FOREIGN KEY (quiz_id) REFERENCES quizzes (id)
      )
    ''');

    // Insert default admin teacher
    await db.insert('users', {
      'name': 'المعلم الافتراضي',
      'email': 'teacher@quiz.com',
      'password': '123456',
      'role': 'teacher',
      'created_at': DateTime.now().toIso8601String(),
    });

    // Insert default student
    await db.insert('users', {
      'name': 'الطالب التجريبي',
      'email': 'student@quiz.com',
      'password': '123456',
      'role': 'student',
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  // User operations
  Future<int> insertUser(User user) async {
    final db = await database;
    return await db.insert('users', user.toMap());
  }

  Future<User?> getUserByEmail(String email) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );
    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  Future<List<User>> getAllUsers() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('users');
    return List.generate(maps.length, (i) => User.fromMap(maps[i]));
  }

  // Quiz operations
  Future<int> insertQuiz(Quiz quiz) async {
    final db = await database;
    return await db.insert('quizzes', quiz.toMap());
  }

  Future<List<Quiz>> getQuizzesByTeacher(int teacherId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'quizzes',
      where: 'teacher_id = ?',
      whereArgs: [teacherId],
      orderBy: 'created_at DESC',
    );
    return List.generate(maps.length, (i) => Quiz.fromMap(maps[i]));
  }

  Future<List<Quiz>> getActiveQuizzes() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'quizzes',
      where: 'is_active = ?',
      whereArgs: [1],
      orderBy: 'created_at DESC',
    );
    return List.generate(maps.length, (i) => Quiz.fromMap(maps[i]));
  }

  Future<Quiz?> getQuizById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'quizzes',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Quiz.fromMap(maps.first);
    }
    return null;
  }

  Future<void> updateQuiz(Quiz quiz) async {
    final db = await database;
    await db.update(
      'quizzes',
      quiz.toMap(),
      where: 'id = ?',
      whereArgs: [quiz.id],
    );
  }

  Future<void> deleteQuiz(int id) async {
    final db = await database;
    await db.delete('quizzes', where: 'id = ?', whereArgs: [id]);
    await db.delete('questions', where: 'quiz_id = ?', whereArgs: [id]);
  }

  // Question operations
  Future<int> insertQuestion(Question question) async {
    final db = await database;
    return await db.insert('questions', question.toMap());
  }

  Future<List<Question>> getQuestionsByQuiz(int quizId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'questions',
      where: 'quiz_id = ?',
      whereArgs: [quizId],
    );
    return List.generate(maps.length, (i) => Question.fromMap(maps[i]));
  }

  Future<void> deleteQuestion(int id) async {
    final db = await database;
    await db.delete('questions', where: 'id = ?', whereArgs: [id]);
  }

  // Quiz result operations
  Future<int> insertQuizResult(QuizResult result) async {
    final db = await database;
    return await db.insert('quiz_results', result.toMap());
  }

  Future<List<QuizResult>> getResultsByStudent(int studentId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'quiz_results',
      where: 'student_id = ?',
      whereArgs: [studentId],
      orderBy: 'completed_at DESC',
    );
    return List.generate(maps.length, (i) => QuizResult.fromMap(maps[i]));
  }

  Future<List<QuizResult>> getResultsByQuiz(int quizId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'quiz_results',
      where: 'quiz_id = ?',
      whereArgs: [quizId],
      orderBy: 'completed_at DESC',
    );
    return List.generate(maps.length, (i) => QuizResult.fromMap(maps[i]));
  }

  Future<bool> hasStudentTakenQuiz(int studentId, int quizId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'quiz_results',
      where: 'student_id = ? AND quiz_id = ?',
      whereArgs: [studentId, quizId],
    );
    return maps.isNotEmpty;
  }
} 