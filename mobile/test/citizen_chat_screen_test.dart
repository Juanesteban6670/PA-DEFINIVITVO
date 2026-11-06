import 'dart:convert';

import 'package:cartagena_segura/data/api_client.dart';
import 'package:cartagena_segura/data/session_controller.dart';
import 'package:cartagena_segura/screens/citizen_chat_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('sends an authenticated message and renders the reply', (
    tester,
  ) async {
    _setViewport(tester);
    http.Request? sentRequest;
    final session = await _createSession(
      MockClient((request) async {
        sentRequest = request;
        return http.Response('{"reply":"Consulta las emergencias."}', 200);
      }),
    );
    await tester.pumpWidget(
      MaterialApp(home: CitizenChatScreen(session: session)),
    );

    await tester.enterText(find.byType(TextField), '¿Qué hago?');
    await tester.tap(find.byTooltip('Enviar mensaje'));
    await tester.pumpAndSettle();

    expect(sentRequest?.url.path, '/api/Ai/Chat');
    expect(sentRequest?.headers['authorization'], 'Bearer citizen-token');
    expect(
      jsonDecode(sentRequest!.body),
      containsPair('message', '¿Qué hago?'),
    );
    expect(find.text('Consulta las emergencias.'), findsOneWidget);
    session.dispose();
  });

  testWidgets('shows an API error and retries the failed message', (
    tester,
  ) async {
    _setViewport(tester);
    var requests = 0;
    final session = await _createSession(
      MockClient((_) async {
        requests++;
        if (requests == 1) {
          return http.Response('{"message":"IA no disponible"}', 503);
        }
        return http.Response('{"reply":"Estoy disponible."}', 200);
      }),
    );
    await tester.pumpWidget(
      MaterialApp(home: CitizenChatScreen(session: session)),
    );

    await tester.enterText(find.byType(TextField), 'Ayuda');
    await tester.tap(find.byTooltip('Enviar mensaje'));
    await tester.pumpAndSettle();
    expect(find.text('IA no disponible'), findsOneWidget);

    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();

    expect(requests, 2);
    expect(find.text('Estoy disponible.'), findsOneWidget);
    expect(find.text('IA no disponible'), findsNothing);
    session.dispose();
  });

  testWidgets('fits a narrow phone viewport without layout exceptions', (
    tester,
  ) async {
    _setViewport(tester, width: 320, height: 568);
    final session = await _createSession(
      MockClient((_) async => http.Response('{"reply":"Respuesta"}', 200)),
    );
    await tester.pumpWidget(
      MaterialApp(home: CitizenChatScreen(session: session)),
    );
    await tester.enterText(find.byType(TextField), 'Una pregunta larga');
    await tester.pump();

    expect(tester.takeException(), isNull);
    session.dispose();
  });
}

Future<SessionController> _createSession(http.Client client) async {
  final session = SessionController(
    api: ApiClient(baseUrl: 'https://api.example.com/api', client: client),
    storage: _TestSessionStorage(),
  );
  await session.initialize();
  session.api.token = 'citizen-token';
  return session;
}

void _setViewport(
  WidgetTester tester, {
  double width = 390,
  double height = 844,
}) {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

class _TestSessionStorage implements SessionStorage {
  final Map<String, String> _values = {};

  @override
  Future<void> delete(String key) async {
    _values.remove(key);
  }

  @override
  Future<String?> read(String key) async => _values[key];

  @override
  Future<void> write(String key, String value) async {
    _values[key] = value;
  }
}
