import 'package:flutter/material.dart';
import '../models/question.dart';
import 'result_screen.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  QuizScreenState createState() => QuizScreenState();
}

class QuizScreenState extends State<QuizScreen> {
  int currentQuestion = 0;
  int score = 0;
  List<int?> selectedAnswers = [null, null, null];

  final List<Question> questions = [
    Question(
      question: 'ما عاصمة العراق؟',
      options: ['بغداد', 'البصرة', 'أربيل'],
      correctAnswer: 0,
    ),
    Question(
      question: 'ما هو ناتج 5 × 3؟',
      options: ['8', '15', '10'],
      correctAnswer: 1,
    ),
    Question(
      question: 'ما لون السماء؟',
      options: ['أزرق', 'أخضر', 'أحمر'],
      correctAnswer: 0,
    ),
  ];

  void nextQuestion() {
    if (selectedAnswers[currentQuestion] == questions[currentQuestion].correctAnswer) {
      score++;
    }
    if (currentQuestion < questions.length - 1) {
      setState(() {
        currentQuestion++;
      });
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ResultScreen(score: score, total: questions.length),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final Question currentQ = questions[currentQuestion];
    return Scaffold(
      appBar: AppBar(title: Text('السؤال ${currentQuestion + 1}')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(currentQ.question, style: const TextStyle(fontSize: 20)),
          ),
          ...List.generate(currentQ.options.length, (index) {
            return RadioListTile<int>(
              title: Text(currentQ.options[index]),
              value: index,
              groupValue: selectedAnswers[currentQuestion],
              onChanged: (value) {
                setState(() {
                  selectedAnswers[currentQuestion] = value;
                });
              },
            );
          }),
          ElevatedButton(
            onPressed: selectedAnswers[currentQuestion] != null ? nextQuestion : null,
            child: const Text('التالي'),
          ),
        ],
      ),
    );
  }
}
