# Cartagena Segura — Web/PWA

La web React es la vía recomendada para usar Cartagena Segura en escritorio y teléfonos Android/iOS. La PWA puede añadirse a la pantalla de inicio desde Chrome en Android y desde Safari en iOS; requiere HTTPS para capacidades de instalación y ubicación.

## Desarrollo local con Docker Compose

Desde la raíz del repositorio, sigue [la guía de despliegue](../docs/deployment.md). La web queda disponible en `http://localhost:3000` y usa `/api` en el mismo origen.

## Desarrollo frontend aislado

Requisitos: Node.js 22 o superior y npm. Con la API disponible localmente:

```powershell
npm ci
npm run dev
```

Vite usa `/api` y `/actuator` como proxy hacia `http://localhost:8080`. Para cambiar el destino, define `API_PROXY_TARGET`, por ejemplo `API_PROXY_TARGET=http://localhost:8081`.

## Validaciones

```powershell
npm run lint:pwa
npm run build
```

`npm run lint` ejecuta ESLint en todo el frontend; actualmente reporta problemas preexistentes en varias pantallas ajenas a la configuración PWA.

El build genera el manifiesto y service worker PWA. La interfaz estática puede abrirse sin conexión, pero el service worker muestra una página de instrucciones; no almacena respuestas del API, sesiones ni reportes.

## Docker

El `Dockerfile` de esta carpeta compila Vite y sirve los archivos con Nginx. La configuración de Nginx da soporte a rutas React y pasa `/api/` al servicio backend. Se construye desde el `compose.yaml` de la raíz.
