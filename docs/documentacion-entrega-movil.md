# Cartagena Segura
## Contrato, API simulada y diseño de pantallas

**Proyecto académico de Computación Móvil**

**Versión de la aplicación móvil analizada:** 1.1.0+2

**Fecha de análisis:** 5 de noviembre de 2026

> Este documento describe el estado visible en el repositorio. Es una especificación académica del alcance implementado, no un contrato legal ni una promesa de disponibilidad de servicios externos.

## 1. Contrato del proyecto

### 1.1 Propósito

Cartagena Segura es una solución de seguridad ciudadana compuesta por una aplicación móvil Flutter para Android e iOS, una aplicación web React y una API REST construida con Spring Boot. La app móvil busca facilitar que una persona consulte incidentes georreferenciados, envíe reportes y encuentre teléfonos de emergencia de Cartagena.

La aplicación móvil consume la misma API del proyecto; no implementa un backend ni una base de datos independiente.

### 1.2 Partes y usuarios

- **Ciudadano:** usuario principal de la app móvil; puede crear una cuenta, iniciar sesión, consultar incidentes, reportar una situación y consultar contactos de emergencia.
- **API del proyecto:** autentica usuarios y centraliza la consulta y persistencia de datos.
- **Administrador/agente:** existen funciones administrativas y de gestión en el sistema general, pero no forman parte de las pantallas móviles analizadas.

### 1.3 Alcance funcional móvil

El alcance implementado en `mobile/` comprende:

1. **Acceso, registro y recuperación de contraseña** mediante los endpoints públicos de autenticación.
2. **Persistencia local de sesión:** el token y los datos básicos de perfil se guardan con almacenamiento seguro del dispositivo para restaurar la sesión.
3. **Inicio ciudadano:** saludo, resumen de incidentes propios por estado y accesos rápidos.
4. **Mis reportes:** consulta de incidentes propios, estado, prioridad, fecha y detalles.
5. **Mapa ciudadano:** incidentes de la API representados en OpenStreetMap cuando contienen coordenadas.
6. **Creación de reportes:** categoría, descripción, dirección/referencia, prioridad y coordenadas opcionales obtenidas con GPS.
7. **Emergencias:** consulta de contactos activos, llamada a un contacto o a la línea 123 desde el dispositivo.
8. **Perfil de solo lectura y cierre de sesión.** El backend no ofrece una operación ciudadana para editar el perfil.
9. **Estados de carga, errores y reintento** en las consultas de datos donde se implementaron.

La app móvil usa la identidad visual de Cartagena Segura (azul `#1D4ED8`, navy `#0F172A`, fondos claros y recursos de marca compartidos con la web). La interfaz web React/PWA permanece como cliente separado y no se sustituye.

### 1.4 Reglas funcionales observables

- El acceso al contenido principal depende de que exista una sesión restaurada o iniciada.
- El formulario requiere usuario y contraseña para iniciar sesión. En registro se requieren usuario, nombre, correo y contraseña; el teléfono es opcional. La validación local de contraseña exige al menos seis caracteres y la validación de correo comprueba que contenga `@`.
- La recuperación solicita el correo con `POST /Auth/ForgotPassword`; el restablecimiento usa el token enviado por correo y `POST /Auth/ResetPassword`.
- El resumen y la lista consultan `GET /Incidents/My`, que requiere un token válido. El mapa consulta `GET /Incidents`, público según la configuración HTTP del backend.
- Un reporte requiere tipo, descripción y dirección o referencia. El uso del GPS es opcional y depende de que el usuario otorgue permisos y tenga habilitados los servicios de ubicación.
- Después de enviar un reporte correctamente, el mapa, el resumen y la lista vuelven a consultar los incidentes.
- El reporte envía prioridad elegida y una lista `imageUrls` vacía. No se implementa selección ni carga de fotografías desde la app móvil actual.
- En el mapa, solo se dibujan marcadores para incidentes con latitud y longitud. Al seleccionar un marcador se muestran descripción, ubicación, estado y prioridad.
- Los contactos proceden de la API. El número 123 está configurado directamente en la interfaz móvil.
- La app utiliza una URL de API inyectada durante la compilación con `--dart-define=API_BASE_URL`; no debe asumirse que `localhost` sea alcanzable desde un teléfono.

### 1.5 Fuera del alcance móvil actual

No se implementan en la app móvil edición de perfil, comentarios, chatbot, notificaciones, análisis Power BI, administración de zonas ni carga de evidencia fotográfica. Algunas capacidades existen en la web o en la API, pero no deben describirse como funcionalidades móviles implementadas. La administración permanece únicamente en la web.

