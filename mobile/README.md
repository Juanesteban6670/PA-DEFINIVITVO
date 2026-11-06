# Cartagena Segura — Flutter para Android/iOS

`mobile/` es el cliente móvil nativo de Cartagena Segura para Android e iOS. Comparte identidad visual y API con la web React/PWA, que se mantiene como cliente web independiente. La app móvil no contiene la consola administrativa ni un backend propio.

## Funcionalidades ciudadanas

- Inicio de sesión, registro y recuperación/restablecimiento de contraseña.
- Sesión persistida mediante almacenamiento seguro del dispositivo.
- Inicio con resumen de reportes propios y accesos rápidos.
- Lista de reportes propios con estado, prioridad y detalle.
- Creación de reportes con ubicación escrita/GPS opcional, evidencia desde cámara o galería, borrador local y cola de reintento.
- Mapa de incidentes públicos con filtros por tipo/estado/prioridad, lista accesible para incidentes sin coordenadas y apertura de ubicaciones en mapas externos.
- Contactos de emergencia desde la API y llamada al 123 o a contactos disponibles.
- Asistente ciudadano conectado al endpoint autenticado existente del backend.
- Historial reciente del chatbot guardado localmente en almacenamiento seguro del dispositivo, con opción para borrarlo.
- Centro de notificaciones de cambios de reportes, sincronizado al abrirlo; requiere conexión y no ofrece notificaciones push.
- Edición autenticada del perfil y cierre de sesión.

El mapa, las teselas, la autenticación y las operaciones de datos requieren conexión. Los borradores de texto y la cola de reportes se guardan en almacenamiento seguro; las fotografías se conservan en el directorio privado de la app hasta confirmar el envío o borrar el pendiente. La cola se reintenta manualmente desde “Mis reportes” cuando vuelve la conexión. La API aplica una clave idempotente para impedir reportes duplicados si se pierde la respuesta de un envío.

La ubicación es opcional: puedes escribir una dirección sin dar permiso. Si los servicios del teléfono están apagados, se deniega el permiso o este quedó bloqueado, la app informa cómo continuar y ofrece abrir los ajustes del sistema. El chatbot utiliza la sesión iniciada y el endpoint `/api/Ai/Chat`; la clave del proveedor de IA permanece configurada en el backend.

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

Las pruebas usan `MockClient` y verifican autenticación, restauración de sesión, contratos de solicitud, navegación y actualización del mapa/lista después de reportar. También revisa los flujos reales en Android/iOS y tamaños de pantalla compactos y tabletas, en especial permisos GPS, llamadas, teclado y almacenamiento seguro.

## Compilar

Para una instalación local Android:

```sh
flutter build apk --release \
  --dart-define=API_BASE_URL=https://tu-dominio.example.com/api
```

La firma release se configura fuera de GitHub, usando estas variables de entorno:

```sh
export ANDROID_KEYSTORE_PATH=/ruta/privada/cartagena-release.jks
export ANDROID_STORE_PASSWORD='...'
export ANDROID_KEY_ALIAS='...'
export ANDROID_KEY_PASSWORD='...'
flutter build appbundle --release \
  --dart-define=API_BASE_URL=https://tu-dominio.example.com/api
```

También se puede crear `mobile/android/key.properties` con `storeFile`, `storePassword`, `keyAlias` y `keyPassword`. Ese archivo, los keystores y sus contraseñas están excluidos de Git. Una compilación release falla expresamente cuando falta la configuración de firma. La publicación Android todavía requiere que el propietario cree/configure la cuenta de Google Play y revise el artefacto.

La distribución iOS requiere macOS/Xcode, cuenta Apple Developer, certificados de distribución y perfiles de aprovisionamiento configurados localmente. No se guardan credenciales ni certificados en el repositorio:

```sh
flutter build ipa --release \
  --dart-define=API_BASE_URL=https://tu-dominio.example.com/api
```

No uses una URL local en los artefactos distribuidos. Mantén secretos de servicios externos fuera de `--dart-define` y del paquete cliente. La solicitud de eliminación de cuenta no está disponible porque aún no existe un flujo backend seguro que preserve la trazabilidad de los reportes.

La interfaz web sigue siendo la aplicación React/PWA en `frontend/`; Flutter está destinado a las apps nativas Android/iOS.

## Integración continua

`.github/workflows/flutter.yml` ejecuta `flutter analyze`, `flutter test` y construye un APK debug para cambios de `mobile/`. La publicación de artefactos release firmados requiere los SDK y credenciales correspondientes y no forma parte de ese workflow.
