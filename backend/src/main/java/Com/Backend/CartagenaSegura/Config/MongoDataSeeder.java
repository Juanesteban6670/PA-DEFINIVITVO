package Com.Backend.CartagenaSegura.Config;

import Com.Backend.CartagenaSegura.Model.Incident;
import Com.Backend.CartagenaSegura.Model.Zone;
import Com.Backend.CartagenaSegura.Repository.IncidentRepository;
import Com.Backend.CartagenaSegura.Repository.ZoneRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.stereotype.Component;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

/**
 * Sembrador de datos geoespaciales realistas para Cartagena de Indias.
 * Si la base de datos MongoDB tiene menos de 15 incidentes, genera automáticamente
 * incidentes distribuidos territorial y temporalmente (últimos 7 días) para que
 * las vistas ciudadanas (Inicio, Mapa, Reportes, Estadísticas) operen 100% con datos reales de MongoDB.
 */
@Component
public class MongoDataSeeder implements ApplicationRunner {

    private static final Logger log = LoggerFactory.getLogger(MongoDataSeeder.class);

    private final IncidentRepository incidentRepository;
    private final ZoneRepository zoneRepository;

    public MongoDataSeeder(IncidentRepository incidentRepository, ZoneRepository zoneRepository) {
        this.incidentRepository = incidentRepository;
        this.zoneRepository = zoneRepository;
    }

    @Override
    public void run(ApplicationArguments args) {
        seedIfNecessary();
    }

