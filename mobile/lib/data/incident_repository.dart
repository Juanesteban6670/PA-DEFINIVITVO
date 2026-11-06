import 'api_client.dart';
import 'models.dart';

Future<List<Incident>> loadIncidents(ApiClient api, {bool mine = false}) async {
  final response = await api.get(mine ? 'Incidents/My' : 'Incidents');
  if (response is! List) {
    throw const FormatException(
      'La API devolvió una lista de incidentes inválida',
    );
  }
  return response
      .whereType<Map<String, dynamic>>()
      .map(Incident.fromJson)
      .toList(growable: false);
}
