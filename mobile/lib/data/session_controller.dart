import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'api_client.dart';
import 'models.dart';

class SessionController extends ChangeNotifier {
  SessionController({required this.api, required this.storage}) {
    api.onUnauthorized = _handleUnauthorized;
  }

  static const _tokenKey = 'session.token';
  static const _userKey = 'session.user';

  final ApiClient api;
  final SessionStorage storage;

  AppUser? user;
  bool initialized = false;
  String? initializationError;
  String? sessionNotice;

  @override
  void dispose() {
    api.close();
    super.dispose();
  }

  Future<void> initialize() async {
    try {
      final token = await storage.read(_tokenKey);
      final profileJson = await storage.read(_userKey);
      if (token == null || profileJson == null) {
        if (token != null) await storage.delete(_tokenKey);
        if (profileJson != null) await storage.delete(_userKey);
      } else {
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

  Future<void> requestPasswordReset(String email) async {
    await api.post('Auth/ForgotPassword', {'email': email.trim()});
  }

  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    await api.post('Auth/ResetPassword', {
      'token': token.trim(),
      'newPassword': newPassword,
    });
  }

  Future<void> updateProfile({
    required String fullName,
    required String email,
    required String phone,
  }) async {
    final currentUser = user;
    if (currentUser == null) {
      throw const ApiException('Inicia sesión para actualizar tu perfil');
    }
    final data = await api.put('Auth/Profile', {
      'fullName': fullName.trim(),
      'email': email.trim(),
      'phone': phone.trim(),
    });
    if (data is! Map<String, dynamic>) {
      throw const FormatException('La API devolvió un perfil no válido');
    }
    final updatedUser = AppUser.fromJson({...data, 'token': currentUser.token});
    if (updatedUser.username != currentUser.username) {
      throw const FormatException('La API devolvió un usuario inesperado');
    }
    await storage.write(
      _userKey,
      jsonEncode({
        'username': updatedUser.username,
        'fullName': updatedUser.fullName,
        'email': updatedUser.email,
        'phone': updatedUser.phone,
      }),
    );
    user = updatedUser;
    notifyListeners();
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

    try {
      await storage.write(
        _userKey,
        jsonEncode({
          'username': authenticatedUser.username,
          'fullName': authenticatedUser.fullName,
          'email': authenticatedUser.email,
          'phone': authenticatedUser.phone,
        }),
      );
      await storage.write(_tokenKey, authenticatedUser.token);
    } on Exception catch (error) {
      try {
        await storage.delete(_tokenKey);
        await storage.delete(_userKey);
      } on Exception catch (cleanupError) {
        throw Exception(
          'No se pudo guardar la sesión ($error) ni limpiar el estado local ($cleanupError)',
        );
      }
      rethrow;
    }
    api.token = authenticatedUser.token;
    user = authenticatedUser;
    sessionNotice = null;
    notifyListeners();
  }

  Future<void> logout() =>
      _clearSession('No se pudo borrar completamente la sesión local');

  Future<void> _handleUnauthorized() => _clearSession(
    'La sesión fue rechazada y no se pudo borrar completamente la sesión local',
  );

  Future<void> _clearSession(String storageFailureMessage) async {
    api.token = null;
    user = null;
    sessionNotice = null;
    notifyListeners();
    try {
      await storage.delete(_tokenKey);
      await storage.delete(_userKey);
    } on Exception catch (error) {
      sessionNotice = '$storageFailureMessage: $error';
      notifyListeners();
    }
  }
}

abstract interface class SessionStorage {
  Future<String?> read(String key);

  Future<void> write(String key, String value);

  Future<void> delete(String key);
}

class SecureSessionStorage implements SessionStorage {
  const SecureSessionStorage(this._storage);

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}
