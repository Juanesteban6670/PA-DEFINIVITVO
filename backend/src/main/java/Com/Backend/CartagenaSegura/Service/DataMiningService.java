package Com.Backend.CartagenaSegura.Service;

import Com.Backend.CartagenaSegura.Model.Incident;
import Com.Backend.CartagenaSegura.Model.Zone;
import Com.Backend.CartagenaSegura.Repository.IncidentRepository;
import Com.Backend.CartagenaSegura.Repository.ZoneRepository;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.*;
import java.util.stream.Collectors;

@Service
public class DataMiningService {

    private final IncidentRepository incidentRepository;
    private final ZoneRepository zoneRepository;

    public static final List<String> CARTAGENA_SECTORS = List.of(
            "Centro Histórico",
            "Bazurto",
            "Olaya Herrera",
            "Getsemaní",
            "Bocagrande",
            "Manga",
            "Pie de la Popa",
            "El Cabrero"
    );

    // Coordenadas representativas de los sectores de Cartagena
    public static final Map<String, double[]> SECTOR_COORDINATES = Map.of(
            "Centro Histórico", new double[]{10.4224, -75.5531},
            "Bazurto", new double[]{10.4072, -75.5182},
            "Olaya Herrera", new double[]{10.3932, -75.4968},
            "Getsemaní", new double[]{10.4195, -75.5458},
            "Bocagrande", new double[]{10.4022, -75.5562},
            "Manga", new double[]{10.4158, -75.5354},
            "Pie de la Popa", new double[]{10.4202, -75.5312},
            "El Cabrero", new double[]{10.4285, -75.5421}
    );

    public DataMiningService(IncidentRepository incidentRepository, ZoneRepository zoneRepository) {
        this.incidentRepository = incidentRepository;
        this.zoneRepository = zoneRepository;
    }

    public record SectorMiningFeatures(
            String sectorName,
            String zoneId,
            int incidentsLast7d,
            int incidentsLast30d,
            double criticalRatio,
            double momentumRatio,
            String predominantIncidentType,
            double latitude,
            double longitude,
            double[] normalizedFeatureVector
    ) {}

    /**
     * Pipeline de minería en tiempo real:
     * 1. Consulta la colección real de MongoDB.
     * 2. Limpia y asocia eventos por sector territorial.
     * 3. Extrae ventanas temporales deslizantes (7d y 30d).
     * 4. Normaliza los valores hacia tensores de entrada para la Red Neuronal.
     */
    public List<SectorMiningFeatures> extractSectorFeatures(LocalDateTime referenceTime) {
        List<Incident> allIncidents = incidentRepository.findAll();
        List<Zone> zones = zoneRepository.findAll();

        Map<String, String> zoneMap = zones.stream()
                .collect(Collectors.toMap(
                        z -> z.getName().toLowerCase().trim(),
                        Zone::getId,
                        (existing, replacement) -> existing
                ));

        LocalDateTime sevenDaysAgo = referenceTime.minusDays(7);
        LocalDateTime thirtyDaysAgo = referenceTime.minusDays(30);

        List<SectorMiningFeatures> results = new ArrayList<>();

        int max30dAcrossSectors = 1;
        Map<String, List<Incident>> incidentsBySector = new HashMap<>();

        for (String sector : CARTAGENA_SECTORS) {
            String sLower = sector.toLowerCase();
            List<Incident> sectorIncidents = allIncidents.stream()
                    .filter(i -> {
                        String loc = (i.getLocation() != null ? i.getLocation() : "").toLowerCase();
                        String desc = (i.getDescription() != null ? i.getDescription() : "").toLowerCase();
                        return loc.contains(sLower) || desc.contains(sLower);
                    })
                    .toList();

            incidentsBySector.put(sector, sectorIncidents);
            if (sectorIncidents.size() > max30dAcrossSectors) {
                max30dAcrossSectors = sectorIncidents.size();
            }
        }

        int targetHour = referenceTime.getHour();
        boolean isWeekend = referenceTime.getDayOfWeek().getValue() >= 6;

        for (String sector : CARTAGENA_SECTORS) {
            List<Incident> incidents = incidentsBySector.getOrDefault(sector, Collections.emptyList());

            int count7d = 0;
            int count30d = 0;
            int highOrCriticalCount = 0;
            Map<String, Integer> typeFrequency = new HashMap<>();

            for (Incident inc : incidents) {
                LocalDateTime created = inc.getCreatedAt() != null ? inc.getCreatedAt() : referenceTime.minusDays(10);
                if (created.isAfter(thirtyDaysAgo)) {
                    count30d++;
                    if (created.isAfter(sevenDaysAgo)) {
                        count7d++;
                    }
                    if (inc.getPriority() == Incident.Priority.CRITICAL || inc.getPriority() == Incident.Priority.HIGH) {
                        highOrCriticalCount++;
                    }
                    String type = inc.getType() != null ? inc.getType() : "ALERTA";
                    typeFrequency.put(type, typeFrequency.getOrDefault(type, 0) + 1);
                }
            }

            double criticalRatio = count30d > 0 ? (double) highOrCriticalCount / count30d : 0.25;
            double momentumRatio = count30d > 0 ? (double) (count7d * 4) / Math.max(1, count30d) : 1.0;

            String predominantType = typeFrequency.entrySet().stream()
                    .max(Map.Entry.comparingByValue())
                    .map(Map.Entry::getKey)
                    .orElse("ROBO");

            double[] coords = SECTOR_COORDINATES.getOrDefault(sector, new double[]{10.4200, -75.5400});
            String zoneId = zoneMap.getOrDefault(sector.toLowerCase(), "zone_" + sector.toLowerCase().replaceAll("\\s+", ""));

            // Generación de vector normalizado [0, 1]
            double normDensity = Math.min(1.0, (double) count30d / Math.max(1, max30dAcrossSectors));
            double normCritical = Math.min(1.0, criticalRatio);
            double hourSin = (Math.sin(2 * Math.PI * targetHour / 24.0) + 1.0) / 2.0;
            double hourCos = (Math.cos(2 * Math.PI * targetHour / 24.0) + 1.0) / 2.0;
            double weekendFactor = isWeekend ? 1.0 : 0.0;
            double momentumNorm = Math.min(1.0, momentumRatio / 3.0);

            double[] featureVector = new double[]{
                    normDensity,
                    normCritical,
                    hourSin,
                    hourCos,
                    weekendFactor,
                    momentumNorm
            };

            results.add(new SectorMiningFeatures(
                    sector,
                    zoneId,
                    count7d,
                    count30d,
                    criticalRatio,
                    momentumRatio,
                    predominantType,
                    coords[0],
                    coords[1],
                    featureVector
            ));
        }

        return results;
    }

    public int getTotalHistoricalSamples() {
        return (int) incidentRepository.count();
    }
}
