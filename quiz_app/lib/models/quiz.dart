import 'question.dart';

class Quiz {
  final int? id;
  final String title;
  final String description;
  final int teacherId;
  final int duration; // in minutes
  final bool isActive;
  final DateTime createdAt;
  final List<Question> questions;

  const Quiz({
    this.id,
    required this.title,
    required this.description,
    required this.teacherId,
    required this.duration,
    this.isActive = true,
    required this.createdAt,
    this.questions = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'teacher_id': teacherId,
      'duration': duration,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Quiz.fromMap(Map<String, dynamic> map) {
    return Quiz(
      id: map['id']?.toInt(),
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      teacherId: map['teacher_id']?.toInt() ?? 0,
      duration: map['duration']?.toInt() ?? 0,
      isActive: map['is_active'] == 1,
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  Quiz copyWith({
    int? id,
    String? title,
    String? description,
    int? teacherId,
    int? duration,
    bool? isActive,
    DateTime? createdAt,
    List<Question>? questions,
  }) {
    return Quiz(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      teacherId: teacherId ?? this.teacherId,
      duration: duration ?? this.duration,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      questions: questions ?? this.questions,
    );
  }
} 