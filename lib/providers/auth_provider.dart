import 'package:flutter/material.dart';
import '../core/storage/local_storage.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  UserModel? _user;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;

  AuthProvider() {
    _loadStoredUser();
  }

  Future<void> _loadStoredUser() async {
    final token = await LocalStorage.getToken();
    final userMap = await LocalStorage.getUser();
    if (token != null && userMap != null) {
      _user = UserModel.fromJson(userMap);
      notifyListeners();
      // Verify token in background
      final res = await _authService.getMe();
      if (res.success && res.data != null) {
        _user = res.data;
        notifyListeners();
      } else if (res.statusCode == 401) {
        await logout();
      }
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final res = await _authService.login(email.trim(), password);

    _isLoading = false;
    if (res.success && res.data != null) {
      _user = res.data;
      notifyListeners();
      return true;
    } else {
      _errorMessage = res.message;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await _authService.logout();
    } catch (_) {}
    _user = null;
    _errorMessage = null;
    notifyListeners();
  }
}
