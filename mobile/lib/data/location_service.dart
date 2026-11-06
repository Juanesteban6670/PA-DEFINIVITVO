import 'package:geolocator/geolocator.dart';

enum LocationSettingsTarget { app, location }

class LocationAccessException implements Exception {
  const LocationAccessException(this.message, {this.settingsTarget});

  final String message;
  final LocationSettingsTarget? settingsTarget;

  @override
  String toString() => message;
}

class LocationService {
  const LocationService._();

  static Future<Position> currentPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const LocationAccessException(
        'Activa los servicios de ubicación del teléfono e inténtalo de nuevo.',
        settingsTarget: LocationSettingsTarget.location,
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      throw const LocationAccessException(
        'El permiso está bloqueado. Activa la ubicación para Cartagena Segura en los ajustes de la aplicación.',
        settingsTarget: LocationSettingsTarget.app,
      );
    }
    if (permission == LocationPermission.denied) {
      throw const LocationAccessException(
        'No se concedió el permiso de ubicación. Puedes continuar con la dirección escrita o volver a intentarlo.',
      );
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 20),
      ),
    );
  }

  static Future<bool> openSettings(LocationSettingsTarget target) =>
      switch (target) {
        LocationSettingsTarget.app => Geolocator.openAppSettings(),
        LocationSettingsTarget.location => Geolocator.openLocationSettings(),
      };
}
