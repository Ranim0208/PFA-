import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  bool _isLoggedIn = false;
  String? _userId;
  String? _userName;
  String? _userRole;

  bool get isLoggedIn => _isLoggedIn;
  String? get userId => _userId;
  String? get userName => _userName;
  String? get userRole => _userRole;

  Future<void> checkAuth() async {
    final loggedIn = await _storage.read(key: 'logged_in');
    _userId = await _storage.read(key: 'user_id');
    _userName = await _storage.read(key: 'user_name');
    _userRole = await _storage.read(key: 'user_role');
    _isLoggedIn = loggedIn == 'true';

    print('👤 userName depuis storage: $_userName'); // ← ajoutez

    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    try {
      final data = await _apiService.login(email, password);

      // Le backend renvoie success + user (pas de token dans le body)
      if (data['success'] == true) {
        final user = data['user'];
        print('👤 user complet: $user'); // ← ajoutez
        print('👤 name: ${user['name']}'); // ← ajoutez
        final token = data['accessToken'];
        await _storage.write(key: 'auth_token', value: token);
        await _storage.write(key: 'user_id', value: user['id'].toString());
        await _storage.write(key: 'user_name', value: user['name']);
        _userName = user['name'];
        await _storage.write(key: 'user_role', value: user['roles'][0]);
        await _storage.write(key: 'logged_in', value: 'true');

        _isLoggedIn = true;
        _userId = user['id'].toString();
        _userName = user['name'];
        _userRole = user['roles'][0];

        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print('Login error: $e');
      return false;
    }
  }

  Future<void> logout() async {
    await _apiService.logout();
    await _storage.delete(key: 'logged_in');
    _isLoggedIn = false;
    _userId = null;
    _userName = null;
    _userRole = null;
    notifyListeners();
  }
}
