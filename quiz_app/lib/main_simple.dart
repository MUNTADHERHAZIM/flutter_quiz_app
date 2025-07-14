import 'package:flutter/material.dart';

void main() {
  runApp(const SimpleQuizApp());
}

class SimpleQuizApp extends StatelessWidget {
  const SimpleQuizApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'نظام إدارة الاختبارات',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Arial',
      ),
      home: const SimpleHomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class SimpleHomeScreen extends StatelessWidget {
  const SimpleHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('نظام إدارة الاختبارات'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.quiz,
              size: 100,
              color: Colors.blue,
            ),
            SizedBox(height: 20),
            Text(
              'مرحباً بك في نظام إدارة الاختبارات',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 10),
            Text(
              'النظام يعمل بنجاح!',
              style: TextStyle(
                fontSize: 16,
                color: Colors.green,
              ),
            ),
            SizedBox(height: 30),
            Text(
              'للوصول للنظام الكامل، تأكد من:',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text('1. تفعيل Developer Mode في Windows'),
            Text('2. تشغيل flutter run بدون مشاكل الذاكرة'),
            Text('3. استخدام main.dart الأساسي'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('النظام جاهز للاستخدام!'),
              backgroundColor: Colors.green,
            ),
          );
        },
        child: const Icon(Icons.check),
      ),
    );
  }
} 