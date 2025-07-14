import 'package:flutter/material.dart';

void main() {
  runApp(const EmergencyQuizApp());
}

class EmergencyQuizApp extends StatelessWidget {
  const EmergencyQuizApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'نظام إدارة الاختبارات - وضع الطوارئ',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        // تقليل استهلاك الموارد
        visualDensity: VisualDensity.compact,
        // إزالة جميع الرسوم المتحركة لتوفير الموارد
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
          },
        ),
      ),
      home: const EmergencyHomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class EmergencyHomeScreen extends StatelessWidget {
  const EmergencyHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('نظام إدارة الاختبارات - وضع الطوارئ'),
        backgroundColor: Colors.red[400],
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // أيقونة تحذير
              Icon(
                Icons.warning_amber_rounded,
                size: 80,
                color: Colors.orange[600],
              ),
              const SizedBox(height: 20),
              
              // رسالة الحالة
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        'وضع الطوارئ',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.red[700],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'تم تشغيل النسخة المبسطة لحل مشكلة استهلاك الموارد',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[700],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 30),
              
              // معلومات النظام
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info, color: Colors.blue[600]),
                          const SizedBox(width: 8),
                          Text(
                            'معلومات النظام',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[700],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow('النسخة:', 'طوارئ 1.0'),
                      _buildInfoRow('الحالة:', 'آمن'),
                      _buildInfoRow('استهلاك الذاكرة:', 'منخفض'),
                      _buildInfoRow('استهلاك المعالج:', 'أدنى حد'),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 30),
              
              // إرشادات الحل
              Card(
                color: Colors.green[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.build, color: Colors.green[600]),
                          const SizedBox(width: 8),
                          Text(
                            'خطوات الحل',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[700],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildSolutionStep('1', 'أعد تشغيل الحاسوب'),
                      _buildSolutionStep('2', 'أغلق البرامج غير الضرورية'),
                      _buildSolutionStep('3', 'زد ذاكرة التخزين المؤقت'),
                      _buildSolutionStep('4', 'استخدم هذه النسخة المبسطة'),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 30),
              
              // أزرار الإجراءات
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _showSystemInfo(context),
                      icon: const Icon(Icons.computer),
                      label: const Text('فحص النظام'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _showMemoryTips(context),
                      icon: const Icon(Icons.memory),
                      label: const Text('نصائح توفير الذاكرة'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _testBasicFeatures(context),
                      icon: const Icon(Icons.play_circle),
                      label: const Text('اختبار بسيط'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildSolutionStep(String step, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.green[600],
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                step,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              description,
              style: TextStyle(color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }

  void _showSystemInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('معلومات النظام'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('• Flutter: نسخة آمنة'),
              Text('• Dart: محدود الموارد'),
              Text('• المتصفح: Edge/Chrome'),
              Text('• الحالة: مستقر'),
              SizedBox(height: 12),
              Text(
                'هذه النسخة تستخدم أقل قدر من الموارد',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('موافق'),
          ),
        ],
      ),
    );
  }

  void _showMemoryTips(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('نصائح توفير الذاكرة'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('1. أغلق علامات التبويب الأخرى'),
              Text('2. أعد تشغيل المتصفح'),
              Text('3. امسح cache المتصفح'),
              Text('4. أغلق البرامج الثقيلة'),
              Text('5. تأكد من وجود ذاكرة كافية (4GB+)'),
              SizedBox(height: 12),
              Text(
                'إذا استمرت المشكلة، استخدم flutter run --release',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('فهمت'),
          ),
        ],
      ),
    );
  }

  void _testBasicFeatures(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SimpleTestScreen(),
      ),
    );
  }
}

class SimpleTestScreen extends StatefulWidget {
  const SimpleTestScreen({super.key});

  @override
  State<SimpleTestScreen> createState() => _SimpleTestScreenState();
}

class _SimpleTestScreenState extends State<SimpleTestScreen> {
  int _currentQuestion = 0;
  int _score = 0;
  
  final List<Map<String, dynamic>> _questions = [
    {
      'question': 'ما هو 2 + 2؟',
      'options': ['3', '4', '5'],
      'correct': 1,
    },
    {
      'question': 'ما عاصمة العراق؟',
      'options': ['بغداد', 'البصرة', 'أربيل'],
      'correct': 0,
    },
    {
      'question': 'كم عدد أيام الأسبوع؟',
      'options': ['6', '7', '8'],
      'correct': 1,
    },
  ];

  void _selectAnswer(int selectedIndex) {
    if (selectedIndex == _questions[_currentQuestion]['correct']) {
      _score++;
    }

    if (_currentQuestion < _questions.length - 1) {
      setState(() {
        _currentQuestion++;
      });
    } else {
      _showResult();
    }
  }

  void _showResult() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('النتيجة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _score >= 2 ? Icons.emoji_events : Icons.thumb_up,
              size: 64,
              color: _score >= 2 ? Colors.amber : Colors.blue, // تم تغيير Colors.gold إلى Colors.amber
            ),
            const SizedBox(height: 16),
            Text(
              'النتيجة: $_score من ${_questions.length}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              _score >= 2 ? 'ممتاز!' : 'جيد!',
              style: TextStyle(
                fontSize: 16,
                color: _score >= 2 ? Colors.green : Colors.blue,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('العودة'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final question = _questions[_currentQuestion];
    
    return Scaffold(
      appBar: AppBar(
        title: Text('السؤال ${_currentQuestion + 1}'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // شريط التقدم
            LinearProgressIndicator(
              value: (_currentQuestion + 1) / _questions.length,
              backgroundColor: Colors.grey[300],
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
            ),
            const SizedBox(height: 30),
            
            // السؤال
            Text(
              question['question'],
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 30),
            
            // الخيارات
            ...List.generate(
              question['options'].length,
              (index) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _selectAnswer(index),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[50],
                      foregroundColor: Colors.blue[800],
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: Colors.blue[300]!),
                    ),
                    child: Text(
                      question['options'][index],
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 