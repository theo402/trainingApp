import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  static const String baseUrl = 'http://localhost:3000/api'; // Change this to your backend URL
  static const String tokenKey = 'auth_token';

  late final Dio _dio;
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  ApiClient() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
      },
    ));

    // Add interceptor for authentication
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          // Token expired or invalid, clear it
          await clearToken();
        }
        handler.next(error);
      },
    ));
  }

  // Token management
  Future<String?> getToken() async {
    return await _storage.read(key: tokenKey);
  }

  Future<void> setToken(String token) async {
    await _storage.write(key: tokenKey, value: token);
  }

  Future<void> clearToken() async {
    await _storage.delete(key: tokenKey);
  }

  Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null;
  }

  // HTTP Methods
  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      return await _dio.get(path, queryParameters: queryParameters);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> post(String path, {dynamic data}) async {
    try {
      return await _dio.post(path, data: data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> put(String path, {dynamic data}) async {
    try {
      return await _dio.put(path, data: data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> patch(String path, {dynamic data}) async {
    try {
      return await _dio.patch(path, data: data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> delete(String path) async {
    try {
      return await _dio.delete(path);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  ApiException _handleError(DioException error) {
    String message = 'An unexpected error occurred';

    if (error.response != null) {
      final statusCode = error.response!.statusCode;
      final data = error.response!.data;

      if (data is Map<String, dynamic> && data.containsKey('error')) {
        message = data['error'];
      } else {
        switch (statusCode) {
          case 400:
            message = 'Bad request';
            break;
          case 401:
            message = 'Unauthorized';
            break;
          case 403:
            message = 'Forbidden';
            break;
          case 404:
            message = 'Not found';
            break;
          case 409:
            message = 'Conflict';
            break;
          case 422:
            message = 'Validation failed';
            break;
          case 500:
            message = 'Internal server error';
            break;
        }
      }

      return ApiException(message, statusCode);
    }

    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      message = 'Connection timeout';
    } else if (error.type == DioExceptionType.connectionError) {
      message = 'No internet connection';
    }

    return ApiException(message, null);
  }
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, this.statusCode);

  @override
  String toString() => message;
}