import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/sqlite_database_service.dart';
import '../models/user.dart';

class QuizManagementScreen extends StatefulWidget {
  final User currentUser;

  const QuizManagementScreen({super.key, required this.currentUser});

  @override
  State<QuizManagementScreen> createState() => _QuizManagementScreenState();
}

class _QuizManagementScreenState extends State<QuizManagementScreen>
    with TickerProviderStateMixin {
  final SQLiteDatabaseService _dbService = SQLiteDatabaseService();
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;

  List<Map<String, dynamic>> _quizzes = [];
  List<Map<String, dynamic>> _filteredQuizzes = [];
  List<Map<String, dynamic>> _subjects = [];
  bool _isLoading = true;

  // Filters
  int? _selectedSubjectId;
  bool? _isActiveFilter;
  bool _showOnlyMyQuizzes = false;

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
      final db = await _dbService.database;
      
      String quizzesQuery = '''
        SELECT q.*, s.name as subject_name, u.name as teacher_name,
               COUNT(DISTINCT qr.id) as total_attempts,
               AVG(qr.score) as avg_score
        FROM quizzes q
        LEFT JOIN subjects s ON q.subject_id = s.id
        LEFT JOIN users u ON q.teacher_id = u.id
        LEFT JOIN quiz_results qr ON q.id = qr.quiz_id
      ''';
      
      if (_showOnlyMyQuizzes && widget.currentUser.role.name != 'admin') {
        quizzesQuery += ' WHERE q.teacher_id = ${widget.currentUser.id}';
      }
      
      quizzesQuery += ' GROUP BY q.id ORDER BY q.created_at DESC';
      
      final quizzes = await db.rawQuery(quizzesQuery);
      final subjects = await db.query('subjects', orderBy: 'name');
      final stats = await _dbService.getSystemStats();

      setState(() {
        _quizzes = quizzes;
        _filteredQuizzes = quizzes;
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
    List<Map<String, dynamic>> filtered = _quizzes;

    // Search filter
    if (_searchController.text.isNotEmpty) {
      final searchTerm = _searchController.text.toLowerCase();
      filtered = filtered.where((quiz) {
        return quiz['title'].toString().toLowerCase().contains(searchTerm) ||
               (quiz['description'] ?? '').toString().toLowerCase().contains(searchTerm) ||
               (quiz['subject_name'] ?? '').toString().toLowerCase().contains(searchTerm) ||
               (quiz['teacher_name'] ?? '').toString().toLowerCase().contains(searchTerm);
      }).toList();
    }

    // Subject filter
    if (_selectedSubjectId != null) {
      filtered = filtered.where((quiz) => quiz['subject_id'] == _selectedSubjectId).toList();
    }

    // Active status filter
    if (_isActiveFilter != null) {
      filtered = filtered.where((quiz) => (quiz['is_active'] == 1) == _isActiveFilter).toList();
    }

    setState(() => _filteredQuizzes = filtered);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildHeader(),
                _buildFilters(),
                _buildStats(),
                Expanded(child: _buildQuizzesList()),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddQuizDialog(),
        icon: const Icon(Icons.add),
        label: Text('إضافة اختبار', style: GoogleFonts.cairo()),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo.shade600, Colors.indigo.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.assignment, color: Colors.white, size: 32),
                const SizedBox(width: 12),
                Text(
                  'إدارة الاختبارات',
                  style: GoogleFonts.cairo(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: _loadData,
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  tooltip: 'تحديث',
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              style: GoogleFonts.cairo(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'البحث في الاختبارات...',
                hintStyle: GoogleFonts.cairo(color: Colors.white70),
                prefixIcon: const Icon(Icons.search, color: Colors.white70),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.white30),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.white30),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.white),
                ),
                filled: true,
                fillColor: Colors.white.withOpacity(0.1),
              ),
              onChanged: (_) => _applyFilters(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // Subject filter
            Container(
              margin: const EdgeInsets.only(right: 8),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int?>(
                  value: _selectedSubjectId,
                  hint: Text('جميع المواد', style: GoogleFonts.cairo()),
                  items: [
                    DropdownMenuItem<int?>(
                      value: null,
                      child: Text('جميع المواد', style: GoogleFonts.cairo()),
                    ),
                    ..._subjects.map((subject) => DropdownMenuItem<int?>(
                      value: subject['id'],
                      child: Text(subject['name'], style: GoogleFonts.cairo()),
                    )),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedSubjectId = value);
                    _applyFilters();
                  },
                ),
              ),
            ),
            
            // Active status filter
            Container(
              margin: const EdgeInsets.only(right: 8),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<bool?>(
                  value: _isActiveFilter,
                  hint: Text('جميع الحالات', style: GoogleFonts.cairo()),
                  items: [
                    DropdownMenuItem<bool?>(
                      value: null,
                      child: Text('جميع الحالات', style: GoogleFonts.cairo()),
                    ),
                    DropdownMenuItem<bool?>(
                      value: true,
                      child: Text('نشط', style: GoogleFonts.cairo()),
                    ),
                    DropdownMenuItem<bool?>(
                      value: false,
                      child: Text('غير نشط', style: GoogleFonts.cairo()),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() => _isActiveFilter = value);
                    _applyFilters();
                  },
                ),
              ),
            ),

            // My quizzes filter (for teachers)
            if (widget.currentUser.role.name == 'teacher')
              Container(
                margin: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text('اختباراتي فقط', style: GoogleFonts.cairo()),
                  selected: _showOnlyMyQuizzes,
                  onSelected: (value) {
                    setState(() => _showOnlyMyQuizzes = value);
                    _loadData();
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStats() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'إجمالي الاختبارات',
              _filteredQuizzes.length.toString(),
              Icons.assignment,
              Colors.blue,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildStatCard(
              'النشطة',
              _filteredQuizzes.where((q) => q['is_active'] == 1).length.toString(),
              Icons.check_circle,
              Colors.green,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildStatCard(
              'غير النشطة',
              _filteredQuizzes.where((q) => q['is_active'] == 0).length.toString(),
              Icons.pause_circle,
              Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.cairo(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: GoogleFonts.cairo(
                fontSize: 10,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuizzesList() {
    if (_filteredQuizzes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'لا توجد اختبارات',
              style: GoogleFonts.cairo(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'قم بإضافة اختبار جديد للبدء',
              style: GoogleFonts.cairo(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredQuizzes.length,
      itemBuilder: (context, index) {
        final quiz = _filteredQuizzes[index];
        return _buildQuizCard(quiz);
      },
    );
  }

  Widget _buildQuizCard(Map<String, dynamic> quiz) {
    final isActive = quiz['is_active'] == 1;
    final totalAttempts = quiz['total_attempts'] ?? 0;
    final avgScore = quiz['avg_score'];
    
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showQuizDetails(quiz),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          quiz['title'],
                          style: GoogleFonts.cairo(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (quiz['description'] != null && quiz['description'].toString().isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              quiz['description'],
                              style: GoogleFonts.cairo(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isActive ? Colors.green.shade100 : Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isActive ? 'نشط' : 'غير نشط',
                      style: GoogleFonts.cairo(
                        fontSize: 10,
                        color: isActive ? Colors.green.shade700 : Colors.orange.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildInfoChip(Icons.subject, quiz['subject_name'] ?? 'غير محدد', Colors.blue),
                  const SizedBox(width: 8),
                  _buildInfoChip(Icons.person, quiz['teacher_name'] ?? 'غير محدد', Colors.purple),
                  const SizedBox(width: 8),
                  _buildInfoChip(Icons.timer, '${quiz['duration']} دقيقة', Colors.orange),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(Icons.analytics, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          'المحاولات: $totalAttempts',
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        if (avgScore != null) ...[
                          const SizedBox(width: 16),
                          Icon(Icons.star, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            'المتوسط: ${avgScore.toStringAsFixed(1)}%',
                            style: GoogleFonts.cairo(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) => _handleQuizAction(value, quiz),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'view',
                        child: Row(
                          children: [
                            const Icon(Icons.visibility, size: 16),
                            const SizedBox(width: 8),
                            Text('عرض التفاصيل', style: GoogleFonts.cairo()),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            const Icon(Icons.edit, size: 16),
                            const SizedBox(width: 8),
                            Text('تعديل', style: GoogleFonts.cairo()),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'questions',
                        child: Row(
                          children: [
                            const Icon(Icons.quiz, size: 16),
                            const SizedBox(width: 8),
                            Text('إدارة الأسئلة', style: GoogleFonts.cairo()),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'results',
                        child: Row(
                          children: [
                            const Icon(Icons.assessment, size: 16),
                            const SizedBox(width: 8),
                            Text('النتائج', style: GoogleFonts.cairo()),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'toggle',
                        child: Row(
                          children: [
                            Icon(isActive ? Icons.pause : Icons.play_arrow, size: 16),
                            const SizedBox(width: 8),
                            Text(isActive ? 'إيقاف' : 'تفعيل', style: GoogleFonts.cairo()),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            const Icon(Icons.delete, size: 16, color: Colors.red),
                            const SizedBox(width: 8),
                            Text(
                              'حذف',
                              style: GoogleFonts.cairo(color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.cairo(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _handleQuizAction(String action, Map<String, dynamic> quiz) {
    switch (action) {
      case 'view':
        _showQuizDetails(quiz);
        break;
      case 'edit':
        _showEditQuizDialog(quiz);
        break;
      case 'questions':
        _showQuizQuestions(quiz);
        break;
      case 'results':
        _showQuizResults(quiz);
        break;
      case 'toggle':
        _toggleQuizStatus(quiz);
        break;
      case 'delete':
        _deleteQuiz(quiz);
        break;
    }
  }

  void _showAddQuizDialog() {
    _showQuizDialog();
  }

  void _showEditQuizDialog(Map<String, dynamic> quiz) {
    _showQuizDialog(quiz: quiz);
  }

  void _showQuizDialog({Map<String, dynamic>? quiz}) {
    final isEditing = quiz != null;
    final titleController = TextEditingController(text: quiz?['title'] ?? '');
    final descriptionController = TextEditingController(text: quiz?['description'] ?? '');
    final durationController = TextEditingController(text: quiz?['duration']?.toString() ?? '60');
    int? selectedSubjectId = quiz?['subject_id'];
    bool isActive = quiz?['is_active'] == 1;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(
            isEditing ? 'تعديل الاختبار' : 'إضافة اختبار جديد',
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: 'عنوان الاختبار',
                    labelStyle: GoogleFonts.cairo(),
                    border: const OutlineInputBorder(),
                  ),
                  style: GoogleFonts.cairo(),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: InputDecoration(
                    labelText: 'وصف الاختبار',
                    labelStyle: GoogleFonts.cairo(),
                    border: const OutlineInputBorder(),
                  ),
                  style: GoogleFonts.cairo(),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
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
                TextField(
                  controller: durationController,
                  decoration: InputDecoration(
                    labelText: 'مدة الاختبار (بالدقائق)',
                    labelStyle: GoogleFonts.cairo(),
                    border: const OutlineInputBorder(),
                  ),
                  style: GoogleFonts.cairo(),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: Text('اختبار نشط', style: GoogleFonts.cairo()),
                  value: isActive,
                  onChanged: (value) => setState(() => isActive = value),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('إلغاء', style: GoogleFonts.cairo()),
            ),
            ElevatedButton(
              onPressed: () => _saveQuiz(
                context,
                quiz?['id'],
                titleController.text,
                descriptionController.text,
                selectedSubjectId,
                int.tryParse(durationController.text) ?? 60,
                isActive,
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

  Future<void> _saveQuiz(
    BuildContext context,
    int? quizId,
    String title,
    String description,
    int? subjectId,
    int duration,
    bool isActive,
  ) async {
    if (title.trim().isEmpty) {
      _showErrorSnackbar('يرجى إدخال عنوان الاختبار');
      return;
    }

    if (subjectId == null) {
      _showErrorSnackbar('يرجى اختيار المادة');
      return;
    }

    try {
      final db = await _dbService.database;
      final data = {
        'title': title.trim(),
        'description': description.trim(),
        'subject_id': subjectId,
        'teacher_id': widget.currentUser.id,
        'duration': duration,
        'is_active': isActive ? 1 : 0,
      };

      if (quizId != null) {
        // Update existing quiz
        data['updated_at'] = DateTime.now().toIso8601String();
        await db.update('quizzes', data, where: 'id = ?', whereArgs: [quizId]);
      } else {
        // Create new quiz
        data['created_at'] = DateTime.now().toIso8601String();
        await db.insert('quizzes', data);
      }

      Navigator.pop(context);
      _showSuccessSnackbar(
        quizId != null ? 'تم تحديث الاختبار بنجاح' : 'تم إضافة الاختبار بنجاح',
      );
      _loadData();
    } catch (e) {
      _showErrorSnackbar('خطأ في حفظ الاختبار: $e');
    }
  }

  void _showQuizDetails(Map<String, dynamic> quiz) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(quiz['title'], style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (quiz['description'] != null && quiz['description'].toString().isNotEmpty)
              Text(
                quiz['description'],
                style: GoogleFonts.cairo(),
              ),
            const SizedBox(height: 16),
            _buildDetailRow('المادة:', quiz['subject_name'] ?? 'غير محدد'),
            _buildDetailRow('المعلم:', quiz['teacher_name'] ?? 'غير محدد'),
            _buildDetailRow('المدة:', '${quiz['duration']} دقيقة'),
            _buildDetailRow('الحالة:', quiz['is_active'] == 1 ? 'نشط' : 'غير نشط'),
            _buildDetailRow('المحاولات:', '${quiz['total_attempts'] ?? 0}'),
            if (quiz['avg_score'] != null)
              _buildDetailRow('المتوسط:', '${quiz['avg_score'].toStringAsFixed(1)}%'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إغلاق', style: GoogleFonts.cairo()),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value, style: GoogleFonts.cairo()),
          ),
        ],
      ),
    );
  }

  void _showQuizQuestions(Map<String, dynamic> quiz) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('سيتم تطوير إدارة أسئلة الاختبار قريباً')),
    );
  }

  void _showQuizResults(Map<String, dynamic> quiz) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('سيتم تطوير عرض نتائج الاختبار قريباً')),
    );
  }

  Future<void> _toggleQuizStatus(Map<String, dynamic> quiz) async {
    try {
      final db = await _dbService.database;
      final newStatus = quiz['is_active'] == 1 ? 0 : 1;
      
      await db.update(
        'quizzes',
        {
          'is_active': newStatus,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [quiz['id']],
      );

      _showSuccessSnackbar(
        newStatus == 1 ? 'تم تفعيل الاختبار' : 'تم إيقاف الاختبار',
      );
      _loadData();
    } catch (e) {
      _showErrorSnackbar('خطأ في تغيير حالة الاختبار: $e');
    }
  }

  void _deleteQuiz(Map<String, dynamic> quiz) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('تأكيد الحذف', style: GoogleFonts.cairo()),
        content: Text(
          'هل أنت متأكد من حذف الاختبار "${quiz['title']}"؟\nسيتم حذف جميع الأسئلة والنتائج المرتبطة به.\nلا يمكن التراجع عن هذا الإجراء.',
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
                final db = await _dbService.database;
                
                // Delete related records first
                await db.delete('quiz_results', where: 'quiz_id = ?', whereArgs: [quiz['id']]);
                await db.delete('quiz_attempts', where: 'quiz_id = ?', whereArgs: [quiz['id']]);
                await db.delete('questions', where: 'quiz_id = ?', whereArgs: [quiz['id']]);
                
                // Delete the quiz
                await db.delete('quizzes', where: 'id = ?', whereArgs: [quiz['id']]);
                
                Navigator.pop(context);
                _showSuccessSnackbar('تم حذف الاختبار بنجاح');
                _loadData();
              } catch (e) {
                Navigator.pop(context);
                _showErrorSnackbar('خطأ في حذف الاختبار: $e');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('حذف', style: GoogleFonts.cairo()),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.cairo()),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.cairo()),
        backgroundColor: Colors.red,
      ),
    );
  }
} 