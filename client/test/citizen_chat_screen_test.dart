import 'dart:convert';

import 'package:cartagena_segura/core/data/api_client.dart';
import 'package:cartagena_segura/core/data/session_controller.dart';
import 'package:cartagena_segura/features/citizen/presentation/citizen_chat_screen.dart';
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

  testWidgets(
    'restores the same server conversation and can clear local history',
    (tester) async {
      _setViewport(tester);
      final storage = _TestSessionStorage({
        'session.token': 'citizen-token',
        'session.user': jsonEncode({
          'username': 'citizen',
          'fullName': 'Persona Ciudadana',
          'email': 'citizen@example.test',
        }),
      });
      final firstSession = await _createSession(
        MockClient(
          (_) async => http.Response('{"reply":"Primera respuesta"}', 200),
        ),
        storage: storage,
      );
      await tester.pumpWidget(
        MaterialApp(home: CitizenChatScreen(session: firstSession)),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Primera pregunta');
      await tester.tap(find.byTooltip('Enviar mensaje'));
      await tester.pumpAndSettle();

      final savedHistory = jsonDecode(storage.values['citizen.chat.citizen']!);
      final savedSessionId = savedHistory['sessionId'];
      expect(savedHistory['messages'], isNotEmpty);
      firstSession.dispose();

      String? retrySessionId;
      final secondSession = await _createSession(
        MockClient((request) async {
          retrySessionId =
              (jsonDecode(request.body) as Map<String, dynamic>)['sessionId']
                  as String;
          return http.Response('{"reply":"Continuación"}', 200);
        }),
        storage: storage,
      );
      await tester.pumpWidget(
        MaterialApp(home: CitizenChatScreen(session: secondSession)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Primera pregunta'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'Segunda pregunta');
      await tester.tap(find.byTooltip('Enviar mensaje'));
      await tester.pumpAndSettle();
      expect(retrySessionId, savedSessionId);

      await tester.tap(find.byTooltip('Nueva conversación'));
      await tester.pumpAndSettle();
      expect(storage.values.containsKey('citizen.chat.citizen'), isFalse);
      secondSession.dispose();
    },
  );

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

Future<SessionController> _createSession(
  http.Client client, {
  _TestSessionStorage? storage,
}) async {
  final session = SessionController(
    api: ApiClient(baseUrl: 'https://api.example.com/api', client: client),
    storage: storage ?? _TestSessionStorage(),
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
  _TestSessionStorage([Map<String, String>? values]) : values = values ?? {};

  final Map<String, String> values;

  @override
  Future<void> delete(String key) async {
    values.remove(key);
  }

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }
}
