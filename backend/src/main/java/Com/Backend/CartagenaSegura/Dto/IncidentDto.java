package Com.Backend.CartagenaSegura.Dto;

import Com.Backend.CartagenaSegura.Model.Incident;
import java.time.LocalDateTime;
import java.util.List;

public class IncidentDto {

    // ---- REQUEST: Crear incidente ----
    public record CreateIncidentRequest(
            String type,
            String description,
            String location,
            Double latitude,
            Double longitude,
            String zoneId,
            Incident.Priority priority,
            List<String> imageUrls,
            String idempotencyKey,
            LocalDateTime createdAt,
            Incident.Status status
    ) {
        public CreateIncidentRequest(
                String type,
                String description,
                String location,
                Double latitude,
                Double longitude,
                String zoneId,
                Incident.Priority priority,
                List<String> imageUrls,
                String idempotencyKey
        ) {
            this(type, description, location, latitude, longitude, zoneId, priority, imageUrls, idempotencyKey, null, null);
        }
    }

    // ---- REQUEST: Actualizar estado ----
    public record UpdateStatusRequest(
            Incident.Status status,
            Incident.Priority priority,
            String assignedTo,
            String changeReason
    ) {}

    // ---- RESPONSE: Incidente completo ----
    public record IncidentResponse(
            String id,
            String type,
            String description,
            String location,
            Double latitude,
            Double longitude,
            String zoneId,
            String reportedBy,
            String assignedTo,
            List<String> imageUrls,
            Incident.Priority priority,
            Incident.Status status,
            LocalDateTime createdAt,
            LocalDateTime updatedAt
    ) {}

    // ---- RESPONSE: Incidente resumido (para listas) ----
    public record IncidentSummary(
            String id,
            String type,
            String location,
            Incident.Priority priority,
            Incident.Status status,
            LocalDateTime createdAt
    ) {}

    public record PublicIncident(
            String id,
            String type,
            String location,
            Double latitude,
            Double longitude,
            String zoneId,
            Incident.Priority priority,
            Incident.Status status,
            LocalDateTime createdAt
    ) {
        public static PublicIncident from(Incident incident) {
            return new PublicIncident(incident.getId(), incident.getType(), "Cartagena",
                    approximate(incident.getLatitude()), approximate(incident.getLongitude()),
                    incident.getZoneId(), incident.getPriority(), incident.getStatus(), incident.getCreatedAt());
        }

        private static Double approximate(Double coordinate) {
            return coordinate == null ? null : Math.round(coordinate * 1_000) / 1_000.0;
        }
    }
}
