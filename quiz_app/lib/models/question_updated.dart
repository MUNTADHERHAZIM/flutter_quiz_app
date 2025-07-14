enum QuestionType {
  multipleChoice,    // اختيار من متعدد
  trueFalse,        // صح أم خطأ
  fillInBlank,      // ملء الفراغات
  shortAnswer,      // إجابة قصيرة
}

class QuestionUpdated {
  final int? id;
  final int? quizId;
  final String question;
  final QuestionType type;
  final List<String> options; // للاختيار من متعدد
  final List<int> correctAnswers; // يمكن أن تكون متعددة
  final String? correctText; // للإجابة القصيرة وملء الفراغات
  final int points; // النقاط لكل سؤال
  final String? explanation; // شرح الإجابة (اختياري)

  const QuestionUpdated({
    this.id,
    this.quizId,
    required this.question,
    required this.type,
    this.options = const [],
    this.correctAnswers = const [],
    this.correctText,
    this.points = 1,
    this.explanation,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'quiz_id': quizId,
      'question': question,
      'type': type.name,
      'options': options.join('|'),
      'correct_answers': correctAnswers.join(','),
      'correct_text': correctText,
      'points': points,
      'explanation': explanation,
    };
  }

  factory QuestionUpdated.fromMap(Map<String, dynamic> map) {
    return QuestionUpdated(
      id: map['id']?.toInt(),
      quizId: map['quiz_id']?.toInt(),
      question: map['question'] ?? '',
      type: QuestionType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => QuestionType.multipleChoice,
      ),
      options: map['options'] != null && map['options'].isNotEmpty
          ? map['options'].split('|')
          : [],
      correctAnswers: map['correct_answers'] != null && map['correct_answers'].isNotEmpty
          ? map['correct_answers'].split(',').map<int>((e) => int.parse(e)).toList()
          : [],
      correctText: map['correct_text'],
      points: map['points']?.toInt() ?? 1,
      explanation: map['explanation'],
    );
  }

  QuestionUpdated copyWith({
    int? id,
    int? quizId,
    String? question,
    QuestionType? type,
    List<String>? options,
    List<int>? correctAnswers,
    String? correctText,
    int? points,
    String? explanation,
  }) {
    return QuestionUpdated(
      id: id ?? this.id,
      quizId: quizId ?? this.quizId,
      question: question ?? this.question,
      type: type ?? this.type,
      options: options ?? this.options,
      correctAnswers: correctAnswers ?? this.correctAnswers,
      correctText: correctText ?? this.correctText,
      points: points ?? this.points,
      explanation: explanation ?? this.explanation,
    );
  }

  // Helper methods
  bool isCorrectAnswer(List<int> selectedAnswers, String? textAnswer) {
    switch (type) {
      case QuestionType.multipleChoice:
        return selectedAnswers.isNotEmpty && 
               correctAnswers.isNotEmpty &&
               selectedAnswers.first == correctAnswers.first;
      
      case QuestionType.trueFalse:
        return selectedAnswers.isNotEmpty && 
               correctAnswers.isNotEmpty &&
               selectedAnswers.first == correctAnswers.first;
      
      case QuestionType.fillInBlank:
      case QuestionType.shortAnswer:
        return textAnswer != null &&
               correctText != null &&
               textAnswer.trim().toLowerCase() == correctText!.trim().toLowerCase();
      
      default:
        return false;
    }
  }

  String getTypeDisplayName() {
    switch (type) {
      case QuestionType.multipleChoice:
        return 'اختيار من متعدد';
      case QuestionType.trueFalse:
        return 'صح أم خطأ';
      case QuestionType.fillInBlank:
        return 'ملء الفراغات';
      case QuestionType.shortAnswer:
        return 'إجابة قصيرة';
    }
  }
} 