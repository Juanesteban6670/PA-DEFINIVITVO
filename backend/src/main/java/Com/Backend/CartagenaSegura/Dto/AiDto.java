package Com.Backend.CartagenaSegura.Dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

public class AiDto {

    /**
     * Petición genérica para Chat y Clasificación con soporte de historial conversacional
     */
    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class Request {
        private String message;     // Para chat
        private String description; // Para clasificación
        private String sessionId;   // Opcional para contexto
        private boolean isAdmin;    // Indica si el usuario es administrador
        private List<MessageHistory> history; // Historial reciente de la conversación
    }

    /**
     * Mensaje en el historial conversacional
     */
    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class MessageHistory {
        private String role; // "user" o "assistant"
        private String content;
    }

    /**
     * Respuesta del Chatbot con soporte de acciones rápidas interactivas
     */
    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class ChatResponse {
        private String reply;
        private List<ActionPrompt> actions;
        private String topic;

        public ChatResponse(String reply) {
            this.reply = reply;
        }

        public ChatResponse(String reply, List<ActionPrompt> actions) {
            this.reply = reply;
            this.actions = actions;
        }

        public ChatResponse(String reply, List<ActionPrompt> actions, String topic) {
            this.reply = reply;
            this.actions = actions;
            this.topic = topic;
        }
    }

    /**
     * Acción interactiva sugerida por el asistente (Llamada rápida, Reporte, Ruta)
     */
    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class ActionPrompt {
        private String type; // "CALL", "NAVIGATE", "REPORT"
        private String label; // ej: "Llamar al CRUE 125"
        private String payload; // ej: "125", "/App/Map"
    }

    /**
     * Respuesta estructurada de clasificación de incidentes
     */
    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class ClassifyResponse {
        private String type;      // ROBO, ACCIDENTE, etc.
        private String priority;  // LOW, MEDIUM, HIGH, CRITICAL
        private Double confidence; // 0.0 a 1.0 (opcional)
    }

    /**
     * Respuesta del resumen narrativo
     */
    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class SummaryResponse {
        private String summary;
    }

    /**
     * Respuesta de análisis de zona
     */
    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class ZoneAnalysis {
        private List<ZoneRecommendation> zones;
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class ZoneRecommendation {
        private String name;
        private String riskLevel;
        private String recommendation;
    }

    /**
     * Plan táctico de patrullaje generado por IA
     */
    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class PatrolPlanResponse {
        private String generatedAt;
        private String districtThreatLevel;
        private int totalActiveIncidents;
        private List<PatrolAssignment> assignments;
        private List<String> tacticalRecommendations;
        private String executiveNotes;
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class PatrolAssignment {
        private String zoneName;
        private String riskLevel;
        private String priorityTimeWindow;
        private String unitType;
        private String focusArea;
        private int suggestedUnits;
        private int activeIncidentsCount;
    }

    /**
     * Detección de anomalías y picos de riesgo
     */
    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class AnomalyResponse {
        private int anomalyScore;
        private String threatStatus;
        private int totalAnomaliesDetected;
        private List<AnomalyItem> anomalies;
        private String systemDiagnosis;
        private String generatedAt;
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class AnomalyItem {
        private String quadrantOrCategory;
        private String anomalyType;
        private String severity;
        private String description;
        private String immediateAction;
    }
}

