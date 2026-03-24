import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  static const String baseUrl =
      'http://192.168.100.9:5000/api'; // 10.0.2.2 = localhost pour émulateur Android

  final Dio _dio = Dio();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  ApiService() {
    _dio.options.baseUrl = baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 10);

    // Intercepteur pour ajouter le token automatiquement
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: 'auth_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
      ),
    );
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _dio.post(
      '/auth/login',
      data: {'email': email, 'password': password},
    );
    return response.data;
  }

  Future<List<dynamic>> getEvents() async {
    final response = await _dio.get('/creathons');
    return response.data['creathons'] ?? [];
  }

  Future<void> saveToken(String token) async {
    await _storage.write(key: 'auth_token', value: token);
  }

  Future<void> saveFcmToken(String userId, String fcmToken) async {
    await _dio.post(
      '/notifications/register-token',
      data: {'userId': userId, 'token': fcmToken, 'device': 'mobile'},
    );
  }

  Future<Map<String, dynamic>> getNotificationPreferences(String userId) async {
    final response = await _dio.get('/notifications/preferences/$userId');
    return response.data;
  }

  Future<void> updateNotificationPreferences(
    String userId,
    bool weekBefore,
    bool dayBefore,
  ) async {
    await _dio.put(
      '/notifications/preferences/$userId',
      data: {'weekBefore': weekBefore, 'dayBefore': dayBefore, 'enabled': true},
    );
  }

  Future<void> logout() async {
    await _storage.delete(key: 'auth_token');
    await _storage.delete(key: 'user_id');
  }

  Future<List<dynamic>> getTrainings() async {
    final response = await _dio.get('/trainings');
    return response.data['data'] ?? [];
  }
}