La app tampoco sustituye servicios oficiales de emergencia, garantiza la atención de reportes ni proporciona operación sin conexión. La disponibilidad de mapas, GPS, telefonía, API y datos depende del dispositivo, permisos, conectividad y servicios externos.

### 1.6 Criterios generales de aceptación

Para considerar operativo el alcance móvil, en un dispositivo o emulador con conectividad se debe poder:

- completar registro o autenticarse con una cuenta válida;
- entrar a la navegación principal y cambiar entre Inicio, Reportes, Mapa, Emergencias y Perfil;
- recuperar/restablecer contraseña siguiendo el token enviado por correo;
- consultar el resumen e historial propio con la cuenta autenticada;
- obtener la lista de incidentes y visualizar los que tengan coordenadas;
- enviar un reporte válido con dirección, tipo y descripción;
- cargar el directorio de contactos y solicitar una llamada a un número seleccionado;
- consultar la información de perfil recibida al iniciar sesión y cerrar sesión;
- recibir un mensaje comprensible cuando falte conexión, haya un error de API o no se conceda permiso de ubicación.

El cumplimiento de estas pruebas depende de que la API y la autenticación estén correctamente configuradas. Véase la limitación técnica en la sección 2.5.

## 2. Mock, API y datos

### 2.1 Situación encontrada

**No hay un Mock Server independiente configurado para la app móvil.** En ejecución, Flutter usa solicitudes HTTP reales hacia el backend Spring Boot. El endpoint base se define al compilar, por ejemplo:

```text
http://10.0.2.2:3000/api
```

para el emulador Android con Docker Compose (el API no publica directamente el puerto 8080 al host), o una URL HTTPS pública para producción.

El proyecto sí usa `MockClient` de `package:http/testing.dart` en pruebas unitarias (`mobile/test/models_test.dart`). Ese cliente falso sustituye el transporte HTTP dentro de una prueba, devuelve una respuesta JSON preparada y permite verificar el parseo y las solicitudes; no es un servidor ejecutable ni abastece datos a la app normal.

### 2.2 Formato común de respuesta

Los controladores del backend envuelven sus respuestas con el formato genérico `success`, `message` y `data`. El cliente Flutter detecta ese sobre y entrega a cada pantalla únicamente su propiedad `data`.

```json
{
  "success": true,
  "message": "OK",
  "data": {}
}
```

Ante respuestas HTTP no exitosas o `success: false`, el cliente produce un error que la pantalla puede presentar al usuario.

### 2.3 Endpoints consumidos por la app

Las rutas siguientes se muestran relativas al prefijo `/api`, que debe estar incluido en `API_BASE_URL`.

| Método y ruta | Uso móvil | Autenticación según backend |
|---|---|---|
| `POST /Auth/Login` | Iniciar sesión | Pública |
| `POST /Auth/Register` | Crear cuenta ciudadana | Pública |
| `POST /Auth/ForgotPassword` | Solicitar recuperación por correo | Pública |
| `POST /Auth/ResetPassword` | Restablecer contraseña con token | Pública |
| `GET /Incidents` | Obtener incidentes para el mapa | Pública según `SecurityConfig` |
| `GET /Incidents/My` | Resumen e historial de reportes propios | Requiere JWT |
| `POST /Incidents` | Crear reporte ciudadano | Requiere JWT |
| `GET /EmergencyContacts` | Cargar directorio de contactos activos | Pública |

El backend contiene además rutas para filtros, historial, comentarios, administración y otras funciones. No todas son invocadas por la app móvil actual y, por ello, no se enumeran como parte de su integración implementada.

Aunque el controlador de incidentes documenta un requisito Bearer en OpenAPI, la configuración HTTP del backend permite el `GET /api/Incidents` sin autenticación; la creación mediante `POST /api/Incidents` sí queda protegida por la regla general de autenticación.

### 2.4 Estructuras JSON de referencia

**Inicio de sesión — solicitud**

```json
{
  "username": "ciudadano",
  "password": "contraseña"
}
```

**Registro — solicitud**

```json
{
  "username": "ciudadano",
  "password": "contraseña",
  "email": "persona@example.com",
  "fullName": "Nombre Apellido",
  "phone": "3001234567"
}
```

**Respuesta de autenticación — ejemplo estructural**

```json
{
  "success": true,
  "message": "Login exitoso",
  "data": {
    "token": "<JWT>",
    "username": "ciudadano",
    "fullName": "Nombre Apellido",
    "email": "persona@example.com",
    "phone": "3001234567",
    "roles": ["USER"]
  }
}
```

