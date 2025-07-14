class QuizResult {
  final int? id;
  final int studentId;
  final int quizId;
  final int score;
  final int totalQuestions;
  final int timeSpent; // in seconds
  final DateTime completedAt;

  const QuizResult({
    this.id,
    required this.studentId,
    required this.quizId,
    required this.score,
    required this.totalQuestions,
    required this.timeSpent,
    required this.completedAt,
  });

  double get percentage => (score / totalQuestions) * 100;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'student_id': studentId,
      'quiz_id': quizId,
      'score': score,
      'total_questions': totalQuestions,
      'time_spent': timeSpent,
      'completed_at': completedAt.toIso8601String(),
    };
  }

  factory QuizResult.fromMap(Map<String, dynamic> map) {
    return QuizResult(
      id: map['id']?.toInt(),
      studentId: map['student_id']?.toInt() ?? 0,
      quizId: map['quiz_id']?.toInt() ?? 0,
      score: map['score']?.toInt() ?? 0,
      totalQuestions: map['total_questions']?.toInt() ?? 0,
      timeSpent: map['time_spent']?.toInt() ?? 0,
      completedAt: DateTime.parse(map['completed_at']),
    );
  }
} 