# Despliegue nuevo de Cartagena Segura

## Arquitectura

- **Web:** alojamiento estático para Vite/React. Directorio raíz de compilación: `frontend`; comandos: `npm ci` y `npm run build`; salida: `dist`.
- **API:** alojamiento de contenedores que admita el [Dockerfile del backend](../backend/Dockerfile); directorio raíz: `backend`. El contenedor escucha el puerto `PORT` asignado por el proveedor.
- **PostgreSQL y MongoDB:** instancias nuevas administradas y accesibles desde la API. No es necesario instalar estas bases de datos en los equipos que usan la aplicación.
- **Archivos de evidencia:** el backend guarda archivos en disco local. En producción, monta almacenamiento persistente en el contenedor en la ruta configurada por `UPLOAD_DIR`; de lo contrario, los archivos se pueden perder al reiniciar o volver a desplegar.
- **Flutter:** el cliente móvil separado en `mobile/` usa la URL HTTPS pública de esta misma API, configurada al compilar mediante `--dart-define=API_BASE_URL=https://<api-publica>/api`.

Crear las cuentas, proyectos e instancias en los proveedores es un paso manual que requiere acceso a las cuentas del propietario. Esta guía prepara los puntos de configuración, pero no crea cuentas ni credenciales.

## Variables de entorno del backend

Configura estas variables en el panel del servicio de API. Usa credenciales nuevas y guarda todos los valores sensibles como secretos del proveedor:

| Variable | Valor |
| --- | --- |
| `DB_URL` | URL JDBC de la instancia PostgreSQL nueva, por ejemplo `jdbc:postgresql://HOST:5432/BASE?sslmode=require` |
| `DB_USERNAME` | Usuario de PostgreSQL |
| `DB_PASSWORD` | Contraseña de PostgreSQL |
| `MONGO_URI` | URI de conexión de la instancia MongoDB nueva |
| `MONGO_DATABASE` | Nombre de la base MongoDB |
| `JWT_SECRET` | Secreto aleatorio, privado, de al menos 32 caracteres |
| `JWT_EXPIRATION` | Vigencia del token en milisegundos, por ejemplo `86400000` |
| `GROQ_API_KEY` | Clave de Groq, si se habilita la integración de IA |
| `APPS_SCRIPT_URL` | URL del servicio de Google Apps Script, si se habilita el correo |
| `PORT` | Lo asigna el proveedor de hosting |
| `BASE_URL` | URL HTTPS pública de la API, sin `/api` al final |
| `FRONTEND_URL` | URL HTTPS pública de la aplicación web |
| `CORS_ALLOWED_ORIGINS` | Orígenes web autorizados separados por comas, sin rutas ni comodines |
| `UPLOAD_DIR` | Ruta del volumen persistente de archivos, por ejemplo `/app/uploads` |

Ejemplo de orígenes CORS: `https://mi-web.example.com`. Para incluir un segundo cliente web, sepáralo con una coma. El cliente Flutter nativo no requiere habilitar cualquier origen CORS; si se construye Flutter Web, incluye su origen exacto.

## Variables de entorno del frontend

Configura `VITE_API_URL` durante la compilación de Vite con la URL HTTPS pública de la API y el prefijo `/api`, por ejemplo `https://mi-api.example.com/api`. Vite incorpora este valor en los archivos de la web; nunca pongas secretos en variables `VITE_*`.

En desarrollo, deja `VITE_API_URL` vacío: Vite usa `/api` y reenvía las solicitudes a `http://localhost:8080`. El destino local se puede cambiar con `API_PROXY_TARGET`.

## Lista de comprobación

1. Crear instancias nuevas de PostgreSQL y MongoDB y permitir conexiones únicamente desde el servicio de la API.
2. Desplegar el backend con `backend/Dockerfile`, las variables anteriores y un volumen persistente para `UPLOAD_DIR`.
3. Comprobar `https://<api-publica>/actuator/health`.
4. Desplegar `frontend/` con `npm ci` y `npm run build`; configurar `VITE_API_URL` antes de compilar.
5. Añadir el origen público de la web a `CORS_ALLOWED_ORIGINS` y establecer `FRONTEND_URL` en el backend.
6. Verificar inicio de sesión, registro, recuperación de contraseña, mapas y carga/consulta de archivos desde un dispositivo distinto.
7. No subir `.env`, contraseñas, claves API ni cadenas de conexión al repositorio.

## Aplicación Flutter

La app `mobile/` ya contiene el MVP ciudadano y usa la misma API. Su URL se inyecta en compilación mediante `--dart-define=API_BASE_URL=...`; así no depende de `localhost` cuando se distribuye. La app almacena el JWT con almacenamiento seguro del dispositivo. Flutter no puede usar `localhost` para llegar a la API publicada ni al PC del desarrollador.