**Creación de incidente — solicitud**

```json
{
  "type": "ROBO",
  "description": "Descripción de lo ocurrido",
  "location": "Barrio, calle o referencia",
  "latitude": 10.4224,
  "longitude": -75.5531,
  "priority": "MEDIUM",
  "imageUrls": []
}
```

La app envía `latitude` y `longitude` como `null` si no se obtuvo GPS. El DTO del backend también admite `zoneId`, aunque el formulario móvil actual no lo envía. El autor del reporte se asigna en el backend a partir del usuario autenticado.

**Incidente — campos relevantes consumidos por el mapa**

```json
{
  "id": "64abc1234567890def",
  "type": "ROBO",
  "description": "Descripción de lo ocurrido",
  "location": "Getsemaní",
  "latitude": 10.4224,
  "longitude": -75.5531,
  "priority": "HIGH",
  "status": "PENDING"
}
```

El modelo del backend puede incluir además `zoneId`, `reportedBy`, `assignedTo`, `imageUrls`, `createdAt` y `updatedAt`. Los valores de prioridad definidos son `LOW`, `MEDIUM`, `HIGH`, `CRITICAL`; los estados incluyen `PENDING`, `IN_PROGRESS`, `RESOLVED` y `REJECTED`.

**Contactos de emergencia — elemento de `data`**

```json
{
  "id": 1,
  "name": "Policía Nacional - Bocagrande",
  "phone": "6047890000",
  "alternativePhone": "123",
  "type": "POLICE",
  "zone": "Bocagrande",
  "address": "Carrera 1 con Calle 8",
  "active": true,
  "notes": "Disponible 24/7"
}
```

La respuesta de consulta es una lista dentro de `data`. La pantalla móvil usa principalmente `name`, `phone`, `type`, `address` y `notes`. Los tipos contemplados por el backend incluyen `POLICE`, `FIRE_STATION`, `CIVIL_DEFENSE`, `HOSPITAL`, `AMBULANCE`, `COAST_GUARD`, `MUNICIPALITY` y `OTHER`.

### 2.5 Autenticación y manejo de sesión

El cliente móvil envía el token guardado en el encabezado `Authorization` con esquema Bearer. El filtro JWT del backend reconoce ese formato; además, la prueba del cliente HTTP verifica que la solicitud autenticada incluya el token. El endpoint `POST /Incidents` requiere una sesión válida.

Cuando una solicitud autenticada recibe HTTP 401, la app limpia la sesión en memoria y elimina las credenciales persistidas para devolver al usuario al acceso. Si falla la eliminación segura, el error se informa en el mensaje de la solicitud en lugar de ocultarse. Los cambios y sus pruebas se describen en la implementación vigente de `mobile/`.

## 3. Diseño de pantallas y flujo

### 3.1 Flujo principal

```text
Arranque
  ├─ Restaurando sesión → Indicador de carga
  ├─ Error al leer sesión → Pantalla de error de inicio
  ├─ Sin usuario → Acceso / Registro
  └─ Usuario autenticado → Navegación inferior
       ├─ Inicio
       ├─ Reportes → Crear reporte
       ├─ Mapa
       ├─ Emergencias
       └─ Perfil
```

El acceso/registro permite abrir recuperación de contraseña; esa vista solicita el correo o permite introducir el token recibido y la nueva contraseña. La barra superior presenta la marca y el acceso al perfil; el cierre de sesión está en Perfil.

### 3.2 Inventario de vistas

