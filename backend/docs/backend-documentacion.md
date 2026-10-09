# Documentacion del Backend - Cartagena Segura

Esta guia explica el backend de **Cartagena Segura** desde cero. La idea es que una persona que apenas abre el proyecto pueda entender que hace cada carpeta, como se conectan las piezas y como usar la API.

## 1. Que es este backend

El backend es una API REST creada con **Spring Boot 3.4.3** y **Java 21**. Su trabajo es recibir peticiones del frontend o de una app movil, procesarlas y guardar/consultar informacion sobre seguridad ciudadana en Cartagena.

El sistema permite:

- Registrar e iniciar sesion de usuarios.
- Proteger rutas con JWT.
- Reportar incidentes de seguridad.
- Consultar y administrar zonas de riesgo.
- Agregar comentarios a incidentes.
- Enviar notificaciones a usuarios.
- Consultar contactos de emergencia.
- Guardar logs de auditoria.
- Subir archivos de evidencia.
- Usar IA con Groq para chatbot, clasificacion y analisis.
- Exponer documentacion interactiva con Swagger/OpenAPI.

## 2. Tecnologias principales

| Tecnologia | Para que se usa |
|---|---|
| Java 21 | Lenguaje principal del backend. |
| Spring Boot | Framework que levanta el servidor y organiza la API. |
| Spring Web | Creacion de controladores REST. |
| Spring Security | Autenticacion, autorizacion y proteccion de rutas. |
| JWT | Token que identifica al usuario despues del login. |
| Spring Data JPA | Acceso a tablas relacionales en PostgreSQL. |
| Spring Data MongoDB | Acceso a colecciones NoSQL en MongoDB. |
| PostgreSQL | Guarda usuarios, roles y contactos de emergencia. |
| MongoDB | Guarda incidentes, zonas, comentarios, logs, reportes y notificaciones. |
| Thymeleaf | Renderiza plantillas HTML para correos. |
| Swagger/OpenAPI | Permite probar y leer la API desde el navegador. |
| Groq API | Proveedor externo usado para funciones de inteligencia artificial. |
| Google Apps Script | Servicio externo usado para delegar el envio de correos. |

## 3. Como esta organizada la arquitectura

El proyecto sigue una estructura comun en Spring Boot:

```text
Cliente o Frontend
        |
        v
Controller  -> recibe la peticion HTTP
        |
        v
Service     -> aplica reglas de negocio
        |
        v
Repository  -> consulta o guarda datos
        |
        v
Base de datos
```

Ejemplo con incidentes:

```text
POST /api/Incidents
        |
IncidentController.create()
        |
IncidentService.create()
        |
IncidentRepository.save()
        |
MongoDB: coleccion incidents
```

## 4. Estructura de carpetas

```text
src/main/java/Com/Backend/CartagenaSegura
├── Config
├── Controller
├── Dto
├── Exception
├── Model
├── Repository
├── Security
├── Service
└── CartagenaSeguraApplication.java
```

### `CartagenaSeguraApplication.java`

Es el punto de entrada de la aplicacion. Cuando se ejecuta:

```powershell
.\mvnw.cmd spring-boot:run
```

Spring Boot inicia el servidor, carga la configuracion, conecta las bases de datos y registra todos los controladores, servicios, repositorios y filtros de seguridad.

### `Controller`

Contiene las clases que reciben las peticiones HTTP. Cada controlador define rutas como `GET`, `POST`, `PUT`, `PATCH` o `DELETE`.

Los controladores no deberian tener mucha logica de negocio. Su tarea principal es:

- Leer parametros, JSON o archivos enviados por el cliente.
- Llamar al servicio correspondiente.
- Retornar una respuesta HTTP.

### `Service`

Contiene la logica real del sistema. Aqui se decide que hacer con los datos:

- Validar si un usuario existe.
- Crear incidentes.
- Generar logs.
- Crear notificaciones.
- Consultar IA.
- Actualizar estadisticas de zonas.

### `Repository`

Contiene interfaces de acceso a datos. Spring Data genera automaticamente las consultas a partir del nombre de los metodos.

