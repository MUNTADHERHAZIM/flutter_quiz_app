import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../models/quiz.dart';
import '../models/question.dart';
import '../services/storage_service.dart';

class QuizBuilderScreen extends StatefulWidget {
  final Quiz? quiz;
  
  const QuizBuilderScreen({super.key, this.quiz});

  @override
  State<QuizBuilderScreen> createState() => _QuizBuilderScreenState();
}

class _QuizBuilderScreenState extends State<QuizBuilderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _durationController = TextEditingController();
  
  final StorageService _databaseService = StorageService(); // تم تغيير الاسم
  List<Question> _questions = [];
  bool _isLoading = false;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    if (widget.quiz != null) {
      _titleController.text = widget.quiz!.title;
      _descriptionController.text = widget.quiz!.description;
      _durationController.text = widget.quiz!.duration.toString();
      _questions = List.from(widget.quiz!.questions);
      _isActive = widget.quiz!.isActive;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  void _addQuestion() {
    showDialog(
      context: context,
      builder: (context) => AddQuestionDialog(
        onQuestionAdded: (question) {
          setState(() {
            _questions.add(question);
          });
        },
      ),
    );
  }

  void _editQuestion(int index) {
    showDialog(
      context: context,
      builder: (context) => AddQuestionDialog(
        question: _questions[index],
        onQuestionAdded: (question) {
          setState(() {
            _questions[index] = question;
          });
        },
      ),
    );
  }

  void _deleteQuestion(int index) {
    setState(() {
      _questions.removeAt(index);
    });
  }

  Future<void> _saveQuiz() async {
    if (!_formKey.currentState!.validate()) return;
    if (_questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يجب إضافة سؤال واحد على الأقل')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final teacher = authProvider.currentUser!;

      final quiz = Quiz(
        id: widget.quiz?.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        teacherId: teacher.id!,
        questions: _questions,
        duration: int.tryParse(_durationController.text) ?? 60,
        isActive: _isActive,
        createdAt: widget.quiz?.createdAt ?? DateTime.now(),
      );

      if (widget.quiz == null) {
        await _databaseService.insertQuiz(quiz);
      } else {
        await _databaseService.updateQuiz(quiz);
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.quiz == null ? 'تم إنشاء الاختبار بنجاح' : 'تم تحديث الاختبار بنجاح')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.quiz == null ? 'إنشاء اختبار جديد' : 'تعديل الاختبار',
          style: GoogleFonts.cairo(),
        ),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _saveQuiz,
            icon: _isLoading 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.save),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Quiz Details Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'تفاصيل الاختبار',
                              style: GoogleFonts.cairo(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            TextFormField(
                              controller: _titleController,
                              decoration: InputDecoration(
                                labelText: 'عنوان الاختبار',
                                labelStyle: GoogleFonts.cairo(),
                                border: const OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'يرجى إدخال عنوان الاختبار';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            
                            TextFormField(
                              controller: _descriptionController,
                              decoration: InputDecoration(
                                labelText: 'وصف الاختبار',
                                labelStyle: GoogleFonts.cairo(),
                                border: const OutlineInputBorder(),
                              ),
                              maxLines: 3,
                            ),
                            const SizedBox(height: 16),
                            
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _durationController,
                                    decoration: InputDecoration(
                                      labelText: 'مدة الاختبار (بالدقائق)',
                                      labelStyle: GoogleFonts.cairo(),
                                      border: const OutlineInputBorder(),
                                    ),
                                    keyboardType: TextInputType.number,
                                    validator: (value) {
                                      if (value == null || value.trim().isEmpty) {
                                        return 'يرجى إدخال مدة الاختبار';
                                      }
                                      final duration = int.tryParse(value);
                                      if (duration == null || duration <= 0) {
                                        return 'يرجى إدخال مدة صحيحة';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Column(
                                  children: [
                                    Text('نشط', style: GoogleFonts.cairo()),
                                    Switch(
                                      value: _isActive,
                                      onChanged: (value) {
                                        setState(() => _isActive = value);
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Questions Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'الأسئلة (${_questions.length})',
                          style: GoogleFonts.cairo(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _addQuestion,
                          icon: const Icon(Icons.add),
                          label: Text('إضافة سؤال', style: GoogleFonts.cairo()),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    if (_questions.isEmpty)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.quiz_outlined,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'لا توجد أسئلة',
                                  style: GoogleFonts.cairo(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                Text(
                                  'ابدأ بإضافة أول سؤال للاختبار',
                                  style: GoogleFonts.cairo(
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    else
                      ..._questions.asMap().entries.map((entry) {
                        final index = entry.key;
                        final question = entry.value;
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.indigo,
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            title: Text(
                              question.question,
                              style: GoogleFonts.cairo(fontWeight: FontWeight.w500),
                            ),
                            subtitle: Text(
                              '${question.options.length} خيارات',
                              style: GoogleFonts.cairo(),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  onPressed: () => _editQuestion(index),
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                ),
                                IconButton(
                                  onPressed: () => _deleteQuestion(index),
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ),
            
            // Bottom Save Button
            if (_questions.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveQuiz,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          widget.quiz == null ? 'إنشاء الاختبار' : 'حفظ التغييرات',
                          style: GoogleFonts.cairo(fontSize: 16),
                        ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class AddQuestionDialog extends StatefulWidget {
  final Question? question;
  final Function(Question) onQuestionAdded;

  const AddQuestionDialog({this.question, required this.onQuestionAdded});

  @override
  State<AddQuestionDialog> createState() => _AddQuestionDialogState();
}

class _AddQuestionDialogState extends State<AddQuestionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _questionController = TextEditingController();
  final List<TextEditingController> _optionControllers = List.generate(4, (index) => TextEditingController());
  int _correctAnswer = 0;

  @override
  void initState() {
    super.initState();
    if (widget.question != null) {
      _questionController.text = widget.question!.question;
      for (int i = 0; i < widget.question!.options.length && i < 4; i++) {
        _optionControllers[i].text = widget.question!.options[i];
      }
      _correctAnswer = widget.question!.correctAnswer;
    }
  }

  @override
  void dispose() {
    _questionController.dispose();
    for (final controller in _optionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final options = _optionControllers
        .map((controller) => controller.text.trim())
        .where((text) => text.isNotEmpty)
        .toList();

    if (options.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يجب إضافة خيارين على الأقل')),
      );
      return;
    }

    if (_correctAnswer >= options.length) {
      _correctAnswer = 0;
    }

    final question = Question(
      question: _questionController.text.trim(),
      options: options,
      correctAnswer: _correctAnswer,
    );

    widget.onQuestionAdded(question);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.question == null ? 'إضافة سؤال' : 'تعديل السؤال',
        style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _questionController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'نص السؤال',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    alignLabelWithHint: true,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'يرجى إدخال نص السؤال';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                Text(
                  'الخيارات',
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                
                ...List.generate(4, (index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Radio<int>(
                          value: index,
                          groupValue: _correctAnswer,
                          onChanged: (value) => setState(() => _correctAnswer = value!),
                        ),
                        Expanded(
                          child: TextFormField(
                            controller: _optionControllers[index],
                            decoration: InputDecoration(
                              labelText: 'الخيار ${index + 1}',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              isDense: true,
                            ),
                            validator: index < 2 ? (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'مطلوب';
                              }
                              return null;
                            } : null,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                
                const SizedBox(height: 8),
                Text(
                  'اختر الإجابة الصحيحة بالضغط على الدائرة المجاورة للخيار',
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          onPressed: _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
          child: const Text('حفظ'),
        ),
      ],
    );
  }
} 