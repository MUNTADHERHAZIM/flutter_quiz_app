import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/sqlite_database_service.dart';
import '../models/user.dart';
import 'registration_screen.dart';

class AdminUsersManagement extends StatefulWidget {
  final User currentAdmin;

  const AdminUsersManagement({super.key, required this.currentAdmin});

  @override
  State<AdminUsersManagement> createState() => _AdminUsersManagementState();
}

class _AdminUsersManagementState extends State<AdminUsersManagement>
    with TickerProviderStateMixin {
  final SQLiteDatabaseService _dbService = SQLiteDatabaseService();
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;

  Map<String, List<Map<String, dynamic>>> _usersByRole = {
    'admin': [],
    'teacher': [],
    'student': [],
  };

  List<Map<String, dynamic>> _filteredUsers = [];
  bool _isLoading = true;
  String _currentRole = 'admin';

  // Stats
  Map<String, int> _stats = {
    'total_users': 0,
    'active_users': 0,
    'inactive_users': 0,
    'admin_count': 0,
    'teacher_count': 0,
    'student_count': 0,
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadUsers();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    setState(() {
      switch (_tabController.index) {
        case 0:
          _currentRole = 'admin';
          break;
        case 1:
          _currentRole = 'teacher';
          break;
        case 2:
          _currentRole = 'student';
          break;
      }
      _filteredUsers = _usersByRole[_currentRole] ?? [];
      _applySearchFilter();
    });
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final db = await _dbService.database;
      final users = await db.query('users', orderBy: 'created_at DESC');

      final usersByRole = <String, List<Map<String, dynamic>>>{
        'admin': [],
        'teacher': [],
        'student': [],
      };

      int totalUsers = users.length;
      int activeUsers = 0;
      int inactiveUsers = 0;

      for (final user in users) {
        final role = user['role'] as String;
        final isActive = user['is_active'] == 1;
        
        if (isActive) {
          activeUsers++;
        } else {
          inactiveUsers++;
        }

        usersByRole[role]?.add(user);
      }

      setState(() {
        _usersByRole = usersByRole;
        _filteredUsers = _usersByRole[_currentRole] ?? [];
        _stats = {
          'total_users': totalUsers,
          'active_users': activeUsers,
          'inactive_users': inactiveUsers,
          'admin_count': usersByRole['admin']?.length ?? 0,
          'teacher_count': usersByRole['teacher']?.length ?? 0,
          'student_count': usersByRole['student']?.length ?? 0,
        };
        _isLoading = false;
      });

      _applySearchFilter();
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorMessage('خطأ في تحميل البيانات: $e');
    }
  }

  void _applySearchFilter() {
    final searchTerm = _searchController.text.toLowerCase();
    if (searchTerm.isEmpty) {
      setState(() => _filteredUsers = _usersByRole[_currentRole] ?? []);
      return;
    }

    final filtered = (_usersByRole[_currentRole] ?? []).where((user) {
      return user['name'].toString().toLowerCase().contains(searchTerm) ||
             user['email'].toString().toLowerCase().contains(searchTerm) ||
             (user['phone'] ?? '').toString().toLowerCase().contains(searchTerm) ||
             (user['department'] ?? '').toString().toLowerCase().contains(searchTerm);
    }).toList();

    setState(() => _filteredUsers = filtered);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildHeader(),
                _buildStats(),
                _buildTabs(),
                Expanded(child: _buildUsersList()),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddUserDialog,
        icon: const Icon(Icons.person_add),
        label: Text('إضافة مستخدم', style: GoogleFonts.cairo()),
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
                const Icon(Icons.people, color: Colors.white, size: 32),
                const SizedBox(width: 12),
                Text(
                  'إدارة المستخدمين',
                  style: GoogleFonts.cairo(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: _loadUsers,
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
                hintText: 'البحث في المستخدمين...',
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
              onChanged: (_) => _applySearchFilter(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStats() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'إجمالي',
              '${_stats['total_users']}',
              Icons.people,
              Colors.blue,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildStatCard(
              'نشط',
              '${_stats['active_users']}',
              Icons.check_circle,
              Colors.green,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildStatCard(
              'غير نشط',
              '${_stats['inactive_users']}',
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

  Widget _buildTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.indigo,
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey[600],
        labelStyle: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        tabs: [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.admin_panel_settings, size: 16),
                const SizedBox(width: 4),
                Text('المدراء (${_stats['admin_count']})'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.school, size: 16),
                const SizedBox(width: 4),
                Text('المعلمون (${_stats['teacher_count']})'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.person, size: 16),
                const SizedBox(width: 4),
                Text('الطلاب (${_stats['student_count']})'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersList() {
    if (_filteredUsers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'لا يوجد مستخدمون',
              style: GoogleFonts.cairo(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'قم بإضافة مستخدم جديد للبدء',
              style: GoogleFonts.cairo(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredUsers.length,
      itemBuilder: (context, index) {
        final user = _filteredUsers[index];
        return _buildUserCard(user);
      },
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final isActive = user['is_active'] == 1;
    final role = user['role'] as String;
    
    Color roleColor;
    IconData roleIcon;
    switch (role) {
      case 'admin':
        roleColor = Colors.purple;
        roleIcon = Icons.admin_panel_settings;
        break;
      case 'teacher':
        roleColor = Colors.blue;
        roleIcon = Icons.school;
        break;
      case 'student':
        roleColor = Colors.green;
        roleIcon = Icons.person;
        break;
      default:
        roleColor = Colors.grey;
        roleIcon = Icons.person_outline;
    }

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: roleColor.withOpacity(0.1),
                  child: Icon(roleIcon, color: roleColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user['name'],
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        user['email'],
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          color: Colors.grey[600],
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
                if (user['phone'] != null) ...[
                  _buildInfoChip('${user['phone']}', Colors.blue),
                  const SizedBox(width: 8),
                ],
                if (user['department'] != null) ...[
                  _buildInfoChip('${user['department']}', Colors.purple),
                  const SizedBox(width: 8),
                ],
                _buildInfoChip(_getRoleDisplayName(role), roleColor),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'تاريخ الإنشاء: ${_formatDate(user['created_at'])}',
                    style: GoogleFonts.cairo(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                Row(
                  children: [
                    _buildActionButton(
                      icon: Icons.edit,
                      color: Colors.blue,
                      onPressed: () => _showEditUserDialog(user),
                      tooltip: 'تعديل',
                    ),
                    const SizedBox(width: 4),
                    _buildActionButton(
                      icon: isActive ? Icons.pause : Icons.play_arrow,
                      color: isActive ? Colors.orange : Colors.green,
                      onPressed: () => _toggleUserStatus(user),
                      tooltip: isActive ? 'إيقاف' : 'تفعيل',
                    ),
                    const SizedBox(width: 4),
                    _buildActionButton(
                      icon: Icons.delete,
                      color: Colors.red,
                      onPressed: () => _deleteUser(user),
                      tooltip: 'حذف',
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
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

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }

  String _getRoleDisplayName(String role) {
    switch (role) {
      case 'admin':
        return 'مدير';
      case 'teacher':
        return 'معلم';
      case 'student':
        return 'طالب';
      default:
        return role;
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'غير محدد';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'غير محدد';
    }
  }

  Future<void> _toggleUserStatus(Map<String, dynamic> user) async {
    try {
      final db = await _dbService.database;
      final newStatus = user['is_active'] == 1 ? 0 : 1;
      
      await db.update(
        'users',
        {
          'is_active': newStatus,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [user['id']],
      );

      _showSuccessMessage(
        newStatus == 1 ? 'تم تفعيل المستخدم' : 'تم إيقاف المستخدم',
      );
      _loadUsers();
    } catch (e) {
      _showErrorMessage('خطأ في تغيير حالة المستخدم: $e');
    }
  }

  Future<void> _deleteUser(Map<String, dynamic> user) async {
    // Prevent admin from deleting themselves
    if (user['id'] == widget.currentAdmin.id) {
      _showErrorMessage('لا يمكنك حذف حسابك الخاص');
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('تأكيد الحذف', style: GoogleFonts.cairo()),
        content: Text(
          'هل أنت متأكد من حذف المستخدم "${user['name']}"؟\nسيتم حذف جميع البيانات المرتبطة به.\nلا يمكن التراجع عن هذا الإجراء.',
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
                await db.delete('users', where: 'id = ?', whereArgs: [user['id']]);
                
                Navigator.pop(context);
                _showSuccessMessage('تم حذف المستخدم بنجاح');
                _loadUsers();
              } catch (e) {
                Navigator.pop(context);
                _showErrorMessage('خطأ في حذف المستخدم: $e');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('حذف', style: GoogleFonts.cairo()),
          ),
        ],
      ),
    );
  }

  void _showAddUserDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const RegistrationScreen(),
      ),
    ).then((_) => _loadUsers());
  }

  void _showEditUserDialog(Map<String, dynamic> user) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('سيتم تطوير واجهة تعديل المستخدم قريباً')),
    );
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.cairo()),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.cairo()),
        backgroundColor: Colors.red,
      ),
    );
  }
} 