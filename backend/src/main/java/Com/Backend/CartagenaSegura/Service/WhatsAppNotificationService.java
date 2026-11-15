package Com.Backend.CartagenaSegura.Service;

import Com.Backend.CartagenaSegura.Model.Incident;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;

import java.net.URI;
import java.net.URLEncoder;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.HashMap;
import java.util.Map;

@Service
public class WhatsAppNotificationService {

    private static final Logger log = LoggerFactory.getLogger(WhatsAppNotificationService.class);

    private final HttpClient httpClient;

    @Value("${app.whatsapp.enabled:false}")
    private boolean enabled;

    @Value("${app.whatsapp.phone:}")
    private String adminPhone;

    @Value("${app.whatsapp.apikey:}")
    private String apiKey;

    @Value("${app.whatsapp.api-url:https://api.callmebot.com/whatsapp.php}")
    private String apiUrl;

    public WhatsAppNotificationService() {
        this(HttpClient.newBuilder().connectTimeout(Duration.ofSeconds(10)).build());
    }

    public WhatsAppNotificationService(HttpClient httpClient) {
        this.httpClient = httpClient;
    }

    public boolean isConfigured() {
        return enabled && adminPhone != null && !adminPhone.isBlank() && apiKey != null && !apiKey.isBlank();
    }

    public String getAdminPhone() {
        return adminPhone;
    }

    public boolean isEnabled() {
        return enabled;
    }

    @Async
    public void sendEmergencyIncidentAlert(Incident incident) {
        if (!isConfigured()) {
            log.debug("Notificación por WhatsApp omitida: servicio no habilitado o sin credenciales completas");
            return;
        }

        String message = buildIncidentAlertMessage(incident);
        send(adminPhone, message, apiKey);
    }

    public Map<String, Object> send(String phone, String text, String key) {
        Map<String, Object> result = new HashMap<>();
        if (phone == null || phone.isBlank() || key == null || key.isBlank()) {
            result.put("success", false);
            result.put("message", "Teléfono y API Key son obligatorios para el envío");
            return result;
        }

        try {
            String targetPhone = phone.trim();
            if (!targetPhone.startsWith("+")) {
                targetPhone = "+" + targetPhone;
            }

            String encodedText = URLEncoder.encode(text, StandardCharsets.UTF_8).replace("+", "%20");
            String encodedPhone = URLEncoder.encode(targetPhone, StandardCharsets.UTF_8);
            String encodedKey = URLEncoder.encode(key.trim(), StandardCharsets.UTF_8);

            String fullUrl = apiUrl + "?phone=" + encodedPhone + "&text=" + encodedText + "&apikey=" + encodedKey;

            HttpRequest request = HttpRequest.newBuilder()
                    .uri(URI.create(fullUrl))
                    .timeout(Duration.ofSeconds(15))
                    .header("User-Agent", "CartagenaSegura-Backend/2.4")
                    .GET()
                    .build();

            HttpResponse<String> response = httpClient.send(request, HttpResponse.BodyHandlers.ofString());

            boolean success = response.statusCode() >= 200 && response.statusCode() < 300;
            result.put("success", success);
            result.put("statusCode", response.statusCode());
            result.put("responseBody", response.body());
            result.put("targetPhone", targetPhone);

            if (success) {
                log.info("Alerta de WhatsApp enviada con éxito a {}", targetPhone);
            } else {
                log.warn("CallMeBot respondió con código HTTP {}: {}", response.statusCode(), response.body());
            }
            return result;
        } catch (Exception e) {
            log.error("Error al despachar mensaje de WhatsApp mediante CallMeBot: {}", e.getMessage(), e);
            result.put("success", false);
            result.put("error", e.getMessage());
            return result;
        }
    }

    public String buildIncidentAlertMessage(Incident incident) {
        StringBuilder sb = new StringBuilder();
        sb.append("🚨 *ALERTA CARTAGENA SEGURA*\n");
        sb.append("━━━━━━━━━━━━━━━━━━━━\n");
        sb.append("📌 *Incidente:* ").append(incident.getType() != null ? incident.getType() : "EMERGENCIA").append("\n");
        sb.append("⚠️ *Prioridad:* ").append(incident.getPriority() != null ? incident.getPriority().name() : "CRITICAL").append("\n");
        sb.append("📍 *Ubicación:* ").append(incident.getLocation() != null ? incident.getLocation() : "Sin dirección").append("\n");

        if (incident.getLatitude() != null && incident.getLongitude() != null) {
            sb.append("🗺️ *Mapa:* https://maps.google.com/?q=")
              .append(incident.getLatitude())
              .append(",")
              .append(incident.getLongitude())
              .append("\n");
        }

        if (incident.getDescription() != null && !incident.getDescription().isBlank()) {
            sb.append("📝 *Detalle:* ").append(incident.getDescription()).append("\n");
        }

        sb.append("👤 *Reportado por:* ").append(incident.getReportedBy() != null ? incident.getReportedBy() : "Anónimo").append("\n");
        sb.append("🕒 *Hora:* ").append(LocalDateTime.now().format(DateTimeFormatter.ofPattern("HH:mm:ss"))).append("\n");
        sb.append("━━━━━━━━━━━━━━━━━━━━\n");
        sb.append("Despachado desde Centro de Operaciones.");
        return sb.toString();
    }
}