Ejemplo:

```java
List<Incident> findByStatus(Incident.Status status);
```

Ese metodo permite buscar incidentes por estado sin escribir una consulta manual.

### `Model`

Contiene las entidades o documentos que representan la informacion guardada en base de datos.

- Las clases con `@Entity` se guardan en PostgreSQL.
- Las clases con `@Document` se guardan en MongoDB.

### `Dto`

DTO significa **Data Transfer Object**. Son objetos usados para recibir o devolver datos por la API sin exponer necesariamente toda la entidad interna.

Ejemplo: `RegisterRequest` contiene los datos que se necesitan para registrar un usuario.

### `Security`

Contiene todo lo relacionado con autenticacion y permisos:

- Generacion y validacion de JWT.
- Filtro que lee el token en cada request.
- Configuracion de rutas publicas y privadas.
- Carga de usuarios para Spring Security.

### `Config`

Contiene configuraciones globales:

- `SwaggerConfig`: configura la documentacion OpenAPI.
- `AsyncConfig`: habilita tareas asincronas con `@Async`, usadas por el envio de correos.

### `Exception`

Contiene el manejador global de errores. Convierte excepciones Java en respuestas JSON claras para la API.

## 5. Configuracion del proyecto

La configuracion principal esta en:

```text
src/main/resources/application.properties
```

Este archivo no guarda claves reales directamente. Lee valores desde variables de entorno:

```properties
spring.datasource.url=${DB_URL}
spring.datasource.username=${DB_USERNAME}
spring.datasource.password=${DB_PASSWORD}
spring.data.mongodb.uri=${MONGO_URI}
spring.data.mongodb.database=${MONGO_DATABASE}
jwt.secret=${JWT_SECRET}
jwt.expiration=${JWT_EXPIRATION}
groq.api.key=${GROQ_API_KEY}
```

Para ejecutar localmente se recomienda crear un archivo `.env` en la raiz del proyecto:

```env
DB_URL=jdbc:postgresql://localhost:5432/cartagena_segura
DB_USERNAME=postgres
DB_PASSWORD=admin

MONGO_URI=mongodb://localhost:27017/
MONGO_DATABASE=cartagena_segura_local

JWT_SECRET=clave_secreta_para_desarrollo_local_123
JWT_EXPIRATION=86400000

GROQ_API_KEY=tu_groq_api_key
APPS_SCRIPT_URL=tu_url_de_google_apps_script

PORT=8080
BASE_URL=http://localhost:8080
UPLOAD_DIR=uploads/
```

## 6. Bases de datos

Este backend usa dos bases de datos al mismo tiempo.

### PostgreSQL

Guarda informacion relacional, especialmente datos que encajan bien en tablas:

| Modelo | Tabla | Funcion |
|---|---|---|
| `User` | `users` | Usuarios registrados. |
| `Role` | `roles` | Roles como `USER` o `ADMIN`. |
| `EmergencyContact` | `emergency_contacts` | Directorio de contactos de emergencia. |

### MongoDB

Guarda informacion flexible y orientada a documentos:

| Modelo | Coleccion | Funcion |
|---|---|---|
| `Incident` | `incidents` | Reportes de incidentes. |
| `IncidentHistory` | `incident_history` | Historial de cambios de un incidente. |
| `Zone` | `zones` | Zonas geograficas y nivel de riesgo. |
| `Comment` | `comments` | Comentarios publicos o internos. |
| `Notification` | `notifications` | Notificaciones de usuario. |
| `LogEntry` | `logs` | Auditoria de acciones. |
| `Report` | `reports` | Reportes generados o planeados. |

## 7. Formato general de respuesta

La mayoria de endpoints devuelven un objeto `ApiResponse<T>`:

```json
{
  "success": true,
  "message": "OK",
  "data": {}
}
```

Cuando hay error:

```json
{
  "success": false,
  "message": "Mensaje del error",
  "data": null
}
```

Esto se define en:

```text
src/main/java/Com/Backend/CartagenaSegura/Dto/SharedDto.java
```

