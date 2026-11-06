import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import 'package:cartagena_segura/core/data/models.dart';

enum SafetyLevel { safe, moderate, risky }

class DestinationPreset {
  const DestinationPreset({
    required this.name,
    required this.description,
    required this.location,
    required this.category,
  });

  final String name;
  final String description;
  final LatLng location;
  final String category;
}

class SafeRoute {
  const SafeRoute({
    required this.points,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.dangerIndex,
    required this.safetyScore,
    required this.safetyLevel,
    required this.hazardsOnRoute,
    required this.label,
    required this.isRecommended,
  });

  final List<LatLng> points;
  final double distanceMeters;
  final double durationSeconds;
  final double dangerIndex;
  final int safetyScore;
  final SafetyLevel safetyLevel;
  final List<Incident> hazardsOnRoute;
  final String label;
  final bool isRecommended;

  String get formattedDuration {
    final minutes = (durationSeconds / 60).round();
    if (minutes < 60) return '$minutes min';
    final hours = minutes ~/ 60;
    final remainingMin = minutes % 60;
    return '${hours}h ${remainingMin}m';
  }

  String get formattedDistance {
    if (distanceMeters < 1000) return '${distanceMeters.round()} m';
    return '${(distanceMeters / 1000).toStringAsFixed(1)} km';
  }

  String get safetyBadgeText => switch (safetyLevel) {
    SafetyLevel.safe => 'Ruta Segura',
    SafetyLevel.moderate => 'Precaución Moderada',
    SafetyLevel.risky => 'Riesgo Alto',
  };
}

class SafeRouteService {
  const SafeRouteService._();

  static const _distance = Distance();

  /// Destinos emblemáticos de Cartagena para acceso inmediato con 1 toque.
  static const List<DestinationPreset> cartagenaPresets = [
    DestinationPreset(
      name: 'Torre del Reloj / Centro Histórico',
      description: 'Entrada principal a la Ciudad Amurallada',
      location: LatLng(10.4236, -75.5478),
      category: 'Turismo',
    ),
    DestinationPreset(
      name: 'Playas de Bocagrande',
      description: 'Av. San Martín / Sector hotelero y comercial',
      location: LatLng(10.4001, -75.5562),
      category: 'Turismo',
    ),
    DestinationPreset(
      name: 'Getsemaní (Plaza de la Trinidad)',
      description: 'Zona cultural y gastronómica',
      location: LatLng(10.4208, -75.5452),
      category: 'Cultural',
    ),
    DestinationPreset(
      name: 'Castillo San Felipe de Barajas',
      description: 'Fortaleza histórica sobre Av. Pedro de Heredia',
      location: LatLng(10.4225, -75.5385),
      category: 'Monumento',
    ),
    DestinationPreset(
      name: 'Manga (Avenida Miramar)',
      description: 'Sector residencial y náutico frente a la bahía',
      location: LatLng(10.4124, -75.5360),
      category: 'Residencial',
    ),
    DestinationPreset(
      name: 'Castillogrande',
      description: 'Paseo peatonal y bahía de Cartagena',
      location: LatLng(10.3920, -75.5540),
      category: 'Residencial',
    ),
    DestinationPreset(
      name: 'Aeropuerto Rafael Núñez (Crespo)',
      description: 'Terminal aérea de Cartagena',
      location: LatLng(10.4424, -75.5129),
      category: 'Transporte',
    ),
    DestinationPreset(
      name: 'Terminal de Transportes',
      description: 'Vía Cordialidad / Salida hacia Barranquilla',
      location: LatLng(10.3970, -75.4640),
      category: 'Transporte',
    ),
  ];

