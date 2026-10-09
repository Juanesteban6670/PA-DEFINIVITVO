import 'dart:convert';

import 'package:cartagena_segura/data/api_client.dart';
import 'package:cartagena_segura/data/session_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('SessionController', () {
    test('logs in, trims the username and persists the returned session', () async {
      final storage = _FakeSessionStorage();
      final client = MockClient((request) async {
        expect(request.url.path, '/api/Auth/Login');
        expect(
          jsonDecode(request.body),
          {'username': 'citizen', 'password': 'secret1'},
        );
        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'Login exitoso',
            'data': {
              'token': 'login-token',
              'username': 'citizen',
              'fullName': 'Persona Ciudadana',
              'email': 'citizen@example.com',
            },
          }),
          200,
        );
      });
      final session = SessionController(
        api: ApiClient(baseUrl: 'https://api.example.com/api', client: client),
        storage: storage,
      );

      await session.login(' citizen ', 'secret1');

      expect(session.user?.username, 'citizen');
      expect(session.api.token, 'login-token');
      expect(storage.values['session.token'], 'login-token');
      expect(
        jsonDecode(storage.values['session.user']!),
        {
          'username': 'citizen',
          'fullName': 'Persona Ciudadana',
          'email': 'citizen@example.com',
        },
      );
      session.dispose();
    });

    test('registers a citizen and persists the returned session', () async {
      final storage = _FakeSessionStorage();
      final client = MockClient((request) async {
        expect(request.url.path, '/api/Auth/Register');
        expect(
          jsonDecode(request.body),
          {
            'username': 'newcitizen',
            'fullName': 'Nombre Completo',
            'email': 'citizen@example.com',
            'phone': '3001234567',
            'password': 'secret1',
          },
        );
        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'Registro exitoso',
            'data': {
              'token': 'register-token',
              'username': 'newcitizen',
              'fullName': 'Nombre Completo',
              'email': 'citizen@example.com',
            },
          }),
          200,
        );
      });
      final session = SessionController(
        api: ApiClient(baseUrl: 'https://api.example.com/api', client: client),
        storage: storage,
      );

      await session.register(
        username: ' newcitizen ',
        fullName: ' Nombre Completo ',
        email: ' citizen@example.com ',
        phone: '3001234567',
        password: 'secret1',
      );

      expect(session.user?.username, 'newcitizen');
      expect(session.api.token, 'register-token');
      expect(storage.values['session.token'], 'register-token');
      session.dispose();
    });

    test('keeps logged out when authentication is rejected', () async {
      final storage = _FakeSessionStorage();
      final client = MockClient(
        (_) async => http.Response(
          '{"success":false,"message":"Credenciales incorrectas","data":null}',
          401,
        ),
      );
      final session = SessionController(
        api: ApiClient(baseUrl: 'https://api.example.com/api', client: client),
        storage: storage,
      );

      await expectLater(
        session.login('citizen', 'wrong'),
        throwsA(
          isA<ApiException>()
              .having((error) => error.statusCode, 'statusCode', 401)
              .having(
                (error) => error.message,
                'message',
                'Credenciales incorrectas',
              ),
        ),
      );

      expect(session.user, isNull);
      expect(session.api.token, isNull);
      expect(storage.values, isEmpty);
      session.dispose();
    });

    test('does not activate session when secure storage write fails', () async {
      final storage = _FakeSessionStorage()
        ..failWriteKey = 'session.token';
      final client = MockClient(
        (_) async => http.Response(
          jsonEncode({
            'success': true,
            'message': 'Login exitoso',
            'data': {
              'token': 'login-token',
              'username': 'citizen',
              'fullName': 'Persona Ciudadana',
            },
          }),
          200,
        ),
      );
      final session = SessionController(
        api: ApiClient(baseUrl: 'https://api.example.com/api', client: client),
        storage: storage,
      );

      await expectLater(
        session.login('citizen', 'secret1'),
        throwsA(isA<Exception>()),
      );

      expect(session.user, isNull);
      expect(session.api.token, isNull);
      expect(storage.values, isEmpty);
      session.dispose();
    });

    test('rejects malformed authentication data without saving a session',
        () async {
      final storage = _FakeSessionStorage();
      final client = MockClient(
        (_) async => http.Response(
          '{"success":true,"message":"OK","data":{"username":"citizen"}}',
          200,
        ),
      );
      final session = SessionController(
        api: ApiClient(baseUrl: 'https://api.example.com/api', client: client),
        storage: storage,
      );

      await expectLater(
        session.login('citizen', 'secret1'),
        throwsA(isA<FormatException>()),
      );

      expect(session.user, isNull);
      expect(session.api.token, isNull);
      expect(storage.values, isEmpty);
      session.dispose();
    });

    test('clears persisted session after the API rejects its token', () async {
      final storage = _FakeSessionStorage({
        'session.token': 'expired-token',
        'session.user': jsonEncode({
          'username': 'citizen',
          'fullName': 'Persona Ciudadana',
          'email': 'citizen@example.com',
        }),
      });
      final client = MockClient((request) async {
        expect(request.headers['Authorization'], 'Bearer expired-token');
        return http.Response(
          '{"success":false,"message":"Token inválido","data":null}',
          401,
        );
      });
      final session = SessionController(
        api: ApiClient(baseUrl: 'https://api.example.com/api', client: client),
        storage: storage,
      );

      await session.initialize();
      expect(session.user?.username, 'citizen');
      expect(session.api.token, 'expired-token');
      expect(session.api.onUnauthorized, isNotNull);
      var unauthorizedCallbackCalled = false;
      final onUnauthorized = session.api.onUnauthorized!;
      session.api.onUnauthorized = () async {
        unauthorizedCallbackCalled = true;
        await onUnauthorized();
      };

      await expectLater(
        session.api.get('Incidents/My'),
        throwsA(
          isA<ApiException>().having(
            (error) => error.statusCode,
            'statusCode',
            401,
          ),
        ),
      );

      expect(unauthorizedCallbackCalled, isTrue);
      expect(session.user, isNull);
      expect(session.api.token, isNull);
      expect(storage.values, isEmpty);
      session.dispose();
    });

    test(
      'removes an incomplete persisted session during initialization',
      () async {
        final storage = _FakeSessionStorage({'session.token': 'orphan-token'});
        final session = SessionController(
          api: ApiClient(
            baseUrl: 'https://api.example.com/api',
            client: MockClient((_) async => http.Response('', 200)),
          ),
          storage: storage,
        );

        await session.initialize();

        expect(session.initializationError, isNull);
        expect(session.initialized, isTrue);
        expect(session.user, isNull);
        expect(session.api.token, isNull);
        expect(storage.values, isEmpty);
        session.dispose();
      },
    );

    test('reports secure-storage errors while logging out', () async {
      final storage = _FakeSessionStorage({
        'session.token': 'saved-token',
        'session.user': jsonEncode({'username': 'citizen'}),
      })..failDeleteKey = 'session.token';
      final session = SessionController(
        api: ApiClient(
          baseUrl: 'https://api.example.com/api',
          client: MockClient((_) async => http.Response('', 200)),
        ),
        storage: storage,
      );
      await session.initialize();

      await session.logout();

      expect(session.user, isNull);
      expect(session.api.token, isNull);
      expect(session.sessionNotice, contains('No se pudo borrar'));
      expect(storage.values['session.token'], 'saved-token');
      session.dispose();
    });

    test(
      'reports secure-storage errors when an unauthorized token is cleared',
      () async {
        final storage = _FakeSessionStorage({
          'session.token': 'expired-token',
          'session.user': jsonEncode({'username': 'citizen'}),
        })..failDeleteKey = 'session.token';
        final session = SessionController(
          api: ApiClient(
            baseUrl: 'https://api.example.com/api',
            client: MockClient(
              (_) async => http.Response(
                '{"success":false,"message":"Token inválido","data":null}',
                401,
              ),
            ),
          ),
          storage: storage,
        );
        await session.initialize();

        await expectLater(
          session.api.get('Incidents/My'),
          throwsA(
            isA<ApiException>().having(
              (error) => error.statusCode,
              'statusCode',
              401,
            ),
          ),
        );

        expect(session.user, isNull);
        expect(session.api.token, isNull);
        expect(session.sessionNotice, contains('no se pudo borrar'));
        session.dispose();
      },
    );
  });
}

class _FakeSessionStorage implements SessionStorage {
  _FakeSessionStorage([Map<String, String>? initialValues])
    : values = Map.of(initialValues ?? const {});

  final Map<String, String> values;
  String? failDeleteKey;
  String? failWriteKey;

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async {
    if (key == failWriteKey) {
      throw Exception('No fue posible guardar $key');
    }
    values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    if (key == failDeleteKey) {
      throw Exception('No fue posible borrar $key');
    }
    values.remove(key);
  }
}
