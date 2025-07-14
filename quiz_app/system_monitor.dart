import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';

class SystemMonitor extends StatefulWidget {
  const SystemMonitor({super.key});

  @override
  State<SystemMonitor> createState() => _SystemMonitorState();
}

class _SystemMonitorState extends State<SystemMonitor> {
  Timer? _timer;
  String _memoryUsage = 'جاري القياس...';
  String _cpuUsage = 'جاري القياس...';
  Color _warningColor = Colors.green;
  bool _isDangerous = false;

  @override
  void initState() {
    super.initState();
    _startMonitoring();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startMonitoring() {
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _checkSystemResources();
    });
  }

  Future<void> _checkSystemResources() async {
    try {
      // محاولة قياس استهلاك الذاكرة (تقديري)
      final memoryInfo = await _getMemoryInfo();
      final cpuInfo = await _getCPUInfo();
      
      setState(() {
        _memoryUsage = memoryInfo;
        _cpuUsage = cpuInfo;
        _updateWarningLevel();
      });
    } catch (e) {
      setState(() {
        _memoryUsage = 'خطأ في القياس';
        _cpuUsage = 'خطأ في القياس';
      });
    }
  }

  Future<String> _getMemoryInfo() async {
    try {
      if (Platform.isWindows) {
        // أمر Windows لقياس الذاكرة
        final result = await Process.run('wmic', [
          'OS',
          'get',
          'TotalVisibleMemorySize,FreePhysicalMemory',
          '/value'
        ]);
        
        if (result.exitCode == 0) {
          final output = result.stdout.toString();
          final lines = output.split('\n').where((line) => line.contains('=')).toList();
          
          int totalMemory = 0;
          int freeMemory = 0;
          
          for (final line in lines) {
            if (line.contains('TotalVisibleMemorySize=')) {
              totalMemory = int.tryParse(line.split('=')[1].trim()) ?? 0;
            }
            if (line.contains('FreePhysicalMemory=')) {
              freeMemory = int.tryParse(line.split('=')[1].trim()) ?? 0;
            }
          }
          
          if (totalMemory > 0 && freeMemory > 0) {
            final usedMemory = totalMemory - freeMemory;
            final usagePercent = (usedMemory / totalMemory * 100).round();
            final usedGB = (usedMemory / 1024 / 1024).toStringAsFixed(1);
            final totalGB = (totalMemory / 1024 / 1024).toStringAsFixed(1);
            
            return 'الذاكرة: $usedGB/${totalGB}GB ($usagePercent%)';
          }
        }
      }
      
      return 'مراقبة تقديرية نشطة';
    } catch (e) {
      return 'خطأ في قياس الذاكرة';
    }
  }

  Future<String> _getCPUInfo() async {
    try {
      if (Platform.isWindows) {
        // أمر Windows لقياس المعالج
        final result = await Process.run('wmic', [
          'cpu',
          'get',
          'loadpercentage',
          '/value'
        ]);
        
        if (result.exitCode == 0) {
          final output = result.stdout.toString();
          final match = RegExp(r'LoadPercentage=(\d+)').firstMatch(output);
          
          if (match != null) {
            final cpuPercent = int.tryParse(match.group(1) ?? '0') ?? 0;
            return 'المعالج: $cpuPercent%';
          }
        }
      }
      
      return 'مراقبة نشطة';
    } catch (e) {
      return 'خطأ في قياس المعالج';
    }
  }

  void _updateWarningLevel() {
    // تحديد مستوى الخطورة بناءً على البيانات
    if (_memoryUsage.contains('%')) {
      final percentMatch = RegExp(r'\((\d+)%\)').firstMatch(_memoryUsage);
      if (percentMatch != null) {
        final percent = int.tryParse(percentMatch.group(1) ?? '0') ?? 0;
        
        if (percent > 90) {
          _warningColor = Colors.red;
          _isDangerous = true;
        } else if (percent > 70) {
          _warningColor = Colors.orange;
          _isDangerous = false;
        } else {
          _warningColor = Colors.green;
          _isDangerous = false;
        }
      }
    }
    
    if (_cpuUsage.contains('%')) {
      final percentMatch = RegExp(r'(\d+)%').firstMatch(_cpuUsage);
      if (percentMatch != null) {
        final percent = int.tryParse(percentMatch.group(1) ?? '0') ?? 0;
        
        if (percent > 90) {
          _warningColor = Colors.red;
          _isDangerous = true;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: _warningColor.withOpacity(0.1),
        border: Border.all(color: _warningColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                _isDangerous ? Icons.dangerous : Icons.monitor,
                color: _warningColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'مراقب النظام',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _warningColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _memoryUsage,
            style: TextStyle(fontSize: 12, color: _warningColor),
          ),
          Text(
            _cpuUsage,
            style: TextStyle(fontSize: 12, color: _warningColor),
          ),
          if (_isDangerous) ...[
            const SizedBox(height: 4),
            Text(
              '⚠️ استهلاك مرتفع!',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// Widget للتحذير من الخطر
class DangerWarning extends StatelessWidget {
  const DangerWarning({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.red[50],
      title: Row(
        children: [
          Icon(Icons.warning, color: Colors.red, size: 32),
          const SizedBox(width: 8),
          Text(
            'تحذير خطر!',
            style: TextStyle(color: Colors.red[800]),
          ),
        ],
      ),
      content: const Text(
        'استهلاك الموارد مرتفع جداً!\n'
        'قد يتسبب هذا في انطفاء الحاسوب.\n\n'
        'يُنصح بإيقاف التطبيق فوراً.',
        style: TextStyle(fontWeight: FontWeight.w500),
      ),
      actions: [
        TextButton(
          onPressed: () {
            // إيقاف فوري للتطبيق
            exit(0);
          },
          style: TextButton.styleFrom(backgroundColor: Colors.red),
          child: const Text(
            'إيقاف فوري',
            style: TextStyle(color: Colors.white),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('متابعة بحذر'),
        ),
      ],
    );
  }
}

// Mixin لإضافة مراقبة الموارد لأي شاشة
mixin ResourceMonitorMixin<T extends StatefulWidget> on State<T> {
  Timer? _resourceTimer;
  bool _isMonitoring = false;

  void startResourceMonitoring() {
    if (_isMonitoring) return;
    
    _isMonitoring = true;
    _resourceTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _checkResourceUsage();
    });
  }

  void stopResourceMonitoring() {
    _isMonitoring = false;
    _resourceTimer?.cancel();
    _resourceTimer = null;
  }

  Future<void> _checkResourceUsage() async {
    if (!mounted) return;

    try {
      // فحص استهلاك الذاكرة بشكل تقديري
      final memoryInfo = await _getMemoryUsage();
      
      if (memoryInfo > 85) { // إذا تجاوز 85% من الذاكرة
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const DangerWarning(),
          );
        }
      }
    } catch (e) {
      // تجاهل الأخطاء في المراقبة
    }
  }

  Future<int> _getMemoryUsage() async {
    // محاولة تقدير استهلاك الذاكرة
    try {
      if (Platform.isWindows) {
        final result = await Process.run('wmic', [
          'OS',
          'get',
          'TotalVisibleMemorySize,FreePhysicalMemory',
          '/value'
        ]).timeout(const Duration(seconds: 2));
        
        if (result.exitCode == 0) {
          final output = result.stdout.toString();
          final lines = output.split('\n').where((line) => line.contains('=')).toList();
          
          int totalMemory = 0;
          int freeMemory = 0;
          
          for (final line in lines) {
            if (line.contains('TotalVisibleMemorySize=')) {
              totalMemory = int.tryParse(line.split('=')[1].trim()) ?? 0;
            }
            if (line.contains('FreePhysicalMemory=')) {
              freeMemory = int.tryParse(line.split('=')[1].trim()) ?? 0;
            }
          }
          
          if (totalMemory > 0 && freeMemory > 0) {
            final usedMemory = totalMemory - freeMemory;
            return (usedMemory / totalMemory * 100).round();
          }
        }
      }
    } catch (e) {
      // في حالة فشل القياس، افترض استهلاك متوسط
    }
    
    return 50; // افتراضي
  }

  @override
  void dispose() {
    stopResourceMonitoring();
    super.dispose();
  }
} 