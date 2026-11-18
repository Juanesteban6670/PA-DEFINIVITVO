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
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
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
    private final ChatSessionManager sessionManager;

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
        return chatWithContext(userMessage, systemMessage, "default-session", null, "Ciudadano", false);
    }

    /**
     * CHAT - Versión completa con memoria conversacional multi-turno y triaje de emergencias
     */
    public AiDto.ChatResponse chatWithContext(String userMessage, String systemMessage, String sessionId, List<AiDto.MessageHistory> clientHistory, String userName, boolean isAdmin) {
        ChatSessionManager.SessionState state = sessionManager.getOrCreate(sessionId);

        // Sincronizar historial cliente si existe
        if (clientHistory != null && !clientHistory.isEmpty()) {
            for (AiDto.MessageHistory h : clientHistory) {
                if (h.getContent() != null && !h.getContent().isBlank()) {
                    state.addMessage(h.getRole(), h.getContent());
                }
            }
        }

        try {
            List<Map<String, String>> messages = new ArrayList<>();
            messages.add(Map.of("role", "system", "content", systemMessage));
            for (AiDto.MessageHistory h : state.getHistory()) {
                messages.add(Map.of("role", h.getRole(), "content", h.getContent()));
            }
            messages.add(Map.of("role", "user", "content", userMessage));

            String respuesta = callGroq(messages);
            if (respuesta != null && !respuesta.isBlank()) {
                sessionManager.recordTurn(sessionId, userMessage, respuesta, null, null, null);
                return new AiDto.ChatResponse(respuesta);
            }
        } catch (Exception ignored) {
            // Se activa el motor contextual inteligente local especializado en Cartagena
        }

        return generateSmartLocalChat(userMessage, systemMessage, state, userName, isAdmin);
    }

    public String generateSmartLocalChat(String rawMessage, String systemContext) {
        AiDto.ChatResponse res = generateSmartLocalChat(rawMessage, systemContext, sessionManager.getOrCreate("legacy"), "Ciudadano", false);
        return res.getReply();
    }

    /**
     * Generador inteligente de respuestas locales basado en datos reales de Cartagena,
     * protocolos oficiales de emergencia (CRUE, DATT, Policía) y memoria de contexto.
     */
    public AiDto.ChatResponse generateSmartLocalChat(String rawMessage, String systemContext, ChatSessionManager.SessionState sessionState, String userName, boolean isAdmin) {
        String query = rawMessage != null ? rawMessage : "";
        int idx = query.lastIndexOf("PREGUNTA DEL USUARIO:");
        if (idx >= 0) {
            query = query.substring(idx + "PREGUNTA DEL USUARIO:".length());
        }
        query = query.toLowerCase().trim();

        String sessId = sessionState != null ? sessionState.getSessionId() : "default";

        // =========================================================================
        // 1. DETECCIÓN DE PREGUNTAS DE SEGUIMIENTO (Context-Aware Follow-up)
        // =========================================================================
        boolean isFollowUp = query.contains("que debo hacer") || query.contains("qué debo hacer") ||
                query.contains("que hago") || query.contains("qué hago") ||
                query.contains("como procedo") || query.contains("cómo procedo") ||
                query.contains("a quien llamo") || query.contains("a quién llamo") ||
                query.contains("a donde voy") || query.contains("a dónde voy") ||
                query.contains("que sigue") || query.contains("qué sigue") ||
                query.contains("y ahora") || query.contains("pasos") ||
                query.contains("instrucciones") || query.contains("que me recomiendas") ||
                (query.contains("ayuda") && query.length() < 12);

        if (isFollowUp && sessionState != null && sessionState.getActiveTopic() != null) {
            String topic = sessionState.getActiveTopic();

            if ("TRAFFIC_ACCIDENT".equals(topic)) {
                String sub = sessionState.getSubtopic() != null ? sessionState.getSubtopic() : "vehículo";
                String reply = String.format("""
                        📋 **Protocolo de Acción Paso a Paso para tu Accidente (%s):**

                        Como acabas de tener un accidente en Cartagena, esta es la secuencia exacta que debes seguir ahora mismo:

                        1. 🛡️ **Verifica tu estado y el de los demás:** Si sientes dolor de cuello o columna, siéntate en un lugar seguro y **no te retires el casco bruscamente**. Si hay heridos que no pueden moverse, no intentes levantarlos a menos que haya riesgo inminente de fuego.
                        2. 🚑 **Solicita ambulancia al CRUE (Línea 125):** Informa si hay personas sangrando o inconscientes. La atención médica de urgencias en clínicas de Cartagena está cubierta al 100%% por el **SOAT** de los vehículos involucrados, sin costo inicial para ti.
                        3. 🚔 **Notifica a Tránsito de Cartagena (DATT):** Marca al **127** o al **123** para que acudan agentes a levantar el croquis oficial. No aceptes acuerdos informales o intimidaciones en caliente sin respaldo pericial.
                        4. 📸 **Documenta la escena:** Antes de que muevan la moto o los carros, toma fotos panorámicas de las placas, la posición en la calzada y las señales viales.
                        5. ✍️ **Alerta comunitaria:** Puedes radicar el incidente en esta app para prevenir a otros conductores sobre el trancón y activar la vigilancia comunitaria.

                        ¿Hay personas heridas en el lugar en este momento? ¿En qué avenida o sector de Cartagena ocurrió?
                        """, sub);

                List<AiDto.ActionPrompt> actions = List.of(
                        new AiDto.ActionPrompt("CALL", "Llamar al CRUE 125 (Ambulancia)", "125"),
                        new AiDto.ActionPrompt("CALL", "Llamar a Tránsito DATT 127", "127"),
                        new AiDto.ActionPrompt("CALL", "Llamar a Policía 123", "123"),
                        new AiDto.ActionPrompt("REPORT", "Radicar Reporte Vial", "ACCIDENTE")
                );
                sessionManager.recordTurn(sessId, rawMessage, reply, "TRAFFIC_ACCIDENT", sub, sessionState.getLastMentionedZone());
                return new AiDto.ChatResponse(reply, actions, "TRAFFIC_ACCIDENT");
            }

            if ("THEFT_ROBBERY".equals(topic)) {
                String reply = """
                        📋 **Protocolo de Reacción Inmediata ante Hurto / Robo:**

                        1. 🛡️ **Ponte a salvo de inmediato:** No persigas al sospechoso. Entra a un establecimiento comercial, CAI o lugar concurrido e iluminado.
                        2. 👮 **Comunícate con la Línea 123:** Indica la dirección exacta o punto de referencia en Cartagena y describe a los sospechosos (vestimenta, placas, moto o a pie) para activar el **Plan Candado** en el cuadrante.
                        3. 📱 **Bloqueo preventivo de emergencia:**
                           * Si te hurtaron el celular, llama desde otro teléfono a tu operador móvil para suspender la SIM y reportar el código **IMEI**.
                           * Ingresa a tu banco virtual desde un dispositivo seguro y bloquea tus tarjetas de crédito y débito.
                        4. ✍️ **Denuncia legal:** Puedes radicar la denuncia virtual en el portal *A Denunciar* de la Policía/Fiscalía o en la URI de Crespo o Canapote.

                        ¿El hecho acaba de ocurrir? ¿Recuerdas en qué calle o barrio exacto fue?
                        """;
                List<AiDto.ActionPrompt> actions = List.of(
                        new AiDto.ActionPrompt("CALL", "Llamar a Policía 123", "123"),
                        new AiDto.ActionPrompt("REPORT", "Radicar Reporte de Hurto", "ROBO")
                );
                sessionManager.recordTurn(sessId, rawMessage, reply, "THEFT_ROBBERY", sessionState.getSubtopic(), sessionState.getLastMentionedZone());
                return new AiDto.ChatResponse(reply, actions, "THEFT_ROBBERY");
            }

            if ("MEDICAL_EMERGENCY".equals(topic)) {
                String reply = """
                        📋 **Protocolo de Auxilio y Emergencia Médica:**

                        1. 🚑 **Llama de inmediato al 125 (CRUE Distrital):** Da la dirección exacta e indica si la persona respira, está consciente o sangra.
                        2. 🧘 **Primeros auxilios:** No muevas bruscamente a la persona ni le suministres bebidas, comidas o medicamentos a personas inconscientes.
                        3. 🏥 **Centros de urgencias principales en Cartagena:**
                           * Hospital Universitario del Caribe (Zaragocilla) - (605) 672-4340
                           * Clínica Cartagena del Mar (El Cabrero) - (605) 664-8888
                           * Clínica Madre Bernarda (La Plazuela) - (605) 661-8000
                           * Hospital Infantil Napoleón Franco Pareja (Casa del Niño)

                        ¿La persona lesionada está consciente y puede responderte?
                        """;
                List<AiDto.ActionPrompt> actions = List.of(
                        new AiDto.ActionPrompt("CALL", "Llamar al CRUE 125 (Ambulancia)", "125"),
                        new AiDto.ActionPrompt("CALL", "Llamar a Emergencias 123", "123")
                );
                sessionManager.recordTurn(sessId, rawMessage, reply, "MEDICAL_EMERGENCY", sessionState.getSubtopic(), sessionState.getLastMentionedZone());
                return new AiDto.ChatResponse(reply, actions, "MEDICAL_EMERGENCY");
            }
        }

        // =========================================================================
        // 2. DETECCIÓN DE ACCIDENTE DE TRÁNSITO / VIAL
        // =========================================================================
        if (query.contains("accidente") || query.contains("moto") || query.contains("carro") ||
                query.contains("choque") || query.contains("estrell") || query.contains("me cai") ||
                query.contains("me caí") || query.contains("atropell") || query.contains("volcadura") ||
                query.contains("volco") || query.contains("volcó") || query.contains("colision") ||
                query.contains("colisión") || query.contains("datt") || query.contains("soat")) {

            String subtopic = query.contains("moto") ? "moto" : (query.contains("carro") ? "carro" : "tránsito");
            String reply = """
                    🚨 **Atención Inmediata por Accidente de Tránsito en Cartagena:**

                    Lamento mucho escuchar eso. Lo más importante en este momento es tu integridad física y la de quienes te acompañan. Mantén la calma y sigue estos pasos de inmediato:

                    1. 🛡️ **Ponte a salvo de la vía:** Si puedes levantarte o caminar, aléjate del tráfico hacia la acera. Si tú o alguien presenta dolor intenso en la espalda/cuello, **no se muevan** para no agravar posibles lesiones.
                    2. 🚑 **Solicitar auxilio médico al 125 (CRUE):** Si hay lesionados, marca de inmediato a las ambulancias distritales de Cartagena al **125** o al **(605) 664-5612**. Toda urgencia por accidente vial está respaldada al 100% por el **SOAT**.
                    3. 🚔 **Notificar al DATT (Tránsito):** Comunícate al **127** o a la línea **123** para que una patrulla del DATT acuda a levantar el croquis oficial del accidente.
                    4. 📸 **Tomar evidencia:** Toma fotografías de los vehículos, placas y la vía antes de moverlos.

                    ¿Hay personas heridas o sangrando en este momento? ¿En qué calle o sector de Cartagena ocurrió el accidente?
                    """;

            List<AiDto.ActionPrompt> actions = List.of(
                    new AiDto.ActionPrompt("CALL", "Llamar al CRUE 125 (Ambulancia)", "125"),
                    new AiDto.ActionPrompt("CALL", "Llamar a Tránsito DATT 127", "127"),
                    new AiDto.ActionPrompt("CALL", "Llamar a Emergencias 123", "123"),
                    new AiDto.ActionPrompt("REPORT", "Radicar Reporte de Accidente", "ACCIDENTE")
            );
            sessionManager.recordTurn(sessId, rawMessage, reply, "TRAFFIC_ACCIDENT", subtopic, null);
            return new AiDto.ChatResponse(reply, actions, "TRAFFIC_ACCIDENT");
        }

        // =========================================================================
        // 3. DETECCIÓN DE HURTO / ROBO / ATRACO
        // =========================================================================
        if (query.contains("robo") || query.contains("robaron") || query.contains("atraco") ||
                query.contains("atracaron") || query.contains("asalto") || query.contains("ladron") ||
                query.contains("ladrones") || query.contains("hurto") || query.contains("cosquilleo") ||
                query.contains("raponeo") || query.contains("escopolamina") || query.contains("me quitaron") ||
                query.contains("fleteo") || query.contains("pistola") || query.contains("arma")) {

            String reply = """
                    🚨 **Alerta por Hurto / Atraco en Cartagena:**

                    1. 🛡️ **Prioriza tu seguridad:** No intentes perseguir a los delincuentes. Resguárdate de inmediato en un local comercial, hotel o lugar vigilado e iluminado.
                    2. 👮 **Llama de inmediato a la Línea 123:** Indica tu ubicación actual y la dirección de escape o características de los asaltantes para que el cuadrante policial active el plan candado en la zona.
                    3. 📱 **Bloqueos preventivos inmediatos:**
                       * Si te hurtaron el celular, llama a tu operador móvil para suspender la línea y bloquear el código **IMEI**.
                       * Ingresa a tu banca en línea desde un dispositivo seguro y bloquea tus tarjetas de débito/crédito.
                    4. ✍️ **Denuncia legal:** Puedes instaurar la denuncia virtual en el portal *A Denunciar* de la Policía/Fiscalía o en la URI (Crespo / Canapote).

                    ¿El hecho acaba de ocurrir? ¿En qué barrio o punto de referencia te encuentras?
                    """;

            List<AiDto.ActionPrompt> actions = List.of(
                    new AiDto.ActionPrompt("CALL", "Llamar a Policía 123", "123"),
                    new AiDto.ActionPrompt("REPORT", "Radicar Reporte de Hurto", "ROBO")
            );
            sessionManager.recordTurn(sessId, rawMessage, reply, "THEFT_ROBBERY", "hurto", null);
            return new AiDto.ChatResponse(reply, actions, "THEFT_ROBBERY");
        }

        // =========================================================================
        // 4. DETECCIÓN DE EMERGENCIA MÉDICA / SALUD
        // =========================================================================
        if (query.contains("ambulancia") || query.contains("herido") || query.contains("desmayo") ||
                query.contains("infarto") || query.contains("sangre") || query.contains("grave") ||
                query.contains("no respira") || query.contains("inconsciente") || query.contains("medico") ||
                query.contains("médico") || query.contains("hospital") || query.contains("clinica") ||
                query.contains("clínica")) {

            String reply = """
                    🚨 **Emergencia Médica y Auxilio Distrital:**

                    1. 🚑 **Llama de inmediato al CRUE (125):** Es el Centro Regulador de Urgencias y Emergencias de Cartagena (teléfono fijo: **(605) 664-5612**).
                    2. 🧘 **Primeros auxilios básicos:**
                       * Mantén la calma y despeja el área alrededor de la persona.
                       * Si está inconsciente pero respira, colócala en posición lateral de seguridad.
                       * No le des líquidos ni alimentos.
                    3. 🏥 **Urgencias hospitalarias principales:** Hospital Universitario del Caribe (Zaragocilla), Clínica Cartagena del Mar (El Cabrero) y Clínica Madre Bernarda (La Plazuela).

                    ¿Dónde te encuentras ubicado para orientarte sobre el centro médico más cercano?
                    """;

            List<AiDto.ActionPrompt> actions = List.of(
                    new AiDto.ActionPrompt("CALL", "Llamar al CRUE 125 (Ambulancia)", "125"),
                    new AiDto.ActionPrompt("CALL", "Llamar a Emergencias 123", "123")
            );
            sessionManager.recordTurn(sessId, rawMessage, reply, "MEDICAL_EMERGENCY", "salud", null);
            return new AiDto.ChatResponse(reply, actions, "MEDICAL_EMERGENCY");
        }

        // =========================================================================
        // 5. DETECCIÓN DE VIOLENCIA DE GÉNERO / INTRAFAMILIAR
        // =========================================================================
        if (query.contains("violencia") || query.contains("me pego") || query.contains("me pegó") ||
                query.contains("mi pareja") || query.contains("me amenaza") || query.contains("maltrato") ||
                query.contains("golpe") || query.contains("abuso") || query.contains("linea purpura") ||
                query.contains("línea púrpura")) {

            String reply = """
                    💜 **Atención y Acompañamiento a Víctimas de Violencia:**

                    No estás sola(o). Tienes a tu disposición canales oficiales y gratuitos de atención y protección inmediata:

                    * 💜 **Línea Púrpura Nacional:** Marca al **155** (gratuito, 24 horas, atención confidencial con abogadas y psicólogas).
                    * 🚨 **Línea 123:** Para auxilio urgente y solicitud de la **Patrulla Púrpura** de la Policía Metropolitana de Cartagena.
                    * 🏛️ **Comisaría de Familia de Cartagena:** Para solicitar medidas de protección inmediata y desalojo del agresor.
                    * 🏢 **Fiscalía General (URI Canapote / Crespo):** Para radicar denuncia penal por violencia intrafamiliar o lesiones.

                    ¿Te encuentras en un lugar seguro en este momento? ¿Requieres que acuda una patrulla policial?
                    """;

            List<AiDto.ActionPrompt> actions = List.of(
                    new AiDto.ActionPrompt("CALL", "Llamar Línea Púrpura 155", "155"),
                    new AiDto.ActionPrompt("CALL", "Llamar a Policía 123", "123")
            );
            sessionManager.recordTurn(sessId, rawMessage, reply, "DOMESTIC_VIOLENCE", "violencia", null);
            return new AiDto.ChatResponse(reply, actions, "DOMESTIC_VIOLENCE");
        }

        // =========================================================================
        // 6. DETECCIÓN DE ZONAS Y BARRIOS DE CARTAGENA
        // =========================================================================
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
                String reply = buildZoneStatusResponse(entry.getValue());
                List<AiDto.ActionPrompt> actions = List.of(
                        new AiDto.ActionPrompt("NAVIGATE", "Ver Zona en Mapa", "/App/Map"),
                        new AiDto.ActionPrompt("REPORT", "Reportar Novedad", "GENERAL")
                );
                sessionManager.recordTurn(sessId, rawMessage, reply, "ZONE_QUERY", entry.getKey(), entry.getValue());
                return new AiDto.ChatResponse(reply, actions, "ZONE_QUERY");
            }
        }

        // =========================================================================
        // 7. LÍNEAS DE EMERGENCIA Y CONTACTO
        // =========================================================================
        if (query.contains("emergencia") || query.contains("policia") || query.contains("bomberos") ||
                query.contains("cai") || query.contains("guardacostas") || query.contains("telefono") ||
                query.contains("numero") || query.contains("llamar") || query.contains("123")) {
            String reply = """
                    🚨 **Líneas de Emergencia Oficiales de Cartagena:**

                    * 👮 **Policía Nacional / Emergencias Generales:** Marca al **123** (gratuito desde cualquier celular).
                    * 🚒 **Cuerpo de Bomberos (Estación Santa Lucía / Bocagrande):** **119** o al (605) 663-1282.
                    * 🚑 **Ambulancias CRUE Distrital:** **125** o al (605) 664-5612.
                    * ⚓ **Guardacostas Armada Nacional (Playas / Bahía):** **146**.
                    * 💜 **Línea Púrpura (Atención a la Mujer):** **155**.
                    * 🏛️ **CAI San Diego (Centro):** (605) 664-5555 | **CAI Bocagrande:** 310 242 7891.

                    Puedes consultar el directorio completo en la sección **"Emergencias"** de esta aplicación.
                    """;
            List<AiDto.ActionPrompt> actions = List.of(
                    new AiDto.ActionPrompt("CALL", "Llamar a Policía 123", "123"),
                    new AiDto.ActionPrompt("CALL", "Llamar a Bomberos 119", "119"),
                    new AiDto.ActionPrompt("CALL", "Llamar a CRUE 125", "125")
            );
            sessionManager.recordTurn(sessId, rawMessage, reply, "EMERGENCY_CONTACTS", null, null);
            return new AiDto.ChatResponse(reply, actions, "EMERGENCY_CONTACTS");
        }

        // =========================================================================
        // 8. CÓMO HACER UN REPORTE CIUDADANO
        // =========================================================================
        if (query.contains("reportar") || query.contains("denunciar") || query.contains("crear reporte") ||
                query.contains("como hago") || query.contains("reporte")) {
            String reply = """
                    📋 **¿Cómo crear un reporte ciudadano en Cartagena Segura?**

                    1. Dirígete a la pestaña **"Reportar"** en la barra de navegación.
                    2. Selecciona la categoría del incidente (*Robo, Accidente, Pelea, Alumbrado, Obstáculo vial, etc.*).
                    3. Agrega una breve descripción de lo que está ocurriendo.
                    4. La app detectará automáticamente tu ubicación por GPS, o puedes tocar un punto en el mapa.
                    5. Opcionalmente adjunta una foto como evidencia y presiona **"Enviar reporte"**.

                    El incidente aparecerá de inmediato en el mapa comunitario y los cuadrantes policiales serán notificados.
                    """;
            List<AiDto.ActionPrompt> actions = List.of(
                    new AiDto.ActionPrompt("REPORT", "Crear Reporte Ahora", "GENERAL")
            );
            sessionManager.recordTurn(sessId, rawMessage, reply, "REPORT_INSTRUCTIONS", null, null);
            return new AiDto.ChatResponse(reply, actions, "REPORT_INSTRUCTIONS");
        }

        // =========================================================================
        // 9. RUTAS SEGURAS Y NAVEGACIÓN GPS
        // =========================================================================
        if (query.contains("ruta") || query.contains("waze") || query.contains("camino") ||
                query.contains("como llegar") || query.contains("navegacion") || query.contains("navegación")) {
            String reply = """
                    🗺️ **Navegación y Rutas Seguras con Guía por Voz:**

                    La función de Rutas Seguras calcula tu trayecto evaluando los índices de criminalidad e incidentes reportados en tiempo real:

                    * Ve a la pestaña **Mapa**.
                    * Toca el botón **"Trazar Ruta Segura"**.
                    * Elige tu destino (*Centro Histórico, Bocagrande, Manga, Aeropuerto*) o selecciona un punto en el mapa.
                    * El sistema te mostrará 3 opciones de ruta clasificadas por color: **Segura (Verde)**, **Moderada (Naranja)** o **Riesgosa (Roja)**.
                    * Inicia la navegación GPS con instrucciones de voz en español y recálculo automático si te desvías.
                    """;
            List<AiDto.ActionPrompt> actions = List.of(
                    new AiDto.ActionPrompt("NAVIGATE", "Abrir Mapa de Rutas", "/App/Map")
            );
            sessionManager.recordTurn(sessId, rawMessage, reply, "SAFE_ROUTES", null, null);
            return new AiDto.ChatResponse(reply, actions, "SAFE_ROUTES");
        }

        // =========================================================================
        // 10. ESTADÍSTICAS O ESTADO DE CARTAGENA
        // =========================================================================
        if (query.contains("estadistica") || query.contains("resumen") || query.contains("ciudad") ||
                query.contains("cuantos incidentes") || query.contains("estado")) {
            long total = incidentRepository.count();
            List<Zone> zones = zoneRepository.findAll();
            String reply = String.format("""
                    📊 **Estado General de Cartagena en Tiempo Real:**

                    * **Total de incidentes registrados:** %d reportes en plataforma.
                    * **Zonas monitoreadas activamente:** %d sectores de Cartagena.
                    * **Sectores con mayor índice de seguridad:** Bocagrande, Manga y Crespo.
                    * **Sectores con vigilancia reforzada:** Mercado de Bazurto y Olaya Herrera.

                    Recuerda que cada reporte que haces contribuye a mantener las rutas seguras actualizadas para toda la comunidad.
                    """, total, zones.size());
            List<AiDto.ActionPrompt> actions = List.of(
                    new AiDto.ActionPrompt("NAVIGATE", "Ver Mapa de Incidentes", "/App/Map")
            );
            sessionManager.recordTurn(sessId, rawMessage, reply, "STATISTICS", null, null);
            return new AiDto.ChatResponse(reply, actions, "STATISTICS");
        }

        // =========================================================================
        // 11. SALUDO O BIENVENIDA
        // =========================================================================
        if (query.contains("hola") || query.contains("buenos") || query.contains("buenas") || query.contains("quien eres")) {
            String nameGreeting = (userName != null && !userName.equalsIgnoreCase("Ciudadano")) ? " " + userName : "";
            String reply = String.format("""
                    ¡Hola%s! Soy **Cartagena Segura AI**, tu asistente oficial de seguridad y convivencia ciudadana.

                    Estoy conectado en tiempo real con la base de datos distrital de Cartagena. Puedo orientarte sobre:
                    * 🚨 **Emergencias en curso:** Accidentes de moto/carro, hurtos o auxilio médico inmediato.
                    * 🛡️ **Seguridad por barrios:** Estado en Centro Histórico, Getsemaní, Bocagrande, Manga, Bazurto, etc.
                    * 🗺️ **Rutas Seguras:** Cómo desplazarte esquivando sectores peligrosos.
                    * ✍️ **Reportes:** Cómo radicar novedades en el mapa distrital.

                    ¿Sobre qué situación o sector te gustaría consultar?
                    """, nameGreeting);
            List<AiDto.ActionPrompt> actions = List.of(
                    new AiDto.ActionPrompt("CALL", "Llamar al 123", "123"),
                    new AiDto.ActionPrompt("NAVIGATE", "Ver Mapa en Vivo", "/App/Map")
            );
            sessionManager.recordTurn(sessId, rawMessage, reply, "GREETING", null, null);
            return new AiDto.ChatResponse(reply, actions, "GREETING");
        }

        // =========================================================================
        // 12. RESPUESTA DINÁMICA DE ORIENTACIÓN GENERAL (Nunca repetitiva)
        // =========================================================================
        String nameRef = (userName != null && !userName.equalsIgnoreCase("Ciudadano")) ? userName : "ciudadano";
        String reply = String.format("""
                Hola %s. He recibido tu consulta en **Cartagena Segura**. Para brindarte la orientación más precisa:

                * Si estás presenciando o involucrado en un **accidente de tránsito (moto o carro)**, por favor indícamelo para activar el protocolo con el CRUE (125) y DATT (127).
                * Si fuiste víctima de un **hurto o situación de peligro**, comunícate de inmediato con la **Línea 123** de la Policía.
                * Si deseas conocer el **nivel de riesgo de un barrio** (*Bocagrande, Getsemaní, Centro, Manga, Bazurto, Olaya*), solo escribe su nombre.

                ¿Qué novedad o inquietud específica estás experimentando?
                """, nameRef);

        List<AiDto.ActionPrompt> actions = List.of(
                new AiDto.ActionPrompt("CALL", "Llamar a Policía 123", "123"),
                new AiDto.ActionPrompt("CALL", "Llamar a CRUE 125", "125"),
                new AiDto.ActionPrompt("NAVIGATE", "Ver Mapa en Vivo", "/App/Map")
        );
        sessionManager.recordTurn(sessId, rawMessage, reply, "GENERAL_GUIDANCE", null, null);
        return new AiDto.ChatResponse(reply, actions, "GENERAL_GUIDANCE");
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

    /**
     * PLAN TÁCTICO DE PATRULLAJE INTELIGENTE
     */
    public AiDto.PatrolPlanResponse generatePatrolPlan() {
        List<Zone> zones = zoneRepository.findAll();
        List<Incident> allIncidents = incidentRepository.findAll();

        List<Incident> activeIncidents = allIncidents.stream()
                .filter(i -> i.getStatus() == Incident.Status.PENDING || i.getStatus() == Incident.Status.IN_PROGRESS)
                .toList();

        String nowStr = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm"));
        List<AiDto.PatrolAssignment> assignments = new ArrayList<>();

        for (Zone zone : zones) {
            long zoneActiveCount = activeIncidents.stream()
                    .filter(i -> zone.getId() != null && zone.getId().equals(i.getZoneId()))
                    .count();

            String timeWindow;
            String unitType;
            String focus;
            int suggestedUnits;

            String zName = zone.getName().toLowerCase();
            if (zName.contains("centro") || zName.contains("amurallada")) {
                timeWindow = "18:00 - 03:00 (Pico turístico y peatonal)";
                unitType = "Policía de Turismo + Patrulla Motorizada Bivalente";
                focus = "Plazas principales (Paz, Santo Domingo, Proclamación), baluartes y corredores gastronómicos.";
                suggestedUnits = zoneActiveCount > 1 ? 4 : 3;
            } else if (zName.contains("bocagrande") || zName.contains("castillogrande") || zName.contains("laguito")) {
                timeWindow = "16:00 - 00:00 (Corredor hotelero y playas)";
                unitType = "Patrulla Motorizada Ligera + Ciclo-patrulla";
                focus = "Avenida San Martín, malecón de las playas y zonas bancarias.";
                suggestedUnits = zoneActiveCount > 1 ? 3 : 2;
            } else if (zName.contains("getsemaní") || zName.contains("getsemani")) {
                timeWindow = "20:00 - 04:00 (Vida nocturna y eventos)";
                unitType = "Cuadrante de Proximidad + CAI Móvil";
                focus = "Plaza de la Trinidad, Calle de la Media Luna y Calle del Arsenal.";
                suggestedUnits = zoneActiveCount > 1 ? 3 : 2;
            } else if (zName.contains("olaya") || zName.contains("herrera")) {
                timeWindow = "14:00 - 23:00 (Sectores residenciales y comercio)";
                unitType = "Fuerza de Reacción Rápida + Cuadrante Móvil";
                focus = "Vías arterias, sectores Stella, Boston y corredores de transporte.";
                suggestedUnits = 4;
            } else if (zName.contains("pozon") || zName.contains("pozón") || zName.contains("bazurto")) {
                timeWindow = "05:00 - 18:00 (Comercio mayorista y aglomeraciones)";
                unitType = "Puesto de Control Fijo + Dron de Reconocimiento CAD";
                focus = "Intersecciones principales, paraderos de Transcaribe y zonas de carga.";
                suggestedUnits = zoneActiveCount > 2 ? 4 : 3;
            } else {
                timeWindow = "12:00 - 22:00 (Vigilancia preventiva estándar)";
                unitType = "Patrulla Cuadrante Motorizado";
                focus = "Parques vecinales, corredores comerciales y accesos principales.";
                suggestedUnits = switch (zone.getRiskLevel()) {
                    case CRITICAL -> 4;
                    case HIGH -> 3;
                    case MODERATE -> 2;
                    case LOW -> 1;
                };
            }

            assignments.add(new AiDto.PatrolAssignment(
                    zone.getName(),
                    zone.getRiskLevel().name(),
                    timeWindow,
                    unitType,
                    focus,
                    suggestedUnits,
                    (int) zoneActiveCount
            ));
        }

        assignments.sort((a, b) -> Integer.compare(b.getActiveIncidentsCount(), a.getActiveIncidentsCount()));

        long criticalCount = allIncidents.stream().filter(i -> i.getPriority() == Incident.Priority.CRITICAL).count();
        String threatLevel = criticalCount > 2 ? "ELEVADO - ATENCIÓN PRIORITARIA" : (activeIncidents.size() > 5 ? "MODERADO EN OBSERVACIÓN" : "ESTABLE CONTROLADO");

        List<String> tacticalRecs = List.of(
                "Desplegar puestos de control dinámicos de 20 minutos en accesos a zonas turísticas para control de parrilleros en motocicleta.",
                "Sincronizar el patrullaje de cuadrantes con el monitoreo en tiempo real de cámaras domo del CAD Distrital.",
                "Priorizar cierre de reportes clasificados como 'ROBO' y 'ACCIDENTE' con geolocalización confirmada.",
                "Activar protocolo de caminatas seguras para turistas en Centro y Getsemaní entre las 20:00 y las 02:00."
        );

        String executiveNotes = String.format(
                "Plan táctico generado automáticamente por Cartagena Segura AI para %d sectores distritales. " +
                "Se registran %d incidentes activos que requieren despacho o seguimiento inmediato. " +
                "Nivel general de amenaza distrital evaluado como %s.",
                zones.size(), activeIncidents.size(), threatLevel
        );

        return new AiDto.PatrolPlanResponse(nowStr, threatLevel, activeIncidents.size(), assignments, tacticalRecs, executiveNotes);
    }

    /**
     * DETECCIÓN DE ANOMALÍAS Y PICOS DE RIESGO
     */
    public AiDto.AnomalyResponse detectAnomalies() {
        List<Zone> zones = zoneRepository.findAll();
        List<Incident> allIncidents = incidentRepository.findAll();
        String nowStr = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm"));

        List<AiDto.AnomalyItem> anomalies = new ArrayList<>();
        int anomalyScore = 15;

        // 1. Detección de incidentes críticos abiertos
        long openCritical = allIncidents.stream()
                .filter(i -> i.getPriority() == Incident.Priority.CRITICAL && i.getStatus() != Incident.Status.RESOLVED && i.getStatus() != Incident.Status.REJECTED)
                .count();

        if (openCritical > 0) {
            anomalyScore += (int) (openCritical * 18);
            anomalies.add(new AiDto.AnomalyItem(
                    "Distrito General",
                    "Incidentes Críticos Sin Resolver",
                    "CRITICAL",
                    String.format("Existen %d reportes de prioridad CRÍTICA pendientes de resolución inmediata en la red distrital.", openCritical),
                    "Despachar unidad de reacción inmediata y notificar al oficial de guardia de la Policía Metropolitana."
            ));
        }

        // 2. Detección de concentración de incidentes por zona
        for (Zone zone : zones) {
            List<Incident> zoneIncidents = allIncidents.stream()
                    .filter(i -> zone.getId() != null && zone.getId().equals(i.getZoneId()))
                    .toList();

            long openCount = zoneIncidents.stream()
                    .filter(i -> i.getStatus() == Incident.Status.PENDING || i.getStatus() == Incident.Status.IN_PROGRESS)
                    .count();

            if (openCount >= 3) {
                anomalyScore += 15;
                anomalies.add(new AiDto.AnomalyItem(
                        zone.getName(),
                        "Saturación de Incidentes Activos",
                        "HIGH",
                        String.format("La zona registra %d reportes activos en curso, superando el umbral operacional estándar.", openCount),
                        "Redistribuir unidades de cuadrantes vecinos para apoyo táctico y acelerar atención."
                ));
            }

            if (zone.getRiskLevel() == Zone.RiskLevel.CRITICAL && zoneIncidents.isEmpty()) {
                anomalies.add(new AiDto.AnomalyItem(
                        zone.getName(),
                        "Zona Crítica con Sub-registro Potencial",
                        "MEDIUM",
                        "Zona catalogada con riesgo crítico sin reportes ciudadanos recientes en la plataforma.",
                        "Enviar patrulla comunitaria para incentivar frentes de seguridad y verificar situación."
                ));
            }
        }

        // 3. Análisis de tasa global de resolución
        long total = allIncidents.size();
        long resolved = allIncidents.stream().filter(i -> i.getStatus() == Incident.Status.RESOLVED || i.getStatus() == Incident.Status.REJECTED).count();
        double resRate = total > 0 ? (resolved * 100.0 / total) : 100.0;

        if (resRate < 70.0 && total >= 5) {
            anomalyScore += 12;
            anomalies.add(new AiDto.AnomalyItem(
                    "Operaciones Distritales",
                    "Baja Tasa de Resolución de Casos",
                    "HIGH",
                    String.format("La tasa de resolución se sitúa en %.1f%%, por debajo del objetivo distrital (85%%).", resRate),
                    "Auditar tiempos de cierre de casos y revisar disponibilidad de patrullas en turnos rotativos."
            ));
        }

        anomalyScore = Math.min(Math.max(anomalyScore, 10), 98);
        String status = anomalyScore >= 60 ? "ALERTA TÁCTICA" : (anomalyScore >= 35 ? "PRECAUCIÓN" : "NORMAL ESTABLE");

        String diagnosis = String.format(
                "Diagnóstico IA: Se detectaron %d desviaciones/anomalías operativas en Cartagena. " +
                "Puntuación de riesgo compuesta: %d/100 (Estado: %s).",
                anomalies.size(), anomalyScore, status
        );

        return new AiDto.AnomalyResponse(anomalyScore, status, anomalies.size(), anomalies, diagnosis, nowStr);
    }
}
