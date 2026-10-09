package Com.Backend.CartagenaSegura.Model;

import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;
import org.springframework.data.mongodb.core.index.Indexed;

import java.time.LocalDateTime;

@Document(collection = "incident_history")
public class IncidentHistory {

    @Id
    private String id;

    @Indexed
    private String incidentId;

    private Incident.Status oldStatus;
    private Incident.Status newStatus;

    private Incident.Priority oldPriority;
    private Incident.Priority newPriority;

    private String changedBy;          // username del agente/admin
    private String changeReason;       // Motivo del cambio (opcional)

    private LocalDateTime changedAt = LocalDateTime.now();

    public IncidentHistory() {}

    public IncidentHistory(String incidentId, Incident.Status oldStatus, Incident.Status newStatus,
                           Incident.Priority oldPriority, Incident.Priority newPriority,
                           String changedBy, String changeReason) {
        this.incidentId = incidentId;
        this.oldStatus = oldStatus;
        this.newStatus = newStatus;
        this.oldPriority = oldPriority;
        this.newPriority = newPriority;
        this.changedBy = changedBy;
        this.changeReason = changeReason;
    }

    // Getters y Setters
    public String getId() { return id; }
    public void setId(String id) { this.id = id; }

    public String getIncidentId() { return incidentId; }
    public void setIncidentId(String incidentId) { this.incidentId = incidentId; }

    public Incident.Status getOldStatus() { return oldStatus; }
    public void setOldStatus(Incident.Status oldStatus) { this.oldStatus = oldStatus; }

    public Incident.Status getNewStatus() { return newStatus; }
    public void setNewStatus(Incident.Status newStatus) { this.newStatus = newStatus; }

    public Incident.Priority getOldPriority() { return oldPriority; }
    public void setOldPriority(Incident.Priority oldPriority) { this.oldPriority = oldPriority; }

    public Incident.Priority getNewPriority() { return newPriority; }
    public void setNewPriority(Incident.Priority newPriority) { this.newPriority = newPriority; }

    public String getChangedBy() { return changedBy; }
    public void setChangedBy(String changedBy) { this.changedBy = changedBy; }

    public String getChangeReason() { return changeReason; }
    public void setChangeReason(String changeReason) { this.changeReason = changeReason; }

    public LocalDateTime getChangedAt() { return changedAt; }
    public void setChangedAt(LocalDateTime changedAt) { this.changedAt = changedAt; }
}
