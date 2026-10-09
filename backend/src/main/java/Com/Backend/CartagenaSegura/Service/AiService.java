package Com.Backend.CartagenaSegura.Service;

import Com.Backend.CartagenaSegura.Dto.AiDto;
import Com.Backend.CartagenaSegura.Model.Incident;
import Com.Backend.CartagenaSegura.Model.Zone;
import Com.Backend.CartagenaSegura.Repository.IncidentRepository;
import Com.Backend.CartagenaSegura.Repository.ZoneRepository;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import java.nio.charset.StandardCharsets;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class AiService {

    @Value("${groq.api.key}")
    private String apiKey;

    @Value("${groq.api.url}")
    private String apiUrl;

    private final IncidentRepository incidentRepository;
    private final ZoneRepository zoneRepository;
    private final ObjectMapper objectMapper;

    /**
     * MÉTODO CENTRAL (LLAMADA A GROQ)
     */
    private String callGroq(List<Map<String, String>> messages) {
        try {
            URL url = new URL(apiUrl);
            HttpURLConnection conn = (HttpURLConnection) url.openConnection();

            conn.setRequestMethod("POST");
            conn.setRequestProperty("Authorization", "Bearer " + apiKey);
            conn.setRequestProperty("Content-Type", "application/json");
            conn.setDoOutput(true);

            Map<String, Object> bodyMap = Map.of(
                    "model", "llama-3.1-8b-instant",
                    "messages", messages
            );

            String body = objectMapper.writeValueAsString(bodyMap);

            try (OutputStream os = conn.getOutputStream()) {
                os.write(body.getBytes(StandardCharsets.UTF_8));
                os.flush();
            }

            int status = conn.getResponseCode();

            BufferedReader br;
            if (status >= 400) {
                br = new BufferedReader(new InputStreamReader(conn.getErrorStream(), StandardCharsets.UTF_8));
            } else {
                br = new BufferedReader(new InputStreamReader(conn.getInputStream(), StandardCharsets.UTF_8));
            }

            StringBuilder response = new StringBuilder();
            String line;

            while ((line = br.readLine()) != null) {
                response.append(line);
            }

            String responseStr = response.toString();
            log.info("GROQ RESPONSE >>> {}", responseStr);

            if (status >= 400) {
                throw new RuntimeException("Error Groq: " + responseStr);
            }

            JsonNode json = objectMapper.readTree(responseStr);

            return json.get("choices")
                    .get(0)
                    .get("message")
                    .get("content")
                    .asText();

        } catch (Exception e) {
            log.error("ERROR REAL GROQ >>> {}", e.getMessage(), e);
            throw new RuntimeException(e); // IMPORTANTE
        }
    }

    /**
     * CHAT - Versión simple (usa prompt por defecto)
     */
    public AiDto.ChatResponse chat(String userMessage) {
        String defaultSystem = "Eres el asistente de 'Cartagena Segura'. Responde de forma clara y útil.";
        return chat(userMessage, defaultSystem);
    }

    /**
     * CHAT - Versión avanzada (permite personalizar el comportamiento del sistema)
     */
    public AiDto.ChatResponse chat(String userMessage, String systemMessage) {
        try {
            String respuesta = callGroq(List.of(
                    Map.of("role", "system", "content", systemMessage),
                    Map.of("role", "user", "content", userMessage)
            ));

            if (respuesta == null) throw new RuntimeException();
            return new AiDto.ChatResponse(respuesta);

        } catch (Exception e) {
            log.warn("Fallback chat: {}", e.getMessage());
            return new AiDto.ChatResponse(
                    "[SIMULACIÓN] El asistente está temporalmente fuera de servicio. Intenta nuevamente más tarde."
            );
        }
    }

    /**
     * CLASIFICACIÓN DE INCIDENTES
     */
    public AiDto.ClassifyResponse classify(String description) {

        String prompt = """
                Clasifica el siguiente incidente en formato JSON con:
                type (ROBO, ACCIDENTE, VANDALISMO, OTRO),
                priority (LOW, MEDIUM, HIGH),
                confidence (0 a 1).

                Incidente: %s
                """.formatted(description);

        try {
            String respuesta = callGroq(List.of(
                    Map.of("role", "user", "content", prompt)
            ));

            if (respuesta == null) throw new RuntimeException();

            respuesta = respuesta.replace("```json", "")
                    .replace("```", "")
                    .trim();

            return objectMapper.readValue(respuesta, AiDto.ClassifyResponse.class);

        } catch (Exception e) {
            log.warn("Fallback clasificación: {}", e.getMessage());

            if (description.toLowerCase().contains("choque") ||
                    description.toLowerCase().contains("carro")) {

                return new AiDto.ClassifyResponse("ACCIDENTE", "MEDIUM", 0.88);
            }

            return new AiDto.ClassifyResponse("ROBO", "HIGH", 0.92);
        }
    }

    /**
     * RESUMEN GENERAL
     */
    public AiDto.SummaryResponse generateSummary() {

        try {
            List<Incident> incidents = incidentRepository.findAll()
                    .stream()
                    .limit(20)
                    .toList();

            String data = incidents.stream()
                    .map(i -> i.getType() + ": " + i.getDescription())
                    .collect(Collectors.joining("\n"));

            String prompt = "Genera un resumen de seguridad basado en estos incidentes:\n" + data;

            String respuesta = callGroq(List.of(
                    Map.of("role", "user", "content", prompt)
            ));

            if (respuesta == null) throw new RuntimeException();

            return new AiDto.SummaryResponse(respuesta);

        } catch (Exception e) {
            return new AiDto.SummaryResponse(
                    "[SIMULACIÓN] Se observa estabilidad en los reportes recientes."
            );
        }
    }

    /**
     * ANÁLISIS DE ZONAS
     */
    public AiDto.ZoneAnalysis analyzeZones() {

        try {
            List<Zone> zones = zoneRepository.findAll();

            String data = zones.stream()
                    .map(Zone::getName)
                    .collect(Collectors.joining(", "));

            String prompt = """
                    Analiza estas zonas y devuelve JSON con:
                    name, riskLevel, recommendation.

                    Zonas: %s
                    """.formatted(data);

            String respuesta = callGroq(List.of(
                    Map.of("role", "user", "content", prompt)
            ));

            if (respuesta == null) throw new RuntimeException();

            respuesta = respuesta.replace("```json", "")
                    .replace("```", "")
                    .trim();

            return objectMapper.readValue(respuesta, AiDto.ZoneAnalysis.class);

        } catch (Exception e) {
            return new AiDto.ZoneAnalysis(List.of(
                    new AiDto.ZoneRecommendation("Centro", "HIGH", "Reforzar vigilancia")
            ));
        }
    }
}
