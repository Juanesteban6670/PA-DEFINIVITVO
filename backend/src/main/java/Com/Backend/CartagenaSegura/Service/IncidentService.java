package Com.Backend.CartagenaSegura.Service;

import Com.Backend.CartagenaSegura.Dto.IncidentDto.*;
import Com.Backend.CartagenaSegura.Model.Incident;
import Com.Backend.CartagenaSegura.Model.IncidentHistory;
import Com.Backend.CartagenaSegura.Repository.IncidentHistoryRepository;
import Com.Backend.CartagenaSegura.Repository.IncidentRepository;
import org.springframework.stereotype.Service;
import org.springframework.dao.DuplicateKeyException;

import java.nio.charset.StandardCharsets;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Objects;
import java.util.UUID;
import org.springframework.messaging.simp.SimpMessagingTemplate;

@Service
public class IncidentService {

    private final IncidentRepository incidentRepository;
    private final IncidentHistoryRepository historyRepository;
    private final NotificationService notificationService;
    private final ZoneService zoneService;
    private final LogService logService;
    private final SimpMessagingTemplate messagingTemplate;

    public IncidentService(IncidentRepository incidentRepository,
                           IncidentHistoryRepository historyRepository,
                           NotificationService notificationService,
                           ZoneService zoneService,
                           LogService logService,
                           @org.springframework.beans.factory.annotation.Autowired(required = false)
                           SimpMessagingTemplate messagingTemplate) {
        this.incidentRepository = incidentRepository;
        this.historyRepository = historyRepository;
        this.notificationService = notificationService;
        this.zoneService = zoneService;
        this.logService = logService;
        this.messagingTemplate = messagingTemplate;
    }

    public Incident create(CreateIncidentRequest req, String reportedBy) {
        String idempotencyKey = req.idempotencyKey();
        if (idempotencyKey != null && !idempotencyKey.isBlank()) {
            Incident existing = incidentRepository
                    .findByReportedByAndIdempotencyKey(reportedBy, idempotencyKey)
                    .orElse(null);
            if (existing != null) {
                ensureSameRequest(existing, req);
                return existing;
            }
        }

        Incident incident = new Incident(
                req.type(), req.description(), req.location(),
                req.latitude(), req.longitude(), reportedBy,
                req.priority() != null ? req.priority() : Incident.Priority.MEDIUM
        );
        incident.setZoneId(req.zoneId());
        incident.setImageUrls(req.imageUrls());
        if (idempotencyKey != null && !idempotencyKey.isBlank()) {
            incident.setIdempotencyKey(idempotencyKey);
            incident.setId(UUID.nameUUIDFromBytes(
                    (reportedBy + "\u0000" + idempotencyKey).getBytes(StandardCharsets.UTF_8)).toString());
        }

        Incident saved;
        try {
            saved = incidentRepository.insert(incident);
        } catch (DuplicateKeyException duplicate) {
            if (idempotencyKey == null || idempotencyKey.isBlank()) {
                throw duplicate;
            }
            Incident existing = incidentRepository.findByReportedByAndIdempotencyKey(reportedBy, idempotencyKey)
                    .orElseThrow(() -> duplicate);
            ensureSameRequest(existing, req);
            return existing;
        }

        // Actualizar stats de la zona
        if (req.zoneId() != null) zoneService.incrementIncidentCount(req.zoneId());

        // Notificar al usuario que su reporte fue recibido
        notificationService.notifyUser(reportedBy, "Reporte recibido",
                "Tu reporte de " + req.type() + " fue recibido y está siendo revisado.",
                Com.Backend.CartagenaSegura.Model.Notification.NotificationType.INCIDENT_CREATED,
                saved.getId(), "Incident");

        logService.log("CREATE_INCIDENT", reportedBy,
                "Incidente creado: " + req.type() + " en " + req.location(),
                "Incident", saved.getId());

        // Emitir alerta en tiempo real a oficiales y administradores via WebSocket
        if (messagingTemplate != null) {
            try {
                messagingTemplate.convertAndSend("/topic/incidents", saved);
                boolean isEmergency = saved.getPriority() == Incident.Priority.CRITICAL
                        || "SOS".equalsIgnoreCase(saved.getType())
                        || "BOTON_PANICO".equalsIgnoreCase(saved.getType())
                        || "PANICO".equalsIgnoreCase(saved.getType());
                if (isEmergency) {
                    java.util.Map<String, Object> alert = new java.util.HashMap<>();
                    alert.put("id", saved.getId());
                    alert.put("type", saved.getType());
                    alert.put("location", saved.getLocation());
                    alert.put("latitude", saved.getLatitude());
                    alert.put("longitude", saved.getLongitude());
                    alert.put("priority", saved.getPriority().name());
                    alert.put("reportedBy", reportedBy);
                    alert.put("timestamp", java.time.Instant.now().toEpochMilli());
                    messagingTemplate.convertAndSend("/topic/alerts", alert);
                }
            } catch (Exception ignored) {}
        }

        return saved;
    }

