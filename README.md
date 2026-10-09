# Cartagena Segura

Proyecto integrado de la plataforma Cartagena Segura. El repositorio contiene el backend Spring Boot y el frontend React en carpetas independientes.

## Estructura

- `backend/`: API REST con Spring Boot, Java 21 y Maven.
- `frontend/`: interfaz React con Vite.

## Requisitos

- Java 21
- Node.js 18+ y npm
- PostgreSQL y MongoDB accesibles para el backend

## Configurar y ejecutar el backend

Configura en el entorno local las variables requeridas por `backend/src/main/resources/application.properties` para las bases de datos, JWT, Groq, almacenamiento y URL base. No guardes credenciales reales en el repositorio.

En PowerShell, desde la raiz del repositorio:

```powershell
cd backend
.\mvnw.cmd spring-boot:run
```

La API queda disponible en `http://localhost:8080` y Swagger en `http://localhost:8080/swagger-ui/index.html`.

## Configurar y ejecutar el frontend

En otra terminal, desde la raiz del repositorio:

```powershell
cd frontend
npm install
npm run dev
```

Vite sirve la aplicacion en `http://localhost:3000`. El frontend espera el backend en `http://localhost:8080`.

## Validaciones

```powershell
cd frontend
npm run lint
npm run build
```

El backend puede compilarse desde `backend/` con `.\mvnw.cmd test`.
