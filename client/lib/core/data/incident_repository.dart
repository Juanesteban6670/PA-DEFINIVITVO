import 'api_client.dart';
import 'models.dart';

Future<List<Incident>> loadIncidents(ApiClient api, {bool mine = false}) async {
  if (mine && (api.token == null || api.token!.isEmpty)) {
    throw const ApiException(
      'Inicia sesión para ver tus reportes personales',
      statusCode: 401,
    );
  }
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