  /// Calcula rutas entre [origin] y [destination] consultando el motor de rutas (OSRM)
  /// y evaluando el índice de seguridad y peligrosidad según los reportes de incidentes.
  static Future<List<SafeRoute>> calculateRoutes({
    required LatLng origin,
    required LatLng destination,
    required List<Incident> incidents,
    http.Client? client,
  }) async {
    final httpClient = client ?? http.Client();
    final url = Uri.parse(
      'https://router.project-osrm.org/route/v1/driving/'
      '${origin.longitude},${origin.latitude};'
      '${destination.longitude},${destination.latitude}'
      '?overview=full&geometries=geojson&alternatives=true',
    );

    List<Map<String, dynamic>> rawRoutes = [];

    try {
      final response = await httpClient.get(url).timeout(const Duration(seconds: 7));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['code'] == 'Ok' && data['routes'] is List) {
          rawRoutes = (data['routes'] as List).cast<Map<String, dynamic>>();
        }
      }
    } catch (_) {
      // Si OSRM no responde o no hay conexión, se genera una ruta directa interpolada
    } finally {
      if (client == null) {
        httpClient.close();
      }
    }

    // Si no obtuvimos rutas de OSRM, generamos ruta de contingencia
    if (rawRoutes.isEmpty) {
      rawRoutes = [_generateFallbackRoute(origin, destination)];
    }

    final validIncidents = incidents
        .where((i) => i.latitude != null && i.longitude != null)
        .toList();

    final evaluatedRoutes = <SafeRoute>[];

    for (var i = 0; i < rawRoutes.length; i++) {
      final raw = rawRoutes[i];
      final geometry = raw['geometry'] as Map<String, dynamic>? ?? {};
      final rawCoords = (geometry['coordinates'] as List? ?? const [])
          .cast<List<dynamic>>();

      final points = rawCoords.map((coord) {
        final lon = (coord[0] as num).toDouble();
        final lat = (coord[1] as num).toDouble();
        return LatLng(lat, lon);
      }).toList();

      if (points.isEmpty) {
        points.addAll([origin, destination]);
      }

      final distanceMeters = ((raw['distance'] as num?) ?? _distance.as(LengthUnit.Meter, origin, destination)).toDouble();
      final durationSeconds = ((raw['duration'] as num?) ?? (distanceMeters / 8.5)).toDouble();

      // Evaluar peligrosidad
      final (dangerIndex, hazards) = _evaluateRouteSafety(points, validIncidents);
      final safetyScore = max(5, min(100, 100 - dangerIndex.round()));

      final safetyLevel = switch (dangerIndex) {
        <= 15.0 => SafetyLevel.safe,
        <= 35.0 => SafetyLevel.moderate,
        _ => SafetyLevel.risky,
      };

      evaluatedRoutes.add(
        SafeRoute(
          points: points,
          distanceMeters: distanceMeters,
          durationSeconds: durationSeconds,
          dangerIndex: dangerIndex,
          safetyScore: safetyScore,
          safetyLevel: safetyLevel,
          hazardsOnRoute: hazards,
          label: i == 0 ? 'Ruta Principal' : 'Alternativa ${i + 1}',
          isRecommended: false,
        ),
      );
    }

    // Ordenar de mayor a menor seguridad (menor dangerIndex es más segura)
    evaluatedRoutes.sort((a, b) {
      final scoreComp = a.dangerIndex.compareTo(b.dangerIndex);
      if (scoreComp != 0) return scoreComp;
      return a.durationSeconds.compareTo(b.durationSeconds);
    });

    // Etiquetar la ruta más segura como la Recomendada
    final labeledRoutes = <SafeRoute>[];
    for (var i = 0; i < evaluatedRoutes.length; i++) {
      final r = evaluatedRoutes[i];
      final isRec = (i == 0);
      String customLabel;
      if (isRec) {
        customLabel = r.safetyLevel == SafetyLevel.safe
            ? 'Ruta Segura (Recomendada)'
            : 'Ruta con Menos Riesgo';
      } else {
        customLabel = 'Ruta Alternativa (${r.formattedDuration})';
      }

      labeledRoutes.add(
        SafeRoute(
          points: r.points,
          distanceMeters: r.distanceMeters,
          durationSeconds: r.durationSeconds,
          dangerIndex: r.dangerIndex,
          safetyScore: r.safetyScore,
          safetyLevel: r.safetyLevel,
          hazardsOnRoute: r.hazardsOnRoute,
          label: customLabel,
          isRecommended: isRec,
        ),
      );
    }

    return labeledRoutes;
  }

  /// Evalúa el peligro de la ruta calculando la distancia de cada incidente al trayecto.
  /// Un incidente a menos de 220 metros de la calle penaliza la ruta según su prioridad y estado.
  static (double, List<Incident>) _evaluateRouteSafety(
    List<LatLng> points,
    List<Incident> incidents,
  ) {
    if (points.isEmpty || incidents.isEmpty) {
      return (0.0, const []);
    }

    // Muestreo de puntos de la ruta cada ~50 metros para no sobrecargar el cálculo
    final sampledPoints = _samplePolyline(points, stepMeters: 50.0);
    final hazards = <Incident>[];
    double totalDanger = 0.0;

    for (final incident in incidents) {
      final incPoint = LatLng(incident.latitude!, incident.longitude!);
      double minDistance = double.infinity;

      for (final routePoint in sampledPoints) {
        final d = _distance.as(LengthUnit.Meter, incPoint, routePoint);
        if (d < minDistance) {
          minDistance = d;
          if (minDistance < 220.0) break; // Ya está en rango de riesgo
        }
      }

      if (minDistance <= 220.0) {
        hazards.add(incident);

        // Ponderación por severidad
        double weight = switch (incident.priority.toUpperCase()) {
          'CRITICAL' => 25.0,
          'HIGH' => 15.0,
          'MEDIUM' => 8.0,
          _ => 3.0,
        };

        // Si el estado es resuelto, penaliza menos (antecedente histórico)
        final status = incident.status.toUpperCase();
        if (status == 'RESOLVED' || status == 'DISMISSED') {
          weight *= 0.25;
        }

        totalDanger += weight;
      }
    }

    return (totalDanger, hazards);
  }

  /// Muestrea puntos espaciados uniformemente a lo largo de la polilínea
  static List<LatLng> _samplePolyline(List<LatLng> points, {double stepMeters = 50.0}) {
    if (points.length <= 2) return points;

    final samples = <LatLng>[points.first];
    double accumulated = 0.0;

    for (var i = 0; i < points.length - 1; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];
      final segDist = _distance.as(LengthUnit.Meter, p1, p2);

      if (accumulated + segDist >= stepMeters) {
        samples.add(p2);
        accumulated = 0.0;
      } else {
        accumulated += segDist;
      }
    }

    if (samples.last != points.last) {
      samples.add(points.last);
    }

    return samples;
  }

  /// Genera una ruta de contingencia conectando origen y destino con puntos intermedios
  static Map<String, dynamic> _generateFallbackRoute(LatLng origin, LatLng destination) {
    final dist = _distance.as(LengthUnit.Meter, origin, destination);
    final midLat = (origin.latitude + destination.latitude) / 2;
    final midLon = (origin.longitude + destination.longitude) / 2;

    return {
      'distance': dist,
      'duration': dist / 8.5,
      'geometry': {
        'coordinates': [
          [origin.longitude, origin.latitude],
          [midLon, midLat],
          [destination.longitude, destination.latitude],
        ],
      },
    };
  }

  /// Búsqueda de destinos libres en Cartagena mediante OpenStreetMap / Nominatim
  static Future<List<DestinationPreset>> searchDestinations(
    String query, {
    http.Client? client,
  }) async {
    final clean = query.trim();
    if (clean.length < 2) return const [];

    final httpClient = client ?? http.Client();
    final url = Uri.parse(
      'https://nominatim.openstreetmap.org/search?q='
      '${Uri.encodeComponent('$clean, Cartagena, Colombia')}'
      '&format=json&limit=5&countrycodes=co',
    );

    try {
      final response = await httpClient.get(
        url,
        headers: {'User-Agent': 'CartagenaSegura/1.0 (contacto@cartagenasegura.gov.co)'},
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List;
        return list.map((item) {
          final lat = double.tryParse(item['lat']?.toString() ?? '') ?? 0.0;
          final lon = double.tryParse(item['lon']?.toString() ?? '') ?? 0.0;
          final displayName = item['display_name']?.toString() ?? clean;
          final name = item['name']?.toString() ?? clean;

          return DestinationPreset(
            name: name.isNotEmpty ? name : clean,
            description: displayName,
            location: LatLng(lat, lon),
            category: 'Búsqueda',
          );
        }).where((p) => p.location.latitude != 0.0).toList();
      }
    } catch (_) {
      // Si falla, se filtra sobre los presets locales
    } finally {
      if (client == null) {
        httpClient.close();
      }
    }

    return cartagenaPresets
        .where((p) => p.name.toLowerCase().contains(clean.toLowerCase()))
        .toList();
  }
}
