import 'package:cartagena_segura/data/incident_filters.dart';
import 'package:cartagena_segura/data/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final incidents = [
    Incident.fromJson({
      'id': 'located',
      'type': 'ROBO',
      'status': 'PENDING',
      'priority': 'HIGH',
      'latitude': 10.4,
      'longitude': -75.5,
    }),
    Incident.fromJson({
      'id': 'without-location',
      'type': 'INCENDIO',
      'status': 'RESOLVED',
      'priority': 'LOW',
    }),
  ];

  test('combines type, state, and priority filters', () {
    final filtered = filterIncidents(
      incidents,
      type: 'ROBO',
      status: 'PENDING',
      priority: 'HIGH',
    );

    expect(filtered.map((incident) => incident.id), ['located']);
  });

  test('preserves incidents without coordinates for the accessible list', () {
    final filtered = filterIncidents(incidents, type: 'INCENDIO');

    expect(filtered.single.id, 'without-location');
    expect(filtered.single.latitude, isNull);
    expect(filtered.single.longitude, isNull);
  });

  test('returns all incidents when no filters are selected', () {
    expect(filterIncidents(incidents), hasLength(2));
  });
}
