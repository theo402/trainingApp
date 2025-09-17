import '../models/user.dart';
import 'api_client.dart';

class AuthService {
  final ApiClient _apiClient = ApiClient();

  Future<AuthResult> register({
    required String email,
    required String password,
    String? firstName,
    String? lastName,
  }) async {
    try {
      final response = await _apiClient.post('/auth/register', data: {
        'email': email,
        'password': password,
        if (firstName != null) 'first_name': firstName,
        if (lastName != null) 'last_name': lastName,
      });

      final data = response.data;
      final token = data['access_token'];
      final user = User.fromJson(data['user']);

      await _apiClient.setToken(token);

      return AuthResult(success: true, user: user, token: token);
    } on ApiException catch (e) {
      return AuthResult(success: false, error: e.message);
    } catch (e) {
      return AuthResult(success: false, error: 'Registration failed');
    }
  }

  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiClient.post('/auth/login', data: {
        'email': email,
        'password': password,
      });

      final data = response.data;
      final token = data['access_token'];
      final user = User.fromJson(data['user']);

      await _apiClient.setToken(token);

      return AuthResult(success: true, user: user, token: token);
    } on ApiException catch (e) {
      return AuthResult(success: false, error: e.message);
    } catch (e) {
      return AuthResult(success: false, error: 'Login failed');
    }
  }

  Future<void> logout() async {
    await _apiClient.clearToken();
  }

  Future<User?> getCurrentUser() async {
    try {
      final response = await _apiClient.get('/profile');
      final userData = response.data['user'];
      return User.fromJson(userData);
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        await logout();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> isAuthenticated() async {
    return await _apiClient.isAuthenticated();
  }
}

class AuthResult {
  final bool success;
  final User? user;
  final String? token;
  final String? error;

  AuthResult({
    required this.success,
    this.user,
    this.token,
    this.error,
  });
}