package Com.Backend.CartagenaSegura.Model;

import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;
import org.springframework.data.mongodb.core.index.Indexed;

import java.time.LocalDateTime;

@Document(collection = "logs")
public class LogEntry {

    @Id
    private String id;

    private String action;         // LOGIN, LOGOUT, CREATE_INCIDENT, UPDATE_STATUS, etc.

    @Indexed
    private String user;           // username

    private String details;

    private String ipAddress;      // IP desde donde se realizo la accion

    private String userAgent;      // Navegador/dispositivo

    private String entityType;     // "Incident", "User", etc.
    private String entityId;       // ID del objeto afectado

    private LogLevel level = LogLevel.INFO;

    @Indexed
    private LocalDateTime timestamp = LocalDateTime.now();

    public enum LogLevel {
        INFO,
        WARN,
        ERROR
    }

    public LogEntry() {}

    public LogEntry(String action, String user, String details, String ipAddress,
                    String userAgent, String entityType, String entityId, LogLevel level) {
        this.action = action;
        this.user = user;
        this.details = details;
        this.ipAddress = ipAddress;
        this.userAgent = userAgent;
        this.entityType = entityType;
        this.entityId = entityId;
        this.level = level;
    }

    // Constructor simplificado (compatibilidad con el original)
    public LogEntry(String action, String user, String details) {
        this.action = action;
        this.user = user;
        this.details = details;
    }

    // Getters y Setters
    public String getId() { return id; }
    public void setId(String id) { this.id = id; }

    public String getAction() { return action; }
    public void setAction(String action) { this.action = action; }

    public String getUser() { return user; }
    public void setUser(String user) { this.user = user; }

    public String getDetails() { return details; }
    public void setDetails(String details) { this.details = details; }

    public String getIpAddress() { return ipAddress; }
    public void setIpAddress(String ipAddress) { this.ipAddress = ipAddress; }

    public String getUserAgent() { return userAgent; }
    public void setUserAgent(String userAgent) { this.userAgent = userAgent; }

    public String getEntityType() { return entityType; }
    public void setEntityType(String entityType) { this.entityType = entityType; }

    public String getEntityId() { return entityId; }
    public void setEntityId(String entityId) { this.entityId = entityId; }

    public LogLevel getLevel() { return level; }
    public void setLevel(LogLevel level) { this.level = level; }

    public LocalDateTime getTimestamp() { return timestamp; }
    public void setTimestamp(LocalDateTime timestamp) { this.timestamp = timestamp; }
}
