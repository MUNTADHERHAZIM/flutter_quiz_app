import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../services/storage_service.dart';

class AuthProvider with ChangeNotifier {
  User? _currentUser;
  final StorageService _storageService = StorageService();

  User? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isTeacher => _currentUser?.role == UserRole.teacher;
  bool get isStudent => _currentUser?.role == UserRole.student;

  Future<void> checkAuthStatus() async {
    await _storageService.initialize();
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('user_email');
    if (email != null) {
      final user = await _storageService.getUserByEmail(email);
      if (user != null) {
        _currentUser = user;
        notifyListeners();
      }
    }
  }

  Future<bool> login(String email, String password) async {
    try {
      await _storageService.initialize();
      final user = await _storageService.getUserByEmail(email);
      if (user != null && user.password == password) {
        _currentUser = user;
        
        // Save to preferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_email', email);
        
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print('Login error: $e');
      return false;
    }
  }

  Future<bool> register(String name, String email, String password, UserRole role) async {
    try {
      await _storageService.initialize();
      // Check if user already exists
      final existingUser = await _storageService.getUserByEmail(email);
      if (existingUser != null) {
        return false; // User already exists
      }

      final user = User(
        name: name,
        email: email,
        password: password,
        role: role,
        createdAt: DateTime.now(),
      );

      final id = await _storageService.insertUser(user);
      _currentUser = user.copyWith(id: id);
      
      // Save to preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_email', email);
      
      notifyListeners();
      return true;
    } catch (e) {
      print('Registration error: $e');
      return false;
    }
  }

  Future<void> logout() async {
    _currentUser = null;
    
    // Clear preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_email');
    
    notifyListeners();
  }
} 