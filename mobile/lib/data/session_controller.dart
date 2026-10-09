import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'api_client.dart';
import 'models.dart';

class SessionController extends ChangeNotifier {
  SessionController({required this.api, required this.storage});

  static const _tokenKey = 'session.token';
  static const _userKey = 'session.user';

  final ApiClient api;
  final FlutterSecureStorage storage;

  AppUser? user;
  bool initialized = false;
  String? initializationError;

  @override
  void dispose() {
    api.close();
    super.dispose();
  }

  Future<void> initialize() async {
    try {
      final token = await storage.read(key: _tokenKey);
      final profileJson = await storage.read(key: _userKey);
      if (token != null && profileJson != null) {
        final profile = jsonDecode(profileJson);
        if (profile is! Map<String, dynamic>) {
          throw const FormatException(
            'El perfil guardado tiene un formato inválido',
          );
        }
        user = AppUser.fromJson({...profile, 'token': token});
        api.token = token;
      }
    } on Exception catch (error) {
      initializationError = error.toString();
    } finally {
      initialized = true;
      notifyListeners();
    }
  }

  Future<void> login(String username, String password) async {
    final data = await api.post('Auth/Login', {
      'username': username.trim(),
      'password': password,
    });
    await _saveUser(data);
  }

  Future<void> register({
    required String username,
    required String fullName,
    required String email,
    required String phone,
    required String password,
  }) async {
    final data = await api.post('Auth/Register', {
      'username': username.trim(),
      'fullName': fullName.trim(),
      'email': email.trim(),
      'phone': phone.trim(),
      'password': password,
    });
    await _saveUser(data);
  }

  Future<void> _saveUser(dynamic data) async {
    if (data is! Map<String, dynamic>) {
      throw const FormatException(
        'La API devolvió un perfil de usuario inválido',
      );
    }
    final authenticatedUser = AppUser.fromJson(data);
    if (authenticatedUser.token.isEmpty) {
      throw const FormatException('La API no devolvió un token de sesión');
    }

    await storage.write(key: _tokenKey, value: authenticatedUser.token);
    await storage.write(
      key: _userKey,
      value: jsonEncode({
        'username': authenticatedUser.username,
        'fullName': authenticatedUser.fullName,
        'email': authenticatedUser.email,
      }),
    );
    api.token = authenticatedUser.token;
    user = authenticatedUser;
    notifyListeners();
  }

  Future<void> logout() async {
    await storage.delete(key: _tokenKey);
    await storage.delete(key: _userKey);
    api.token = null;
    user = null;
    notifyListeners();
  }
}
