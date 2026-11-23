import 'models.dart';

List<Incident> filterIncidents(
  Iterable<Incident> incidents, {
  String? type,
  String? status,
  String? priority,
}) => incidents
    .where(
      (incident) =>
          (type == null || incident.type == type) &&
          (status == null || incident.status == status) &&
          (priority == null || incident.priority == priority),
    )
    .toList(growable: false);
