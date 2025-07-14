class Question {
  final int? id;
  final int? quizId;
  final String question;
  final List<String> options;
  final int correctAnswer;

  const Question({
    this.id,
    this.quizId,
    required this.question,
    required this.options,
    required this.correctAnswer,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'quiz_id': quizId,
      'question': question,
      'options': options.join('|'), // Join options with delimiter
      'correct_answer': correctAnswer,
    };
  }

  factory Question.fromMap(Map<String, dynamic> map) {
    return Question(
      id: map['id']?.toInt(),
      quizId: map['quiz_id']?.toInt(),
      question: map['question'] ?? '',
      options: (map['options'] ?? '').split('|'), // Split options by delimiter
      correctAnswer: map['correct_answer']?.toInt() ?? 0,
    );
  }

  Question copyWith({
    int? id,
    int? quizId,
    String? question,
    List<String>? options,
    int? correctAnswer,
  }) {
    return Question(
      id: id ?? this.id,
      quizId: quizId ?? this.quizId,
      question: question ?? this.question,
      options: options ?? this.options,
      correctAnswer: correctAnswer ?? this.correctAnswer,
    );
  }
}
