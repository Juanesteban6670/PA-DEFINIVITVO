import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

enum LocationSettingsTarget { app, location }

class LocationAccessException implements Exception {
  const LocationAccessException(
    this.message, {
    this.settingsTarget,
    this.isPermissionBlocked = false,
  });

  final String message;
  final LocationSettingsTarget? settingsTarget;
  final bool isPermissionBlocked;

  @override
  String toString() => message;
}

class LocationService {
  const LocationService._();

  /// Comprueba si el usuario ya otorgó permiso de ubicación previamente.
  static Future<bool> hasPermission() async {
    try {
      final permission = await Geolocator.checkPermission();
      return permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;
    } catch (_) {
      return false;
    }
  }

  /// Comprueba si el permiso se encuentra bloqueado de forma permanente.
  static Future<bool> isPermissionBlocked() async {
    try {
      final permission = await Geolocator.checkPermission();
      return permission == LocationPermission.deniedForever;
    } catch (_) {
      return false;
    }
  }

  /// Obtiene la posición actual implementando fallback progresivo:
  /// 1. Verifica estado de permisos de forma amigable.
  /// 2. Intento 1: Alta precisión satelital (máximo 8 segundos).
  /// 3. Intento 2: Precisión media (antenas celulares/WiFi, máx 10 segundos) si alta precisión da timeout en interiores.
  /// 4. Intento 3: Última posición conocida si el navegador o sistema la tiene en caché.
  static Future<Position> currentPosition() async {
    if (!kIsWeb) {
      try {
        final enabled = await Geolocator.isLocationServiceEnabled();
        if (!enabled) {
          throw const LocationAccessException(
            'Activa los servicios de ubicación del dispositivo e inténtalo de nuevo.',
            settingsTarget: LocationSettingsTarget.location,
          );
        }
      } catch (e) {
        if (e is LocationAccessException) rethrow;
      }
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      throw LocationAccessException(
        kIsWeb
            ? 'El permiso de ubicación fue bloqueado en el navegador.'
            : 'El permiso está bloqueado. Activa la ubicación para Cartagena Segura en los ajustes del dispositivo.',
        settingsTarget: LocationSettingsTarget.app,
        isPermissionBlocked: true,
      );
    }

    if (permission == LocationPermission.denied) {
      throw const LocationAccessException(
        'No se concedió el permiso de ubicación. Puedes ingresar la dirección de forma manual o volver a intentarlo.',
      );
    }

    // Estrategia progresiva / en cascada para Web Móvil:
    // Intento 1: Alta precisión (GNSS/GPS) con timeout razonable (8s)
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      );
    } catch (_) {
      // Intento 2: Precisión media (WiFi / Cell towers) útil en interiores
      try {
        return await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 10),
          ),
        );
      } catch (_) {
        // Intento 3: Última posición registrada si existe
        try {
          final lastKnown = await Geolocator.getLastKnownPosition();
          if (lastKnown != null) {
            return lastKnown;
          }
        } catch (_) {
          // Ignorar y arrojar la excepción final
        }

        throw const LocationAccessException(
          'No fue posible obtener la señal de GPS precisa. Intenta en un espacio abierto o ingresa la dirección escrita.',
        );
      }
    }
  }

  /// Abre ajustes en plataformas nativas; en Web retorna false de forma segura.
  static Future<bool> openSettings(LocationSettingsTarget target) async {
    if (kIsWeb) {
      return false;
    }
    return switch (target) {
      LocationSettingsTarget.app => Geolocator.openAppSettings(),
      LocationSettingsTarget.location => Geolocator.openLocationSettings(),
    };
  }
}
