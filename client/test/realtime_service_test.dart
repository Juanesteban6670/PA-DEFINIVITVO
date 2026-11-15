import 'package:flutter_test/flutter_test.dart';

import 'package:cartagena_segura/core/data/realtime_service.dart';

void main() {
  group('RealtimeAlertService', () {
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
