# Puesta en marcha y despliegue de Cartagena Segura

## Arquitectura desplegable

El proyecto se ejecuta con Docker Compose:

- **Frontend:** React/Vite compilado y servido por Nginx.
- **Flutter Web:** experiencia ciudadana instalable bajo `/ciudadano/`; React/PWA conserva la ruta `/`. Los proyectos Android/iOS fuente no forman parte del despliegue web.
- **API:** backend Spring Boot.
- **Datos:** PostgreSQL y MongoDB con volúmenes persistentes y sin puertos expuestos a Internet.
- **HTTPS opcional/producción:** Caddy termina TLS automáticamente y publica web/API bajo un mismo dominio.

En Android se puede instalar Flutter Web desde Chrome y en iOS desde Safari. React/PWA sigue disponible en la raíz y Flutter Web se sirve en `/ciudadano/`; ambos consumen el mismo backend HTTPS. Los clientes no deben guardar respuestas autenticadas, sesiones ni reportes en la caché offline.

## Requisitos

- Docker Desktop o Docker Engine con Docker Compose v2.
- Para producción: un VPS con puertos 80 y 443 disponibles y un dominio cuyo DNS apunte al VPS.
- Flutter 3.47.9 o posterior compatible con Dart `^3.13.3` en el equipo que compile Flutter Web.

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

### GPS en Safari/iPhone

Safari no permite geolocalización desde una dirección HTTP de red local como `http://192.168.x.x:3000`, aunque el iPhone y el servidor estén en la misma Wi‑Fi. La aplicación mostrará un aviso para abrir una dirección HTTPS; no es un fallo del permiso GPS ni se debe intentar eludir la política del navegador. Para probar en un iPhone usa el dominio HTTPS de staging/producción con certificado válido. En pruebas HTTPS locales, el certificado debe ser confiable también para iOS y CORS debe permitir el origen exacto. Los reportes permiten escribir la dirección aunque no se comparta la ubicación.

En Flutter Web, permite la ubicación en Safari/Chrome y usa una página HTTPS con certificado válido. La ubicación es opcional y se puede escribir una referencia manual.

## Despliegue en un VPS con HTTPS

1. Instala Docker Engine y Compose v2 en el VPS y clona el repositorio.
2. Copia `.env.example` a `.env`; cambia todas las contraseñas y `JWT_SECRET` por valores aleatorios privados. Usa una contraseña Mongo compatible con URI (por ejemplo, caracteres alfanuméricos y `-._~`) o codifica sus caracteres reservados.
3. Configura `DOMAIN` con el nombre DNS real y cambia `BASE_URL`, `FRONTEND_URL` y `CORS_ALLOWED_ORIGINS` al origen HTTPS exacto, por ejemplo `https://segura.example.com`. No agregues comodines.
4. Asegúrate de que el DNS apunte al VPS y que los puertos TCP 80/443 (y opcionalmente UDP 443) estén permitidos.
5. En un equipo con Flutter 3.47.9+, compila el sitio con el mismo origen HTTPS para el API:

   ```sh
   cd mobile
   flutter pub get
   flutter build web --release --base-href=/ciudadano/ \
     --dart-define=API_BASE_URL=https://segura.example.com/api
   ```

   Reemplaza `segura.example.com` por el dominio configurado. Copia el directorio ignorado `mobile/build/web/` al mismo directorio del repositorio en el VPS; el servicio Docker lo necesita para construir la imagen estática. También puedes ejecutar el build directamente en el VPS si allí está instalado Flutter.
6. Inicia todos los servicios, incluyendo el perfil HTTPS:

   ```sh
   docker compose --profile production up --build -d
   docker compose ps
   ```

7. Visita `https://<tu-dominio>` para React o `https://<tu-dominio>/ciudadano/` para Flutter Web. Caddy solicita y renueva TLS; la API está disponible en el mismo origen bajo `/api`.
8. Instala Flutter Web: en Android abre `/ciudadano/` con Chrome y selecciona **Instalar aplicación** o **Añadir a pantalla de inicio**. En iOS ábrelo con Safari y usa **Compartir > Añadir a pantalla de inicio**.

PostgreSQL, MongoDB y la API no publican puertos al host. El frontend solo se publica en loopback y Caddy es el punto de entrada en producción. No habilites puertos de bases de datos en el firewall.

## Persistencia y respaldos

Compose mantiene datos en volúmenes `postgres_data`, `mongo_data`, `uploaded_files`, `caddy_data` y `caddy_config`. Los volúmenes sobreviven a recrear contenedores, pero **no** sustituyen copias de seguridad. Programa respaldos de PostgreSQL, MongoDB y archivos de evidencia, guarda las copias fuera del VPS y prueba periódicamente su restauración. Protege también `.env` (permisos restringidos); no lo subas a Git ni lo incluyas en imágenes.

## Configuración e integraciones

- `POSTGRES_*`, `MONGO_*`: bases locales del stack. No publiques los servicios de datos externamente.
- `JWT_SECRET`: secreto privado aleatorio; nunca reutilices el valor de ejemplo.
- `GROQ_API_KEY` y `APPS_SCRIPT_URL`: opcionales según las funciones de IA/correo habilitadas.
- `CORS_ALLOWED_ORIGINS`: orígenes web permitidos, separados por comas. En producción basta el origen HTTPS compartido de React y Flutter Web; durante desarrollo web local agrega el origen exacto de Flutter.
- `BASE_URL` y `FRONTEND_URL`: enlaces públicos usados por la API, por ejemplo para archivos y correos.
- `WEB_PORT`: puerto local de loopback para abrir la aplicación en el propio servidor/desarrollador.

El Docker Compose incluido usa bases de datos autocontenidas y persistentes en el servidor. Si se cambia a bases de datos administradas, se deben adaptar `DB_URL`, `DB_SSL`, `DB_SSLMODE`, `MONGO_URI` y retirar los servicios locales correspondientes. Las claves de servicios externos deben configurarse como secretos, nunca en variables `VITE_*` que terminarían dentro del navegador.

## Verificación y límites

- Backend: se sirve bajo el mismo origen en `/api`; Actuator se usa para la comprobación interna del contenedor.
- Flutter Web: comprueba `/ciudadano/`, rutas profundas, manifest, instalación en Chrome Android y Safari iOS, sesión, fotos, mapas, GPS y reportes.
- Sin Internet no se deben cachear datos privados; los reportes con fotos seleccionadas en Flutter Web requieren que la pestaña siga abierta para poder enviar la evidencia.
- El proyecto no crea dominio, cuentas de hosting ni credenciales. El propietario debe configurarlos y validar datos de prueba antes de usarlo con información real.

## Flutter Web

`mobile/` proporciona acceso/registro, inicio, reportes, mapa, emergencias y perfil como aplicación Flutter Web instalable en Android/iOS. El workflow de Flutter verifica el build web y la configuración Docker/Caddy. Para compilar localmente y desplegar, consulta [mobile/README.md](../mobile/README.md). La publicación real requiere definir el dominio y compilar con su URL HTTPS de API.
