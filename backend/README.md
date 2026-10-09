# Cartagena Segura - Backend

Sistema de gestión y seguridad ciudadana para la ciudad de Cartagena. Esta documentación corresponde a la configuración del entorno de desarrollo **local**.

## Documentación del código

La explicación completa del backend está en:

* [docs/backend-documentacion.md](docs/backend-documentacion.md)

Ahí se explica la arquitectura, carpetas, seguridad JWT, bases de datos, servicios, modelos, endpoints y flujos principales para que cualquier persona pueda entender cómo funciona el código.

## Requisitos
* Java 21
* Maven 3.x
* PostgreSQL (Local)
* MongoDB (Local)

## Instalación

* git clone https://github.com/TheSantSalazar/Cartagena-Segura
* Abrir la carpeta con tu editor de codigo o IDE favorito

## Ejecución

* Linux / Mac: ./mvnw spring-boot:run

* Windows PowerShell: .\mvnw.cmd spring-boot:run

* El servidor estará disponible en: http://localhost:8080

## Swagger

* Documentación de la API (disponible al ejecutar): http://localhost:8080/swagger-ui/index.html

## Tecnologías del Proyecto

* Framework: Spring Boot 3.4.3
* Lenguaje: Java 21
* Gestor de Dependencias: Maven
* Bases de Datos: PostgreSQL & MongoDB
* Seguridad: JWT (JSON Web Token)
* IA: Groq API
* Notificaciones: SendGrid

## Variables de Entorno (.env)
Crea un archivo `.env` en la raíz del proyecto para la ejecución local:

```env
# Configuración Base de Datos (PostgreSQL Local)
DB_URL=jdbc:postgresql://localhost:5432/cartagena_segura
DB_USERNAME=postgres
DB_PASSWORD=admin

# Configuración NoSQL (MongoDB Local)
MONGO_URI=mongodb://localhost:27017/
MONGO_DATABASE=cartagena_segura_local

# Seguridad y Autenticación
JWT_SECRET=clave_secreta_para_desarrollo_local_123
JWT_EXPIRATION=86400000

# Integraciones de Terceros (API Keys)
GROQ_API_KEY=tu_groq_api_key_aqui
SENDGRID_API_KEY=tu_sendgrid_key_aqui
MAIL_FROM=test@localhost.com

# Servidor y Almacenamiento
PORT=8080
BASE_URL=http://localhost:8080
UPLOAD_DIR=uploads/
