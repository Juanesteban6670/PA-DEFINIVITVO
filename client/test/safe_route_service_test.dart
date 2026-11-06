import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:latlong2/latlong.dart';

import 'package:cartagena_segura/core/data/models.dart';
import 'package:cartagena_segura/core/data/safe_route_service.dart';

void main() {
  group('SafeRouteService Tests', () {
    test('cartagenaPresets are defined and have valid coordinates', () {
      expect(SafeRouteService.cartagenaPresets.isNotEmpty, isTrue);
      for (final preset in SafeRouteService.cartagenaPresets) {
        expect(preset.name.isNotEmpty, isTrue);
        expect(preset.location.latitude, inInclusiveRange(10.0, 11.0));
        expect(preset.location.longitude, inInclusiveRange(-76.0, -75.0));
      }
    });

    test('calculateRoutes returns clean route with 100% safety when no incidents', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'code': 'Ok',
            'routes': [
              {
                'distance': 2500.0,
                'duration': 300.0,
                'geometry': {
                  'coordinates': [
                    [-75.5478, 10.4236],
                    [-75.5500, 10.4100],
                    [-75.5562, 10.4001],
                  ],
                },
              }
            ],
          }),
          200,
        );
      });

      final routes = await SafeRouteService.calculateRoutes(
        origin: const LatLng(10.4236, -75.5478),
        destination: const LatLng(10.4001, -75.5562),
        incidents: const [],
        client: mockClient,
      );

      expect(routes.length, 1);
      final route = routes.first;
      expect(route.safetyScore, 100);
      expect(route.safetyLevel, SafetyLevel.safe);
      expect(route.hazardsOnRoute.isEmpty, isTrue);
      expect(route.formattedDistance, '2.5 km');
      expect(route.formattedDuration, '5 min');
      expect(route.isRecommended, isTrue);
    });

    test('calculateRoutes penalizes route when critical incidents are in trajectory', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'code': 'Ok',
            'routes': [
              {
                'distance': 1000.0,
                'duration': 120.0,
                'geometry': {
                  'coordinates': [
                    [-75.5478, 10.4236],
                    [-75.5480, 10.4230],
                    [-75.5490, 10.4220],
                  ],
                },
              }
            ],
          }),
          200,
        );
      });

      // Incidente crítico a menos de 50 metros del punto central de la ruta
      final incidents = [
        const Incident(
          id: 'inc-1',
          type: 'Robo a mano armada',
          description: 'Sector peligroso',
          location: 'Centro',
          latitude: 10.4230,
          longitude: -75.5480,
          priority: 'CRITICAL',
          status: 'PENDING',
        ),
      ];

      final routes = await SafeRouteService.calculateRoutes(
        origin: const LatLng(10.4236, -75.5478),
        destination: const LatLng(10.4220, -75.5490),
        incidents: incidents,
        client: mockClient,
      );

      expect(routes.length, 1);
      final route = routes.first;
      expect(route.dangerIndex, greaterThan(0));
      expect(route.safetyScore, lessThan(100));
      expect(route.hazardsOnRoute.length, 1);
      expect(route.hazardsOnRoute.first.id, 'inc-1');
    });

    test('calculateRoutes gracefully falls back when OSRM fails', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Server error', 500);
      });

      final routes = await SafeRouteService.calculateRoutes(
        origin: const LatLng(10.4236, -75.5478),
        destination: const LatLng(10.4001, -75.5562),
        incidents: const [],
        client: mockClient,
      );

      expect(routes.isNotEmpty, isTrue);
      expect(routes.first.points.length, greaterThanOrEqualTo(2));
      expect(routes.first.distanceMeters, greaterThan(0));
    });
  });
}
