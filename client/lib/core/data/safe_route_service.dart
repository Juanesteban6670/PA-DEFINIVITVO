import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import 'package:cartagena_segura/core/data/models.dart';

enum SafetyLevel { safe, moderate, risky }

enum TransportMode {
  driving('Vehicular', 'driving', Icons.directions_car_rounded),
  walking('Caminata Segura', 'foot', Icons.directions_walk_rounded);

  const TransportMode(this.label, this.osrmProfile, this.icon);
  final String label;
  final String osrmProfile;
  final IconData icon;
}

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

  int get highRiskCount =>
      hazardsOnRoute.where(SafeRouteService.isHighRisk).length;

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
    TransportMode mode = TransportMode.driving,
    http.Client? client,
    bool allowFallback = true,
    List<Incident> avoid = const [],
  }) async {
    final httpClient = client ?? http.Client();
    final profile = mode.osrmProfile;
    final url = Uri.parse(
      'https://router.project-osrm.org/route/v1/$profile/'
      '${origin.longitude},${origin.latitude};'
      '${destination.longitude},${destination.latitude}'
      '?overview=full&geometries=geojson&alternatives=3',
    );

    List<Map<String, dynamic>> rawRoutes = [];

    try {
      final response = await httpClient
          .get(url)
          .timeout(const Duration(seconds: 7));
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
      if (!allowFallback || avoid.isNotEmpty) return const [];
      rawRoutes = [_generateFallbackRoute(origin, destination)];
    }

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

      if (points.length < 2 ||
          evaluatedRoutes.any(
            (route) =>
                route.points.length == points.length &&
                Iterable<int>.generate(points.length)
                    .every((index) => route.points[index] == points[index]),
          ) ||
          incidentsNearRoute(points, avoid).isNotEmpty) {
        continue;
      }

      final distanceMeters =
          ((raw['distance'] as num?) ??
                  _distance.as(LengthUnit.Meter, origin, destination))
              .toDouble();
      final durationSeconds =
          ((raw['duration'] as num?) ?? (distanceMeters / 8.5)).toDouble();

      evaluatedRoutes.add(
        _score(points, distanceMeters, durationSeconds, incidents),
      );
    }

    return refreshRoutes(evaluatedRoutes, incidents).take(3).toList();
  }

  static bool isActive(Incident incident) => !const {
    'RESOLVED',
    'REJECTED',
    'DISMISSED',
  }.contains(incident.status.toUpperCase());

  static bool isHighRisk(Incident incident) =>
      const {'HIGH', 'CRITICAL'}.contains(incident.priority.toUpperCase());

  static List<SafeRoute> refreshRoutes(
    List<SafeRoute> routes,
    List<Incident> incidents,
  ) {
    final scored = routes
        .map(
          (route) => _score(
            route.points,
            route.distanceMeters,
            route.durationSeconds,
            incidents,
          ),
        )
        .toList();
    scored.sort((a, b) {
      final highRisk = a.highRiskCount.compareTo(b.highRiskCount);
      if (highRisk != 0) return highRisk;
      final total = a.hazardsOnRoute.length.compareTo(b.hazardsOnRoute.length);
      return total != 0
          ? total
          : a.durationSeconds.compareTo(b.durationSeconds);
    });
    return [
      for (var i = 0; i < scored.length; i++)
        SafeRoute(
          points: scored[i].points,
          distanceMeters: scored[i].distanceMeters,
          durationSeconds: scored[i].durationSeconds,
          dangerIndex: scored[i].dangerIndex,
          safetyScore: scored[i].safetyScore,
          safetyLevel: scored[i].safetyLevel,
          hazardsOnRoute: scored[i].hazardsOnRoute,
          label: i == 0
              ? 'Menor riesgo según reportes activos'
              : 'Alternativa ${i + 1}',
          isRecommended: i == 0,
        ),
    ];
  }

  static SafeRoute _score(
    List<LatLng> points,
    double distance,
    double duration,
    List<Incident> incidents,
  ) {
    final hazards = incidentsNearRoute(points, incidents);
    final danger = hazards.fold(
      0.0,
      (total, incident) =>
          total +
          switch (incident.priority.toUpperCase()) {
            'CRITICAL' => 25,
            'HIGH' => 15,
            'MEDIUM' => 8,
            _ => 3,
          },
    );
    return SafeRoute(
      points: points,
      distanceMeters: distance,
      durationSeconds: duration,
      dangerIndex: danger,
      safetyScore: max(5, 100 - danger.round()),
      safetyLevel: switch (danger) {
        <= 15 => SafetyLevel.safe,
        <= 35 => SafetyLevel.moderate,
        _ => SafetyLevel.risky,
      },
      hazardsOnRoute: hazards,
      label: '',
      isRecommended: false,
    );
  }

  static const routeCorridorMeters = 220.0;

  static List<Incident> incidentsNearRoute(
    List<LatLng> points,
    Iterable<Incident> incidents, {
    double corridorMeters = routeCorridorMeters,
  }) {
    final seen = <String>{};
    return [
      for (final incident in incidents)
        if (isActive(incident) &&
            incident.latitude != null &&
            incident.longitude != null &&
            distanceToRoute(
                  LatLng(incident.latitude!, incident.longitude!),
                  points,
                ) <=
                corridorMeters &&
            seen.add(incident.id))
          incident,
    ];
  }

  static double distanceToRoute(LatLng point, List<LatLng> points) {
    const metersPerDegree = 111195.0;
    final longitudeScale = metersPerDegree * cos(point.latitude * pi / 180);
    var closest = double.infinity;
    for (var i = 1; i < points.length; i++) {
      final start = points[i - 1];
      final end = points[i];
      final x = (start.longitude - point.longitude) * longitudeScale;
      final y = (start.latitude - point.latitude) * metersPerDegree;
      final dx = (end.longitude - start.longitude) * longitudeScale;
      final dy = (end.latitude - start.latitude) * metersPerDegree;
      final lengthSquared = dx * dx + dy * dy;
      final t = lengthSquared == 0
          ? 0.0
          : (-(x * dx + y * dy) / lengthSquared).clamp(0.0, 1.0);
      final px = x + t * dx;
      final py = y + t * dy;
      closest = min(closest, px * px + py * py);
    }
    return sqrt(closest);
  }

  /// Genera una ruta de contingencia conectando origen y destino con puntos intermedios
  static Map<String, dynamic> _generateFallbackRoute(
    LatLng origin,
    LatLng destination,
  ) {
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
      final response = await httpClient
          .get(
            url,
            headers: {
              'User-Agent':
                  'CartagenaSegura/1.0 (contacto@cartagenasegura.gov.co)',
            },
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List;
        return list
            .map((item) {
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
            })
            .where((p) => p.location.latitude != 0.0)
            .toList();
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
