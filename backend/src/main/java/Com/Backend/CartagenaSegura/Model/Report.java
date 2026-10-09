package Com.Backend.CartagenaSegura.Model;

import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.Map;

@Document(collection = "reports")
public class Report {

    @Id
    private String id;

    private String title;

    private ReportType type;

    private String generatedBy;        // username del admin

    // Periodo del reporte
    private LocalDate periodStart;
    private LocalDate periodEnd;

    // Filtros aplicados (zona, tipo de incidente, etc.)
    private Map<String, String> filters;

    // Resumen de datos (estadísticas clave del reporte)
    private Map<String, Object> summary;

    private String fileUrl;            // URL del PDF generado (si aplica)

    private ReportStatus status = ReportStatus.GENERATING;

    private LocalDateTime createdAt = LocalDateTime.now();

    public enum ReportType {
        DAILY,
        WEEKLY,
        MONTHLY,
        CUSTOM
    }

    public enum ReportStatus {
        GENERATING,
        READY,
        FAILED
    }

    public Report() {}

    public Report(String title, ReportType type, String generatedBy,
                  LocalDate periodStart, LocalDate periodEnd, Map<String, String> filters) {
        this.title = title;
        this.type = type;
        this.generatedBy = generatedBy;
        this.periodStart = periodStart;
        this.periodEnd = periodEnd;
        this.filters = filters;
    }

    // Getters y Setters
    public String getId() { return id; }
    public void setId(String id) { this.id = id; }

    public String getTitle() { return title; }
    public void setTitle(String title) { this.title = title; }

    public ReportType getType() { return type; }
    public void setType(ReportType type) { this.type = type; }

    public String getGeneratedBy() { return generatedBy; }
    public void setGeneratedBy(String generatedBy) { this.generatedBy = generatedBy; }

    public LocalDate getPeriodStart() { return periodStart; }
    public void setPeriodStart(LocalDate periodStart) { this.periodStart = periodStart; }

    public LocalDate getPeriodEnd() { return periodEnd; }
    public void setPeriodEnd(LocalDate periodEnd) { this.periodEnd = periodEnd; }

    public Map<String, String> getFilters() { return filters; }
    public void setFilters(Map<String, String> filters) { this.filters = filters; }

    public Map<String, Object> getSummary() { return summary; }
    public void setSummary(Map<String, Object> summary) { this.summary = summary; }

    public String getFileUrl() { return fileUrl; }
    public void setFileUrl(String fileUrl) { this.fileUrl = fileUrl; }

    public ReportStatus getStatus() { return status; }
    public void setStatus(ReportStatus status) { this.status = status; }

    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }
}
