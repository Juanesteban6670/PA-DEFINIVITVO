package Com.Backend.CartagenaSegura.Model;

import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;

@Document(collection = "zones")
public class Zone {

    @Id
    private String id;

    private String name;           // Ej: "Bocagrande", "Getsemaní", "El Centro"
    private String description;

    // Nivel de riesgo calculado o asignado manualmente
    private RiskLevel riskLevel = RiskLevel.LOW;

    // Coordenadas del centro de la zona (para el mapa)
    private Double centerLatitude;
    private Double centerLongitude;

    // Estadísticas (se pueden actualizar periódicamente)
    private int totalIncidents = 0;
    private int pendingIncidents = 0;
    private int resolvedIncidents = 0;

    private boolean active = true;

    public enum RiskLevel {
        LOW,
        MODERATE,
        HIGH,
        CRITICAL
    }

    public Zone() {}

    public Zone(String name, String description, Double centerLatitude, Double centerLongitude) {
        this.name = name;
        this.description = description;
        this.centerLatitude = centerLatitude;
        this.centerLongitude = centerLongitude;
    }

    // Getters y Setters
    public String getId() { return id; }
    public void setId(String id) { this.id = id; }

    public String getName() { return name; }
    public void setName(String name) { this.name = name; }

    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }

    public RiskLevel getRiskLevel() { return riskLevel; }
    public void setRiskLevel(RiskLevel riskLevel) { this.riskLevel = riskLevel; }

    public Double getCenterLatitude() { return centerLatitude; }
    public void setCenterLatitude(Double centerLatitude) { this.centerLatitude = centerLatitude; }

    public Double getCenterLongitude() { return centerLongitude; }
    public void setCenterLongitude(Double centerLongitude) { this.centerLongitude = centerLongitude; }

    public int getTotalIncidents() { return totalIncidents; }
    public void setTotalIncidents(int totalIncidents) { this.totalIncidents = totalIncidents; }

    public int getPendingIncidents() { return pendingIncidents; }
    public void setPendingIncidents(int pendingIncidents) { this.pendingIncidents = pendingIncidents; }

    public int getResolvedIncidents() { return resolvedIncidents; }
    public void setResolvedIncidents(int resolvedIncidents) { this.resolvedIncidents = resolvedIncidents; }

    public boolean isActive() { return active; }
    public void setActive(boolean active) { this.active = active; }
}
