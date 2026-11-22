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

List<Incident> latestIncidents(Iterable<Incident> incidents, {int limit = 4}) {
  final sorted = incidents.toList()
    ..sort((a, b) {
      final first = a.createdAt;
      final second = b.createdAt;
      if (first == null) return second == null ? 0 : 1;
      if (second == null) return -1;
      return second.compareTo(first);
    });
  return sorted.take(limit).toList(growable: false);
}
