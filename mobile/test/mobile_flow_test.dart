import 'dart:convert';

import 'package:cartagena_segura/data/api_client.dart';
import 'package:cartagena_segura/data/session_controller.dart';
import 'package:cartagena_segura/screens/home_shell.dart';
import 'package:cartagena_segura/screens/sign_in_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('Sign-in and registration screens', () {
    testWidgets('submits valid credentials and displays API errors', (
      tester,
    ) async {
      _setMobileViewport(tester);
      final storage = _MemorySessionStorage();
      final session = SessionController(
        api: ApiClient(
          baseUrl: 'https://api.example.com/api',
          client: MockClient(
            (_) async => http.Response(
              '{"success":false,"message":"Credenciales incorrectas","data":null}',
              401,
            ),
          ),
        ),
        storage: storage,
      );
      await session.initialize();
      await tester.pumpWidget(
        MaterialApp(home: SignInScreen(session: session)),
      );

      await tester.enterText(find.byType(TextFormField).at(0), 'citizen');
      await tester.enterText(find.byType(TextFormField).at(1), 'wrongpass');
      await tester.tap(find.text('Iniciar sesión'));
      await tester.pumpAndSettle();

      expect(find.text('Credenciales incorrectas'), findsOneWidget);
      expect(session.user, isNull);
      session.dispose();
    });

    testWidgets('validates and submits the citizen registration form', (
      tester,
    ) async {
      _setMobileViewport(tester);
      Map<String, dynamic>? submitted;
      final storage = _MemorySessionStorage();
      final session = SessionController(
        api: ApiClient(
          baseUrl: 'https://api.example.com/api',
          client: MockClient((request) async {
            submitted = jsonDecode(request.body) as Map<String, dynamic>;
            return http.Response(
              jsonEncode({
                'success': true,
                'message': 'Registro exitoso',
                'data': {
                  'token': 'created-token',
                  'username': 'newcitizen',
                  'fullName': 'Nombre Completo',
                  'email': 'citizen@example.com',
                },
              }),
              200,
            );
          }),
        ),
        storage: storage,
      );
      await session.initialize();
      await tester.pumpWidget(
        MaterialApp(home: SignInScreen(session: session)),
      );

      await tester.tap(find.text('Crear una cuenta ciudadana'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Crear cuenta'));
      await tester.tap(find.text('Crear cuenta'));
      await tester.pumpAndSettle();
      expect(find.text('Este campo es obligatorio'), findsNWidgets(4));

      await tester.enterText(
        find.byType(TextFormField).at(0),
        'Nombre Completo',
      );
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'citizen@example.com',
      );
      await tester.ensureVisible(find.byType(TextFormField).at(2));
      await tester.enterText(find.byType(TextFormField).at(2), '3001234567');
      await tester.enterText(find.byType(TextFormField).at(3), ' newcitizen ');
      await tester.enterText(find.byType(TextFormField).at(4), 'secret1');
      await tester.ensureVisible(find.text('Crear cuenta'));
      await tester.tap(find.text('Crear cuenta'));
      await tester.pumpAndSettle();

      expect(submitted?['username'], 'newcitizen');
      expect(submitted?['fullName'], 'Nombre Completo');
      expect(session.user?.username, 'newcitizen');
      expect(storage.values['session.token'], 'created-token');
      session.dispose();
    });
  });

  testWidgets(
    'refreshes incidents after a successful report and navigates tabs',
    (tester) async {
      _setMobileViewport(tester);
      var incidentReads = 0;
      final storage = _MemorySessionStorage({
        'session.token': 'valid-token',
        'session.user': jsonEncode({
          'username': 'citizen',
          'fullName': 'Persona Ciudadana',
          'email': 'citizen@example.com',
        }),
      });
      final client = MockClient((request) async {
        if (request.method == 'GET' && request.url.path == '/api/Incidents') {
          incidentReads++;
          return http.Response(
            '{"success":true,"message":"OK","data":[]}',
            200,
          );
        }
        if (request.method == 'GET' &&
            request.url.path == '/api/EmergencyContacts') {
          return http.Response(
            '{"success":true,"message":"OK","data":[]}',
            200,
          );
        }
        if (request.method == 'POST' && request.url.path == '/api/Incidents') {
          return http.Response(
            '{"success":true,"message":"Creado","data":{"id":"new-incident"}}',
            200,
          );
        }
        return http.Response(
          '{"success":false,"message":"Ruta inesperada","data":null}',
          404,
        );
      });
      final session = SessionController(
        api: ApiClient(baseUrl: 'https://api.example.com/api', client: client),
        storage: storage,
      );
      await session.initialize();
      await tester.pumpWidget(MaterialApp(home: HomeShell(session: session)));
      await tester.pump();
      expect(incidentReads, 1);

      await tester.tap(find.text('Reportar').last);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextFormField).at(0),
        'Descripción del reporte',
      );
      await tester.enterText(find.byType(TextFormField).at(1), 'Barrio Centro');
      await tester.ensureVisible(find.text('Enviar reporte'));
      await tester.tap(find.text('Enviar reporte'));
      await tester.pumpAndSettle();

      expect(
        find.text('Tu reporte fue enviado a Cartagena Segura'),
        findsOneWidget,
      );
      expect(incidentReads, 2);

      await tester.tap(find.text('Emergencias').last);
      await tester.pumpAndSettle();
      expect(find.text('Contactos disponibles'), findsOneWidget);
      expect(find.text('Llamar al 123'), findsOneWidget);

      await tester.tap(find.text('Inicio').last);
      await tester.pumpAndSettle();
      expect(find.text('Hola, Persona Ciudadana'), findsOneWidget);
      session.dispose();
    },
  );
}

void _setMobileViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

class _MemorySessionStorage implements SessionStorage {
  _MemorySessionStorage([Map<String, String>? values])
    : values = Map.of(values ?? const {});

  final Map<String, String> values;

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    values.remove(key);
  }
}
