package Com.Backend.CartagenaSegura.Config;

import io.swagger.v3.oas.models.Components;
import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Contact;
import io.swagger.v3.oas.models.info.Info;
import io.swagger.v3.oas.models.info.License;
import io.swagger.v3.oas.models.security.SecurityRequirement;
import io.swagger.v3.oas.models.security.SecurityScheme;
import io.swagger.v3.oas.models.servers.Server;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.util.List;

@Configuration
public class SwaggerConfig {

    @Bean
    public OpenAPI openAPI() {
        return new OpenAPI()
                .info(new Info()
                        .title("Cartagena Segura API")
                        .description("""
                    API REST para el sistema de seguridad ciudadana de Cartagena.
                    
                    ## Autenticación
                    Esta API usa **JWT Bearer Token**. Para obtener un token:
                    1. Regístrate en `POST /api/Auth/Register`
                    2. Inicia sesión en `POST /api/Auth/Login`
                    3. Copia el token de la respuesta
                    4. Haz clic en **Authorize** e ingresa: `Bearer <tu_token>`
                    
                    ## Roles
                    - **USER** -> puede reportar incidentes, comentar y ver notificaciones
                    - **ADMIN** -> acceso completo al sistema
                    """)
                        .version("1.0.0")
                        .contact(new Contact()
                                .name("ProAula - Cartagena Segura")
                                .email("admin@cartagenasegura.com"))
                        .license(new License()
                                .name("MIT")
                                .url("https://opensource.org/licenses/MIT"))
                )
                .servers(List.of(
                        new Server().url("http://localhost:8080").description("Servidor de desarrollo"),
                        new Server().url("https://api.cartagenasegura.com").description("Servidor de producción")
                ))
                // Configurar esquema de seguridad JWT
                .addSecurityItem(new SecurityRequirement().addList("bearerAuth"))
                .components(new Components()
                        .addSecuritySchemes("bearerAuth", new SecurityScheme()
                                .name("bearerAuth")
                                .type(SecurityScheme.Type.HTTP)
                                .scheme("bearer")
                                .bearerFormat("JWT")
                                .description("Ingresa tu JWT token. Ejemplo: Bearer eyJhbGci...")
                        )
                );
    }
}
