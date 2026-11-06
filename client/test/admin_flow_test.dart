import 'dart:convert';

import 'package:cartagena_segura/core/data/api_client.dart';
import 'package:cartagena_segura/core/data/report_draft_store.dart';
import 'package:cartagena_segura/core/data/session_controller.dart';
import 'package:cartagena_segura/features/admin/presentation/admin_shell.dart';
import 'package:cartagena_segura/features/citizen/presentation/my_reports_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('filters incidents by status', (tester) async {
    _setViewport(tester);
    final api = ApiClient(
      baseUrl: 'https://api.example.com/api',
      client: MockClient((request) async {
        expect(request.url.path, '/api/Incidents');
        return http.Response(
          jsonEncode({
            'success': true,
            'data': [
              {'id': 'pending', 'type': 'Robo', 'status': 'PENDING'},
              {'id': 'resolved', 'type': 'Choque', 'status': 'RESOLVED'},
            ],
          }),
          200,
        );
      }),
    );
    addTearDown(api.close);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AdminSectionPage(api: api, location: '/Admin/Incidents'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Robo'), findsOneWidget);
    expect(find.text('Choque'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilterChip, 'Pendiente'));
    await tester.pumpAndSettle();

    expect(find.text('Robo'), findsOneWidget);
    expect(find.text('Choque'), findsNothing);
  });

  testWidgets('opens an incident selected through its URL id', (tester) async {
    _setViewport(tester);
    final api = ApiClient(
      baseUrl: 'https://api.example.com/api',
      client: MockClient((request) async {
        expect(request.url.path, '/api/Incidents');
        return http.Response(
          '{"success":true,"data":[{"id":"incident-1","type":"Robo","status":"PENDING"}]}',
          200,
        );
      }),
    );
    addTearDown(api.close);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AdminSectionPage(
            api: api,
            location: '/Admin/Incidents',
            initialIncidentId: 'incident-1',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Robo'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('opens a citizen report selected through its URL id', (
    tester,
  ) async {
    _setViewport(tester);
    final api = ApiClient(
      baseUrl: 'https://api.example.com/api',
      client: MockClient((request) async {
        expect(request.url.path, '/api/Incidents/My');
        return http.Response(
          '{"success":true,"data":[{"id":"incident-1","type":"Robo","status":"PENDING"}]}',
          200,
        );
      }),
    );
    addTearDown(api.close);
    final refresh = ValueNotifier<int>(0);
    addTearDown(refresh.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: MyReportsScreen(
          api: api,
          drafts: ReportDraftStore(storage: _MemoryStorage(), owner: 'citizen'),
          incidentRefresh: refresh,
          onReportSubmitted: () {},
          initialIncidentId: 'incident-1',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(BottomSheet), findsOneWidget);
  });
}

void _setViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1024, 768);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

class _MemoryStorage implements SessionStorage {
  final Map<String, String> values = {};

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
