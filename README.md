# Cartagena Segura

Plataforma ciudadana con una API REST en Spring Boot y una aplicación web en React. La web y la API se despliegan una sola vez en servicios accesibles por Internet; cualquier PC o teléfono puede abrir la misma URL sin instalar el proyecto.

## Componentes

- `backend/`: API REST con Spring Boot, Java 21 y Maven Wrapper.
- `frontend/`: web React con Vite.
- `mobile/`: aplicación móvil ciudadana Flutter para Android e iOS.
- `docs/deployment.md`: guía para configurar un despliegue nuevo y sus servicios.

## Desarrollo local

Requisitos: Java 21, Node.js LTS y npm. Para una instalación rápida de las dependencias y configuración, consulta [docs/deployment.md](docs/deployment.md).

1. Copia `backend/.env.example` a `backend/.env` y configura las conexiones de PostgreSQL y MongoDB y los secretos locales.
2. Inicia el backend desde su carpeta:

   ```powershell
   cd backend
   .\mvnw.cmd spring-boot:run
   ```

3. En otra terminal, prepara y ejecuta la web:

   ```powershell
   cd frontend
   Copy-Item .env.example .env
   npm ci
   npm run dev
   ```

La web se sirve en `http://localhost:3000`, la API en `http://localhost:8080` y Swagger en `http://localhost:8080/swagger-ui/index.html`.

## Despliegue

El frontend y la API deben tener URLs públicas HTTPS. Configura `VITE_API_URL` al compilar la web, y configura en el backend `BASE_URL`, `FRONTEND_URL` y `CORS_ALLOWED_ORIGINS` con las URLs reales. Las bases de datos, claves y demás variables se configuran como secretos en el proveedor de alojamiento; no se guardan en GitHub.

Sigue la [guía de despliegue](docs/deployment.md) antes de publicar.

## Aplicación móvil

La app ciudadana en Flutter usa la misma API y guarda el JWT con almacenamiento seguro del dispositivo. Consulta [mobile/README.md](mobile/README.md) para ejecutarla o compilar Android; compilar para iOS requiere macOS y Xcode.