## 8. Seguridad y autenticacion

El sistema usa **JWT Bearer Token**.

### Flujo normal

1. El usuario se registra en `POST /api/Auth/Register`.
2. El usuario inicia sesion en `POST /api/Auth/Login`.
3. El backend devuelve un `token`.
4. El cliente envia ese token en cada peticion protegida:

```http
Authorization: Bearer <token>
```

5. `JwtAuthFilter` lee el token, lo valida y carga el usuario autenticado en Spring Security.

### Clases importantes

| Clase | Funcion |
|---|---|
| `SecurityConfig` | Define rutas publicas, privadas, CORS, encoder de passwords y filtros. |
| `JwtUtil` | Crea tokens, extrae usuario y valida expiracion/firma. |
| `JwtAuthFilter` | Intercepta cada request y revisa el header `Authorization`. |
| `UserDetailsServiceImpl` | Busca usuarios por username, email o telefono. |
| `User` | Implementa `UserDetails`, por eso Spring Security puede autenticarlo. |

### Rutas publicas principales

- `/`
- `/Index.html`
- `/swagger-ui.html`
- `/swagger-ui/**`
- `/api-docs/**`
- `/v3/api-docs/**`
- `/actuator/**`
- `/api/Auth/**`
- `GET /api/Incidents`
- `GET /api/Zones`
- `GET /api/Files/**`
- `/api/EmergencyContacts/**`

### Rutas solo ADMIN

- `/api/Logs/**`
- `/api/Reports/**`
- `/api/Admin/**`
- `GET /api/Ai/Summary`
- `GET /api/Ai/Zones/Analysis`
- Endpoints marcados con `@PreAuthorize("hasRole('ADMIN')")`.

## 9. Modulos del backend

## 9.1 Autenticacion

Archivos principales:

- `AuthController`
- `AuthService`
- `User`
- `Role`
- `UserRepository`
- `RoleRepository`
- `JwtUtil`

Endpoints:

| Metodo | Ruta | Que hace |
|---|---|---|
| `POST` | `/api/Auth/Register` | Crea un usuario con rol `USER`. |
| `POST` | `/api/Auth/Login` | Autentica usuario, email o telefono y devuelve JWT. |
| `POST` | `/api/Auth/ForgotPassword` | Genera token de recuperacion y envia correo. |
| `POST` | `/api/Auth/ResetPassword` | Cambia la contrasena usando el token. |

Registro:

```json
{
  "username": "juanperez",
  "password": "Password123!",
  "email": "juan@email.com",
  "fullName": "Juan Perez",
  "phone": "3001234567"
}
```

Login:

```json
{
  "username": "juanperez",
  "password": "Password123!"
}
```

Notas:

- Las contrasenas se guardan cifradas con BCrypt.
- Si no existe el rol `USER`, el sistema lo crea automaticamente.
- En cada registro y login se guarda un log de auditoria.
- El reset de password usa un token UUID que expira en 1 hora.

## 9.2 Incidentes

Archivos principales:

- `IncidentController`
- `IncidentService`
- `Incident`
- `IncidentHistory`
- `IncidentRepository`
- `IncidentHistoryRepository`

Endpoints:

| Metodo | Ruta | Que hace |
|---|---|---|
| `POST` | `/api/Incidents` | Crea un incidente. |
| `GET` | `/api/Incidents` | Lista todos los incidentes. |
| `GET` | `/api/Incidents/{id}` | Busca un incidente por ID. |
| `GET` | `/api/Incidents/My` | Lista incidentes reportados por el usuario autenticado. |
| `GET` | `/api/Incidents/Status/{status}` | Filtra por estado. |
| `GET` | `/api/Incidents/Zone/{zoneId}` | Filtra por zona. |
| `GET` | `/api/Incidents/Assigned` | Lista incidentes asignados al usuario autenticado. |
| `PATCH` | `/api/Incidents/{id}/Status` | Solo ADMIN. Actualiza estado, prioridad o asignado. |
| `GET` | `/api/Incidents/{id}/History` | Solo ADMIN. Consulta historial. |
| `DELETE` | `/api/Incidents/{id}` | Solo ADMIN. Elimina el incidente. |