    private void ensureSameRequest(Incident existing, CreateIncidentRequest req) {
        Incident.Priority priority = req.priority() == null
                ? Incident.Priority.MEDIUM : req.priority();
        if (!Objects.equals(existing.getType(), req.type())
                || !Objects.equals(existing.getDescription(), req.description())
                || !Objects.equals(existing.getLocation(), req.location())
                || !Objects.equals(existing.getLatitude(), req.latitude())
                || !Objects.equals(existing.getLongitude(), req.longitude())
                || !Objects.equals(existing.getZoneId(), req.zoneId())
                || !Objects.equals(existing.getPriority(), priority)
                || !Objects.equals(existing.getImageUrls(), req.imageUrls())) {
            throw new IllegalArgumentException(
                    "Esta clave de envío ya se usó con datos distintos; crea un nuevo borrador.");
        }
    }

    public Incident getById(String id) {
        return incidentRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Incidente no encontrado: " + id));
    }

    public List<Incident> getAll() {
        return incidentRepository.findAll();
    }

    public List<Incident> getByStatus(Incident.Status status) {
        return incidentRepository.findByStatus(status);
    }

    public List<Incident> getByZone(String zoneId) {
        return incidentRepository.findByZoneId(zoneId);
    }

    public List<Incident> getByUser(String userId) {
        return incidentRepository.findByReportedBy(userId);
    }

    public List<Incident> getByAssignedTo(String agentId) {
        return incidentRepository.findByAssignedTo(agentId);
    }

    public Incident updateStatus(String id, UpdateStatusRequest req, String changedBy) {
        Incident incident = getById(id);

        Incident.Status oldStatus = incident.getStatus();
        Incident.Priority oldPriority = incident.getPriority();

        if (req.status() != null) incident.setStatus(req.status());
        if (req.priority() != null) incident.setPriority(req.priority());
        if (req.assignedTo() != null) incident.setAssignedTo(req.assignedTo());
        incident.setUpdatedAt(LocalDateTime.now());

        Incident updated = incidentRepository.save(incident);

        // Guardar historial de cambio
        IncidentHistory history = new IncidentHistory(
                id, oldStatus, req.status(),
                oldPriority, req.priority(),
                changedBy, req.changeReason()
        );
        historyRepository.save(history);

        // Notificar al reportador del cambio
        if (incident.getReportedBy() != null) {
            notificationService.notifyUser(incident.getReportedBy(),
                    "Tu incidente fue actualizado",
                    "Estado: " + updated.getStatus().name(),
                    Com.Backend.CartagenaSegura.Model.Notification.NotificationType.INCIDENT_UPDATED,
                    id, "Incident");
        }

        logService.log("UPDATE_INCIDENT_STATUS", changedBy,
                "Estado cambiado de " + oldStatus + " a " + req.status(),
                "Incident", id);

        if (messagingTemplate != null) {
            try {
                messagingTemplate.convertAndSend("/topic/incidents", updated);
            } catch (Exception ignored) {}
        }

        return updated;
    }

    public void delete(String id, String deletedBy) {
        Incident incident = getById(id);
        incidentRepository.delete(incident);
        logService.log("DELETE_INCIDENT", deletedBy,
                "Incidente eliminado: " + incident.getType(), "Incident", id);
    }

    public List<IncidentHistory> getHistory(String incidentId) {
        return historyRepository.findByIncidentIdOrderByChangedAtDesc(incidentId);
    }

    // Estadísticas
    public long countByStatus(Incident.Status status) {
        return incidentRepository.countByStatus(status);
    }

    public long countByZone(String zoneId) {
        return incidentRepository.countByZoneId(zoneId);
    }
}
