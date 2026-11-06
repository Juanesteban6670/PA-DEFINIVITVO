# Puesta en marcha y despliegue de Cartagena Segura

## Arquitectura desplegable

El proyecto se ejecuta con Docker Compose:

- **Frontend:** React/Vite compilado y servido por Nginx.
- **App móvil:** Flutter nativo para Android/iOS, con la misma identidad visual y API; no sustituye ni modifica la web.
- **API:** backend Spring Boot.
- **Datos:** PostgreSQL y MongoDB con volúmenes persistentes y sin puertos expuestos a Internet.
- **HTTPS opcional/producción:** Caddy termina TLS automáticamente y publica web/API bajo un mismo dominio.

En teléfono se puede usar la PWA desde el navegador o instalar el cliente Flutter nativo. Ambos consumen el mismo backend. La PWA ofrece una página informativa offline; no almacena respuestas del API, datos personales, sesiones ni reportes.

## Requisitos

- Docker Desktop o Docker Engine con Docker Compose v2.
- Para producción: un VPS con puertos 80 y 443 disponibles y un dominio cuyo DNS apunte al VPS.

## Ejecución local

En PowerShell, desde la raíz del repositorio:

```powershell
Copy-Item .env.example .env
docker compose up --build -d
docker compose ps
```

Abre `http://localhost:3000`. Compose inicia las bases de datos, espera sus comprobaciones de salud y luego inicia API y web. La primera compilación descarga dependencias y puede tardar. Los cambios de backend/frontend se incorporan reconstruyendo con `docker compose up --build -d`.

El archivo `.env.example` contiene credenciales exclusivamente locales. `.env` está excluido de Git. Para borrar contenedores sin borrar datos usa `docker compose down`; **no** agregues `-v` salvo que quieras eliminar bases de datos, archivos y certificados persistidos.

## Probar desde un teléfono en la red local

La publicación local queda ligada a `127.0.0.1` por seguridad. Para una prueba temporal en una red privada, cambia `WEB_BIND_ADDRESS` en `.env` a `0.0.0.0`, agrega `http://<IP-del-PC>:3000` a `CORS_ALLOWED_ORIGINS`, abre el puerto `WEB_PORT` solo en una red confiable y visita desde el teléfono `http://<IP-del-PC>:3000`. Limita el acceso con el firewall y restaura la configuración al terminar. Las funciones del navegador que requieren contexto seguro, como geolocalización, deben probarse en un despliegue HTTPS real.

## Despliegue en un VPS con HTTPS

1. Instala Docker Engine y Compose v2 en el VPS y clona el repositorio.
2. Copia `.env.example` a `.env`; cambia todas las contraseñas y `JWT_SECRET` por valores aleatorios privados. Usa una contraseña Mongo compatible con URI (por ejemplo, caracteres alfanuméricos y `-._~`) o codifica sus caracteres reservados.
3. Configura `DOMAIN` con el nombre DNS real y cambia `BASE_URL`, `FRONTEND_URL` y `CORS_ALLOWED_ORIGINS` al origen HTTPS exacto, por ejemplo `https://segura.example.com`. No agregues comodines.
4. Asegúrate de que el DNS apunte al VPS y que los puertos TCP 80/443 (y opcionalmente UDP 443) estén permitidos.
5. Inicia todos los servicios, incluyendo el perfil HTTPS:

   ```sh
   docker compose --profile production up --build -d
   docker compose ps
   ```

6. Visita `https://<tu-dominio>`. Caddy solicitará y renovará los certificados TLS automáticamente. La API se sirve en el mismo origen bajo `/api`; el navegador no necesita una URL de API diferente.
7. Elige la experiencia móvil:
   - **PWA:** en Android abre la URL con Chrome y selecciona **Instalar aplicación** o **Añadir a pantalla de inicio**. En iOS abre la URL con Safari y usa **Compartir > Añadir a pantalla de inicio**.
   - **Flutter nativo:** compila la app usando `https://<tu-dominio>/api` como `API_BASE_URL`, firma los artefactos con credenciales propias y distribúyelos por los canales oficiales de Android/iOS. Consulta [mobile/README.md](../mobile/README.md).

PostgreSQL, MongoDB y la API no publican puertos al host. El frontend solo se publica en loopback y Caddy es el punto de entrada en producción. No habilites puertos de bases de datos en el firewall.

## Persistencia y respaldos

Compose mantiene datos en volúmenes `postgres_data`, `mongo_data`, `uploaded_files`, `caddy_data` y `caddy_config`. Los volúmenes sobreviven a recrear contenedores, pero **no** sustituyen copias de seguridad. Programa respaldos de PostgreSQL, MongoDB y archivos de evidencia, guarda las copias fuera del VPS y prueba periódicamente su restauración. Protege también `.env` (permisos restringidos); no lo subas a Git ni lo incluyas en imágenes.

## Configuración e integraciones

- `POSTGRES_*`, `MONGO_*`: bases locales del stack. No publiques los servicios de datos externamente.
- `JWT_SECRET`: secreto privado aleatorio; nunca reutilices el valor de ejemplo.
- `GROQ_API_KEY` y `APPS_SCRIPT_URL`: opcionales según las funciones de IA/correo habilitadas.
- `CORS_ALLOWED_ORIGINS`: orígenes web permitidos, separados por comas. En producción indica únicamente la URL web HTTPS; el cliente Flutter nativo no depende de CORS del navegador.
- `BASE_URL` y `FRONTEND_URL`: enlaces públicos usados por la API, por ejemplo para archivos y correos.
- `WEB_PORT`: puerto local de loopback para abrir la aplicación en el propio servidor/desarrollador.

El Docker Compose incluido usa bases de datos autocontenidas y persistentes en el servidor. Si se cambia a bases de datos administradas, se deben adaptar `DB_URL`, `DB_SSL`, `DB_SSLMODE`, `MONGO_URI` y retirar los servicios locales correspondientes. Las claves de servicios externos deben configurarse como secretos, nunca en variables `VITE_*` que terminarían dentro del navegador.

## Verificación y límites

- Backend: se sirve bajo el mismo origen en `/api`; Actuator se usa para la comprobación interna del contenedor.
- Frontend/PWA: comprueba la instalación desde Chrome Android y Safari iOS reales, acceso a las rutas, mapas, GPS y reportes.
- Sin Internet, la PWA solo muestra la página de ayuda; no permite consultar incidentes/contactos ni enviar reportes.
- El proyecto no crea dominio, cuentas de hosting ni credenciales. El propietario debe configurarlos y validar datos de prueba antes de usarlo con información real.

## Flutter nativo

`mobile/` proporciona los flujos ciudadanos nativos de acceso/registro, inicio, reportes, mapa, emergencias y perfil de solo lectura. En desarrollo con Compose, el backend no publica el puerto 8080 al host; configura Flutter con `http://10.0.2.2:3000/api` en Android Emulator, `http://localhost:3000/api` en Flutter Web sobre el host, o una URL HTTPS pública para producción. La compilación de iOS requiere macOS/Xcode; las cuentas de publicación, certificados Apple y firma Android deben ser aportados por el propietario.
