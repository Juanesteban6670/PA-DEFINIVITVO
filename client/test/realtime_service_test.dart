import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:cartagena_segura/core/data/realtime_service.dart';

void main() {
  group('RealtimeAlertService', () {
    test(
      'polls the incidents API if the Android websocket is unavailable',
      () async {
        final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
        addTearDown(() => server.close(force: true));
        server.listen((request) async {
          request.response.statusCode = HttpStatus.notFound;
          await request.response.close();
        });
        final requestedUri = Completer<Uri>();
        final origin = 'http://127.0.0.1:${server.port}';
        final service = RealtimeAlertService(
          baseUrl: '$origin/api/',
          client: MockClient((request) async {
            if (!requestedUri.isCompleted) requestedUri.complete(request.url);
            return http.Response('{"data":[]}', 200);
          }),
        );
        addTearDown(service.dispose);

        service.connect();

        expect(
          await requestedUri.future.timeout(const Duration(seconds: 5)),
          Uri.parse('$origin/api/Incidents'),
        );
      },
    );

    test('initializes with disconnected state', () {
      final service = RealtimeAlertService(baseUrl: 'http://localhost:8080');
      expect(service.connectionMode.value, RealtimeMode.disconnected);
      service.dispose();
    });

    test('registers and removes incident and alert listeners', () {
      final service = RealtimeAlertService(baseUrl: 'http://localhost:8080');

      void incidentListener() {}
      void alertListener(Map<String, dynamic> alert) {}

      service.addIncidentListener(incidentListener);
      service.addAlertListener(alertListener);

      service.removeIncidentListener(incidentListener);
      service.removeAlertListener(alertListener);

      service.dispose();
    });
  });
}