Crear incidente:

```json
{
  "type": "ROBO",
  "description": "Se observo un robo a mano armada",
  "location": "Carrera 3 con Calle 10, Getsemani",
  "latitude": 10.4224,
  "longitude": -75.5531,
  "zoneId": "64abc123",
  "priority": "HIGH",
  "imageUrls": []
}
```

Estados disponibles:

- `PENDING`
- `IN_PROGRESS`
- `RESOLVED`
- `REJECTED`

Prioridades:

- `LOW`
- `MEDIUM`
- `HIGH`
- `CRITICAL`

Cuando se crea un incidente:

1. Se guarda en MongoDB.
2. Si trae `zoneId`, se aumenta el contador de incidentes de esa zona.
3. Se crea una notificacion para el usuario que reporto.
4. Se guarda un log `CREATE_INCIDENT`.

Cuando un ADMIN cambia el estado:

1. Se actualiza el incidente.
2. Se crea un documento en `incident_history`.
3. Se notifica al usuario que reporto.
4. Se guarda un log `UPDATE_INCIDENT_STATUS`.

## 9.3 Zonas

Archivos principales:

- `ZoneController`
- `ZoneService`
- `Zone`
- `ZoneRepository`

Endpoints:

| Metodo | Ruta | Que hace |
|---|---|---|
| `POST` | `/api/Zones` | Solo ADMIN. Crea una zona. |
| `GET` | `/api/Zones` | Lista zonas activas. |
| `GET` | `/api/Zones/{id}` | Busca zona por ID. |
| `GET` | `/api/Zones/Risk/{level}` | Filtra por nivel de riesgo. |
| `PATCH` | `/api/Zones/{id}/Risk` | Solo ADMIN. Cambia el riesgo. |
| `DELETE` | `/api/Zones/{id}` | Solo ADMIN. Desactiva la zona. |

Crear zona:

```json
{
  "name": "Getsemani",
  "description": "Barrio historico y turistico",
  "centerLatitude": 10.4224,
  "centerLongitude": -75.5531
}
```

Niveles de riesgo:

- `LOW`
- `MODERATE`
- `HIGH`
- `CRITICAL`

El borrado de zonas es **soft delete**: no elimina el documento, solo pone `active = false`.

## 9.4 Comentarios

Archivos principales:

- `CommentController`
- `CommentService`
- `Comment`
- `CommentRepository`

Base de ruta:

```text
/api/Incidents/{incidentId}/Comments
```

Endpoints:

| Metodo | Ruta | Que hace |
|---|---|---|
| `POST` | `/api/Incidents/{incidentId}/Comments` | Agrega comentario. |
| `GET` | `/api/Incidents/{incidentId}/Comments` | Lista comentarios publicos. |
| `GET` | `/api/Incidents/{incidentId}/Comments/All` | Solo ADMIN. Incluye internos. |
| `PUT` | `/api/Incidents/{incidentId}/Comments/{commentId}` | Edita comentario del autor. |
| `DELETE` | `/api/Incidents/{incidentId}/Comments/{commentId}` | Soft delete del comentario. |

Crear comentario:

```json
{
  "content": "Se envio patrulla al sector",
  "isInternal": false
}
```

Si `isInternal` es `true`, el comentario es para uso operativo interno.

## 9.5 Notificaciones

Archivos principales:

- `NotificationController`
- `NotificationService`
- `Notification`
- `NotificationRepository`

Endpoints:

| Metodo | Ruta | Que hace |
|---|---|---|
| `GET` | `/api/Notifications` | Lista mis notificaciones. |
| `GET` | `/api/Notifications/Unread` | Lista mis no leidas. |
| `GET` | `/api/Notifications/Unread/Count` | Cuenta no leidas. |
| `PATCH` | `/api/Notifications/{id}/Read` | Marca una como leida. |
| `PATCH` | `/api/Notifications/ReadAll` | Marca todas como leidas. |
| `DELETE` | `/api/Notifications/{id}` | Elimina una notificacion. |

