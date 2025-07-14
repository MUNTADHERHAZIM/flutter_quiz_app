import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import '../services/sqlite_database_service.dart';
import '../models/user.dart';

class QuestionBankScreen extends StatefulWidget {
  final User currentUser;

  const QuestionBankScreen({super.key, required this.currentUser});

  @override
  State<QuestionBankScreen> createState() => _QuestionBankScreenState();
}

class _QuestionBankScreenState extends State<QuestionBankScreen>
    with TickerProviderStateMixin {
  final SQLiteDatabaseService _dbService = SQLiteDatabaseService();
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;

  List<Map<String, dynamic>> _questions = [];
  List<Map<String, dynamic>> _filteredQuestions = [];
  List<Map<String, dynamic>> _subjects = [];
  bool _isLoading = true;

  // Filters
  int? _selectedSubjectId;
  String? _selectedDifficulty;
  String? _selectedQuestionType;
  bool _showOnlyMyQuestions = false;

  // Stats
  Map<String, int> _stats = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final questions = await _dbService.getQuestionBank(
        createdBy: _showOnlyMyQuestions ? widget.currentUser.id : null,
      );
      final subjects = await _dbService.getSubjects();
      final stats = await _dbService.getSystemStats();

      setState(() {
        _questions = questions;
        _filteredQuestions = questions;
        _subjects = subjects;
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackbar('خطأ في تحميل البيانات: $e');
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredQuestions = _questions.where((question) {
        bool matches = true;

        // Search filter
        if (_searchController.text.isNotEmpty) {
          matches = matches &&
              question['question_text']
                  .toString()
                  .toLowerCase()
                  .contains(_searchController.text.toLowerCase());
        }

        // Subject filter
        if (_selectedSubjectId != null) {
          matches = matches && question['subject_id'] == _selectedSubjectId;
        }

        // Difficulty filter
        if (_selectedDifficulty != null) {
          matches = matches && question['difficulty_level'] == _selectedDifficulty;
        }

        // Question type filter
        if (_selectedQuestionType != null) {
          matches = matches && question['question_type'] == _selectedQuestionType;
        }

        // My questions filter
        if (_showOnlyMyQuestions) {
          matches = matches && question['created_by'] == widget.currentUser.id;
        }

        return matches;
      }).toList();
    });
  }

  void _clearFilters() {
    setState(() {
      _selectedSubjectId = null;
      _selectedDifficulty = null;
      _selectedQuestionType = null;
      _showOnlyMyQuestions = false;
      _searchController.clear();
      _filteredQuestions = _questions;
    });
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        action: SnackBarAction(
          label: 'إعادة المحاولة',
          textColor: Colors.white,
          onPressed: _loadData,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('بنك الأسئلة', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: [
            Tab(
              icon: const Icon(Icons.list),
              text: 'جميع الأسئلة',
            ),
            Tab(
              icon: const Icon(Icons.analytics),
              text: 'الإحصائيات',
            ),
            Tab(
              icon: const Icon(Icons.settings),
              text: 'الإعدادات',
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddQuestionDialog(),
            tooltip: 'إضافة سؤال جديد',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'تحديث',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildQuestionsTab(),
          _buildStatsTab(),
          _buildSettingsTab(),
        ],
      ),
    );
  }

  Widget _buildQuestionsTab() {
    return Column(
      children: [
        // Search and Filter Bar
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 3,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Search Bar
              TextField(
                controller: _searchController,
                onChanged: (_) => _applyFilters(),
                decoration: InputDecoration(
                  hintText: 'البحث في الأسئلة...',
                  hintStyle: GoogleFonts.cairo(),
                  prefixIcon: const Icon(Icons.search, color: Colors.indigo),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _applyFilters();
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
                style: GoogleFonts.cairo(),
              ),
              const SizedBox(height: 12),
              
              // Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    // Subject Filter
                    _buildFilterChip(
                      label: _selectedSubjectId == null
                          ? 'جميع المواد'
                          : _subjects
                              .firstWhere((s) => s['id'] == _selectedSubjectId)['name'],
                      isSelected: _selectedSubjectId != null,
                      onTap: () => _showSubjectFilter(),
                    ),
                    const SizedBox(width: 8),
                    
                    // Difficulty Filter
                    _buildFilterChip(
                      label: _selectedDifficulty == null
                          ? 'جميع المستويات'
                          : _getDifficultyLabel(_selectedDifficulty!),
                      isSelected: _selectedDifficulty != null,
                      onTap: () => _showDifficultyFilter(),
                    ),
                    const SizedBox(width: 8),
                    
                    // Question Type Filter
                    _buildFilterChip(
                      label: _selectedQuestionType == null
                          ? 'جميع الأنواع'
                          : _getQuestionTypeLabel(_selectedQuestionType!),
                      isSelected: _selectedQuestionType != null,
                      onTap: () => _showQuestionTypeFilter(),
                    ),
                    const SizedBox(width: 8),
                    
                    // My Questions Filter
                    _buildFilterChip(
                      label: 'أسئلتي فقط',
                      isSelected: _showOnlyMyQuestions,
                      onTap: () {
                        setState(() => _showOnlyMyQuestions = !_showOnlyMyQuestions);
                        _applyFilters();
                      },
                    ),
                    const SizedBox(width: 8),
                    
                    // Clear Filters
                    if (_hasActiveFilters())
                      _buildFilterChip(
                        label: 'مسح الفلاتر',
                        isSelected: false,
                        onTap: _clearFilters,
                        icon: Icons.clear,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Results Count
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'عدد النتائج: ${_filteredQuestions.length}',
                style: GoogleFonts.cairo(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (_isLoading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
        ),

        // Questions List
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filteredQuestions.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredQuestions.length,
                      itemBuilder: (context, index) {
                        final question = _filteredQuestions[index];
                        return _buildQuestionCard(question, index);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    IconData? icon,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.indigo : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.indigo : Colors.grey[300]!,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : Colors.grey[600],
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: GoogleFonts.cairo(
                color: isSelected ? Colors.white : Colors.grey[700],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionCard(Map<String, dynamic> question, int index) {
    final questionType = question['question_type'] as String;
    final difficulty = question['difficulty_level'] as String;
    final subjectName = _subjects
        .firstWhere((s) => s['id'] == question['subject_id'], orElse: () => {'name': 'غير محدد'})['name'];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: _getQuestionTypeColor(questionType),
          child: Icon(
            _getQuestionTypeIcon(questionType),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          question['question_text'],
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              _buildInfoChip(subjectName, Colors.blue),
              _buildInfoChip(_getDifficultyLabel(difficulty), _getDifficultyColor(difficulty)),
              _buildInfoChip('${question['points']} نقطة', Colors.amber),
              if (question['usage_count'] > 0)
                _buildInfoChip('استُخدم ${question['usage_count']} مرة', Colors.green),
            ],
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Question Content
                if (questionType == 'multipleChoice' && question['options'] != null) ...[
                  Text(
                    'الخيارات:',
                    style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...(_parseJsonList(question['options']) ?? []).asMap().entries.map(
                    (entry) {
                      final isCorrect = _parseJsonList(question['correct_answers'])?.contains(entry.key) ?? false;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Icon(
                              isCorrect ? Icons.check_circle : Icons.radio_button_unchecked,
                              color: isCorrect ? Colors.green : Colors.grey,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                entry.value,
                                style: GoogleFonts.cairo(
                                  color: isCorrect ? Colors.green[700] : null,
                                  fontWeight: isCorrect ? FontWeight.w600 : null,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],

                if (questionType == 'trueFalse') ...[
                  Text(
                    'الإجابة الصحيحة:',
                    style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        (_parseJsonList(question['correct_answers'])?.first == 0)
                            ? Icons.check_circle
                            : Icons.cancel,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        (_parseJsonList(question['correct_answers'])?.first == 0) ? 'صح' : 'خطأ',
                        style: GoogleFonts.cairo(
                          color: Colors.green[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],

                if ((questionType == 'fillInBlank' || questionType == 'shortAnswer') &&
                    question['correct_text'] != null) ...[
                  Text(
                    'الإجابة الصحيحة:',
                    style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green[200]!),
                    ),
                    child: Text(
                      question['correct_text'],
                      style: GoogleFonts.cairo(color: Colors.green[700]),
                    ),
                  ),
                ],

                // Explanation
                if (question['explanation'] != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    'التوضيح:',
                    style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Text(
                      question['explanation'],
                      style: GoogleFonts.cairo(color: Colors.blue[700]),
                    ),
                  ),
                ],

                // Hint
                if (question['hint'] != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.lightbulb_outline, color: Colors.amber[700]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'تلميح: ${question['hint']}',
                            style: GoogleFonts.cairo(color: Colors.amber[700]),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Action Buttons
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _editQuestion(question),
                      icon: const Icon(Icons.edit, size: 18),
                      label: Text('تعديل', style: GoogleFonts.cairo()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _duplicateQuestion(question),
                      icon: const Icon(Icons.copy, size: 18),
                      label: Text('نسخ', style: GoogleFonts.cairo()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _deleteQuestion(question),
                      icon: const Icon(Icons.delete, size: 18),
                      label: Text('حذف', style: GoogleFonts.cairo()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: GoogleFonts.cairo(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
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
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'ابدأ بإضافة أسئلة جديدة إلى بنك الأسئلة',
            style: GoogleFonts.cairo(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showAddQuestionDialog(),
            icon: const Icon(Icons.add),
            label: Text('إضافة سؤال جديد', style: GoogleFonts.cairo()),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Overall Stats
          Row(
            children: [
              _buildStatCard(
                'إجمالي الأسئلة',
                _stats['questions']?.toString() ?? '0',
                Icons.quiz,
                Colors.blue,
              ),
              const SizedBox(width: 16),
              _buildStatCard(
                'المواد',
                _subjects.length.toString(),
                Icons.subject,
                Colors.green,
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Question Types Distribution
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'توزيع أنواع الأسئلة',
                    style: GoogleFonts.cairo(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ..._getQuestionTypeStats().entries.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: _getQuestionTypeColor(entry.key),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _getQuestionTypeLabel(entry.key),
                              style: GoogleFonts.cairo(),
                            ),
                          ),
                          Text(
                            entry.value.toString(),
                            style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 8),
              Text(
                value,
                style: GoogleFonts.cairo(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                title,
                style: GoogleFonts.cairo(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.import_export),
              title: Text('تصدير بنك الأسئلة', style: GoogleFonts.cairo()),
              subtitle: Text('تصدير جميع الأسئلة إلى ملف JSON', style: GoogleFonts.cairo()),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => _exportQuestions(),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.upload_file),
              title: Text('استيراد أسئلة', style: GoogleFonts.cairo()),
              subtitle: Text('استيراد أسئلة من ملف JSON', style: GoogleFonts.cairo()),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => _importQuestions(),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.refresh),
              title: Text('تحديث الإحصائيات', style: GoogleFonts.cairo()),
              subtitle: Text('إعادة حساب إحصائيات الاستخدام', style: GoogleFonts.cairo()),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => _refreshStats(),
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods
  String _getDifficultyLabel(String difficulty) {
    switch (difficulty) {
      case 'easy': return 'سهل';
      case 'medium': return 'متوسط';
      case 'hard': return 'صعب';
      default: return difficulty;
    }
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty) {
      case 'easy': return Colors.green;
      case 'medium': return Colors.orange;
      case 'hard': return Colors.red;
      default: return Colors.grey;
    }
  }

  String _getQuestionTypeLabel(String type) {
    switch (type) {
      case 'multipleChoice': return 'اختيار من متعدد';
      case 'trueFalse': return 'صح أم خطأ';
      case 'fillInBlank': return 'ملء الفراغات';
      case 'shortAnswer': return 'إجابة قصيرة';
      case 'essay': return 'مقال';
      case 'matching': return 'مطابقة';
      default: return type;
    }
  }

  Color _getQuestionTypeColor(String type) {
    switch (type) {
      case 'multipleChoice': return Colors.blue;
      case 'trueFalse': return Colors.green;
      case 'fillInBlank': return Colors.orange;
      case 'shortAnswer': return Colors.purple;
      case 'essay': return Colors.teal;
      case 'matching': return Colors.pink;
      default: return Colors.grey;
    }
  }

  IconData _getQuestionTypeIcon(String type) {
    switch (type) {
      case 'multipleChoice': return Icons.radio_button_checked;
      case 'trueFalse': return Icons.check_circle;
      case 'fillInBlank': return Icons.edit;
      case 'shortAnswer': return Icons.text_fields;
      case 'essay': return Icons.article;
      case 'matching': return Icons.compare_arrows;
      default: return Icons.help;
    }
  }

  List<dynamic>? _parseJsonList(dynamic jsonString) {
    try {
      if (jsonString == null) return null;
      return json.decode(jsonString.toString());
    } catch (e) {
      return null;
    }
  }

  bool _hasActiveFilters() {
    return _selectedSubjectId != null ||
           _selectedDifficulty != null ||
           _selectedQuestionType != null ||
           _showOnlyMyQuestions ||
           _searchController.text.isNotEmpty;
  }

  Map<String, int> _getQuestionTypeStats() {
    final stats = <String, int>{};
    for (final question in _questions) {
      final type = question['question_type'] as String;
      stats[type] = (stats[type] ?? 0) + 1;
    }
    return stats;
  }

  // Action methods
  void _showSubjectFilter() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('اختر المادة', style: GoogleFonts.cairo()),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              ListTile(
                title: Text('جميع المواد', style: GoogleFonts.cairo()),
                onTap: () {
                  setState(() => _selectedSubjectId = null);
                  _applyFilters();
                  Navigator.pop(context);
                },
              ),
              ..._subjects.map(
                (subject) => ListTile(
                  title: Text(subject['name'], style: GoogleFonts.cairo()),
                  onTap: () {
                    setState(() => _selectedSubjectId = subject['id']);
                    _applyFilters();
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDifficultyFilter() {
    final difficulties = [
      {'value': null, 'label': 'جميع المستويات'},
      {'value': 'easy', 'label': 'سهل'},
      {'value': 'medium', 'label': 'متوسط'},
      {'value': 'hard', 'label': 'صعب'},
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('اختر مستوى الصعوبة', style: GoogleFonts.cairo()),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: difficulties.map(
              (diff) => ListTile(
                title: Text(diff['label']!, style: GoogleFonts.cairo()),
                onTap: () {
                  setState(() => _selectedDifficulty = diff['value']);
                  _applyFilters();
                  Navigator.pop(context);
                },
              ),
            ).toList(),
          ),
        ),
      ),
    );
  }

  void _showQuestionTypeFilter() {
    final types = [
      {'value': null, 'label': 'جميع الأنواع'},
      {'value': 'multipleChoice', 'label': 'اختيار من متعدد'},
      {'value': 'trueFalse', 'label': 'صح أم خطأ'},
      {'value': 'fillInBlank', 'label': 'ملء الفراغات'},
      {'value': 'shortAnswer', 'label': 'إجابة قصيرة'},
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('اختر نوع السؤال', style: GoogleFonts.cairo()),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: types.map(
              (type) => ListTile(
                title: Text(type['label']!, style: GoogleFonts.cairo()),
                onTap: () {
                  setState(() => _selectedQuestionType = type['value']);
                  _applyFilters();
                  Navigator.pop(context);
                },
              ),
            ).toList(),
          ),
        ),
      ),
    );
  }

  void _showAddQuestionDialog() {
    _showQuestionDialog();
  }

  void _editQuestion(Map<String, dynamic> question) {
    _showQuestionDialog(question: question);
  }

  void _duplicateQuestion(Map<String, dynamic> question) {
    // TODO: Implement duplicate question
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('سيتم تطوير واجهة نسخ السؤال قريباً')),
    );
  }

  void _deleteQuestion(Map<String, dynamic> question) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('تأكيد الحذف', style: GoogleFonts.cairo()),
        content: Text(
          'هل أنت متأكد من حذف هذا السؤال؟ لا يمكن التراجع عن هذا الإجراء.',
          style: GoogleFonts.cairo(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء', style: GoogleFonts.cairo()),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _dbService.deleteQuestionFromBank(question['id']);
                await _loadData();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم حذف السؤال بنجاح')),
                );
              } catch (e) {
                Navigator.pop(context);
                _showErrorSnackbar('خطأ في حذف السؤال: $e');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('حذف', style: GoogleFonts.cairo()),
          ),
        ],
      ),
    );
  }

  void _exportQuestions() {
    // TODO: Implement export
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('سيتم تطوير ميزة التصدير قريباً')),
    );
  }

  void _importQuestions() {
    // TODO: Implement import
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('سيتم تطوير ميزة الاستيراد قريباً')),
    );
  }

  void _refreshStats() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1)); // Simulate refresh
    await _loadData();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم تحديث الإحصائيات بنجاح')),
    );
  }

  void _showQuestionDialog({Map<String, dynamic>? question}) {
    final isEditing = question != null;
    final questionController = TextEditingController(text: question?['question_text'] ?? '');
    final explanationController = TextEditingController(text: question?['explanation'] ?? '');
    int? selectedSubjectId = question?['subject_id'];
    String selectedDifficulty = question?['difficulty'] ?? 'متوسط';
    String selectedType = question?['question_type'] ?? 'multiple_choice';

    // Controllers for options (for multiple choice questions)
    final List<TextEditingController> optionControllers = List.generate(
      4,
      (index) => TextEditingController(
        text: question != null && question['options'] != null
            ? (question['options'] is String
                ? (jsonDecode(question['options']) as List<dynamic>).length > index
                    ? jsonDecode(question['options'])[index]
                    : ''
                : question['options'].length > index
                    ? question['options'][index]
                    : '')
            : '',
      ),
    );

    int correctAnswerIndex = question?['correct_answer'] ?? 0;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(
            isEditing ? 'تعديل السؤال' : 'إضافة سؤال جديد',
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.8,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Subject dropdown
                  DropdownButtonFormField<int>(
                    value: selectedSubjectId,
                    decoration: InputDecoration(
                      labelText: 'المادة',
                      labelStyle: GoogleFonts.cairo(),
                      border: const OutlineInputBorder(),
                    ),
                    items: _subjects.map((subject) {
                      return DropdownMenuItem<int>(
                        value: subject['id'],
                        child: Text(subject['name'], style: GoogleFonts.cairo()),
                      );
                    }).toList(),
                    onChanged: (value) => selectedSubjectId = value,
                  ),
                  const SizedBox(height: 16),

                  // Question type dropdown
                  DropdownButtonFormField<String>(
                    value: selectedType,
                    decoration: InputDecoration(
                      labelText: 'نوع السؤال',
                      labelStyle: GoogleFonts.cairo(),
                      border: const OutlineInputBorder(),
                    ),
                    items: [
                      DropdownMenuItem(value: 'multiple_choice', child: Text('اختيار متعدد', style: GoogleFonts.cairo())),
                      DropdownMenuItem(value: 'true_false', child: Text('صح/خطأ', style: GoogleFonts.cairo())),
                      DropdownMenuItem(value: 'short_answer', child: Text('إجابة قصيرة', style: GoogleFonts.cairo())),
                      DropdownMenuItem(value: 'fill_blank', child: Text('ملء الفراغ', style: GoogleFonts.cairo())),
                    ],
                    onChanged: (value) => setState(() => selectedType = value!),
                  ),
                  const SizedBox(height: 16),

                  // Difficulty dropdown
                  DropdownButtonFormField<String>(
                    value: selectedDifficulty,
                    decoration: InputDecoration(
                      labelText: 'مستوى الصعوبة',
                      labelStyle: GoogleFonts.cairo(),
                      border: const OutlineInputBorder(),
                    ),
                    items: [
                      DropdownMenuItem(value: 'سهل', child: Text('سهل', style: GoogleFonts.cairo())),
                      DropdownMenuItem(value: 'متوسط', child: Text('متوسط', style: GoogleFonts.cairo())),
                      DropdownMenuItem(value: 'صعب', child: Text('صعب', style: GoogleFonts.cairo())),
                    ],
                    onChanged: (value) => selectedDifficulty = value!,
                  ),
                  const SizedBox(height: 16),

                  // Question text
                  TextField(
                    controller: questionController,
                    decoration: InputDecoration(
                      labelText: 'نص السؤال',
                      labelStyle: GoogleFonts.cairo(),
                      border: const OutlineInputBorder(),
                    ),
                    style: GoogleFonts.cairo(),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),

                  // Options (for multiple choice and true/false)
                  if (selectedType == 'multiple_choice') ...[
                    Text('الخيارات:', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ...List.generate(4, (index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Radio<int>(
                              value: index,
                              groupValue: correctAnswerIndex,
                              onChanged: (value) => setState(() => correctAnswerIndex = value!),
                            ),
                            Expanded(
                              child: TextField(
                                controller: optionControllers[index],
                                decoration: InputDecoration(
                                  labelText: 'الخيار ${index + 1}',
                                  labelStyle: GoogleFonts.cairo(),
                                  border: const OutlineInputBorder(),
                                ),
                                style: GoogleFonts.cairo(),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ] else if (selectedType == 'true_false') ...[
                    Text('الإجابة الصحيحة:', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                    Row(
                      children: [
                        Radio<int>(
                          value: 1,
                          groupValue: correctAnswerIndex,
                          onChanged: (value) => setState(() => correctAnswerIndex = value!),
                        ),
                        Text('صح', style: GoogleFonts.cairo()),
                        Radio<int>(
                          value: 0,
                          groupValue: correctAnswerIndex,
                          onChanged: (value) => setState(() => correctAnswerIndex = value!),
                        ),
                        Text('خطأ', style: GoogleFonts.cairo()),
                      ],
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Explanation
                  TextField(
                    controller: explanationController,
                    decoration: InputDecoration(
                      labelText: 'شرح الإجابة (اختياري)',
                      labelStyle: GoogleFonts.cairo(),
                      border: const OutlineInputBorder(),
                    ),
                    style: GoogleFonts.cairo(),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                // Dispose controllers
                questionController.dispose();
                explanationController.dispose();
                for (var controller in optionControllers) {
                  controller.dispose();
                }
                Navigator.pop(context);
              },
              child: Text('إلغاء', style: GoogleFonts.cairo()),
            ),
            ElevatedButton(
              onPressed: () => _saveQuestion(
                context,
                question?['id'],
                questionController.text,
                selectedSubjectId,
                selectedType,
                selectedDifficulty,
                optionControllers,
                correctAnswerIndex,
                explanationController.text,
                isEditing,
              ),
              child: Text(
                isEditing ? 'حفظ التعديلات' : 'إضافة',
                style: GoogleFonts.cairo(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveQuestion(
    BuildContext context,
    int? questionId,
    String questionText,
    int? subjectId,
    String questionType,
    String difficulty,
    List<TextEditingController> optionControllers,
    int correctAnswer,
    String explanation,
    bool isEditing,
  ) async {
    if (questionText.trim().isEmpty) {
      _showErrorSnackbar('يرجى إدخال نص السؤال');
      return;
    }

    if (subjectId == null) {
      _showErrorSnackbar('يرجى اختيار المادة');
      return;
    }

    // Prepare options based on question type
    List<String> options = [];
    if (questionType == 'multiple_choice') {
      options = optionControllers.map((c) => c.text.trim()).toList();
      if (options.any((option) => option.isEmpty)) {
        _showErrorSnackbar('يرجى ملء جميع الخيارات');
        return;
      }
    } else if (questionType == 'true_false') {
      options = ['خطأ', 'صح'];
    }

    try {
      final data = {
        'question_text': questionText.trim(),
        'subject_id': subjectId,
        'question_type': questionType,
        'difficulty': difficulty,
        'options': jsonEncode(options),
        'correct_answer': correctAnswer,
        'explanation': explanation.trim().isEmpty ? null : explanation.trim(),
        'created_by': widget.currentUser.id,
      };

      if (isEditing && questionId != null) {
        data['updated_at'] = DateTime.now().toIso8601String();
        await _dbService.updateQuestionInBank(questionId, data);
      } else {
        data['created_at'] = DateTime.now().toIso8601String();
        await _dbService.insertQuestionToBank(data);
      }

      // Dispose controllers
      for (var controller in optionControllers) {
        controller.dispose();
      }

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEditing ? 'تم تحديث السؤال بنجاح' : 'تم إضافة السؤال بنجاح',
            style: GoogleFonts.cairo(),
          ),
          backgroundColor: Colors.green,
        ),
      );
      _loadData();
    } catch (e) {
      _showErrorSnackbar('خطأ في حفظ السؤال: $e');
    }
  }
} 