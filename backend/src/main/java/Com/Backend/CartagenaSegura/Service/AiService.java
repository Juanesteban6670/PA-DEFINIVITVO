package Com.Backend.CartagenaSegura.Service;

import Com.Backend.CartagenaSegura.Dto.AiDto;
import Com.Backend.CartagenaSegura.Model.EmergencyContact;
import Com.Backend.CartagenaSegura.Model.Incident;
import Com.Backend.CartagenaSegura.Model.Zone;
import Com.Backend.CartagenaSegura.Repository.EmergencyContactRepository;
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
import java.util.*;
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
    private final EmergencyContactRepository emergencyContactRepository;
    private final ObjectMapper objectMapper;

    /**
     * MÉTODO CENTRAL (LLAMADA A GROQ)
     */
    private String callGroq(List<Map<String, String>> messages) {
        if (apiKey == null || apiKey.trim().isEmpty() || apiKey.equalsIgnoreCase("dev-only-change-this-secret")) {
            throw new IllegalStateException("Groq API key no configurada; utilizando motor inteligente local.");
        }

        try {
            URL url = new URL(apiUrl);
            HttpURLConnection conn = (HttpURLConnection) url.openConnection();

            conn.setRequestMethod("POST");
            conn.setRequestProperty("Authorization", "Bearer " + apiKey);
            conn.setRequestProperty("Content-Type", "application/json");
            conn.setConnectTimeout(5000);
            conn.setReadTimeout(10000);
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
                throw new RuntimeException("Error Groq HTTP " + status + ": " + responseStr);
            }

            JsonNode json = objectMapper.readTree(responseStr);

            return json.get("choices")
                    .get(0)
                    .get("message")
                    .get("content")
                    .asText();

        } catch (Exception e) {
            log.warn("Llamada externa a Groq no disponible ({}). Activando motor local inteligente.", e.getMessage());
            throw new RuntimeException(e);
        }
    }

    /**
     * CHAT - Versión simple
     */
    public AiDto.ChatResponse chat(String userMessage) {
        String defaultSystem = "Eres el asistente oficial de 'Cartagena Segura'. Responde con empatía, precisión y datos reales.";
        return chat(userMessage, defaultSystem);
    }

    /**
     * CHAT - Versión con RAG híbrido y contingencia heurística inteligente
     */
    public AiDto.ChatResponse chat(String userMessage, String systemMessage) {
        try {
            String respuesta = callGroq(List.of(
                    Map.of("role", "system", "content", systemMessage),
                    Map.of("role", "user", "content", userMessage)
            ));

            if (respuesta != null && !respuesta.isBlank()) {
                return new AiDto.ChatResponse(respuesta);
            }
        } catch (Exception ignored) {
            // Se activa el motor contextual inteligente local
        }

        return new AiDto.ChatResponse(generateSmartLocalChat(userMessage, systemMessage));
    }

    /**
     * Generador inteligente de respuestas locales basado en datos reales de Cartagena
     */
    private String generateSmartLocalChat(String rawMessage, String systemContext) {
        String query = rawMessage;
        int idx = query.lastIndexOf("PREGUNTA DEL USUARIO:");
        if (idx >= 0) {
            query = query.substring(idx + "PREGUNTA DEL USUARIO:".length());
        }
        query = query.toLowerCase();

        // 1. Detección de zonas de Cartagena
        Map<String, String> zoneAliases = Map.ofEntries(
                Map.entry("centro", "Centro Histórico y San Diego"),
                Map.entry("historico", "Centro Histórico y San Diego"),
                Map.entry("histórico", "Centro Histórico y San Diego"),
                Map.entry("san diego", "Centro Histórico y San Diego"),
                Map.entry("amurallada", "Centro Histórico y San Diego"),
                Map.entry("getsemani", "Getsemaní"),
                Map.entry("getsemaní", "Getsemaní"),
                Map.entry("trinidad", "Getsemaní"),
                Map.entry("bocagrande", "Bocagrande y Castillogrande"),
                Map.entry("castillogrande", "Bocagrande y Castillogrande"),
                Map.entry("manga", "Manga"),
                Map.entry("popa", "Pie de la Popa y Cerro de la Popa"),
                Map.entry("pie de la popa", "Pie de la Popa y Cerro de la Popa"),
                Map.entry("bazurto", "Mercado de Bazurto y La Quinta"),
                Map.entry("olaya", "Olaya Herrera y Boston"),
                Map.entry("pozon", "El Pozón y Villa Estrella"),
                Map.entry("pozón", "El Pozón y Villa Estrella"),
                Map.entry("crespo", "Crespo y Marbella"),
                Map.entry("marbella", "Crespo y Marbella"),
                Map.entry("plazuela", "La Plazuela y San Fernando"),
                Map.entry("san fernando", "La Plazuela y San Fernando")
        );

        for (Map.Entry<String, String> entry : zoneAliases.entrySet()) {
            if (query.contains(entry.getKey())) {
                return buildZoneStatusResponse(entry.getValue());
            }
        }

        // 2. Preguntas sobre líneas o contactos de emergencia
        if (query.contains("emergencia") || query.contains("policia") || query.contains("bomberos") ||
                query.contains("cai") || query.contains("ambulancia") || query.contains("guardacostas") ||
                query.contains("telefono") || query.contains("numero") || query.contains("llamar") || query.contains("123")) {
            return """
                    🚨 **Líneas de Emergencia Oficiales de Cartagena:**

                    * 👮 **Policía Nacional / Emergencias Generales:** Marca al **123** (gratuito desde cualquier celular).
                    * 🚒 **Cuerpo de Bomberos (Estación Santa Lucía / Bocagrande):** **119** o al (605) 663-1282.
                    * 🚑 **Ambulancias CRUE Distrital:** **125** o al (605) 664-5612.
                    * ⚓ **Guardacostas Armada Nacional (Playas / Bahía):** **146**.
                    * 💜 **Línea Púrpura (Atención a la Mujer):** **155**.
                    * 🏛️ **CAI San Diego (Centro):** (605) 664-5555 | **CAI Bocagrande:** 310 242 7891.

                    Puedes consultar el directorio completo en la sección **"Emergencias"** de esta aplicación.
                    """;
        }

        // 3. Cómo hacer un reporte ciudadano
        if (query.contains("reportar") || query.contains("denunciar") || query.contains("crear reporte") ||
                query.contains("como hago") || query.contains("reporte")) {
            return """
                    📋 **¿Cómo crear un reporte ciudadano en Cartagena Segura?**

                    1. Dirígete a la pestaña **"Reportar"** en la barra inferior.
                    2. Selecciona la categoría del incidente (*Robo, Accidente, Pelea, Alumbrado, Obstáculo vial, etc.*).
                    3. Agrega una breve descripción de lo que está ocurriendo.
                    4. La app detectará automáticamente tu ubicación por GPS, o puedes tocar un punto en el mapa.
                    5. Opcionalmente adjunta una foto como evidencia y presiona **"Enviar reporte"**.

                    El incidente aparecerá de inmediato en el mapa comunitario y el cuadrante correspondiente será notificado.
                    """;
        }

        // 4. Preguntas sobre rutas seguras
        if (query.contains("ruta") || query.contains("waze") || query.contains("camino") || query.contains("como llegar") || query.contains("segura")) {
            return """
                    🗺️ **Navegación y Rutas Seguras:**

                    La función de Rutas Seguras calcula tu trayecto evaluando los índices de criminalidad e incidentes recientes reportados por la ciudadanía.

                    * Ve a la pestaña **Mapa**.
                    * Toca el botón flotante **"Trazar Ruta Segura"**.
                    * Elige un destino popular (*Centro Histórico, Bocagrande, Manga, Aeropuerto*) o marca un punto en el mapa.
                    * El sistema te mostrará 3 opciones de ruta clasificadas por color: **Segura (Verde)**, **Moderada (Naranja)** o **Riesgosa (Roja)**, esquivando automáticamente zonas de alto peligro.
                    """;
        }

        // 5. Estadísticas o estado general de la ciudad
        if (query.contains("estadistica") || query.contains("resumen") || query.contains("ciudad") || query.contains("cuantos incidentes") || query.contains("estado")) {
            long total = incidentRepository.count();
            List<Zone> zones = zoneRepository.findAll();
            return String.format("""
                    📊 **Estado General de Cartagena en Tiempo Real:**

                    * **Total de incidentes registrados:** %d reportes en plataforma.
                    * **Zonas monitoreadas activamente:** %d sectores de Cartagena.
                    * **Sectores con mayor índice de seguridad:** Bocagrande, Manga y Crespo.
                    * **Sectores con vigilancia reforzada:** Mercado de Bazurto y Olaya Herrera.

                    Recuerda que cada reporte que haces contribuye a mantener las rutas seguras actualizadas para toda la comunidad.
                    """, total, zones.size());
        }

        // 6. Saludo
        if (query.contains("hola") || query.contains("buenos") || query.contains("buenas") || query.contains("ayuda") || query.contains("quien eres")) {
            return """
                    ¡Hola! Soy **Cartagena Segura AI**, tu asistente oficial de seguridad y convivencia ciudadana.

                    Estoy conectado en tiempo real con la base de datos distrital. Puedo ayudarte con:
                    * 🛡️ Consultar el nivel de seguridad de cualquier barrio o zona de Cartagena.
                    * 🚨 Directorio de teléfonos de emergencia (Policía, Bomberos, CRUE, Guardacostas).
                    * 🗺️ Cómo trazar Rutas Seguras esquivando zonas peligrosas.
                    * ✍️ Orientación para radicar reportes ciudadanos.

                    ¿Sobre qué sector o tema te gustaría consultar?
                    """;
        }

        // Respuesta estándar empática
        return """
                Entiendo tu consulta. Como asistente de **Cartagena Segura**, te recomiendo siempre transitar por avenidas principales iluminadas y revisar el **Mapa en Vivo** antes de desplazarte.

                Si tienes una urgencia de seguridad en este momento, comunícate de inmediato con la **Línea 123** de la Policía Nacional. ¿Deseas consultar la situación de algún barrio en específico (*Centro, Getsemaní, Bocagrande, Manga, Bazurto, etc.*)?
                """;
    }

    private String buildZoneStatusResponse(String zoneName) {
        Zone zone = zoneRepository.findAll().stream()
                .filter(z -> z.getName().equalsIgnoreCase(zoneName))
                .findFirst()
                .orElse(null);

        if (zone == null) {
            return "La zona de **" + zoneName + "** se encuentra monitoreada. Te sugerimos precaución y consultar las rutas seguras en el mapa.";
        }

        List<Incident> zoneIncidents = incidentRepository.findAll().stream()
                .filter(i -> zone.getId() != null && zone.getId().equals(i.getZoneId()))
                .toList();

        long pending = zoneIncidents.stream().filter(i -> i.getStatus() == Incident.Status.PENDING).count();
        long resolved = zoneIncidents.stream().filter(i -> i.getStatus() == Incident.Status.RESOLVED).count();

        String advice = switch (zone.getRiskLevel()) {
            case LOW -> "Es un sector con **bajo índice de riesgo**. Ideal para desplazamientos diurnos y paseos turísticos, manteniendo las precauciones habituales.";
            case MODERATE -> "Es un sector con **nivel de riesgo moderado**. Recomendamos estar atento a pertenencias personales en horarios nocturnos y aglomeraciones.";
            case HIGH -> "Es un sector con **nivel de riesgo alto**. Se aconseja no portar objetos de alto valor visibles y desplazarse preferiblemente por vías principales acompañadas.";
            case CRITICAL -> "Es un sector clasificado como **riesgo crítico**. El sistema aconseja evitar rutas peatonales nocturnas por calles secundarias y transitar en vehículo.";
        };

        return String.format("""
                📍 **Reporte de Seguridad: %s**

                * **Nivel de Riesgo Distrital:** **%s**
                * **Descripción:** %s
                * **Incidentes registrados en el sector:** %d (%d pendientes de atención, %d resueltos).
                * **Recomendación preventiva:** %s

                Si observas alguna situación irregular en este sector, puedes reportarla al instante desde la pestaña **Reportar**.
                """, zone.getName(), zone.getRiskLevel(), zone.getDescription(), zoneIncidents.size(), pending, resolved, advice);
    }

    /**
     * CLASIFICACIÓN DE INCIDENTES (Híbrida)
     */
    public AiDto.ClassifyResponse classify(String description) {
        String prompt = """
                Clasifica el siguiente incidente en formato JSON con:
                type (ROBO, ACCIDENTE, PELEA, VANDALISMO, EMERGENCIA, LUMINARIA_DANADA, OBSTACULO_VIAL, OTRO),
                priority (LOW, MEDIUM, HIGH, CRITICAL),
                confidence (0 a 1).

                Incidente: %s
                """.formatted(description);

        try {
            String respuesta = callGroq(List.of(
                    Map.of("role", "user", "content", prompt)
            ));

            if (respuesta != null && !respuesta.isBlank()) {
                respuesta = respuesta.replace("```json", "")
                        .replace("```", "")
                        .trim();
                return objectMapper.readValue(respuesta, AiDto.ClassifyResponse.class);
            }
        } catch (Exception ignored) {
            // Falla externa -> Clasificación heurística inteligente
        }

        return classifyLocally(description);
    }

    private AiDto.ClassifyResponse classifyLocally(String desc) {
        if (desc == null) desc = "";
        String text = desc.toLowerCase();

        if (text.contains("arma") || text.contains("pistola") || text.contains("fleteo") || text.contains("atraco")) {
            return new AiDto.ClassifyResponse("ROBO", "CRITICAL", 0.95);
        }
        if (text.contains("robo") || text.contains("hurto") || text.contains("celular") || text.contains("bolso") || text.contains("cosquilleo")) {
            return new AiDto.ClassifyResponse("ROBO", "HIGH", 0.92);
        }
        if (text.contains("incendio") || text.contains("fuego") || text.contains("inundacion") || text.contains("arroyo") || text.contains("derrumbe")) {
            return new AiDto.ClassifyResponse("EMERGENCIA", "CRITICAL", 0.98);
        }
        if (text.contains("choque") || text.contains("accidente") || text.contains("atropell") || text.contains("colision") || text.contains("carro") || text.contains("moto")) {
            String prio = (text.contains("herido") || text.contains("grave")) ? "HIGH" : "MEDIUM";
            return new AiDto.ClassifyResponse("ACCIDENTE", prio, 0.90);
        }
        if (text.contains("pelea") || text.contains("rina") || text.contains("golpe") || text.contains("discusion")) {
            return new AiDto.ClassifyResponse("PELEA", "HIGH", 0.88);
        }
        if (text.contains("sospechoso") || text.contains("merodeando") || text.contains("sin placa") || text.contains("vigilando")) {
            return new AiDto.ClassifyResponse("ACTIVIDAD_SOSPECHOSA", "MEDIUM", 0.86);
        }
        if (text.contains("luz") || text.contains("poste") || text.contains("luminaria") || text.contains("oscuridad")) {
            return new AiDto.ClassifyResponse("LUMINARIA_DANADA", "LOW", 0.94);
        }
        if (text.contains("hueco") || text.contains("arbol") || text.contains("obstaculo") || text.contains("bloqueo") || text.contains("alcantarilla")) {
            return new AiDto.ClassifyResponse("OBSTACULO_VIAL", "MEDIUM", 0.89);
        }

        return new AiDto.ClassifyResponse("OTRO", "MEDIUM", 0.75);
    }

    /**
     * RESUMEN GENERAL (Híbrido)
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

            String prompt = "Genera un resumen ejecutivo de seguridad en Cartagena basado en estos incidentes:\n" + data;

            String respuesta = callGroq(List.of(
                    Map.of("role", "user", "content", prompt)
            ));

            if (respuesta != null && !respuesta.isBlank()) {
                return new AiDto.SummaryResponse(respuesta);
            }
        } catch (Exception ignored) {
            // Motor local
        }

        return generateLocalSummary();
    }

    private AiDto.SummaryResponse generateLocalSummary() {
        List<Incident> all = incidentRepository.findAll();
        long total = all.size();
        long resolved = all.stream().filter(i -> i.getStatus() == Incident.Status.RESOLVED).count();
        long pending = all.stream().filter(i -> i.getStatus() == Incident.Status.PENDING).count();
        long critical = all.stream().filter(i -> i.getPriority() == Incident.Priority.CRITICAL).count();

        double resolutionRate = total > 0 ? (resolved * 100.0 / total) : 0.0;

        String summary = String.format(
                "INFORME EJECUTIVO DE SEGURIDAD CIUDADANA - CARTAGENA:\n\n" +
                "• Monitoreo activo de %d incidentes en plataforma distrital.\n" +
                "• Tasa de resolución operativa: %.1f%% (%d casos resueltos, %d en investigación/proceso).\n" +
                "• Incidentes de prioridad crítica: %d eventos bajo atención prioritaria de cuadrantes.\n" +
                "• Sectores turísticos (Centro Histórico y Bocagrande) reportan estabilidad con patrullajes de turismo.\n" +
                "• Recomendación operativa: Reforzar presencia preventiva en corredor Bazurto y Olaya Herrera.",
                total, resolutionRate, resolved, pending, critical
        );

        return new AiDto.SummaryResponse(summary);
    }

    /**
     * ANÁLISIS DE ZONAS (Híbrido)
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

            if (respuesta != null && !respuesta.isBlank()) {
                respuesta = respuesta.replace("```json", "")
                        .replace("```", "")
                        .trim();
                return objectMapper.readValue(respuesta, AiDto.ZoneAnalysis.class);
            }
        } catch (Exception ignored) {
            // Motor local
        }

        return analyzeZonesLocally();
    }

    private AiDto.ZoneAnalysis analyzeZonesLocally() {
        List<Zone> zones = zoneRepository.findAll();
        List<AiDto.ZoneRecommendation> list = new ArrayList<>();

        for (Zone zone : zones) {
            String reco = switch (zone.getRiskLevel()) {
                case CRITICAL -> "Implementar cuadrante de reacción rápida y patrullaje motorizado permanente.";
                case HIGH -> "Instalar cámaras domo 360 conectadas al CAD y mejorar alumbrado público.";
                case MODERATE -> "Incrementar rondas de vigilancia preventiva en horarios pico y nocturnos.";
                case LOW -> "Mantener operativos de proximidad y frentes de seguridad comunitaria.";
            };
            list.add(new AiDto.ZoneRecommendation(zone.getName(), zone.getRiskLevel().name(), reco));
        }

        if (list.isEmpty()) {
            list.add(new AiDto.ZoneRecommendation("Centro Histórico", "MODERATE", "Mantener rondas de policía de turismo."));
        }

        return new AiDto.ZoneAnalysis(list);
    }
}
