package Com.Backend.CartagenaSegura.Dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

public class AiDto {

    /**
     * Petición genérica para Chat y Clasificación
     */
    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class Request {
        private String message;     // Para chat
        private String description; // Para clasificación
        private String sessionId;   // Opcional para contexto
        private boolean isAdmin;    // Indica si el usuario es administrador
    }

    /**
     * Respuesta simple del Chatbot
     */
    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class ChatResponse {
        private String reply;
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
}