Las notificaciones se crean desde servicios como `IncidentService`, no necesariamente desde un endpoint directo.

Tipos:

- `INCIDENT_CREATED`
- `INCIDENT_UPDATED`
- `INCIDENT_RESOLVED`
- `INCIDENT_ASSIGNED`
- `ZONE_ALERT`
- `SYSTEM`

## 9.6 Contactos de emergencia

Archivos principales:

- `EmergencyContactController`
- `EmergencyContactService`
- `EmergencyContact`
- `EmergencyContactRepository`

Endpoints:

| Metodo | Ruta | Que hace |
|---|---|---|
| `GET` | `/api/EmergencyContacts` | Publico. Lista contactos activos. |
| `GET` | `/api/EmergencyContacts/Zone/{zone}` | Publico. Filtra por zona. |
| `GET` | `/api/EmergencyContacts/Type/{type}` | Publico. Filtra por tipo. |
| `GET` | `/api/EmergencyContacts/{id}` | Publico. Busca por ID. |
| `POST` | `/api/EmergencyContacts` | Solo ADMIN. Crea contacto. |
| `PUT` | `/api/EmergencyContacts/{id}` | Solo ADMIN. Actualiza contacto. |
| `DELETE` | `/api/EmergencyContacts/{id}` | Solo ADMIN. Desactiva contacto. |

Tipos:

- `POLICE`
- `FIRE_STATION`
- `CIVIL_DEFENSE`
- `HOSPITAL`
- `AMBULANCE`
- `COAST_GUARD`
- `MUNICIPALITY`
- `OTHER`

## 9.7 Logs de auditoria

Archivos principales:

- `LogController`
- `LogService`
- `LogEntry`
- `LogEntryRepository`

Los logs registran acciones importantes del sistema:

- Registro.
- Login.
- Creacion de incidentes.
- Cambio de estado.
- Creacion o actualizacion de contactos.
- Cambios en zonas.

Endpoints solo ADMIN:

| Metodo | Ruta | Que hace |
|---|---|---|
| `GET` | `/api/Logs` | Lista todos los logs. |
| `GET` | `/api/Logs/User/{username}` | Filtra por usuario. |
| `GET` | `/api/Logs/Level/{level}` | Filtra por severidad. |
| `GET` | `/api/Logs/Range?from=...&to=...` | Filtra por fechas. |
| `GET` | `/api/Logs/Entity/{type}/{id}` | Filtra por entidad afectada. |

Niveles:

- `INFO`
- `WARN`
- `ERROR`

## 9.8 Archivos

Archivo principal:

- `FileUploadController`

Endpoints:

| Metodo | Ruta | Que hace |
|---|---|---|
| `POST` | `/api/Files/Upload` | Sube hasta 5 archivos. Requiere token. |
| `GET` | `/api/Files/{filename}` | Sirve un archivo guardado. Publico. |

Restricciones:

- Maximo 5 archivos por request.
- Maximo 10 MB por archivo.
- Tipos permitidos:
  - `image/jpeg`
  - `image/png`
  - `image/webp`
  - `image/gif`
  - `application/pdf`
  - `text/plain`
  - `application/msword`
  - `application/vnd.openxmlformats-officedocument.wordprocessingml.document`

Los archivos se guardan en la carpeta configurada por:

```properties
app.upload.dir=${UPLOAD_DIR}
```

Y las URLs se construyen con:

```properties
app.base-url=${BASE_URL}
```

## 9.9 Inteligencia artificial

Archivos principales:

- `AiController`
- `AiService`
- `ChatbotAgent`
- `AiDto`

Endpoints:

| Metodo | Ruta | Que hace |
|---|---|---|
| `POST` | `/api/Ai/Chat` | Chatbot con contexto del sistema. |
| `POST` | `/api/Ai/Classify` | Clasifica una descripcion de incidente. |
| `GET` | `/api/Ai/Summary` | Solo ADMIN. Resumen narrativo. |
| `GET` | `/api/Ai/Zones/Analysis` | Solo ADMIN. Analisis de zonas. |

