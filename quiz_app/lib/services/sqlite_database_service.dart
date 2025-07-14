import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../models/user.dart';
import '../models/quiz.dart';
import '../models/question_updated.dart';
import '../models/quiz_result.dart';

class SQLiteDatabaseService {
  static final SQLiteDatabaseService _instance = SQLiteDatabaseService._internal();
  factory SQLiteDatabaseService() => _instance;
  SQLiteDatabaseService._internal();

  static Database? _database;
  
  // Database version for migrations
  static const int _databaseVersion = 1;
  static const String _databaseName = 'quiz_app_pro.db';

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, _databaseName);
    
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _createTables,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _createTables(Database db, int version) async {
    await _createUsersTable(db);
    await _createSubjectsTable(db);
    await _createQuizzesTable(db);
    await _createQuestionsTable(db);
    await _createQuizResultsTable(db);
    await _createQuestionBankTable(db);
    await _createTagsTable(db);
    await _createQuestionTagsTable(db);
    await _createQuizAttemptsTable(db);
    await _createSystemSettingsTable(db);
    
    // إدراج البيانات الأولية
    await _insertInitialData(db);
  }

  Future<void> _createUsersTable(Database db) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        email TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        name TEXT NOT NULL,
        role TEXT NOT NULL CHECK (role IN ('admin', 'teacher', 'student')),
        avatar_url TEXT,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        last_login DATETIME,
        is_active INTEGER DEFAULT 1,
        phone TEXT,
        department TEXT,
        student_id TEXT,
        teacher_id TEXT
      )
    ''');
  }

  Future<void> _createSubjectsTable(Database db) async {
    await db.execute('''
      CREATE TABLE subjects (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        code TEXT UNIQUE NOT NULL,
        description TEXT,
        color TEXT DEFAULT '#2196F3',
        icon TEXT DEFAULT 'book',
        created_by INTEGER,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        is_active INTEGER DEFAULT 1,
        FOREIGN KEY (created_by) REFERENCES users (id)
      )
    ''');
  }

  Future<void> _createQuizzesTable(Database db) async {
    await db.execute('''
      CREATE TABLE quizzes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT,
        subject_id INTEGER,
        teacher_id INTEGER NOT NULL,
        duration INTEGER NOT NULL DEFAULT 30,
        total_points INTEGER DEFAULT 0,
        pass_percentage REAL DEFAULT 60.0,
        attempts_allowed INTEGER DEFAULT 1,
        is_active INTEGER DEFAULT 1,
        is_published INTEGER DEFAULT 0,
        start_date DATETIME,
        end_date DATETIME,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        instructions TEXT,
        show_results_immediately INTEGER DEFAULT 1,
        shuffle_questions INTEGER DEFAULT 0,
        shuffle_answers INTEGER DEFAULT 0,
        FOREIGN KEY (subject_id) REFERENCES subjects (id),
        FOREIGN KEY (teacher_id) REFERENCES users (id)
      )
    ''');
  }

  Future<void> _createQuestionsTable(Database db) async {
    await db.execute('''
      CREATE TABLE questions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        quiz_id INTEGER,
        question_bank_id INTEGER,
        question_text TEXT NOT NULL,
        question_type TEXT NOT NULL CHECK (question_type IN ('multipleChoice', 'trueFalse', 'fillInBlank', 'shortAnswer', 'essay', 'matching')),
        options TEXT, -- JSON array for multiple choice options
        correct_answers TEXT, -- JSON array of correct answer indices
        correct_text TEXT, -- For text-based answers
        points INTEGER DEFAULT 1,
        explanation TEXT,
        hint TEXT,
        difficulty_level TEXT DEFAULT 'medium' CHECK (difficulty_level IN ('easy', 'medium', 'hard')),
        time_limit INTEGER, -- in seconds, optional per question
        image_url TEXT,
        audio_url TEXT,
        video_url TEXT,
        order_index INTEGER DEFAULT 0,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (quiz_id) REFERENCES quizzes (id) ON DELETE CASCADE,
        FOREIGN KEY (question_bank_id) REFERENCES question_bank (id)
      )
    ''');
  }

  Future<void> _createQuizResultsTable(Database db) async {
    await db.execute('''
      CREATE TABLE quiz_results (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        student_id INTEGER NOT NULL,
        quiz_id INTEGER NOT NULL,
        attempt_number INTEGER DEFAULT 1,
        score INTEGER NOT NULL,
        total_points INTEGER NOT NULL,
        percentage REAL NOT NULL,
        time_spent INTEGER NOT NULL, -- in seconds
        completed_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        started_at DATETIME,
        answers TEXT, -- JSON of all answers
        is_completed INTEGER DEFAULT 1,
        ip_address TEXT,
        user_agent TEXT,
        FOREIGN KEY (student_id) REFERENCES users (id),
        FOREIGN KEY (quiz_id) REFERENCES quizzes (id)
      )
    ''');
  }

  Future<void> _createQuestionBankTable(Database db) async {
    await db.execute('''
      CREATE TABLE question_bank (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        subject_id INTEGER,
        created_by INTEGER NOT NULL,
        question_text TEXT NOT NULL,
        question_type TEXT NOT NULL CHECK (question_type IN ('multipleChoice', 'trueFalse', 'fillInBlank', 'shortAnswer', 'essay', 'matching')),
        options TEXT, -- JSON array
        correct_answers TEXT, -- JSON array
        correct_text TEXT,
        points INTEGER DEFAULT 1,
        explanation TEXT,
        hint TEXT,
        difficulty_level TEXT DEFAULT 'medium' CHECK (difficulty_level IN ('easy', 'medium', 'hard')),
        usage_count INTEGER DEFAULT 0,
        success_rate REAL DEFAULT 0.0,
        image_url TEXT,
        audio_url TEXT,
        video_url TEXT,
        is_public INTEGER DEFAULT 0, -- Can be used by other teachers
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        last_used DATETIME,
        FOREIGN KEY (subject_id) REFERENCES subjects (id),
        FOREIGN KEY (created_by) REFERENCES users (id)
      )
    ''');
  }

  Future<void> _createTagsTable(Database db) async {
    await db.execute('''
      CREATE TABLE tags (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT UNIQUE NOT NULL,
        color TEXT DEFAULT '#9E9E9E',
        description TEXT,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    ''');
  }

  Future<void> _createQuestionTagsTable(Database db) async {
    await db.execute('''
      CREATE TABLE question_tags (
        question_bank_id INTEGER,
        tag_id INTEGER,
        PRIMARY KEY (question_bank_id, tag_id),
        FOREIGN KEY (question_bank_id) REFERENCES question_bank (id) ON DELETE CASCADE,
        FOREIGN KEY (tag_id) REFERENCES tags (id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _createQuizAttemptsTable(Database db) async {
    await db.execute('''
      CREATE TABLE quiz_attempts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        student_id INTEGER NOT NULL,
        quiz_id INTEGER NOT NULL,
        attempt_number INTEGER NOT NULL,
        started_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        ended_at DATETIME,
        current_question INTEGER DEFAULT 0,
        answers TEXT, -- JSON of answers so far
        is_completed INTEGER DEFAULT 0,
        time_remaining INTEGER,
        FOREIGN KEY (student_id) REFERENCES users (id),
        FOREIGN KEY (quiz_id) REFERENCES quizzes (id)
      )
    ''');
  }

  Future<void> _createSystemSettingsTable(Database db) async {
    await db.execute('''
      CREATE TABLE system_settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL,
        description TEXT,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle database migrations here
    if (oldVersion < 2) {
      // Add new columns or tables for version 2
    }
  }

  Future<void> _insertInitialData(Database db) async {
    // إدراج المستخدم الإداري
    await db.insert('users', {
      'email': 'admin@quiz.com',
      'password': 'admin123', // في الإنتاج يجب تشفير كلمة المرور
      'name': 'مدير النظام',
      'role': 'admin',
      'created_at': DateTime.now().toIso8601String(),
    });

    // إدراج معلم تجريبي
    await db.insert('users', {
      'email': 'teacher@quiz.com',
      'password': '123456',
      'name': 'أحمد محمد - معلم الرياضيات',
      'role': 'teacher',
      'department': 'الرياضيات',
      'teacher_id': 'T001',
      'created_at': DateTime.now().toIso8601String(),
    });

    // إدراج طالب تجريبي
    await db.insert('users', {
      'email': 'student@quiz.com',
      'password': '123456',
      'name': 'فاطمة أحمد - طالبة',
      'role': 'student',
      'student_id': 'S001',
      'created_at': DateTime.now().toIso8601String(),
    });

    // إدراج المواد الدراسية
    final subjects = [
      {'name': 'الرياضيات', 'code': 'MATH', 'color': '#FF5722', 'icon': 'calculate'},
      {'name': 'العلوم', 'code': 'SCI', 'color': '#4CAF50', 'icon': 'science'},
      {'name': 'اللغة العربية', 'code': 'AR', 'color': '#3F51B5', 'icon': 'language'},
      {'name': 'اللغة الإنجليزية', 'code': 'EN', 'color': '#FF9800', 'icon': 'translate'},
      {'name': 'التاريخ', 'code': 'HIST', 'color': '#8BC34A', 'icon': 'history_edu'},
      {'name': 'الجغرافيا', 'code': 'GEO', 'color': '#009688', 'icon': 'public'},
    ];

    for (final subject in subjects) {
      await db.insert('subjects', {
        ...subject,
        'created_by': 1,
        'created_at': DateTime.now().toIso8601String(),
      });
    }

    // إدراج التصنيفات (Tags)
    final tags = [
      {'name': 'أساسي', 'color': '#4CAF50'},
      {'name': 'متقدم', 'color': '#FF5722'},
      {'name': 'مراجعة', 'color': '#2196F3'},
      {'name': 'امتحان', 'color': '#F44336'},
      {'name': 'واجب', 'color': '#FF9800'},
      {'name': 'تدريب', 'color': '#9C27B0'},
    ];

    for (final tag in tags) {
      await db.insert('tags', {
        ...tag,
        'created_at': DateTime.now().toIso8601String(),
      });
    }

    // إدراج أسئلة متنوعة في بنك الأسئلة
    await _insertSampleQuestions(db);

    // إدراج اختبار تجريبي
    await _insertSampleQuiz(db);

    // إعدادات النظام
    final settings = [
      {'key': 'app_name', 'value': 'نظام إدارة الاختبارات المتقدم', 'description': 'اسم التطبيق'},
      {'key': 'max_attempts', 'value': '3', 'description': 'الحد الأقصى لمحاولات الاختبار'},
      {'key': 'session_timeout', 'value': '30', 'description': 'مهلة انتهاء الجلسة بالدقائق'},
      {'key': 'auto_save', 'value': 'true', 'description': 'الحفظ التلقائي للإجابات'},
    ];

    for (final setting in settings) {
      await db.insert('system_settings', {
        ...setting,
        'updated_at': DateTime.now().toIso8601String(),
      });
    }
  }

  Future<void> _insertSampleQuestions(Database db) async {
    // أسئلة الرياضيات
    final mathQuestions = [
      {
        'subject_id': 1,
        'created_by': 2,
        'question_text': 'ما هو ناتج 15 + 28؟',
        'question_type': 'multipleChoice',
        'options': '["43", "42", "44", "41"]',
        'correct_answers': '[0]',
        'points': 2,
        'explanation': 'نجمع الأرقام: 15 + 28 = 43',
        'difficulty_level': 'easy',
      },
      {
        'subject_id': 1,
        'created_by': 2,
        'question_text': 'هل العدد 17 عدد أولي؟',
        'question_type': 'trueFalse',
        'correct_answers': '[0]',
        'points': 3,
        'explanation': 'العدد 17 أولي لأنه لا يقبل القسمة إلا على نفسه وعلى الواحد',
        'difficulty_level': 'medium',
      },
      {
        'subject_id': 1,
        'created_by': 2,
        'question_text': 'أكمل المعادلة: x² + 5x + 6 = (x + 2)(x + ___)',
        'question_type': 'fillInBlank',
        'correct_text': '3',
        'points': 4,
        'explanation': 'نحلل المعادلة: x² + 5x + 6 = (x + 2)(x + 3)',
        'difficulty_level': 'hard',
        'hint': 'فكر في العددين اللذين حاصل ضربهما 6 ومجموعهما 5',
      },
      {
        'subject_id': 1,
        'created_by': 2,
        'question_text': 'اشرح قانون فيثاغورس وكيفية تطبيقه',
        'question_type': 'shortAnswer',
        'correct_text': 'في المثلث القائم الزاوية، مربع الوتر يساوي مجموع مربعي الضلعين الآخرين',
        'points': 5,
        'explanation': 'قانون فيثاغورس: a² + b² = c² حيث c هو الوتر',
        'difficulty_level': 'medium',
      },
    ];

    // أسئلة العلوم
    final scienceQuestions = [
      {
        'subject_id': 2,
        'created_by': 2,
        'question_text': 'ما هو الرمز الكيميائي للماء؟',
        'question_type': 'multipleChoice',
        'options': '["H2O", "CO2", "NaCl", "O2"]',
        'correct_answers': '[0]',
        'points': 2,
        'explanation': 'الماء يتكون من ذرتين هيدروجين وذرة أكسجين واحدة',
        'difficulty_level': 'easy',
      },
      {
        'subject_id': 2,
        'created_by': 2,
        'question_text': 'هل الشمس نجم؟',
        'question_type': 'trueFalse',
        'correct_answers': '[0]',
        'points': 2,
        'explanation': 'الشمس هي النجم الأقرب إلى الأرض',
        'difficulty_level': 'easy',
      },
      {
        'subject_id': 2,
        'created_by': 2,
        'question_text': 'كم عدد الكواكب في النظام الشمسي؟',
        'question_type': 'fillInBlank',
        'correct_text': '8',
        'points': 3,
        'explanation': 'النظام الشمسي يحتوي على 8 كواكب بعد إعادة تصنيف بلوتو',
        'difficulty_level': 'medium',
      },
    ];

    // أسئلة اللغة العربية
    final arabicQuestions = [
      {
        'subject_id': 3,
        'created_by': 2,
        'question_text': 'ما إعراب كلمة "طالب" في جملة "جاء طالب مجتهد"؟',
        'question_type': 'multipleChoice',
        'options': '["فاعل مرفوع", "مفعول به منصوب", "مبتدأ مرفوع", "خبر مرفوع"]',
        'correct_answers': '[0]',
        'points': 3,
        'explanation': 'طالب فاعل مرفوع وعلامة رفعه الضمة الظاهرة',
        'difficulty_level': 'medium',
      },
      {
        'subject_id': 3,
        'created_by': 2,
        'question_text': 'هل "إن" حرف ناسخ؟',
        'question_type': 'trueFalse',
        'correct_answers': '[0]',
        'points': 2,
        'explanation': 'إن من الحروف الناسخة التي تنصب المبتدأ وترفع الخبر',
        'difficulty_level': 'easy',
      },
    ];

    // إدراج الأسئلة
    final allQuestions = [...mathQuestions, ...scienceQuestions, ...arabicQuestions];
    
    for (final question in allQuestions) {
      final questionId = await db.insert('question_bank', {
        ...question,
        'created_at': DateTime.now().toIso8601String(),
      });

      // ربط الأسئلة بالتصنيفات
      if (question['difficulty_level'] == 'easy') {
        await db.insert('question_tags', {'question_bank_id': questionId, 'tag_id': 1});
      } else if (question['difficulty_level'] == 'hard') {
        await db.insert('question_tags', {'question_bank_id': questionId, 'tag_id': 2});
      }
    }
  }

  Future<void> _insertSampleQuiz(Database db) async {
    // إنشاء اختبار تجريبي
    final quizId = await db.insert('quizzes', {
      'title': 'اختبار شامل - الرياضيات والعلوم',
      'description': 'اختبار تجريبي يحتوي على أسئلة متنوعة في الرياضيات والعلوم',
      'subject_id': 1,
      'teacher_id': 2,
      'duration': 30,
      'total_points': 20,
      'pass_percentage': 70.0,
      'is_active': 1,
      'is_published': 1,
      'instructions': 'اقرأ الأسئلة بعناية واختر الإجابة الصحيحة. لديك 30 دقيقة لإنهاء الاختبار.',
      'created_at': DateTime.now().toIso8601String(),
    });

    // ربط أسئلة من بنك الأسئلة بالاختبار
    final selectedQuestions = [1, 2, 3, 5, 6]; // IDs من بنك الأسئلة
    
    for (int i = 0; i < selectedQuestions.length; i++) {
      final questionBankId = selectedQuestions[i];
      final questionData = await db.query(
        'question_bank',
        where: 'id = ?',
        whereArgs: [questionBankId],
      );
      
      if (questionData.isNotEmpty) {
        final question = questionData.first;
        await db.insert('questions', {
          'quiz_id': quizId,
          'question_bank_id': questionBankId,
          'question_text': question['question_text'],
          'question_type': question['question_type'],
          'options': question['options'],
          'correct_answers': question['correct_answers'],
          'correct_text': question['correct_text'],
          'points': question['points'],
          'explanation': question['explanation'],
          'hint': question['hint'],
          'difficulty_level': question['difficulty_level'],
          'order_index': i,
          'created_at': DateTime.now().toIso8601String(),
        });
      }
    }
  }

  // Methods for data operations
  Future<List<Map<String, dynamic>>> getUsers() async {
    final db = await database;
    return await db.query('users', where: 'is_active = ?', whereArgs: [1]);
  }

  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    final db = await database;
    final results = await db.query(
      'users',
      where: 'email = ? AND is_active = ?',
      whereArgs: [email, 1],
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<List<Map<String, dynamic>>> getSubjects() async {
    final db = await database;
    return await db.query('subjects', where: 'is_active = ?', whereArgs: [1]);
  }

  Future<List<Map<String, dynamic>>> getQuizzes({int? teacherId}) async {
    final db = await database;
    if (teacherId != null) {
      return await db.query(
        'quizzes',
        where: 'teacher_id = ? AND is_active = ?',
        whereArgs: [teacherId, 1],
        orderBy: 'created_at DESC',
      );
    }
    return await db.query(
      'quizzes',
      where: 'is_active = ? AND is_published = ?',
      whereArgs: [1, 1],
      orderBy: 'created_at DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getQuestionBank({
    int? subjectId,
    String? difficulty,
    String? questionType,
    int? createdBy,
  }) async {
    final db = await database;
    String where = '1=1';
    List<dynamic> whereArgs = [];

    if (subjectId != null) {
      where += ' AND subject_id = ?';
      whereArgs.add(subjectId);
    }
    if (difficulty != null) {
      where += ' AND difficulty_level = ?';
      whereArgs.add(difficulty);
    }
    if (questionType != null) {
      where += ' AND question_type = ?';
      whereArgs.add(questionType);
    }
    if (createdBy != null) {
      where += ' AND (created_by = ? OR is_public = 1)';
      whereArgs.add(createdBy);
    }

    return await db.query(
      'question_bank',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'created_at DESC',
    );
  }

  Future<int> insertQuestionToBank(Map<String, dynamic> question) async {
    final db = await database;
    question['created_at'] = DateTime.now().toIso8601String();
    question['updated_at'] = DateTime.now().toIso8601String();
    return await db.insert('question_bank', question);
  }

  Future<void> updateQuestionInBank(int id, Map<String, dynamic> question) async {
    final db = await database;
    question['updated_at'] = DateTime.now().toIso8601String();
    await db.update(
      'question_bank',
      question,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteQuestionFromBank(int id) async {
    final db = await database;
    await db.delete('question_bank', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> searchQuestions(String searchTerm) async {
    final db = await database;
    return await db.query(
      'question_bank',
      where: 'question_text LIKE ?',
      whereArgs: ['%$searchTerm%'],
      orderBy: 'usage_count DESC, created_at DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getQuestionsByQuiz(int quizId) async {
    final db = await database;
    return await db.query(
      'questions',
      where: 'quiz_id = ?',
      whereArgs: [quizId],
      orderBy: 'order_index ASC',
    );
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }

  // Statistics methods
  Future<Map<String, int>> getSystemStats() async {
    final db = await database;
    
    final userCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM users WHERE is_active = 1')) ?? 0;
    final quizCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM quizzes WHERE is_active = 1')) ?? 0;
    final questionCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM question_bank')) ?? 0;
    final resultCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM quiz_results')) ?? 0;
    
    return {
      'users': userCount,
      'quizzes': quizCount,
      'questions': questionCount,
      'results': resultCount,
    };
  }
} 