    public synchronized int seedIfNecessary() {
        long count = incidentRepository.count();
        if (count >= 15) {
            log.info("MongoDB ya contiene {} incidentes. No se requiere siembra.", count);
            return (int) count;
        }

        log.info("Iniciando siembra de datos geoespaciales en MongoDB Atlas (Incidentes existentes: {})...", count);

        // Asegurar que las zonas existan
        List<Zone> zones = ensureZones();
        String zoneCentro = findZoneId(zones, "Centro", "zone_centro");
        String zoneGetsemani = findZoneId(zones, "Getsemaní", "zone_getsemani");
        String zoneBoca = findZoneId(zones, "Bocagrande", "zone_bocagrande");
        String zoneManga = findZoneId(zones, "Manga", "zone_manga");
        String zoneOlaya = findZoneId(zones, "Olaya", "zone_olaya");

        LocalDateTime now = LocalDateTime.now();
        List<Incident> seedList = new ArrayList<>();

        // Helper para crear incidentes
        // Día 0 (Hoy)
        seedList.add(createIncident("TRAFICO", "Congestión vehicular moderada en retorno", "Avenida San Martín con Calle 8, Bocagrande",
                10.4055, -75.5562, zoneBoca, "ciudadano_maria", Incident.Priority.MEDIUM, Incident.Status.RESOLVED, now.minusHours(2)));
        seedList.add(createIncident("SEGURIDAD", "Patrullaje preventivo solicitado por comerciantes", "Calle de la Moneda, Centro Histórico",
                10.4238, -75.5492, zoneCentro, "juan123", Incident.Priority.LOW, Incident.Status.IN_PROGRESS, now.minusHours(4)));
        seedList.add(createIncident("INFRAESTRUCTURA", "Semáforo peatonal intermitente", "Avenida Pedro de Heredia, Sector Bazurto",
                10.4082, -75.5186, zoneCentro, "ciudadano_camilo", Incident.Priority.MEDIUM, Incident.Status.PENDING, now.minusHours(6)));
        seedList.add(createIncident("ROBO", "Intento de hurto frustrado por cuadrante", "Plaza de la Trinidad, Getsemaní",
                10.4195, -75.5452, zoneGetsemani, "ciudadano_maria", Incident.Priority.HIGH, Incident.Status.RESOLVED, now.minusHours(8)));

        // Día 1 (Ayer)
        LocalDateTime day1 = now.minusDays(1);
        seedList.add(createIncident("ACCIDENTE_TRANSITO", "Colisión simple de dos taxis sin lesionados", "Avenida Blas de Lezo frente al Muelle",
                10.4215, -75.5488, zoneCentro, "oficial_cuadrante4", Incident.Priority.HIGH, Incident.Status.RESOLVED, day1.minusHours(3)));
        seedList.add(createIncident("TRAFICO", "Paso vehicular restringido por evento cultural", "Calle de la Media Luna, Getsemaní",
                10.4198, -75.5435, zoneGetsemani, "ciudadano_camilo", Incident.Priority.LOW, Incident.Status.RESOLVED, day1.minusHours(5)));
        seedList.add(createIncident("ALUMBRADO_PUBLICO", "Luminarias apagadas en sendero peatonal", "Avenida Miramar, Manga",
                10.4145, -75.5385, zoneManga, "ciudadano_maria", Incident.Priority.MEDIUM, Incident.Status.RESOLVED, day1.minusHours(7)));
        seedList.add(createIncident("ALTERCADO", "Discusión en vía pública por estacionamiento", "Carrera 3 con Calle 10, Bocagrande",
                10.4040, -75.5570, zoneBoca, "ciudadano_maria", Incident.Priority.MEDIUM, Incident.Status.RESOLVED, day1.minusHours(9)));
        seedList.add(createIncident("INFRAESTRUCTURA", "Tapa de alcantarilla desnivelada", "Calle del Toril, Pie de la Popa",
                10.4190, -75.5335, zoneManga, "juan123", Incident.Priority.LOW, Incident.Status.RESOLVED, day1.minusHours(11)));

        // Día 2 (Hace 2 días)
        LocalDateTime day2 = now.minusDays(2);
        seedList.add(createIncident("ROBO", "Hurto de pertenencias en zona de playa", "Playa Hollywood, Bocagrande",
                10.4012, -75.5601, zoneBoca, "ciudadano_camilo", Incident.Priority.HIGH, Incident.Status.RESOLVED, day2.minusHours(4)));
        seedList.add(createIncident("VIA_CERRADA", "Mantenimiento de tubería matriz", "Calle San Juan de Dios, Centro Histórico",
                10.4215, -75.5492, zoneCentro, "admin", Incident.Priority.MEDIUM, Incident.Status.RESOLVED, day2.minusHours(8)));
        seedList.add(createIncident("SEGURIDAD", "Alerta comunitaria por personas sospechosas", "Sector Stella, Olaya Herrera",
                10.3945, -75.4975, zoneOlaya, "oficial_cuadrante4", Incident.Priority.HIGH, Incident.Status.IN_PROGRESS, day2.minusHours(12)));
        seedList.add(createIncident("TRAFICO", "Alta afluencia de transporte público", "Mercado de Bazurto, Av. Pedro de Heredia",
                10.4091, -75.5202, zoneCentro, "ciudadano_maria", Incident.Priority.LOW, Incident.Status.RESOLVED, day2.minusHours(16)));

        // Día 3 (Viernes - Pico semanal con mayor actividad)
        LocalDateTime day3 = now.minusDays(3);
        seedList.add(createIncident("TRAFICO", "Congestión alta en horas pico nocturnas", "Avenida San Martín #8-45, Bocagrande",
                10.4062, -75.5558, zoneBoca, "ciudadano_maria", Incident.Priority.MEDIUM, Incident.Status.RESOLVED, day3.minusHours(2)));
        seedList.add(createIncident("ALTERCADO", "Alteración del orden público en terraza comercial", "Calle del Pozo, Getsemaní",
                10.4188, -75.5441, zoneGetsemani, "ciudadano_camilo", Incident.Priority.HIGH, Incident.Status.RESOLVED, day3.minusHours(4)));
        seedList.add(createIncident("ROBO", "Cosquilleo en aglomeración turística", "Plaza de los Coches, Torre del Reloj",
                10.4228, -75.5486, zoneCentro, "oficial_cuadrante4", Incident.Priority.MEDIUM, Incident.Status.RESOLVED, day3.minusHours(6)));
        seedList.add(createIncident("ACCIDENTE_TRANSITO", "Caída de motociclista por asfalto húmedo", "Puente Román, Manga",
                10.4182, -75.5410, zoneManga, "juan123", Incident.Priority.HIGH, Incident.Status.RESOLVED, day3.minusHours(7)));
        seedList.add(createIncident("SOS", "Asistencia de primeros auxilios por golpe de calor", "Plaza Santo Domingo, Centro Histórico",
                10.4231, -75.5505, zoneCentro, "ciudadano_maria", Incident.Priority.CRITICAL, Incident.Status.RESOLVED, day3.minusHours(9)));
        seedList.add(createIncident("INFRAESTRUCTURA", "Desprendimiento de rama de árbol en vía", "Callejón Dandy, Manga",
                10.4120, -75.5398, zoneManga, "ciudadano_camilo", Incident.Priority.LOW, Incident.Status.RESOLVED, day3.minusHours(11)));
        seedList.add(createIncident("TRAFICO", "Retención vehicular en intersección", "Carrera 2 con Calle 6, Bocagrande",
                10.4021, -75.5582, zoneBoca, "oficial_cuadrante4", Incident.Priority.LOW, Incident.Status.RESOLVED, day3.minusHours(14)));
        seedList.add(createIncident("SEGURIDAD", "Verificación de antecedentes en punto de control", "Cancha de Olaya, Olaya Herrera",
                10.3930, -75.4960, zoneOlaya, "oficial_cuadrante4", Incident.Priority.MEDIUM, Incident.Status.RESOLVED, day3.minusHours(18)));

        // Día 4 (Hace 4 días)
        LocalDateTime day4 = now.minusDays(4);
        seedList.add(createIncident("VIA_CERRADA", "Pavimentación preventiva de calzada", "Calle de la Media Luna, Getsemaní",
                10.4200, -75.5440, zoneGetsemani, "admin", Incident.Priority.MEDIUM, Incident.Status.RESOLVED, day4.minusHours(5)));
        seedList.add(createIncident("ROBO", "Hurto de bicicleta en parque residencial", "Paseo Peatonal de Manga",
                10.4135, -75.5370, zoneManga, "ciudadano_camilo", Incident.Priority.MEDIUM, Incident.Status.RESOLVED, day4.minusHours(8)));
        seedList.add(createIncident("TRAFICO", "Operativo de control vial", "Avenida Santander frente a Murallas",
                10.4270, -75.5440, zoneCentro, "oficial_cuadrante4", Incident.Priority.LOW, Incident.Status.RESOLVED, day4.minusHours(12)));
        seedList.add(createIncident("ALUMBRADO_PUBLICO", "Luminarias intermitentes en parque infantil", "Parque Lacustre, Manga",
                10.4110, -75.5350, zoneManga, "ciudadano_maria", Incident.Priority.LOW, Incident.Status.RESOLVED, day4.minusHours(16)));

        // Día 5 (Hace 5 días)
        LocalDateTime day5 = now.minusDays(5);
        seedList.add(createIncident("ALTERCADO", "Riña verbal disuadida por auxiliares", "Sector La Cuchilla, Bazurto",
                10.4072, -75.5178, zoneCentro, "oficial_cuadrante4", Incident.Priority.MEDIUM, Incident.Status.RESOLVED, day5.minusHours(6)));
        seedList.add(createIncident("ACCIDENTE_TRANSITO", "Roce entre bus y automóvil", "Avenida San Martín, Bocagrande",
                10.4070, -75.5550, zoneBoca, "ciudadano_maria", Incident.Priority.HIGH, Incident.Status.RESOLVED, day5.minusHours(10)));
        seedList.add(createIncident("INFRAESTRUCTURA", "Hueco en calzada señalizado", "Subida al Convento de la Popa",
                10.4215, -75.5310, zoneManga, "juan123", Incident.Priority.LOW, Incident.Status.RESOLVED, day5.minusHours(14)));

        // Día 6 (Hace 6 días)
        LocalDateTime day6 = now.minusDays(6);
        seedList.add(createIncident("TRAFICO", "Paso lento por vehículo varado", "Avenida Pedro de Heredia, Mercado Bazurto",
                10.4085, -75.5190, zoneCentro, "ciudadano_camilo", Incident.Priority.LOW, Incident.Status.RESOLVED, day6.minusHours(8)));
        seedList.add(createIncident("ROBO", "Hurto menor a transeúnte reportado oportunamente", "Calle de las Damas, Centro Histórico",
                10.4220, -75.5510, zoneCentro, "ciudadano_maria", Incident.Priority.MEDIUM, Incident.Status.RESOLVED, day6.minusHours(14)));

        incidentRepository.saveAll(seedList);
        log.info("✓ Siembra de MongoDB exitosa: se insertaron {} incidentes georreferenciados en Cartagena.", seedList.size());
        return seedList.size();
    }