| Vista | Propósito y contenido | Acciones y datos |
|---|---|---|
| **Carga/restauración de sesión** | Estado transitorio al inicializar almacenamiento seguro y revisar si existe una sesión previa. | Muestra un indicador de progreso; decide si abre el acceso o la navegación principal. |
| **Error de restauración** | Informa que no se pudo recuperar la sesión almacenada. | Muestra el detalle del error; no carga la experiencia autenticada. |
| **Acceso / Registro** | Pantalla con fondos, logotipo, panel translúcido, campos y errores de validación/API que conserva el estilo visual de la web. | Envía `POST /Auth/Login` o `POST /Auth/Register`. En registro agrega nombre, correo y teléfono. Permite alternar los modos y abrir recuperación. |
| **Recuperación** | Formulario para solicitar enlace y vista para pegar token y establecer contraseña nueva. | Envía `POST /Auth/ForgotPassword` y `POST /Auth/ResetPassword`. |
| **Inicio** | Banner de bienvenida, resumen personal por estado, accesos rápidos y recordatorio de llamar al 123 ante peligro inmediato. | Consulta `GET /Incidents/My`; accesos a Reportes, Mapa y Emergencias. |
| **Mis reportes** | Lista propia con ubicación, fecha, estados/prioridad y panel de detalle; muestra vacíos, errores y reintento. | Consulta `GET /Incidents/My`; abre el formulario de creación. |
| **Mapa ciudadano** | Mapa centrado inicialmente en Cartagena con mosaicos de OpenStreetMap, pines coloreados según prioridad y resumen de cantidad de reportes/con ubicación. | Consulta `GET /Incidents`, permite actualizar y seleccionar marcadores para ver detalles. Incidentes sin coordenadas no aparecen como pines. |
| **Reportar un incidente** | Formulario de tipo, descripción, dirección/referencia y prioridad; muestra las coordenadas si el usuario solicita GPS. | Valida campos obligatorios, solicita permisos de ubicación y envía `POST /Incidents`. Tras éxito, actualiza el mapa, el resumen y la lista. No adjunta fotos. |
| **Emergencias** | Banner destacado para el 123 y directorio de contactos obtenidos desde la API. | Consulta `GET /EmergencyContacts`, permite reintentar si falla y solicita al sistema operativo abrir el marcador telefónico para llamar. |
| **Perfil** | Presenta usuario, nombre, correo y teléfono devueltos por la API. | Permite cerrar la sesión segura. No ofrece edición de datos, pues no existe endpoint ciudadano para ese fin. |

### 3.3 Navegación y componentes

- **Inicio** corresponde al índice `0` de la navegación inferior.
- **Reportes** corresponde al índice `1` y permite abrir el formulario de creación.
- **Mapa**, **Emergencias** y **Perfil** corresponden a los índices `2`, `3` y `4`.
- Cerrar sesión elimina las claves de sesión guardadas y devuelve al flujo de acceso.
- El mapa requiere acceso de red tanto a la API como al servicio de teselas de OpenStreetMap.

### 3.4 Estados alternativos relevantes

- La consulta del mapa muestra carga, error con acción de reintento o el mapa con reportes.
- Emergencias muestra carga, error con reintento, directorio o mensaje cuando no hay contactos publicados.
- La solicitud de GPS distingue servicios desactivados, permiso denegado y permiso bloqueado.
- Los envíos deshabilitan temporalmente el botón y muestran actividad mientras esperan respuesta.

## 4. Exportar este documento a PDF

El archivo fuente está en Markdown para conservar títulos, tablas y ejemplos JSON. Para generar el PDF sin alterar el repositorio:

1. Abre `docs/documentacion-entrega-movil.md` en Microsoft Word o LibreOffice Writer. Si el editor no abre Markdown directamente, crea un documento nuevo y pega el contenido renderizado desde la vista previa Markdown de VS Code.
2. Revisa la portada, completa los datos institucionales que solicite el curso (integrantes, docente, institución y fecha de entrega) y comprueba que las tablas no queden cortadas.
3. En Word selecciona **Archivo → Exportar/Guardar como → PDF**. En LibreOffice selecciona **Archivo → Exportar como → Exportar como PDF**.
4. Guarda el resultado como `documentacion-cartagena-segura.pdf`.

Como alternativa reproducible, con Pandoc y un motor LaTeX instalados:

```powershell
pandoc docs/documentacion-entrega-movil.md `
  --from markdown `
  --pdf-engine=xelatex `
  --toc `
  --number-sections `
  -o docs/documentacion-cartagena-segura.pdf
```

El PDF debe revisarse visualmente antes de entregar, especialmente los saltos de página de las tablas y los bloques JSON.

## 5. Referencias del repositorio

- `mobile/lib/main.dart`: inicialización de sesión y decisión entre acceso y contenido autenticado.
- `mobile/lib/data/api_client.dart`: URL base, solicitudes, cabeceras y tratamiento del sobre de respuesta.
- `mobile/lib/data/session_controller.dart`: registro, acceso y almacenamiento seguro de sesión.
- `mobile/lib/data/models.dart`: modelos de usuario, incidente y contacto.
- `mobile/lib/screens/`: implementación de las vistas descritas.
- `mobile/test/models_test.dart`: pruebas de modelos y ejemplo de `MockClient` en memoria.
- `backend/src/main/java/Com/Backend/CartagenaSegura/Controller/`: rutas de la API.
- `mobile/README.md`: configuración, ejecución y compilación del cliente Flutter.
