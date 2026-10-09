package Com.Backend.CartagenaSegura.Service;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;
import org.thymeleaf.TemplateEngine;
import org.thymeleaf.context.Context;

import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;

@Service
public class EmailService {

    private final TemplateEngine templateEngine;
    private final ObjectMapper objectMapper;

    @Value("${apps.script.url}")
    private String appsScriptUrl;

    @Value("${app.base-url:https://cartagena-segura-production.up.railway.app}")
    private String apiBaseUrl;

    public EmailService(TemplateEngine templateEngine, ObjectMapper objectMapper) {
        this.templateEngine = templateEngine;
        this.objectMapper = objectMapper;
    }

    @Async
    public void sendWelcomeEmail(String to, String username, String fullName) {
        try {
            Context context = new Context();
            context.setVariable("username",     username);
            context.setVariable("email",        to);
            context.setVariable("fullName",     fullName != null ? fullName : username);
            context.setVariable("registeredAt", LocalDateTime.now());
            context.setVariable("appUrl",       "https://cartagena-segura.vercel.app");
            context.setVariable("apiUrl",       apiBaseUrl);

            // Se genera el HTML desde la plantilla
            String html = templateEngine.process("EmailBienvenida", context);

            // Preparar el cuerpo JSON
            Map<String, String> payload = new HashMap<>();
            payload.put("to", to);
            payload.put("subject", "¡Bienvenido a Cartagena Segura!");
            payload.put("html", html);

            String requestBody = objectMapper.writeValueAsString(payload);

            // Enviar petición HTTPS a Google Apps Script
            HttpClient client = HttpClient.newBuilder()
                    .followRedirects(HttpClient.Redirect.ALWAYS) // Apps script requiere redirecciones
                    .build();

            HttpRequest request = HttpRequest.newBuilder()
                    .uri(URI.create(appsScriptUrl))
                    .header("Content-Type", "application/json")
                    .POST(HttpRequest.BodyPublishers.ofString(requestBody))
                    .build();

            HttpResponse<String> response = client.send(request, HttpResponse.BodyHandlers.ofString());

            if (response.statusCode() == 200 || response.statusCode() == 302) {
                 System.out.println("Email delegado existosamente a Google Apps Script para: " + to);
            } else {
                 System.err.println("Google Script retornó código HTTP: " + response.statusCode());
            }

        } catch (Exception e) {
            System.err.println("Error delegando email a Google Apps Script para " + to + ": " + e.getMessage());
        }
    }
    @Async
    public void sendPasswordResetEmail(String to, String username, String resetUrl) {
        try {
            Context context = new Context();
            context.setVariable("username", username);
            context.setVariable("resetUrl", resetUrl);
            context.setVariable("appUrl",   "https://cartagena-segura.vercel.app");
            context.setVariable("apiUrl",   apiBaseUrl);

            String html = templateEngine.process("EmailResetPassword", context);

            Map<String, String> payload = new HashMap<>();
            payload.put("to", to);
            payload.put("subject", "Restablecer Contraseña - Cartagena Segura");
            payload.put("html", html);

            String requestBody = objectMapper.writeValueAsString(payload);

            HttpClient client = HttpClient.newBuilder()
                    .followRedirects(HttpClient.Redirect.ALWAYS)
                    .build();

            HttpRequest request = HttpRequest.newBuilder()
                    .uri(URI.create(appsScriptUrl))
                    .header("Content-Type", "application/json")
                    .POST(HttpRequest.BodyPublishers.ofString(requestBody))
                    .build();

            HttpResponse<String> response = client.send(request, HttpResponse.BodyHandlers.ofString());

            if (response.statusCode() == 200 || response.statusCode() == 302) {
                System.out.println("Email de restablecimiento delegado existosamente para: " + to);
            } else {
                System.err.println("Google Script (Reset) retornó código HTTP: " + response.statusCode());
            }

        } catch (Exception e) {
            System.err.println("Error delegando email de restablecimiento para " + to + ": " + e.getMessage());
        }
    }
}
