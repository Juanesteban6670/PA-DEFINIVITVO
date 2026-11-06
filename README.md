# Cartagena Segura

Cartagena Segura es una plataforma ciudadana con una API REST Spring Boot, una web React/PWA y un cliente móvil nativo Flutter. La web y la app móvil comparten identidad visual y backend: React permanece como experiencia web y Flutter cubre los flujos ciudadanos en Android/iOS.

## Componentes

- `frontend/`: web React/Vite adaptable a móviles y PWA.
- `backend/`: API REST con Spring Boot, Java 21 y Maven Wrapper.
- `compose.yaml`: web, API, PostgreSQL y MongoDB con persistencia.
- `mobile/`: app Flutter nativa ciudadana para Android/iOS.
- `docs/deployment.md`: ejecución local, despliegue HTTPS y uso en teléfonos.

## Estado actual

El repositorio incluye el frontend PWA, una app Flutter para móvil, Docker Compose para web/API/PostgreSQL/MongoDB y una configuración opcional de Caddy para HTTPS en un servidor con dominio. Ambas interfaces usan la misma API. Las operaciones de mapa, autenticación, GPS, directorio y reportes requieren conexión; la PWA no guarda información personal ni reportes sin conexión.

El frontend web y el cliente Flutter son productos complementarios, no una sustitución del código React. La app móvil requiere una URL de API accesible desde cada dispositivo; consulta [mobile/README.md](mobile/README.md) para probarla, compilar Android/iOS y revisar qué credenciales de firma debe aportar el propietario. Los cambios de Flutter se validan con el workflow de GitHub Actions y también deben probarse en dispositivos reales antes de publicar.

## Ejecutar localmente

Requisito: Docker Desktop o Docker Engine con Docker Compose v2.

1. Copia `.env.example` a `.env`.
2. Desde la raíz del repositorio ejecuta:

   ```powershell
   docker compose up --build -d
   docker compose ps
   ```

3. Abre `http://localhost:3000`.

La primera construcción puede tardar. Los datos se conservan en volúmenes de Docker. `docker compose down` detiene los servicios sin borrar esos volúmenes; evita `docker compose down -v` si necesitas conservar los datos. Los valores de ejemplo son solo locales, no los uses como secretos de producción.

Para desarrollar solo la web se requieren Node.js y npm; instrucciones en [frontend/README.md](frontend/README.md). Para ejecutar y verificar el backend fuera de Docker se requiere Java 21; consulta [backend/README.md](backend/README.md).

## Usar en Android e iOS

La app nativa Flutter es la experiencia móvil recomendada; también se puede abrir la web/PWA desde el navegador. Despliega primero la API con HTTPS y configura la URL pública al compilar Flutter. La PWA se puede instalar con Chrome en Android y Safari en iOS; los artefactos nativos necesitan compilación y firma mediante los SDK/cuentas oficiales de cada plataforma.

La app Flutter guarda el token con almacenamiento seguro, pero las consultas y los envíos requieren conectividad; no guarda reportes offline. GPS y llamadas dependen de permisos y del sistema operativo, por lo que deben comprobarse en dispositivos reales.

El despliegue público aún requiere la infraestructura y los secretos del propietario. Consulta la [guía de despliegue](docs/deployment.md) para activar HTTPS automático con Caddy, configurar dominio y secretos, y preparar respaldos.

## Cliente Flutter móvil

Flutter cubre los flujos ciudadanos móviles de autenticación, inicio, reportes, mapa, emergencias y perfil de solo lectura. El panel administrativo permanece en la web. Consulta [mobile/README.md](mobile/README.md) para ejecutar y compilar la app.

El alcance Flutter está descrito en [docs/documentacion-entrega-movil.md](docs/documentacion-entrega-movil.md).

## Integración continua

GitHub Actions está configurado para validar lint/build de la web, ejecutar `mvn verify` con Java 21, comprobar los contenedores y ejecutar `flutter analyze`, `flutter test` y una compilación debug de Android. Revisa la pestaña **Actions** para confirmar los resultados; la existencia de los workflows no implica que todas las comprobaciones ya hayan pasado.

## Desarrolladores y creadores

- Juan Esteban de los Ríos Tibocha
- Robinson Emiro Castaño Mercado
- Álvaro Cervantes Noel
