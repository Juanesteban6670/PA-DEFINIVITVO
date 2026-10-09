# Aplicación móvil Cartagena Segura

Cliente Flutter ciudadano para Android e iOS. Consume la API REST de `backend/`; no mantiene una base de datos distinta. Incluye inicio y registro de sesión, mapa de incidentes, envío de reportes de texto con GPS y contactos de emergencia. La carga de fotografías se puede añadir en una siguiente iteración.

## Requisitos

- Flutter estable y Dart incluidos con Flutter.
- Android Studio con Android SDK para compilar y ejecutar en Android.
- macOS con Xcode para compilar y publicar en iOS.
- API accesible desde el emulador o dispositivo.

## Ejecutar en desarrollo

Desde `mobile/`, indica la URL que pueda alcanzar el dispositivo:

```powershell
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080/api
```

`10.0.2.2` es la dirección del equipo anfitrión desde el emulador Android. En un teléfono físico, usa la IP local del PC que ejecuta la API y asegúrate de que ambos estén en una red permitida. Para iOS Simulator, usa la dirección accesible desde el simulador.

## Compilar contra el despliegue público

La API debe tener HTTPS público; proporciona su URL durante la compilación:

```powershell
flutter build apk --release --dart-define=API_BASE_URL=https://tu-api-publica/api
```

El cliente guarda el JWT en almacenamiento seguro del dispositivo. No se debe usar `localhost` como URL en un APK distribuido: en cada teléfono `localhost` se refiere a ese mismo teléfono.

## Simulación visual en navegador

El soporte web permite revisar rápidamente las pantallas Flutter desde Chrome o Edge con el tamaño de vista configurado como teléfono. Desde `mobile/`:

```powershell
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8080/api
```

La API debe estar ejecutándose localmente para probar inicio de sesión, reportes, mapa y contactos. Sin API se puede revisar la interfaz de acceso, pero las operaciones que envían solicitudes no funcionarán. Esta vista previa ayuda a validar la disposición visual y no sustituye una prueba en Android o iOS: permisos, GPS, llamadas telefónicas y almacenamiento seguro nativo deben verificarse en un dispositivo/emulador correspondiente.

Al enviar un reporte exitosamente, la lista de incidentes se vuelve a consultar para que el mapa refleje los datos más recientes.

## Verificaciones

```powershell
flutter analyze
flutter test
```

Para probar Android instala Android Studio y el Android SDK. Para compilar iOS se requiere macOS y Xcode; Flutter en Windows no produce un IPA de iOS.
