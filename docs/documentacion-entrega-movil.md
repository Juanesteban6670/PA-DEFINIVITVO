# Cartagena Segura — alcance de la aplicación Flutter

## Arquitectura

La aplicación Flutter de `client/` es el cliente único para Web y los proyectos fuente Android/iOS. Flutter Web se publica en `/`; la API Spring Boot se conserva bajo `/api/`. PostgreSQL y MongoDB mantienen la persistencia existente. Esta migración no cambia contratos, datos ni servicios backend.

La navegación conserva rutas públicas y rutas protegidas:

| Ruta | Acceso | Función |
|---|---|---|
| `/` | Público | Landing |
| `/Login`, `/Register` | Público | Inicio de sesión y registro |
| `/ForgotPassword`, `/ResetPassword` | Público | Recuperación de acceso |
| `/App` | Ciudadano | Inicio y resumen |
| `/App/Incidents` | Ciudadano | Reportes propios y creación de reporte |
| `/App/Map` | Ciudadano | Mapa de incidentes |
| `/App/Emergency` | Ciudadano | Contactos de emergencia |
| `/App/Analytics` | Ciudadano | Resumen de reportes |
| `/App/Profile` | Ciudadano | Perfil y sesión |
| `/App/Notifications` | Usuario autenticado | Centro de notificaciones |
| `/Admin` y `/Admin/*` | Administrador | Resumen, incidentes, zonas, auditoría, contactos, reportes e IA |

El router redirige a la autenticación si no hay sesión y limita las rutas administrativas a roles `ADMIN`/`ROLE_ADMIN`. Las rutas de incidentes admiten `?id=...` para abrir el elemento relacionado con una notificación.

## Funcionalidades implementadas

- Registro, inicio de sesión, cierre de sesión y restablecimiento de contraseña.
- Persistencia segura del token y perfil por medio de las implementaciones de almacenamiento disponibles en cada plataforma.
- Reportes ciudadanos con categoría, descripción, referencia, prioridad y ubicación opcional.
- Selección y carga de evidencia; en Web, los bytes de fotos permanecen solo en memoria de la pestaña.
- Borradores y reintentos para reportes sin fotos; no se guardan fotos ni datos sensibles en caché offline.
- Mapa OpenStreetMap con incidentes georreferenciados, filtros y acceso a detalles.
- Contactos de emergencia, notificaciones sincronizadas desde la API y perfil.
- Panel administrativo para visualizar incidentes, historial, comentarios, estado, prioridad y asignación; administrar zonas y contactos; consultar auditoría y resúmenes de IA.
- Integración con chatbot y clasificador IA a través de endpoints backend existentes; las claves de proveedores externos permanecen en el servidor.
- Reportes administrativos enlazan el tablero Power BI externo existente.

GPS requiere permiso del usuario y HTTPS en navegadores. La ubicación es opcional; se puede proporcionar una dirección manual. El envío de fotos en Web requiere que la pestaña permanezca abierta hasta completar la carga.

El centro de notificaciones consulta al abrirse o actualizarse manualmente. No hay suscripción push remota porque el backend actual no define una API para registrar suscripciones push.

## API

La base se configura con `--dart-define=API_BASE_URL`; para el despliegue integrado se usa `/api`. Los endpoints consumidos incluyen:

| Grupo | Operaciones principales |
|---|---|
| Autenticación | `POST /Auth/Login`, `/Auth/Register`, `/Auth/ForgotPassword`, `/Auth/ResetPassword`, `GET/PUT /Auth/Profile` |
| Incidentes | `GET /Incidents`, `/Incidents/My`, `POST /Incidents`, carga por `POST /Files/Upload`, estado, historial y comentarios |
| Zonas y auditoría | consulta/creación/actualización de `Zones`, `GET /Logs` |
| Emergencias | consulta, creación, actualización y desactivación de `EmergencyContacts` |
| Notificaciones | consulta, conteo, marcar como leída/todas leídas y eliminación |
| IA | resumen, análisis de zonas, clasificación y chat mediante `/Ai/*` |

Las rutas se muestran relativas al prefijo `/api`. El cliente interpreta el sobre Spring `{success, message, data}` y reporta errores de red o del servidor; no sustituye la autorización del backend.

## Desarrollo y validación

Desde `client/`:

```sh
flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build web --release --base-href=/ \
  --dart-define=API_BASE_URL=/api
```

Los tests usan `MockClient` en memoria para validar modelos, solicitudes, sesión, navegación, reportes, chat y acciones administrativas; no es un servidor de datos. Antes de publicar, probar en HTTPS real, Chrome Android y Safari iOS: sesión, permisos, GPS, fotos, refresh de rutas directas y diseños pequeños/grandes.

La instalación desde el navegador es una PWA Flutter Web. Los directorios fuente Android/iOS se conservan, pero no se generan ni publican APK/IPA en el alcance actual. Véase [la guía de despliegue](deployment.md) y [la guía del cliente](../client/README.md).
