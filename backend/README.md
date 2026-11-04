# Cartagena Segura — API

API REST Spring Boot 3.4.3 / Java 21 usada por la web React/PWA. Para iniciar API, frontend y bases de datos juntos, sigue [la guía de Docker Compose](../docs/deployment.md); desde la raíz, ejecuta `docker compose up --build -d`.

## Ejecución independiente

Requiere Java 21, PostgreSQL y MongoDB accesibles, además de las variables de entorno indicadas en `application.properties`. En Windows PowerShell, desde `backend/`:

```powershell
.\mvnw.cmd spring-boot:run
```

La API escucha en `http://localhost:8080`. Swagger está en `/swagger-ui/index.html`. En ejecución aislada, configura `DB_URL`, `DB_USERNAME`, `DB_PASSWORD`, `DB_SSL`, `DB_SSLMODE`, `MONGO_URI`, `MONGO_DATABASE`, `JWT_SECRET` y los orígenes CORS permitidos.

No uses las credenciales de `.env.example` en producción. La guía principal documenta HTTPS, secretos y persistencia de datos.
