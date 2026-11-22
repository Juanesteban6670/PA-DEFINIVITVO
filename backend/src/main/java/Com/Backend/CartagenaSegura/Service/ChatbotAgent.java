package Com.Backend.CartagenaSegura.Service;

import Com.Backend.CartagenaSegura.Dto.AiDto;
import Com.Backend.CartagenaSegura.Model.Incident;
import Com.Backend.CartagenaSegura.Model.Zone;
import Com.Backend.CartagenaSegura.Repository.IncidentRepository;
import Com.Backend.CartagenaSegura.Repository.ZoneRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.stream.Collectors;

/**
 * Agente Inteligente para la gestión de conversaciones del dominio de seguridad.
 * Implementa RAG (Retrieval Augmented Generation) básico consultando la BD local.
 */
@Service
@RequiredArgsConstructor
public class ChatbotAgent {

    private final AiService aiService;
    private final IncidentRepository incidentRepository;
    private final ZoneRepository zoneRepository;

    private static final String SYSTEM_PROMPT = """
        Eres 'Asistente Cartagena Segura', el asistente virtual e inteligente oficial de seguridad ciudadana, convivencia y movilidad de Cartagena de Indias.
        TU REGLA MÁXIMA: Tienes acceso directo a la base de datos real del sistema. NUNCA digas que no tienes información o acceso.
        
        OBJETIVOS Y CAPACIDADES:
        1. Ayudar a los ciudadanos y administradores a resolver dudas y utilizar todas las funciones de Cartagena Segura (reportes ciudadanos, alertas GPS, estadísticas, rutas seguras).
        2. Proporcionar orientación inmediata en emergencias (Línea 123 Policía Nacional, 125 CRUE Ambulancias, 127 Tránsito DATT, 119 Bomberos, 155 Línea Púrpura).
        3. Explicar cómo radicar un reporte paso a paso (botón Reportar, categoría de incidente, ubicación GPS o en mapa, descripción y fotos de evidencia).
        4. Explicar los tipos de incidentes: Hurtos, Accidentes viales, Riñas, Problemas de iluminación pública, Emergencias médicas, Zonas de riesgo.
        5. Brindar recomendaciones preventivas claras y aplicables en los barrios y sectores de Cartagena de Indias.
        
        INSTRUCCIONES DE RESPUESTA:
        1. Usa EXCLUSIVAMENTE la información del 'CONTEXTO ACTUAL DEL SISTEMA' para responder sobre incidentes reales registrados y zonas de riesgo. NUNCA inventes estadísticas, reportes o alertas ficticias.
        2. Si el CONTEXTO no contiene reportes para un sector específico, indícalo con honestidad: "Actualmente no se registran incidentes recientes en la base de datos para ese sector", destacando que los ciudadanos pueden radicar novedades en cualquier momento.
        3. En situaciones de riesgo inminente a la vida o integridad física, prioriza recomendar llamar a la Línea 123 antes de cualquier otro procedimiento.
        4. Responde siempre en español, con tono empático, profesional, respetuoso y estructurado con viñetas o pasos Markdown cuando sea apropiado.
        """;

    /**
     * Procesa la consulta del usuario enriqueciendo el prompt con el estado actual de la BD,
     * memoria de sesión multi-turno y triaje de emergencias.
     */
    public AiDto.ChatResponse processMessage(AiDto.Request request, boolean isAdmin, String userName) {
        String userMessage = request.getMessage() != null ? request.getMessage() : "";
        String sessionId = request.getSessionId() != null && !request.getSessionId().isBlank() 
                ? request.getSessionId() 
                : "session-" + userName;
        List<AiDto.MessageHistory> clientHistory = request.getHistory();


        // 1. Obtener contexto de la BD
        String context = gatherSystemContext();

        // 2. Ajustar el rol en el prompt de sistema
        String customSystemPrompt = SYSTEM_PROMPT;
        if (isAdmin) {
            customSystemPrompt += "\n5. El usuario actual es " + userName + " (ADMINISTRADOR). Salúdalo formalmente por su nombre y usa un tono de reporte operativo.";
        } else {
            customSystemPrompt += "\n5. El usuario actual es " + userName + " (CIUDADANO). Salúdalo cálidamente por su nombre, sé empático y evita frases genéricas como 'Estimado ciudadano'.";
        }

        // 3. Construir el cuerpo del mensaje de usuario
        String userContent = "SITUACIÓN ACTUAL DE LA BASE DE DATOS:\n" + context + 
                            "\n\nPREGUNTA DEL USUARIO: " + userMessage;

        // 4. Llamar al servicio pasando contexto, sesión e historial conversacional
        return aiService.chatWithContext(userContent, customSystemPrompt, sessionId, clientHistory, userName, isAdmin);
    }

    public AiDto.ChatResponse processMessage(String userMessage, boolean isAdmin, String userName) {
        return processMessage(new AiDto.Request(userMessage, null, "default-" + userName, isAdmin, null), isAdmin, userName);
    }

    public AiDto.ChatResponse processMessage(String userMessage) {
        return processMessage(userMessage, false, "Ciudadano");
    }

    /**
     * Recopila información relevante de Incidentes y Zonas para alimentar al LLM.
     */
    private String gatherSystemContext() {
        // Últimos 10 incidentes
        List<Incident> recentIncidents = incidentRepository.findAll().stream()
                .limit(10)
                .collect(Collectors.toList());
                
        String incidentsTxt = recentIncidents.isEmpty() ? 
                "No hay incidentes reportados en el sistema." :
                recentIncidents.stream()
                .map(i -> "- " + i.getType() + " en " + i.getLocation() + " (Estado: " + i.getStatus() + ")")
                .collect(Collectors.joining("\n"));

        // Estado de las Zonas
        List<Zone> zones = zoneRepository.findAll();
        String zonesTxt = zones.isEmpty() ?
                "No hay información de zonas configurada." :
                zones.stream()
                .map(z -> "- Zona " + z.getName() + ": Nivel de Riesgo " + z.getRiskLevel())
                .collect(Collectors.joining("\n"));

        return "### DATOS DE LA BASE DE DATOS LOCAL:\n" +
               "--- INCIDENTES ---\n" + incidentsTxt + 
               "\n\n--- ZONAS DE RIESGO ---\n" + zonesTxt;
    }
}

