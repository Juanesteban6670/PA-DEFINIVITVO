# Puesta en marcha y despliegue de Cartagena Segura

## Arquitectura

Docker Compose ejecuta:

- Flutter Web compilado y servido por Nginx en `/`.
- La API Spring Boot, disponible internamente para el contenedor web y Caddy bajo `/api/`.
- PostgreSQL y MongoDB con volúmenes persistentes y sin puertos publicados.
- Caddy opcional para HTTPS en producción.

El backend, sus contratos y sus datos persistidos no se modifican. `/actuator` se usa para la comprobación de salud interna y devuelve 404 desde las rutas públicas.

## Requisitos

- Docker Desktop o Docker Engine con Docker Compose v2.
- Para producción: un VPS con puertos 80/443 disponibles y dominio DNS dirigido al servidor.
- Para desarrollo Flutter fuera de Docker: Flutter 3.47.9 o posterior compatible con Dart `^3.13.3`.

## Ejecución local

Desde la raíz del repositorio:

```sh
cp .env.example .env
```

Reemplaza en `.env` las contraseñas y el secreto JWT de ejemplo. Luego ejecuta:

```sh
docker compose up --build -d
docker compose ps
```

Abre `http://localhost:3000`. Compose construye Flutter Web y la API, y Nginx reenvía `/api/` al backend. Los cambios se aplican con `docker compose up --build -d`.

Para borrar contenedores sin borrar datos usa `docker compose down`; no agregues `-v` salvo que quieras eliminar bases de datos, archivos y certificados persistidos. Los valores del archivo de ejemplo son solo locales, no los uses como secretos de producción.

## Probar desde un teléfono en la red local

Por defecto, la aplicación queda ligada a `127.0.0.1`. Para una prueba temporal en una red privada, configura `WEB_BIND_ADDRESS=0.0.0.0`, limita el acceso con el firewall y restaura la configuración al terminar. GPS y algunas funciones de almacenamiento del navegador necesitan un contexto seguro; valida esas funciones desde HTTPS.

Para ejecutar Flutter directamente con `flutter run`, consulta [../client/README.md](../client/README.md). En ese modo, permite el origen del servidor Flutter en `CORS_ALLOWED_ORIGINS` y configura la URL de API accesible desde el dispositivo. GPS es opcional; también se puede escribir una referencia manual.

## Despliegue en un VPS con HTTPS

1. Instala Docker Engine y Compose v2 en el VPS y clona el repositorio.
2. Copia `.env.example` a `.env`; cambia todas las contraseñas y `JWT_SECRET` por valores aleatorios privados. Usa una contraseña Mongo compatible con URI o codifica sus caracteres reservados.
3. Configura `DOMAIN` con el nombre DNS real. Cambia `BASE_URL`, `FRONTEND_URL` y `CORS_ALLOWED_ORIGINS` al origen HTTPS exacto, por ejemplo `https://segura.example.com`; no uses comodines.
4. Asegúrate de que el DNS apunte al VPS y que los puertos TCP 80/443 estén permitidos.
5. Inicia los servicios, incluyendo el perfil HTTPS:

   ```sh
   docker compose --profile production up --build -d
   docker compose ps
   ```

6. Visita `https://<tu-dominio>`. Caddy solicita y renueva TLS. Flutter se sirve en `/`, la API en `/api/` y Actuator no se publica.
7. En Android abre el sitio HTTPS desde Chrome e instálalo desde el menú del navegador. En iOS abre el sitio con Safari y usa **Compartir > Añadir a pantalla de inicio**.

La imagen Flutter construye el sitio dentro del contenedor a partir de `client/`; no es necesario generar ni copiar `build/web/` manualmente. El frontend solo se publica en el punto de entrada web; no publiques puertos de API, bases de datos ni archivos de Actuator en Internet.

## Persistencia y respaldos

Compose mantiene datos en los volúmenes `postgres_data`, `mongo_data`, `uploaded_files`, `caddy_data` y `caddy_config`. Los volúmenes sobreviven a recrear contenedores, pero no sustituyen copias de seguridad. Programa respaldos de PostgreSQL, MongoDB y archivos de evidencia, guárdalos fuera del VPS y prueba periódicamente su restauración. Protege `.env`; no lo subas a Git ni lo incluyas en imágenes.

## Configuración e integraciones

- `POSTGRES_*`, `MONGO_*`: bases locales del stack; no publiques los servicios de datos externamente.
- `JWT_SECRET`: secreto privado aleatorio; nunca reutilices el valor de ejemplo.
- `GROQ_API_KEY` y `APPS_SCRIPT_URL`: opcionales según las funciones de IA/correo habilitadas.
- `CORS_ALLOWED_ORIGINS`: orígenes permitidos separados por comas. En producción, agrega el origen HTTPS exacto.
- `BASE_URL` y `FRONTEND_URL`: enlaces públicos usados por la API, por ejemplo para archivos y correos.
- `WEB_PORT`: puerto local enlazado por defecto a loopback.

Si se usan bases administradas, adapta `DB_URL`, `DB_SSL`, `DB_SSLMODE` y `MONGO_URI` y retira los servicios locales correspondientes. Las claves de servicios externos deben permanecer en el backend, nunca en el bundle Flutter.

## Verificación y límites

- Confirma `/`, rutas profundas y recarga directa, manifiesto e iconos PWA.
- Confirma que `/api/` responde a través del mismo origen y que `/actuator` devuelve 404.
- Valida sesión, GPS bajo HTTPS, selección y envío de fotos, mapas y reportes en Android/iOS.
- La web no persiste fotos seleccionadas ni datos sensibles offline. Una foto pendiente requiere que la pestaña siga abierta para poder completar el envío.
- El centro de notificaciones sincroniza al abrirse/actualizarse. El backend actual no ofrece una API de suscripción para notificaciones push remotas.
- El proyecto no crea dominio, cuentas de hosting ni credenciales. El propietario debe configurarlos y validar datos de prueba antes de usarlo con información real.

Consulta la [guía del cliente Flutter](../client/README.md) para comandos de desarrollo, análisis y pruebas.