### Como funciona el chatbot

`ChatbotAgent` consulta datos recientes de MongoDB:

- Ultimos incidentes.
- Zonas y niveles de riesgo.

Luego construye un prompt con ese contexto y se lo envia a `AiService`, que llama a Groq.

Flujo:

```text
Usuario pregunta
        |
AiController.chat()
        |
ChatbotAgent.processMessage()
        |
Consulta incidents y zones
        |
AiService.chat()
        |
Groq API
        |
Respuesta al usuario
```

Si Groq falla, algunos metodos devuelven respuestas de simulacion para que el sistema no se caiga completamente.

## 9.10 Correos

Archivo principal:

- `EmailService`

Plantillas:

```text
src/main/resources/Templates/EmailBienvenida.html
src/main/resources/Templates/EmailResetPassword.html
```

El servicio:

1. Toma una plantilla Thymeleaf.
2. Rellena variables como username, email o resetUrl.
3. Genera HTML.
4. Envia el HTML a un endpoint de Google Apps Script.

Se usa en:

- Registro de usuario: correo de bienvenida.
- Recuperacion de contrasena: correo con enlace de reset.

## 10. Documentacion Swagger

Cuando el servidor esta corriendo, puedes abrir:

```text
http://localhost:8080/swagger-ui.html
```

Tambien puede estar disponible en:

```text
http://localhost:8080/swagger-ui/index.html
```

Swagger permite:

- Ver todos los endpoints.
- Probar peticiones desde el navegador.
- Autorizarse con JWT usando el boton `Authorize`.

Formato del token en Swagger:

```text
Bearer eyJhbGciOi...
```

## 11. Como ejecutar el backend localmente

Requisitos:

- Java 21.
- PostgreSQL.
- MongoDB.
- Maven o el wrapper incluido.

Pasos:

1. Clonar el repositorio.
2. Crear la base de datos PostgreSQL.
3. Tener MongoDB corriendo.
4. Crear el archivo `.env`.
5. Ejecutar:

```powershell
.\mvnw.cmd spring-boot:run
```

En Linux o macOS:

```bash
./mvnw spring-boot:run
```

El servidor queda en:

```text
http://localhost:8080
```

## 12. Como probar un flujo completo

### 1. Registrar usuario

```http
POST /api/Auth/Register
```

```json
{
  "username": "ana",
  "password": "Password123!",
  "email": "ana@email.com",
  "fullName": "Ana Gomez",
  "phone": "3001234567"
}
```

Guardar el `token` que devuelve.

### 2. Usar el token

En cada request protegida:

```http
Authorization: Bearer <token>
```

### 3. Crear un incidente

```http
POST /api/Incidents
```

```json
{
  "type": "ROBO",
  "description": "Robo reportado cerca al centro historico",
  "location": "Centro historico",
  "latitude": 10.4236,
  "longitude": -75.5507,
  "priority": "HIGH",
  "imageUrls": []
}
```

### 4. Consultar mis incidentes

```http
GET /api/Incidents/My
```

### 5. Revisar notificaciones

```http
GET /api/Notifications
```

## 13. Explicacion de los modelos principales

### `User`

Representa una cuenta del sistema.

Campos importantes:

- `username`: identificador unico.
- `password`: contrasena cifrada.
- `email`: correo.
- `phone`: telefono.
- `roles`: permisos asignados.
- `resetToken`: token temporal para recuperar contrasena.
- `lastLogin`: ultimo inicio de sesion.

### `Role`

Representa un rol de permisos. Ejemplos:

- `USER`
- `ADMIN`

Spring Security los convierte a autoridades como `ROLE_USER` o `ROLE_ADMIN`.

### `Incident`

Representa un reporte de seguridad.

Campos importantes:

