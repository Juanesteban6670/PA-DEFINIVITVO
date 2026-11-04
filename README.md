# Cartagena Segura

Cartagena Segura es una plataforma ciudadana con una API REST Spring Boot y una web React que se prepara para instalarse como PWA. En Android e iOS, el flujo previsto es abrir la web publicada mediante HTTPS desde el navegador y, opcionalmente, añadirla a la pantalla de inicio. No hace falta instalar Flutter ni publicar en una tienda.

## Componentes

- `frontend/`: web React/Vite adaptable a móviles y PWA.
- `backend/`: API REST con Spring Boot, Java 21 y Maven Wrapper.
- `compose.yaml`: web, API, PostgreSQL y MongoDB con persistencia.
- `mobile/`: cliente Flutter nativo opcional e independiente.
- `docs/deployment.md`: ejecución local, despliegue HTTPS y uso en teléfonos.

## Estado actual

El repositorio ya incluye el frontend PWA, archivos Docker Compose para web/API/PostgreSQL/MongoDB, y una configuración opcional de Caddy para HTTPS en un servidor con dominio. La instalación debe funcionar bajo conexión; sin Internet la PWA muestra instrucciones y no guarda reportes ni datos personales.

El frontend se compiló y se comprobó en navegador en tamaños móviles, incluyendo la shell PWA y su pantalla sin conexión. La auditoría de dependencias de producción del frontend no detectó vulnerabilidades. No se ha confirmado todavía un despliegue público ni una prueba en dispositivos Android/iOS reales. En la última validación local no estaban disponibles Docker ni Java, por lo que faltan probar el stack Compose y las verificaciones Maven; el workflow de GitHub Actions también debe confirmarse en **Actions**.

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

Una vez configurados el servidor, dominio, DNS y secretos, despliega la aplicación con HTTPS y visita su URL en el teléfono. En Android, usa Chrome y selecciona **Instalar aplicación** o **Añadir a pantalla de inicio**. En iOS, abre la URL en Safari y selecciona **Compartir > Añadir a pantalla de inicio**. También se puede usar directamente en el navegador.

Sin conexión solo se muestra una página de ayuda; no se guardan sesiones, datos personales ni reportes. La ubicación y el mapa requieren permisos y conectividad. Las capacidades de instalación y GPS deben comprobarse en dispositivos reales.

El despliegue público aún requiere la infraestructura y los secretos del propietario. Consulta la [guía de despliegue](docs/deployment.md) para activar HTTPS automático con Caddy, configurar dominio y secretos, y preparar respaldos.

## Cliente Flutter opcional

El cliente Flutter existente se conserva como alternativa nativa, pero no es necesario para distribuir ni usar la PWA en Android/iOS. Consulta [mobile/README.md](mobile/README.md) para ejecutarlo por separado.

El alcance Flutter está descrito en [docs/documentacion-entrega-movil.md](docs/documentacion-entrega-movil.md).

## Integración continua

GitHub Actions está configurado para validar lint/build de la web, ejecutar `mvn verify` con Java 21 y comprobar/construir los contenedores. El workflow Flutter existente valida el cliente nativo opcional. Revisa la pestaña **Actions** para confirmar el resultado de las ejecuciones; la existencia de los workflows no implica que todas las comprobaciones ya hayan pasado.

## Desarrolladores y creadores

- Juan Esteban de los Ríos Tibocha
- Robinson Emiro Castaño Mercado
- Álvaro Cervantes Noel
