# Cartagena Segura

Cartagena Segura es una plataforma de seguridad ciudadana con una aplicación Flutter multiplataforma y una API REST Spring Boot. Flutter Web es la interfaz web principal y puede instalarse desde Chrome en Android y Safari en iOS. Los directorios fuente Android e iOS se conservan; la publicación de paquetes nativos no forma parte del alcance actual.

## Componentes

- `client/`: aplicación Flutter Web, configuración PWA y proyectos fuente Android/iOS.
- `backend/`: API REST con Spring Boot, Java 21 y Maven Wrapper.
- `compose.yaml`: aplicación web, API, PostgreSQL y MongoDB con persistencia.
- `Caddyfile`: HTTPS y enrutamiento del sitio y la API para producción.
- `docs/deployment.md`: ejecución local, despliegue y verificación.

## Funcionalidades

La aplicación reúne el landing público, autenticación y recuperación de cuenta, reportes ciudadanos, mapa, contactos de emergencia, notificaciones, perfil, panel administrativo, auditoría, zonas e integración con IA. Las interfaces usan la API existente; no se modifican sus contratos ni los datos persistidos.

En Flutter Web, las fotos seleccionadas para un reporte permanecen en memoria mientras la pestaña está abierta. No se guardan fotos ni datos sensibles en caché offline. GPS requiere HTTPS y permiso del usuario; la ubicación es opcional.

## Ejecutar localmente

Requisito: Docker Desktop o Docker Engine con Docker Compose v2.

1. Copia `.env.example` a `.env` y sustituye los secretos de ejemplo.
2. Desde la raíz ejecuta:

   ```sh
   docker compose up --build -d
   docker compose ps
   ```

3. Abre `http://localhost:3000`.

Compose construye Flutter Web y la API. Nginx sirve Flutter en `/` y reenvía `/api/` al backend; Caddy se reserva para el perfil de producción. Los datos se conservan en volúmenes. `docker compose down` no los elimina; evita `docker compose down -v` si necesitas conservarlos.

Para desarrollar Flutter en Chrome, consulta [client/README.md](client/README.md). Para ejecutar y verificar la API fuera de Docker se requiere Java 21; consulta [backend/README.md](backend/README.md).

## Android e iOS

Abre el sitio HTTPS desde Chrome en Android o Safari en iOS y usa la opción del navegador para instalarlo o añadirlo a la pantalla de inicio. No se generan APK ni IPA en esta etapa. Los directorios fuente Flutter de Android/iOS se conservan para una posible compilación futura.

## Despliegue

El despliegue público requiere un dominio, DNS y secretos controlados por el propietario. Caddy termina TLS y sirve Flutter en `/`, mientras `/api/` llega al backend. Actuator no se publica. Sigue la [guía de despliegue](docs/deployment.md) y valida los flujos en un entorno HTTPS antes de usar datos reales.

## Integración continua

GitHub Actions valida formato, análisis, pruebas y build web de Flutter, además del backend y la configuración de los contenedores. La existencia de los workflows no implica que se haya publicado el servicio.

## Desarrolladores y creadores

- Juan Esteban de los Ríos Tibocha
- Robinson Emiro Castaño Mercado
- Álvaro Cervantes Noel