- `type`: tipo de incidente.
- `description`: descripcion enviada por el usuario.
- `location`: ubicacion textual.
- `latitude` y `longitude`: coordenadas.
- `zoneId`: zona asociada.
- `reportedBy`: usuario que reporto.
- `priority`: prioridad.
- `status`: estado actual.
- `assignedTo`: agente asignado.
- `imageUrls`: evidencias.

### `Zone`

Representa una zona de Cartagena.

Campos importantes:

- `name`: nombre.
- `riskLevel`: nivel de riesgo.
- `centerLatitude` y `centerLongitude`: centro en mapa.
- `totalIncidents`: total registrados.
- `pendingIncidents`: pendientes.
- `resolvedIncidents`: resueltos.
- `active`: permite desactivar sin borrar.

### `Comment`

Representa un comentario asociado a un incidente.

Campos importantes:

- `incidentId`: incidente al que pertenece.
- `userId` y `username`: autor.
- `content`: texto.
- `isInternal`: define si es interno.
- `deleted`: soft delete.

### `Notification`

Representa un aviso para un usuario.

Campos importantes:

- `userId`: destinatario.
- `title`: titulo.
- `message`: contenido.
- `type`: tipo de notificacion.
- `read`: si fue leida.
- `relatedEntityId`: objeto relacionado.

### `LogEntry`

Representa una accion registrada en auditoria.

Campos importantes:

- `action`: accion realizada.
- `user`: usuario que la hizo.
- `details`: descripcion.
- `ipAddress`: IP si aplica.
- `userAgent`: navegador o cliente.
- `entityType` y `entityId`: objeto afectado.
- `level`: severidad.

## 14. Manejo de errores

El archivo `GlobalExceptionHandler` centraliza los errores:

| Excepcion | HTTP | Respuesta |
|---|---:|---|
| `IllegalArgumentException` | 400 | Mensaje especifico del error. |
| `BadCredentialsException` | 401 | `Credenciales incorrectas`. |
| `AuthenticationException` | 401 | `Credenciales incorrectas`. |
| `RuntimeException` | 500 | `Error interno del servidor`. |

Esto evita que el cliente reciba trazas tecnicas de Java.

## 15. CORS

`SecurityConfig` permite peticiones desde:

- `http://localhost:3000`
- `http://localhost:5173`
- `http://localhost:8080`
- `https://cartagena-segura.vercel.app`
- `https://cartagena-segura-mobile.vercel.app`
- `https://cartagena-segura.up.railway.app`

Si se despliega un nuevo frontend en otro dominio, debe agregarse en `corsConfigurationSource()`.

## 16. Consejos para modificar el codigo

### Si quieres crear un nuevo modulo

Sigue este orden:

1. Crear el modelo en `Model`.
2. Crear el repositorio en `Repository`.
3. Crear la logica en `Service`.
4. Crear rutas en `Controller`.
5. Crear DTOs si se necesitan.
6. Agregar permisos en `SecurityConfig` si aplica.
7. Documentar el endpoint con anotaciones Swagger.

### Si quieres agregar una ruta protegida

No necesitas validar el token manualmente en cada controlador. Spring Security ya lo hace con `JwtAuthFilter`.

Para obtener el usuario actual:

```java
@AuthenticationPrincipal UserDetails userDetails
```

Para restringir solo a administradores:

```java
@PreAuthorize("hasRole('ADMIN')")
```

### Si quieres consultar la base de datos

Agrega metodos al repositorio usando nombres descriptivos:

```java
List<Incident> findByReportedBy(String reportedBy);
```

Spring Data interpreta ese nombre y genera la consulta.

## 17. Resumen mental rapido

Piensa el backend asi:

- **Controller**: puerta de entrada HTTP.
- **Service**: cerebro del caso de uso.
- **Repository**: puente a base de datos.
- **Model**: forma de los datos guardados.
- **Dto**: forma de los datos que entran o salen por API.
- **Security**: autenticacion y permisos.
- **Config**: ajustes globales.
- **Exception**: respuestas limpias cuando algo falla.

Con esa idea, leer cualquier funcionalidad se vuelve mas facil: busca primero el controlador, luego el servicio y finalmente el repositorio/modelo que usa.
