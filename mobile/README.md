# Cartagena Segura — Flutter para Android/iOS

`mobile/` es el cliente móvil nativo de Cartagena Segura para Android e iOS. Comparte identidad visual y API con la web React/PWA, que se mantiene como cliente web independiente. La app móvil no contiene la consola administrativa ni un backend propio.

## Funcionalidades ciudadanas

- Inicio de sesión, registro y recuperación/restablecimiento de contraseña.
- Sesión persistida mediante almacenamiento seguro del dispositivo.
- Inicio con resumen de reportes propios y accesos rápidos.
- Lista de reportes propios con estado, prioridad y detalle.
- Creación de reportes con ubicación escrita y GPS opcional.
- Mapa de incidentes públicos con OpenStreetMap.
- Contactos de emergencia desde la API y llamada al 123 o a contactos disponibles.
- Perfil de solo lectura y cierre de sesión. El backend actual no ofrece una operación ciudadana para editar el perfil.

El mapa, las teselas, la autenticación y las operaciones de datos requieren conexión. La app no guarda borradores de reportes sin conexión. El formulario no adjunta fotografías todavía.

## Requisitos

- Flutter estable y Dart incluidos con Flutter (el `pubspec.yaml` especifica Dart `^3.13.3`).
- Para Android: Android Studio, Android SDK y un emulador o dispositivo.
- Para iOS: macOS, Xcode y simulador o dispositivo.
- API REST accesible desde el dispositivo. Para funciones con GPS, concede el permiso de ubicación.

## Ejecutar y probar

Desde esta carpeta:

```sh
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000/api
```

`10.0.2.2` permite que el emulador Android alcance la publicación local del frontend de Docker Compose, que hace proxy a `/api`; el backend no publica directamente el puerto 8080. En un teléfono físico utiliza `http://<IP-LAN-del-host>:3000/api`, cambia `WEB_BIND_ADDRESS=0.0.0.0` solo durante una prueba en red confiable y agrega ese origen a `CORS_ALLOWED_ORIGINS` si pruebas Flutter Web. En producción usa HTTPS. `localhost` dentro del teléfono apunta al propio dispositivo, no al servidor.

Para validar la app:

```sh
dart format --set-exit-if-changed lib test
flutter analyze
flutter test
```

Las pruebas usan `MockClient` y verifican autenticación, restauración de sesión, contratos de solicitud, navegación y actualización del mapa/lista después de reportar. También revisa los flujos reales en Android/iOS, en especial permisos GPS, llamadas y almacenamiento seguro.

## Compilar

Para una instalación local Android:

```sh
flutter build apk --release \
  --dart-define=API_BASE_URL=https://tu-dominio.example.com/api
```

Para Google Play:

```sh
flutter build appbundle --release \
  --dart-define=API_BASE_URL=https://tu-dominio.example.com/api
```

La configuración actual de Gradle usa la firma debug para la variante release y solo sirve para pruebas/sideload; **no publiques ese APK/AAB en Google Play**. Antes, el propietario debe cambiarla a una clave de release privada y configurar el registro de Google Play. Los certificados/perfiles de Apple y las cuentas de publicación también los aporta el propietario; no guardes credenciales en el repositorio. iOS se compila desde macOS/Xcode:

```sh
flutter build ipa --release \
  --dart-define=API_BASE_URL=https://tu-dominio.example.com/api
```

No uses una URL local en los artefactos distribuidos. Mantén secretos de servicios externos fuera de `--dart-define` y del paquete cliente.

## Previsualización web de Flutter

Se puede revisar la disposición con Flutter Web, pero esto no reemplaza pruebas nativas de Android/iOS:

```sh
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8080/api
```

Con Docker Compose usa `http://localhost:3000/api`; `localhost:8080` aplica únicamente si se inicia el backend fuera de Compose.

## Integración continua

`.github/workflows/flutter.yml` ejecuta `flutter analyze`, `flutter test` y construye un APK debug para cambios de `mobile/`. La publicación de artefactos release firmados requiere los SDK y credenciales correspondientes y no forma parte de ese workflow.