    private Incident createIncident(String type, String description, String location,
                                    Double lat, Double lon, String zoneId, String reportedBy,
                                    Incident.Priority priority, Incident.Status status, LocalDateTime createdAt) {
        Incident inc = new Incident(type, description, location, lat, lon, reportedBy, priority);
        inc.setZoneId(zoneId);
        inc.setStatus(status);
        inc.setCreatedAt(createdAt);
        inc.setUpdatedAt(createdAt.plusHours(1));
        return inc;
    }

    private List<Zone> ensureZones() {
        List<Zone> existing = zoneRepository.findAll();
        if (!existing.isEmpty()) {
            return existing;
        }

        List<Zone> zones = List.of(
                new Zone("Centro Histórico y San Diego", "Sector amurallado, patrimonio arquitectónico y alta afluencia", 10.4235, -75.5485),
                new Zone("Getsemaní", "Barrio colonial bohemio, vida nocturna y plazas culturales", 10.4202, -75.5448),
                new Zone("Bocagrande y Castillogrande", "Zona costera moderna, playas y centros comerciales", 10.4045, -75.5565),
                new Zone("Manga y Pie de la Popa", "Zona residencial tradicional, puerto marítimo y paseos", 10.4132, -75.5342),
                new Zone("Olaya Herrera y La Candelaria", "Sector suroriental residencial con vigilancia prioritaria", 10.3985, -75.4982)
        );
        return zoneRepository.saveAll(zones);
    }

    private String findZoneId(List<Zone> zones, String nameKeyword, String defaultId) {
        return zones.stream()
                .filter(z -> z.getName() != null && z.getName().toLowerCase().contains(nameKeyword.toLowerCase()))
                .map(Zone::getId)
                .findFirst()
                .orElse(defaultId);
    }
}
