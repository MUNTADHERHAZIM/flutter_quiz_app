import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/quiz.dart';
import '../models/question_updated.dart';
import '../services/persistent_storage_service.dart';

class EnhancedQuizBuilder extends StatefulWidget {
  final int teacherId;
  final Quiz? quiz;

  const EnhancedQuizBuilder({super.key, required this.teacherId, this.quiz});

  @override
  State<EnhancedQuizBuilder> createState() => _EnhancedQuizBuilderState();
}

class _EnhancedQuizBuilderState extends State<EnhancedQuizBuilder> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _durationController = TextEditingController();
  
  final _storage = PersistentStorageService();
  List<QuestionUpdated> _questions = [];
  bool _isLoading = false;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    if (widget.quiz != null) {
      _titleController.text = widget.quiz!.title;
      _descriptionController.text = widget.quiz!.description;
      _durationController.text = widget.quiz!.duration.toString();
      _isActive = widget.quiz!.isActive;
      _loadQuestions();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _loadQuestions() async {
    if (widget.quiz?.id != null) {
      try {
        final questions = await _storage.getQuestionsByQuiz(widget.quiz!.id!);
        setState(() => _questions = questions);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('خطأ في تحميل الأسئلة: $e')),
          );
        }
      }
    }
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
      Quiz quiz;
      if (widget.quiz == null) {
        // Create new quiz
        quiz = Quiz(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          teacherId: widget.teacherId,
          duration: int.parse(_durationController.text),
          isActive: _isActive,
          createdAt: DateTime.now(),
        );
        
        final quizId = await _storage.insertQuiz(quiz);
        
        // Save questions
        for (final question in _questions) {
          await _storage.insertQuestion(
            question.copyWith(quizId: quizId),
          );
        }
      } else {
        // Update existing quiz
        quiz = widget.quiz!.copyWith(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          duration: int.parse(_durationController.text),
          isActive: _isActive,
        );
        
        await _storage.updateQuiz(quiz);
        
        // Delete existing questions and add new ones
        final existingQuestions = await _storage.getQuestionsByQuiz(widget.quiz!.id!);
        for (final q in existingQuestions) {
          await _storage.deleteQuestion(q.id!);
        }
        
        for (final question in _questions) {
          await _storage.insertQuestion(
            question.copyWith(quizId: widget.quiz!.id),
          );
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.quiz == null ? 'تم إنشاء الاختبار بنجاح' : 'تم تحديث الاختبار بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في حفظ الاختبار: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _addQuestion() {
    showDialog(
      context: context,
      builder: (context) => EnhancedQuestionDialog(
        onSave: (question) {
          setState(() => _questions.add(question));
        },
      ),
    );
  }

  void _editQuestion(int index) {
    showDialog(
      context: context,
      builder: (context) => EnhancedQuestionDialog(
        question: _questions[index],
        onSave: (question) {
          setState(() => _questions[index] = question);
        },
      ),
    );
  }

  void _deleteQuestion(int index) {
    setState(() => _questions.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.quiz == null ? 'إنشاء اختبار مطور' : 'تعديل الاختبار',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          if (_isLoading)
            const Center(child: CircularProgressIndicator(color: Colors.white))
          else
            TextButton(
              onPressed: _saveQuiz,
              child: Text(
                'حفظ',
                style: GoogleFonts.cairo(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'معلومات الاختبار',
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
                        prefixIcon: const Icon(Icons.title),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
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
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'وصف الاختبار (اختياري)',
                        prefixIcon: const Icon(Icons.description),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _durationController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'مدة الاختبار (بالدقائق)',
                              prefixIcon: const Icon(Icons.timer),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
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
                        Expanded(
                          child: SwitchListTile(
                            title: Text(
                              'الاختبار نشط',
                              style: GoogleFonts.cairo(),
                            ),
                            value: _isActive,
                            onChanged: (value) => setState(() => _isActive = value),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                    
                    if (_questions.isEmpty) ...[
                      const SizedBox(height: 32),
                      Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.help_outline,
                              size: 48,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'لم يتم إضافة أسئلة بعد',
                              style: GoogleFonts.cairo(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'يمكنك إضافة أنواع مختلفة من الأسئلة:\n• اختيار من متعدد\n• صح أم خطأ\n• ملء الفراغات\n• إجابة قصيرة',
                              style: GoogleFonts.cairo(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                    ] else ...[
                      const SizedBox(height: 16),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _questions.length,
                        itemBuilder: (context, index) {
                          final question = _questions[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _getQuestionTypeColor(question.type),
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              title: Text(
                                question.question,
                                style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    question.getTypeDisplayName(),
                                    style: GoogleFonts.cairo(
                                      fontSize: 12,
                                      color: _getQuestionTypeColor(question.type),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (question.type == QuestionType.multipleChoice ||
                                      question.type == QuestionType.trueFalse)
                                    Text(
                                      'الإجابة الصحيحة: ${question.options[question.correctAnswers.first]}',
                                      style: GoogleFonts.cairo(fontSize: 11),
                                    )
                                  else
                                    Text(
                                      'الإجابة الصحيحة: ${question.correctText}',
                                      style: GoogleFonts.cairo(fontSize: 11),
                                    ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blue),
                                    onPressed: () => _editQuestion(index),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _deleteQuestion(index),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getQuestionTypeColor(QuestionType type) {
    switch (type) {
      case QuestionType.multipleChoice:
        return Colors.blue;
      case QuestionType.trueFalse:
        return Colors.green;
      case QuestionType.fillInBlank:
        return Colors.orange;
      case QuestionType.shortAnswer:
        return Colors.purple;
    }
  }
}

class EnhancedQuestionDialog extends StatefulWidget {
  final QuestionUpdated? question;
  final Function(QuestionUpdated) onSave;

  const EnhancedQuestionDialog({super.key, this.question, required this.onSave});

  @override
  State<EnhancedQuestionDialog> createState() => _EnhancedQuestionDialogState();
}

class _EnhancedQuestionDialogState extends State<EnhancedQuestionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _questionController = TextEditingController();
  final _correctTextController = TextEditingController();
  final _explanationController = TextEditingController();
  final List<TextEditingController> _optionControllers = List.generate(4, (index) => TextEditingController());
  
  QuestionType _selectedType = QuestionType.multipleChoice;
  int _correctAnswer = 0;
  int _points = 1;

  @override
  void initState() {
    super.initState();
    if (widget.question != null) {
      final q = widget.question!;
      _questionController.text = q.question;
      _selectedType = q.type;
      _points = q.points;
      _explanationController.text = q.explanation ?? '';
      
      if (q.type == QuestionType.multipleChoice || q.type == QuestionType.trueFalse) {
        for (int i = 0; i < q.options.length && i < 4; i++) {
          _optionControllers[i].text = q.options[i];
        }
        _correctAnswer = q.correctAnswers.isNotEmpty ? q.correctAnswers.first : 0;
      } else {
        _correctTextController.text = q.correctText ?? '';
      }
      
      if (q.type == QuestionType.trueFalse) {
        _optionControllers[0].text = 'صح';
        _optionControllers[1].text = 'خطأ';
      }
    } else {
      _setupTrueFalseOptions();
    }
  }

  @override
  void dispose() {
    _questionController.dispose();
    _correctTextController.dispose();
    _explanationController.dispose();
    for (final controller in _optionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _setupTrueFalseOptions() {
    if (_selectedType == QuestionType.trueFalse) {
      _optionControllers[0].text = 'صح';
      _optionControllers[1].text = 'خطأ';
      _correctAnswer = 0;
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    List<String> options = [];
    List<int> correctAnswers = [];
    String? correctText;

    switch (_selectedType) {
      case QuestionType.multipleChoice:
        options = _optionControllers
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
        correctAnswers = [_correctAnswer];
        break;

      case QuestionType.trueFalse:
        options = ['صح', 'خطأ'];
        correctAnswers = [_correctAnswer];
        break;

      case QuestionType.fillInBlank:
      case QuestionType.shortAnswer:
        if (_correctTextController.text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('يرجى إدخال الإجابة الصحيحة')),
          );
          return;
        }
        correctText = _correctTextController.text.trim();
        break;
    }

    final question = QuestionUpdated(
      question: _questionController.text.trim(),
      type: _selectedType,
      options: options,
      correctAnswers: correctAnswers,
      correctText: correctText,
      points: _points,
      explanation: _explanationController.text.trim().isEmpty 
          ? null 
          : _explanationController.text.trim(),
    );

    widget.onSave(question);
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
        height: MediaQuery.of(context).size.height * 0.7,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Question Type Selection
                Text(
                  'نوع السؤال',
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<QuestionType>(
                  value: _selectedType,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    isDense: true,
                  ),
                  items: QuestionType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Row(
                        children: [
                          Icon(
                            _getQuestionTypeIcon(type),
                            size: 20,
                            color: _getQuestionTypeColor(type),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _getQuestionTypeDisplayName(type),
                            style: GoogleFonts.cairo(),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedType = value!;
                      if (_selectedType == QuestionType.trueFalse) {
                        _setupTrueFalseOptions();
                      }
                    });
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Question Text
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
                
                // Options or Text Answer based on type
                if (_selectedType == QuestionType.multipleChoice) ...[
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
                ] else if (_selectedType == QuestionType.trueFalse) ...[
                  Text(
                    'الإجابة الصحيحة',
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<int>(
                          title: Text('صح', style: GoogleFonts.cairo()),
                          value: 0,
                          groupValue: _correctAnswer,
                          onChanged: (value) => setState(() => _correctAnswer = value!),
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<int>(
                          title: Text('خطأ', style: GoogleFonts.cairo()),
                          value: 1,
                          groupValue: _correctAnswer,
                          onChanged: (value) => setState(() => _correctAnswer = value!),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  Text(
                    _selectedType == QuestionType.fillInBlank ? 'الإجابة الصحيحة للفراغ' : 'الإجابة الصحيحة',
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _correctTextController,
                    decoration: InputDecoration(
                      labelText: _selectedType == QuestionType.fillInBlank 
                          ? 'النص المطلوب في الفراغ'
                          : 'الإجابة المتوقعة',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'يرجى إدخال الإجابة الصحيحة';
                      }
                      return null;
                    },
                  ),
                ],
                
                const SizedBox(height: 16),
                
                // Points
                Row(
                  children: [
                    Text(
                      'النقاط: ',
                      style: GoogleFonts.cairo(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Expanded(
                      child: Slider(
                        value: _points.toDouble(),
                        min: 1,
                        max: 10,
                        divisions: 9,
                        label: '$_points نقطة',
                        onChanged: (value) => setState(() => _points = value.toInt()),
                      ),
                    ),
                    Text(
                      '$_points',
                      style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Explanation (optional)
                TextFormField(
                  controller: _explanationController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'شرح الإجابة (اختياري)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    alignLabelWithHint: true,
                  ),
                ),
                
                const SizedBox(height: 8),
                Text(
                  _selectedType == QuestionType.multipleChoice
                      ? 'اختر الإجابة الصحيحة بالضغط على الدائرة المجاورة للخيار'
                      : _selectedType == QuestionType.trueFalse
                          ? 'اختر الإجابة الصحيحة: صح أم خطأ'
                          : 'اكتب الإجابة الصحيحة كما تتوقعها من الطالب',
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
          child: Text('إلغاء', style: GoogleFonts.cairo()),
        ),
        ElevatedButton(
          onPressed: _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
          child: Text('حفظ', style: GoogleFonts.cairo()),
        ),
      ],
    );
  }

  IconData _getQuestionTypeIcon(QuestionType type) {
    switch (type) {
      case QuestionType.multipleChoice:
        return Icons.radio_button_checked;
      case QuestionType.trueFalse:
        return Icons.check_box;
      case QuestionType.fillInBlank:
        return Icons.text_fields;
      case QuestionType.shortAnswer:
        return Icons.short_text;
    }
  }

  Color _getQuestionTypeColor(QuestionType type) {
    switch (type) {
      case QuestionType.multipleChoice:
        return Colors.blue;
      case QuestionType.trueFalse:
        return Colors.green;
      case QuestionType.fillInBlank:
        return Colors.orange;
      case QuestionType.shortAnswer:
        return Colors.purple;
    }
  }

  String _getQuestionTypeDisplayName(QuestionType type) {
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