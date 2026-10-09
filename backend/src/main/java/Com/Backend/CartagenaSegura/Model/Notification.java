package Com.Backend.CartagenaSegura.Model;

import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;
import org.springframework.data.mongodb.core.index.Indexed;

import java.time.LocalDateTime;

@Document(collection = "notifications")
public class Notification {

    @Id
    private String id;

    @Indexed
    private String userId;         // A quién va dirigida

    private String title;
    private String message;

    private NotificationType type;

    private String relatedEntityId;   // ID del incidente, zona, etc.
    private String relatedEntityType; // "Incident", "Zone", etc.

    private boolean read = false;

    private LocalDateTime createdAt = LocalDateTime.now();
    private LocalDateTime readAt;

    public enum NotificationType {
        INCIDENT_CREATED,       // Se creó un incidente en tu zona
        INCIDENT_UPDATED,       // Tu incidente fue actualizado
        INCIDENT_RESOLVED,      // Tu incidente fue resuelto
        INCIDENT_ASSIGNED,      // Te asignaron un incidente
        ZONE_ALERT,             // Alerta en una zona
        SYSTEM                  // Notificación general del sistema
    }

    public Notification() {}

    public Notification(String userId, String title, String message,
                        NotificationType type, String relatedEntityId, String relatedEntityType) {
        this.userId = userId;
        this.title = title;
        this.message = message;
        this.type = type;
        this.relatedEntityId = relatedEntityId;
        this.relatedEntityType = relatedEntityType;
    }

    // Getters y Setters
    public String getId() { return id; }
    public void setId(String id) { this.id = id; }

    public String getUserId() { return userId; }
    public void setUserId(String userId) { this.userId = userId; }

    public String getTitle() { return title; }
    public void setTitle(String title) { this.title = title; }

    public String getMessage() { return message; }
    public void setMessage(String message) { this.message = message; }

    public NotificationType getType() { return type; }
    public void setType(NotificationType type) { this.type = type; }

    public String getRelatedEntityId() { return relatedEntityId; }
    public void setRelatedEntityId(String relatedEntityId) { this.relatedEntityId = relatedEntityId; }

    public String getRelatedEntityType() { return relatedEntityType; }
    public void setRelatedEntityType(String relatedEntityType) { this.relatedEntityType = relatedEntityType; }

    public boolean isRead() { return read; }
    public void setRead(boolean read) { this.read = read; }

    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }

    public LocalDateTime getReadAt() { return readAt; }
    public void setReadAt(LocalDateTime readAt) { this.readAt = readAt; }
}
