package Com.Backend.CartagenaSegura.Service;

import Com.Backend.CartagenaSegura.Dto.SharedDto.CreateZoneRequest;
import Com.Backend.CartagenaSegura.Model.Zone;
import Com.Backend.CartagenaSegura.Repository.ZoneRepository;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class ZoneService {

    private final ZoneRepository zoneRepository;
    private final LogService logService;

    public ZoneService(ZoneRepository zoneRepository, LogService logService) {
        this.zoneRepository = zoneRepository;
        this.logService = logService;
    }

    public Zone create(CreateZoneRequest req, String createdBy) {
        Zone zone = new Zone(req.name(), req.description(), req.centerLatitude(), req.centerLongitude());
        Zone saved = zoneRepository.save(zone);
        logService.log("CREATE_ZONE", createdBy, "Zona creada: " + req.name(), "Zone", saved.getId());
        return saved;
    }

    public Zone getById(String id) {
        return zoneRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Zona no encontrada: " + id));
    }

    public List<Zone> getAll() {
        return zoneRepository.findByActiveTrue();
    }

    public List<Zone> getByRiskLevel(Zone.RiskLevel riskLevel) {
        return zoneRepository.findByRiskLevelAndActiveTrue(riskLevel);
    }

    public Zone updateRiskLevel(String id, Zone.RiskLevel riskLevel, String updatedBy) {
        Zone zone = getById(id);
        zone.setRiskLevel(riskLevel);
        Zone saved = zoneRepository.save(zone);
        logService.log("UPDATE_ZONE_RISK", updatedBy,
                "Nivel de riesgo actualizado a " + riskLevel + " en zona " + zone.getName(),
                "Zone", id);
        return saved;
    }

    // Llamado internamente al crear/resolver incidentes
    public void incrementIncidentCount(String zoneId) {
        zoneRepository.findById(zoneId).ifPresent(zone -> {
            zone.setTotalIncidents(zone.getTotalIncidents() + 1);
            zone.setPendingIncidents(zone.getPendingIncidents() + 1);
            zoneRepository.save(zone);
        });
    }

    public void resolveIncident(String zoneId) {
        zoneRepository.findById(zoneId).ifPresent(zone -> {
            zone.setPendingIncidents(Math.max(0, zone.getPendingIncidents() - 1));
            zone.setResolvedIncidents(zone.getResolvedIncidents() + 1);
            zoneRepository.save(zone);
        });
    }

    public void deactivate(String id, String deactivatedBy) {
        Zone zone = getById(id);
        zone.setActive(false);
        zoneRepository.save(zone);
        logService.log("DEACTIVATE_ZONE", deactivatedBy, "Zona desactivada: " + zone.getName(), "Zone", id);
    }
}
