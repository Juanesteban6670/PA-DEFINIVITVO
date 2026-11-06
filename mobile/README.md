# Cartagena Segura — Flutter Web para Android/iOS

`mobile/` es la experiencia ciudadana Flutter Web, instalable desde el navegador en Android (Chrome) y iOS (Safari). En producción se sirve bajo `/ciudadano/`; React/PWA conserva la ruta raíz `/`. Los proyectos fuente Android/iOS se mantienen en el repositorio, pero no forman parte del despliegue web.

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

El mapa, las teselas, la autenticación y las operaciones de datos requieren conexión. Los borradores de texto y metadatos se guardan en el almacenamiento seguro del navegador. Las fotos seleccionadas en Flutter Web solo permanecen en memoria mientras la pestaña está abierta; no se guardan en el almacenamiento persistente del navegador. Si una foto aún no se ha subido, la app no permite guardarla para envío offline. La cola de reportes sin fotos se reintenta manualmente desde “Mis reportes” cuando vuelve la conexión. La API aplica una clave idempotente para impedir reportes duplicados si se pierde la respuesta de un envío.

La ubicación es opcional: puedes escribir una dirección sin dar permiso. Si los servicios del teléfono están apagados, se deniega el permiso o este quedó bloqueado, la app informa cómo continuar y ofrece abrir los ajustes del sistema. El chatbot utiliza la sesión iniciada y el endpoint `/api/Ai/Chat`; la clave del proveedor de IA permanece configurada en el backend.

## Requisitos

- Flutter 3.47.9 o posterior compatible con Dart `^3.13.3`.
- Chrome para el desarrollo local; Chrome en Android y Safari en iOS para la validación en dispositivos.
- API REST accesible. La sesión persistente y el GPS en dispositivos requieren HTTPS.

## Ejecutar y probar

Desde esta carpeta:

```sh
flutter pub get
flutter run -d chrome --web-hostname 0.0.0.0 --web-port 8080 \
  --dart-define=API_BASE_URL=http://localhost:3000/api
```

La URL anterior es para un navegador en el mismo computador con Docker Compose en marcha. Para probar en un teléfono conectado a la misma red, usa la IP LAN del computador tanto para abrir Flutter como para llamar al API; permite el origen del servidor Flutter en `CORS_ALLOWED_ORIGINS` y expón temporalmente el puerto solo en una red confiable. No uses `localhost` ni `10.0.2.2` desde un navegador de teléfono. La ubicación y el almacenamiento seguro pueden estar restringidos sobre HTTP local; valida esos flujos bajo HTTPS.

Para validar la app:

```sh
dart format --set-exit-if-changed lib test
flutter analyze
flutter test
```

Las pruebas usan `MockClient` y verifican autenticación, restauración de sesión, contratos de solicitud, navegación y actualización del mapa/lista después de reportar. También revisa los flujos reales en Android/iOS y tamaños de pantalla compactos y tabletas, en especial permisos GPS, llamadas, teclado y almacenamiento seguro.

## Compilar y desplegar en producción

Primero configura el dominio DNS en `.env` y apunta `API_BASE_URL` a la API HTTPS del mismo origen. Reemplaza el dominio de ejemplo en el comando:

```sh
flutter build web --release --base-href=/ciudadano/ \
  --dart-define=API_BASE_URL=https://segura.example.com/api
```

Desde la raíz del proyecto, construye y levanta el perfil de producción:

```sh
docker compose --profile production up --build -d
```

La web queda en `https://<dominio>/ciudadano/`; React permanece en `https://<dominio>/`. La URL de API es pública y se incorpora al bundle; no incluyas claves ni otros secretos en `--dart-define`. Mantén Caddy y el backend en el mismo origen para no ampliar CORS.

En Android instala desde el menú de Chrome. En iPhone/iPad abre la página en Safari y usa **Compartir > Añadir a pantalla de inicio**. Confirma la instalación, orientación vertical/horizontal, sesión, GPS, selección y envío de fotos, reportes y navegación en ambos dispositivos.

## Integración continua

`.github/workflows/flutter.yml` usa Flutter 3.47.9 para ejecutar `flutter analyze`, `flutter test`, validar el manifest, compilar Flutter Web con base `/ciudadano/` y comprobar la imagen estática, Compose y Caddy. El build de CI usa un dominio reservado de prueba y no es un artefacto publicable.
