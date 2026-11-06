# Cartagena Segura — Flutter

`client/` contiene la aplicación Flutter compartida por Flutter Web y los proyectos fuente Android/iOS. Flutter Web se sirve en `/` y consume la API del mismo origen bajo `/api/`. La app se puede instalar desde Chrome en Android y Safari en iOS. No se generan APK ni IPA en esta etapa.

## Funcionalidades

- Landing público, inicio de sesión, registro y recuperación/restablecimiento de contraseña.
- Rutas ciudadanas protegidas: reportes, mapa, emergencias, estadísticas y perfil.
- Rutas administrativas protegidas por rol: resumen, incidentes, zonas, auditoría, contactos, reportes externos e IA.
- Comentarios e historial de incidentes, cambios de estado/prioridad, notificaciones y chat con IA.
- Sesión persistida mediante almacenamiento seguro disponible en cada plataforma.
- Reportes con ubicación opcional, evidencia, borrador y cola de reintento.

La app requiere conexión para autenticación, datos y envíos. En Web, las fotos seleccionadas solo permanecen en memoria mientras la pestaña está abierta; no se guardan en almacenamiento persistente del navegador ni en caché offline. Los reportes con fotos requieren que la pestaña siga abierta para poder enviar la evidencia. La ubicación es opcional; GPS requiere HTTPS y permiso del usuario.

El centro de notificaciones sincroniza al abrirse o actualizarse manualmente. No hay integración de notificaciones push remotas: el backend actual no proporciona suscripciones push.

## Requisitos

- Flutter 3.47.9 o posterior compatible con Dart `^3.13.3`.
- Chrome para desarrollo web.
- API REST accesible. Para uso en dispositivos, despliega la web/API con HTTPS.

## Ejecutar y probar

Para desarrollo directo con la API local servida por Compose:

```sh
cd client
flutter pub get
flutter run -d chrome --web-hostname 0.0.0.0 --web-port 8080 \
  --dart-define=API_BASE_URL=http://localhost:3000/api
```

`.env.example` permite el origen de desarrollo `http://localhost:8080`. Para probar desde un teléfono en la misma red, configura el origen y la URL de API con las direcciones LAN correctas; GPS y almacenamiento seguro pueden estar restringidos sobre HTTP local. No uses `localhost` como host de API desde otro dispositivo.

Validaciones:

```sh
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build web --release --base-href=/ \
  --dart-define=API_BASE_URL=/api
```

Las pruebas usan respuestas HTTP simuladas para verificar modelos, sesión, navegación, reportes, notificaciones, chat y acciones administrativas. Antes de publicar, prueba también rutas directas y refresh, formularios, permisos GPS, selección/envío de fotos y diseños de teléfono/tableta en dispositivos reales.

## Web e instalación

La imagen web se construye mediante `Dockerfile.web`; no se requiere copiar un build al repositorio:

```sh
docker compose up --build -d
```

Abre `http://localhost:3000`. En producción, Flutter se sirve en `/`, la API en `/api/`, y Caddy proporciona HTTPS. Revisa [../docs/deployment.md](../docs/deployment.md) antes de publicar.

Para instalarla, abre el sitio HTTPS con Chrome en Android y elige **Instalar aplicación** o **Añadir a pantalla de inicio**. En iOS abre el sitio en Safari y usa **Compartir > Añadir a pantalla de inicio**. Esta instalación es la PWA web; no produce un paquete nativo.

Los directorios `android/` e `ios/` se conservan como fuentes Flutter para una posible compilación posterior. No se compilan ni firman APK/IPA en el alcance actual.
