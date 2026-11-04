# Cartagena Segura

Plataforma ciudadana con API REST en Spring Boot y web React instalable como PWA. En Android e iOS, el flujo recomendado es abrir la URL HTTPS desde el navegador y, opcionalmente, añadirla a la pantalla de inicio; no hace falta instalar Flutter ni publicar en una tienda.

## Componentes

- `frontend/`: web React/Vite adaptable a móviles y PWA.
- `backend/`: API REST con Spring Boot, Java 21 y Maven Wrapper.
- `compose.yaml`: web, API, PostgreSQL y MongoDB con persistencia.
- `mobile/`: cliente Flutter nativo opcional e independiente.
- `docs/deployment.md`: ejecución local, despliegue HTTPS y uso en teléfonos.

## Desarrollo local

Requisito: Docker Desktop (Windows/macOS) o Docker Engine con el plugin Docker Compose.

```powershell
Copy-Item .env.example .env
docker compose up --build -d
docker compose ps
```

Abre `http://localhost:3000`. El primer inicio compila los contenedores y puede tardar. `.env.example` contiene valores solo para desarrollo; reemplázalos antes de publicar. No ejecutes `docker compose down -v` salvo que quieras borrar los datos persistidos.

Para desarrollar solo el frontend con Vite, consulta [frontend/README.md](frontend/README.md).

## Usar en Android e iOS

Despliega la aplicación con HTTPS y visita su URL en el teléfono. En Android, usa Chrome y selecciona **Instalar aplicación** o **Añadir a pantalla de inicio**. En iOS, abre la URL en Safari y selecciona **Compartir > Añadir a pantalla de inicio**. También se puede usar directamente en el navegador.

Sin conexión solo se muestra una página de ayuda; no se guardan sesiones, datos personales ni reportes. La ubicación y el mapa requieren permisos y conectividad. La PWA no reemplaza una prueba en dispositivos reales.

Consulta la [guía de despliegue](docs/deployment.md) para activar HTTPS automático con Caddy y configurar dominio, secretos y respaldos.

## Cliente Flutter opcional

El cliente Flutter existente se conserva como alternativa nativa, pero no es necesario para distribuir ni usar la PWA en Android/iOS. Consulta [mobile/README.md](mobile/README.md) para ejecutarlo por separado.

El alcance Flutter está descrito en [docs/documentacion-entrega-movil.md](docs/documentacion-entrega-movil.md).

## Integración continua

GitHub Actions valida lint/build de la web y prueba/compila el backend. El workflow Flutter existente continúa validando el cliente nativo opcional.

## Desarrolladores y creadores

- Juan Esteban de los Ríos Tibocha
- Robinson Emiro Castaño Mercado
- Álvaro Cervantes Noel
