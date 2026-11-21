import 'package:cartagena_segura/core/data/incident_repository.dart';
import 'package:cartagena_segura/core/data/models.dart';
import 'package:cartagena_segura/features/citizen/presentation/zone_proximity_alerts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('recent reports are ordered by date and limited to four', () {
    final reports = [
      for (final day in [3, 5, 1, 4, 2])
        Incident(
          id: '$day',
          type: 'Robo',
          description: '',
          location: 'Centro',
          createdAt: DateTime.utc(2026, 1, day),
        ),
      const Incident(
        id: 'unknown',
        type: 'Otro',
        description: '',
        location: '',
      ),
    ];
    expect(latestIncidents(reports).map((item) => item.id), [
      '5',
      '4',
      '3',
      '2',
    ]);
    expect(reports.first.id, '3');
  });

  test('distance is measured to the modeled zone boundary', () {
    expect(distanceToDistrictZone(500), 0);
    expect(distanceToDistrictZone(650), 0);
    expect(distanceToDistrictZone(1000), 350);
    expect(distanceToDistrictZone(1001), greaterThan(350));
  });
}
