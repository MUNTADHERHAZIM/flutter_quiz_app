import 'package:flutter/material.dart';
import 'quiz_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(' مرحبا بكم في نظام لاختبارات ')),
      body: Center(
        child: ElevatedButton(
          child: const Text('ابدأ الاختبار'),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => QuizScreen()),
            );
          },
        ),
      ),
    );
  }
}
