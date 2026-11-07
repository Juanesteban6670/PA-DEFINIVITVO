# 🛡️ Cartagena Segura — Plataforma de Seguridad Ciudadana

Plataforma integral de seguridad ciudadana, monitoreo geoespacial en tiempo real y asistencia inteligente para el Distrito Turístico y Cultural de **Cartagena de Indias**. Integra una aplicación ciudadana multiplataforma (**Flutter Web / PWA / Móvil**), una API REST robusta (**Spring Boot 3 con Java 21**), persistencia políglota (**PostgreSQL 16 + MongoDB 7**) y un motor de **Inteligencia Artificial Híbrido** con RAG local y soporte en la nube.

---

## 🌐 Despliegue Oficial en Vivo 24/7 (Producción Cloud)

La plataforma se encuentra actualmente desplegada y disponible permanentemente en la nube para acceso público, evaluación docente y pruebas ciudadanas:

* 🚀 **Aplicación Web Oficial:** [https://pa-definivitvo.onrender.com](https://pa-definivitvo.onrender.com)
* 📖 **Documentación Interactiva Swagger:** [https://pa-definivitvo.onrender.com/swagger-ui/index.html](https://pa-definivitvo.onrender.com/swagger-ui/index.html)
* 🩺 **Monitoreo de Salud del Sistema:** [https://pa-definivitvo.onrender.com/actuator/health](https://pa-definivitvo.onrender.com/actuator/health)

---

## 🛠️ Stack Tecnológico, Lenguajes y Frameworks

El proyecto está diseñado bajo una arquitectura desacoplada, modular y de alta disponibilidad:

### 1. 📱 Frontend & Aplicación Cliente
* **Lenguaje:** [Dart 3.x](https://dart.dev/)
* **Framework:** [Flutter 3.47.x](https://flutter.dev/) (Compilación optimizada para **Web PWA**, con arquitectura lista para Android e iOS nativo).
* **Gestión de Estado:** [Flutter Riverpod](https://riverpod.dev/) (`flutter_riverpod: ^2.6.1`) complementado con `ValueNotifier` y controladores de sesión reactivos.
* **Enrutamiento:** [GoRouter](https://pub.dev/packages/go_router) (`go_router: ^14.8.1`) con guardas de autenticación, redirecciones por rol y enlaces profundos (*deep linking*).
* **Mapas & Geoespacial:**
  * [Flutter Map](https://pub.dev/packages/flutter_map) (`flutter_map: ^8.3.2`) con renderizado vectorial y capas múltiples.
  * [LatLong2](https://pub.dev/packages/latlong2) (`latlong2: ^0.10.1`) para cálculos geodésicos y fórmulas de proximidad.
  * **Teselas Gratuitas:** OpenStreetMap Standard Tiles y Esri World Imagery (capa satelital de alta resolución).
  * **Funciones Geoespaciales:** Agrupamiento inteligente de marcadores (*Clustering*), polígonos translúcidos de riesgo distrital, radar pulsante de ubicación GPS y cálculo de rutas seguras tipo Waze con detección de peligros en el trayecto.
* **Visualización & Métricas:** [FL Chart](https://pub.dev/packages/fl_chart) (`fl_chart: ^0.70.2`) para gráficos estadísticos y distribución de incidentes en el panel de control administrativo.
* **Diseño & UI/UX:**
  * Material Design 3 con paleta semántica dual (**Modo Claro** y **Modo Oscuro Obsidian**).
  * Diseño contemporáneo con componentes en cristal esmerilado (*Glassmorphism* con `BackdropFilter`).
  * Cuadrícula asimétrica estilo **Bento Grid** y contadores numéricos animados en la Landing Page.
  * Efecto **Shimmer / Skeleton Loaders** y badges estilo cápsula con *status dots*.
  * Soporte PWA instalable con `manifest.json` y service worker.
* **Almacenamiento Seguro:** [Flutter Secure Storage](https://pub.dev/packages/flutter_secure_storage) para persistencia cifrada de tokens JWT y preferencias de tema.
* **Hardware & Servicios:**
  * [Geolocator](https://pub.dev/packages/geolocator) para geolocalización GPS precisa del dispositivo.
  * [Image Picker](https://pub.dev/packages/image_picker) para captura de evidencias fotográficas desde cámara o galería.
  * [Url Launcher](https://pub.dev/packages/url_launcher) para llamadas directas de emergencia al **123** y apertura de mapas externos.

---

### 2. ☕ Backend & API REST
* **Lenguaje:** [Java 21 LTS](https://www.oracle.com/java/technologies/downloads/#java21) (aprovechando Virtual Threads, Records, Pattern Matching y Switch Expressions).
* **Framework:** [Spring Boot 3.3.x](https://spring.io/projects/spring-boot).
* **Construcción y Dependencias:** Apache Maven 3.9+ mediante **Maven Wrapper** (`mvnw`).
* **Seguridad & Identidad:**
  * **Spring Security 6:** Configuración *stateless* basada en filtros JWT (`JwtAuthenticationFilter`).
  * **Criptografía:** Hashing de contraseñas con **BCrypt** (`PasswordEncoder`).
  * **Tokens:** [JJWT](https://github.com/jwtk/jjwt) (`io.jsonwebtoken:jjwt`) para emisión y verificación criptográfica de tokens con expiración configurable.
  * **Control de Acceso Basado en Roles (RBAC):** Jerarquía de roles (`ADMIN`, `OFFICER`, `USER`).
* **Inteligencia Artificial Híbrida (RAG & Heurística):**
  * **RAG Context-Aware:** El asistente analiza dinámicamente incidentes y sectores de Cartagena desde la base de datos para responder con precisión territorial.
  * **Motor Dual:** Conexión con **Groq Cloud API** (Llama 3.1 / 3.3) si se suministra API key, o activación automática del **Motor Local Inteligente** (100% gratuito, sin conexión externa requerida y con cero latencia).
  * Funciones de auto-clasificación de severidad y generación de resúmenes ejecutivos.
* **Almacenamiento de Archivos:** Controlador de evidencias con validación estricta de *Magic Bytes* (firmas de archivos JPG, PNG, WEBP, PDF) para prevenir inyecciones binarias.
* **Documentación & Monitoreo:**
  * **Springdoc OpenAPI / Swagger UI 3** para documentación interactiva de la API en `/swagger-ui.html`.
  * **Spring Boot Actuator** para sondas de salud (`/actuator/health`) integradas con los healthchecks de Docker.

---

### 3. 🗄️ Persistencia Políglota (Bases de Datos Híbridas)

El sistema implementa persistencia híbrida separando la información relacional y transaccional del contenido dinámico geoespacial:

| Motor | Tipo | Colecciones / Tablas | Propósito y Ventajas |
| :--- | :--- | :--- | :--- |
| **PostgreSQL 16 (Alpine)** | Relacional (SQL / ACID) | `users`, `roles`, `user_roles`, `emergency_contacts`, `audit_logs` | Garantiza integridad referencial estricta, autenticación JWT, registro inmutable de auditoría y directorio de entidades de emergencia. |
| **MongoDB 7** | NoSQL (Documentos JSON / Geo) | `incidents`, `zones`, `comments`, `notifications`, `incident_history` | Esquema elástico para reportes con evidencias, cálculo de zonas de riesgo distritales, notificaciones e historial de cambios sin bloqueos de tabla. |

---

### 4. 🐳 DevOps, Infraestructura & Despliegue
* **Contenedores:** [Docker](https://www.docker.com/) y **Docker Compose v2** con compilaciones multi-etapa (*multi-stage builds*) para reducir drásticamente el peso de las imágenes finales.
* **Servidores Web & Proxies Inversos:**
  * **Nginx 1.27 Alpine:** Sirve el frontend web con compresión gzip, encabezados de seguridad (CSP, HSTS, X-Frame-Options) y proxy reverso que canaliza las peticiones `/api/` hacia el backend en el puerto 8080.
  * **Caddy 2:** Servidor perimetral opcional con aprovisionamiento y renovación automática de certificados SSL/TLS (Let's Encrypt).
* **Túnel Seguro Público:** [Cloudflare Tunnels](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/) (`cloudflared`) para exposición pública cifrada HTTPS sin necesidad de abrir puertos o configurar NAT/DMZ en el router.
* **Integración Continua (CI/CD):** [GitHub Actions](https://github.com/features/actions) con flujos de trabajo que validan:
  * Formato Dart y análisis estático con `flutter analyze` (**0 advertencias**).
  * Suite de 49 pruebas unitarias y de widgets aprobadas al 100%.
  * Compilación cruzada de la aplicación web y empaquetado del contenedor.

---

## 🚀 Puesta en Marcha Local

### Requisitos previos
* **Docker Desktop** (Mac/Windows) o **Docker Engine** con Docker Compose v2 (Linux).

### Pasos de ejecución
1. Clona el repositorio y entra al directorio:
   ```sh
   git clone https://github.com/Juanesteban6670/PA-DEFINIVITVO.git
   cd PA-DEFINIVITVO
   ```
2. Si no existe, crea el archivo de variables `.env` a partir de la plantilla:
   ```sh
   cp .env.example .env
   ```
3. Construye y levanta todos los contenedores en segundo plano:
   ```sh
   docker compose up --build -d
   ```
4. Verifica el estado de los servicios:
   ```sh
   docker compose ps
   ```
5. Accede desde tu navegador web:
   * **Aplicación Web:** `http://localhost:3000`
   * **Documentación Swagger API:** `http://localhost:3000/swagger-ui.html`
   * **Healthcheck:** `http://localhost:3000/actuator/health`

---

## 🔑 Credenciales de Prueba Preconfiguradas

La base de datos incluye semillas iniciales de prueba para evaluar los diferentes roles del sistema:

| Rol | Usuario | Contraseña | Capacidades |
| :--- | :--- | :--- | :--- |
| **Administrador** | `admin` | `Password123!` | Acceso completo al panel admin, gestión de zonas, asignación de cuadrantes, auditoría y exportación CSV. |
| **Ciudadano** | `ciudadano_maria` | `Password123!` | Creación de reportes con fotos, chat con IA, consulta de rutas seguras y botón de pánico SOS. |
| **Oficial de Policía** | `oficial_cuadrante4` | `Password123!` | Monitoreo territorial, atención de incidentes asignados y consulta de emergencias. |

---

## 📱 Instalación en Dispositivos Móviles (PWA)

* **Android:** Abre la URL de la plataforma en Google Chrome, pulsa los tres puntos superiores `⋮` y selecciona **"Instalar aplicación"** o **"Añadir a la pantalla de inicio"**.
* **iOS (iPhone/iPad):** Abre la URL en Safari, pulsa el botón Compartir y selecciona **"Añadir a la pantalla de inicio"**.

---

## 👨‍💻 Autores y Creadores

Proyecto de Aula desarrollado con dedicación y compromiso por:

* **Juan Esteban de los Ríos Tibocha**
* **Robinson Emiro Castaño Mercado**
* **Álvaro Cervantes Noel**
