import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  User? _user;
  bool _isLoading = false;
  bool _isAuthenticated = false;

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;

  AuthProvider() {
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    _isLoading = true;
    notifyListeners();

    try {
      _isAuthenticated = await _authService.isAuthenticated();
      if (_isAuthenticated) {
        _user = await _authService.getCurrentUser();
        if (_user == null) {
          _isAuthenticated = false;
        }
      }
    } catch (e) {
      _isAuthenticated = false;
      _user = null;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<AuthResult> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _authService.login(email: email, password: password);

      if (result.success) {
        _user = result.user;
        _isAuthenticated = true;
      }

      _isLoading = false;
      notifyListeners();

      return result;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return AuthResult(success: false, error: 'Login failed');
    }
  }

  Future<AuthResult> register({
    required String email,
    required String password,
    String? firstName,
    String? lastName,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _authService.register(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
      );

      if (result.success) {
        _user = result.user;
        _isAuthenticated = true;
      }

      _isLoading = false;
      notifyListeners();

      return result;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return AuthResult(success: false, error: 'Registration failed');
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _user = null;
    _isAuthenticated = false;
    notifyListeners();
  }

  Future<void> refreshUser() async {
    if (!_isAuthenticated) return;

    try {
      _user = await _authService.getCurrentUser();
      if (_user == null) {
        await logout();
      }
      notifyListeners();
    } catch (e) {
      await logout();
    }
  }

  /// Demo/offline login for testing without backend
  Future<AuthResult> loginDemo() async {
    _isLoading = true;
    notifyListeners();

    // Create a demo user
    final demoUser = User(
      id: 'demo-user-id',
      email: 'demo@example.com',
      firstName: 'Demo',
      lastName: 'User',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    _user = demoUser;
    _isAuthenticated = true;
    _isLoading = false;
    notifyListeners();

    return AuthResult(success: true, user: demoUser, token: 'demo-token');
  }

  /// Add demo data for testing
  Future<void> addDemoData() async {
    // This will be called after demo login to populate with sample data
    // You can implement this to add sample exercises and exercise types
  }
}