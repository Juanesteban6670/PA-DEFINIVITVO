import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:cartagena_segura/data/api_client.dart';
import 'package:cartagena_segura/data/models.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('API client', () {
    test('normalizes the API base URL and joins paths', () {
      final api = ApiClient(baseUrl: 'https://api.example.com/api/');

      expect(
        api.endpoint('/Auth/Login').toString(),
        'https://api.example.com/api/Auth/Login',
      );
    });

    test('requires an API URL before making requests', () {
      final api = ApiClient(baseUrl: '');

      expect(() => api.endpoint('Auth/Login'), throwsA(isA<ApiException>()));
    });

    test(
      'reads the Spring response envelope and sends the stored JWT',
      () async {
        final client = MockClient((request) async {
          expect(request.url.path, '/api/Auth/Login');
          expect(request.headers['Authorization'], 'Bearer saved-jwt');
          return http.Response(
            jsonEncode({
              'success': true,
              'message': 'OK',
              'data': {'token': 'new-jwt'},
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        });
        final api = ApiClient(
          baseUrl: 'https://api.example.com/api',
          client: client,
        )..token = 'saved-jwt';

        final result = await api.post('Auth/Login', {
          'username': 'citizen',
          'password': 'password',
        });

        expect(result, {'token': 'new-jwt'});
      },
    );
  });

  test('parses the authentication response returned by Spring', () {
    final user = AppUser.fromJson({
      'token': 'jwt-token',
      'username': 'ciudadano',
      'fullName': 'Persona Ciudadana',
      'email': 'persona@example.com',
      'roles': ['USER'],
    });

    expect(user.token, 'jwt-token');
    expect(user.username, 'ciudadano');
    expect(user.fullName, 'Persona Ciudadana');
  });

  test('parses incident coordinates from JSON numbers', () {
    final incident = Incident.fromJson({
      'id': 'incident-id',
      'type': 'ROBO',
      'description': 'Reporte ciudadano',
      'location': 'Getsemaní',
      'latitude': 10.42,
      'longitude': -75.55,
    });

    expect(incident.latitude, 10.42);
    expect(incident.longitude, -75.55);
  });
}
