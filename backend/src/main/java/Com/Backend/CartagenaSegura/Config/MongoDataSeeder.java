package Com.Backend.CartagenaSegura.Config;

import Com.Backend.CartagenaSegura.Model.Incident;
import Com.Backend.CartagenaSegura.Model.Zone;
import Com.Backend.CartagenaSegura.Repository.IncidentRepository;
import Com.Backend.CartagenaSegura.Repository.ZoneRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.stereotype.Component;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Random;

/**
 * Sembrador de datos geoespaciales realistas para Cartagena de Indias.
 * Genera un conjunto rico de incidentes (~150 reportes) distribuidos
 * temporalmente a lo largo de 90 días (hoy, semana actual, semanas previas y meses anteriores)
 * para que los filtros de fecha en la pantalla de estadísticas ("Hoy", "Esta semana",
 * "Este mes", "3 meses", "Todo") muestren variaciones reales y marcadas.
 */
@Component
public class MongoDataSeeder implements ApplicationRunner {

    private static final Logger log = LoggerFactory.getLogger(MongoDataSeeder.class);

    private final IncidentRepository incidentRepository;
    private final ZoneRepository zoneRepository;

    @Value("${app.demo.seed-enabled:false}")
    private boolean enabled;

    public MongoDataSeeder(IncidentRepository incidentRepository, ZoneRepository zoneRepository) {
        this.incidentRepository = incidentRepository;
        this.zoneRepository = zoneRepository;
    }

    @Override
    public void run(ApplicationArguments args) {
        if (enabled) seedIfNecessary();
    }

    public boolean isEnabled() {
        return enabled;
    }

    public synchronized int seedIfNecessary() {
        if (!enabled) throw new IllegalStateException("La carga de datos de demostración está desactivada");
        long count = incidentRepository.count();
        if (count > 0) {
            log.info("MongoDB ya contiene {} incidentes. Se conservan los reportes existentes.", count);
            return (int) count;
        }

        log.info("Cargando incidentes de demostración en una base vacía.");

        List<Zone> zones = ensureZones();
        String zoneCentro = findZoneId(zones, "Centro", "zone_centro");
        String zoneGetsemani = findZoneId(zones, "Getsemaní", "zone_getsemani");
        String zoneBoca = findZoneId(zones, "Bocagrande", "zone_bocagrande");
        String zoneManga = findZoneId(zones, "Manga", "zone_manga");
        String zoneOlaya = findZoneId(zones, "Olaya", "zone_olaya");

        LocalDateTime now = LocalDateTime.now();
        List<Incident> seedList = new ArrayList<>();

        // Plantillas de sectores con coordenadas reales en Cartagena
        record LocationSpec(String sector, String place, double lat, double lon, String zoneId) {}
        List<LocationSpec> locations = List.of(
                new LocationSpec("Centro Histórico", "Plaza de los Coches, Torre del Reloj", 10.4228, -75.5486, zoneCentro),
                new LocationSpec("Centro Histórico", "Calle de la Moneda con Calle de la Iglesia", 10.4242, -75.5499, zoneCentro),
                new LocationSpec("Centro Histórico", "Plaza Santo Domingo", 10.4231, -75.5505, zoneCentro),
                new LocationSpec("Centro Histórico", "Baluarte de San Ignacio", 10.4208, -75.5512, zoneCentro),
                new LocationSpec("Centro Histórico", "Calle San Juan de Dios #3-45", 10.4215, -75.5492, zoneCentro),
                new LocationSpec("Centro Histórico", "Calle de las Damas", 10.4220, -75.5510, zoneCentro),
                new LocationSpec("Bocagrande", "Avenida San Martín #8-45", 10.4062, -75.5558, zoneBoca),
                new LocationSpec("Bocagrande", "Carrera 2 con Calle 6", 10.4021, -75.5582, zoneBoca),
                new LocationSpec("Bocagrande", "Playa Hollywood", 10.4012, -75.5601, zoneBoca),
                new LocationSpec("Bocagrande", "Avenida San Martín con Calle 10", 10.4045, -75.5565, zoneBoca),
                new LocationSpec("Bocagrande", "Malecón de Bocagrande frente al Hotel Decameron", 10.4030, -75.5590, zoneBoca),
                new LocationSpec("Manga", "Avenida Miramar frente al Club de Pesca", 10.4145, -75.5385, zoneManga),
                new LocationSpec("Manga", "Callejón Dandy #22-14", 10.4120, -75.5398, zoneManga),
                new LocationSpec("Manga", "Puente Román", 10.4182, -75.5410, zoneManga),
                new LocationSpec("Manga", "Paseo Peatonal de Manga", 10.4135, -75.5370, zoneManga),
                new LocationSpec("Getsemaní", "Calle de la Media Luna", 10.4198, -75.5435, zoneGetsemani),
                new LocationSpec("Getsemaní", "Plaza de la Trinidad", 10.4195, -75.5452, zoneGetsemani),
                new LocationSpec("Getsemaní", "Calle del Pozo #25-10", 10.4188, -75.5441, zoneGetsemani),
                new LocationSpec("Bazurto", "Avenida Pedro de Heredia frente a Transcaribe", 10.4085, -75.5195, zoneCentro),
                new LocationSpec("Bazurto", "Sector La Cuchilla, Mercado de Bazurto", 10.4072, -75.5178, zoneCentro),
                new LocationSpec("Bazurto", "Central de Abastos de Bazurto", 10.4091, -75.5202, zoneCentro),
                new LocationSpec("Pie de la Popa", "Subida al Convento de la Popa", 10.4215, -75.5310, zoneManga),
                new LocationSpec("Pie de la Popa", "Calle del Toril, Pie de la Popa", 10.4190, -75.5335, zoneManga),
                new LocationSpec("Olaya Herrera", "Sector Stella Calle 32, Olaya Herrera", 10.3945, -75.4975, zoneOlaya),
                new LocationSpec("Olaya Herrera", "Carrera 50 con Calle 34, Olaya Herrera", 10.3962, -75.4990, zoneOlaya),
                new LocationSpec("Olaya Herrera", "Cancha deportiva de Olaya Herrera", 10.3930, -75.4960, zoneOlaya)
        );

        // Catálogo de tipos y descripciones realistas
        record IncidentTemplate(String type, String descPrefix, Incident.Priority prio) {}
        List<IncidentTemplate> templates = List.of(
                new IncidentTemplate("TRAFICO", "Congestión vehicular por alto flujo y semáforo intermitente", Incident.Priority.MEDIUM),
                new IncidentTemplate("ACCIDENTE_TRANSITO", "Colisión leve de vehículos sin lesionados de gravedad", Incident.Priority.HIGH),
                new IncidentTemplate("VIA_CERRADA", "Paso vehicular restringido por labores de mantenimiento en la calzada", Incident.Priority.MEDIUM),
                new IncidentTemplate("OBSTACULO_VIAL", "Caída de ramas y escombros que reducen la velocidad", Incident.Priority.LOW),
                new IncidentTemplate("ROBO", "Hurto de dispositivo móvil frustrado por la red de apoyo", Incident.Priority.HIGH),
                new IncidentTemplate("ALTERCADO", "Discusión en espacio público atendida preventivamente por la patrulla", Incident.Priority.MEDIUM),
                new IncidentTemplate("ACTIVIDAD_SOSPECHOSA", "Presencia de sospechosos reportada por comerciantes del sector", Incident.Priority.LOW),
                new IncidentTemplate("SOS", "Solicitud de asistencia médica y primeros auxilios", Incident.Priority.CRITICAL),
                new IncidentTemplate("PELEA", "Riña entre particulares disuelta por las autoridades", Incident.Priority.HIGH),
                new IncidentTemplate("ALUMBRADO_PUBLICO", "Luminarias públicas averiadas generando baja visibilidad nocturna", Incident.Priority.LOW),
                new IncidentTemplate("INFRAESTRUCTURA", "Desnivel pronunciado en la vía pública señalizado preventivamente", Incident.Priority.LOW),
                new IncidentTemplate("INUNDACION", "Acumulación temporal de agua de lluvia en la calzada", Incident.Priority.MEDIUM)
        );

        List<String> users = List.of("ciudadano_maria", "ciudadano_camilo", "juan123", "admin", "oficial_cuadrante4");
        Random rnd = new Random(42); // Semilla fija para consistencia

        // Función generadora de incidentes en un día específico
        RunnableGenerator generator = (daysAgo, countForDay, defaultStatus) -> {
            for (int i = 0; i < countForDay; i++) {
                LocationSpec loc = locations.get(rnd.nextInt(locations.size()));
                IncidentTemplate tmpl = templates.get(rnd.nextInt(templates.size()));
                String reporter = users.get(rnd.nextInt(users.size()));

                // Hora variada dentro de ese día (entre 7 AM y 11 PM)
                int hour = 7 + rnd.nextInt(16);
                int minute = rnd.nextInt(60);
                LocalDateTime incidentTime = now.minusDays(daysAgo).withHour(hour).withMinute(minute);

                Incident.Status status = defaultStatus;
                if (status == null) {
                    // Si no se especifica, días antiguos son casi todos RESOLVED
                    if (daysAgo >= 7) {
                        status = rnd.nextDouble() < 0.88 ? Incident.Status.RESOLVED : Incident.Status.IN_PROGRESS;
                    } else if (daysAgo >= 2) {
                        status = rnd.nextDouble() < 0.75 ? Incident.Status.RESOLVED : Incident.Status.IN_PROGRESS;
                    } else if (daysAgo == 1) {
                        status = rnd.nextDouble() < 0.65 ? Incident.Status.RESOLVED : (rnd.nextBoolean() ? Incident.Status.IN_PROGRESS : Incident.Status.PENDING);
                    } else { // Hoy
                        status = rnd.nextDouble() < 0.35 ? Incident.Status.RESOLVED : (rnd.nextBoolean() ? Incident.Status.IN_PROGRESS : Incident.Status.PENDING);
                    }
                }

                String fullDesc = tmpl.descPrefix + " en " + loc.sector;
                String fullLocation = loc.place + ", " + loc.sector;

                Incident inc = new Incident(
                        tmpl.type,
                        fullDesc,
                        fullLocation,
                        loc.lat + (rnd.nextDouble() - 0.5) * 0.002, // Pequeña variación GPS
                        loc.lon + (rnd.nextDouble() - 0.5) * 0.002,
                        reporter,
                        tmpl.prio
                );
                inc.setZoneId(loc.zoneId);
                inc.setStatus(status);
                inc.setCreatedAt(incidentTime);
                inc.setUpdatedAt(status == Incident.Status.RESOLVED ? incidentTime.plusHours(2) : incidentTime);
                if (status == Incident.Status.RESOLVED || status == Incident.Status.IN_PROGRESS) {
                    inc.setAssignedTo("oficial_cuadrante4");
                }
                seedList.add(inc);
            }
        };

        // =========================================================================
        // 1. DÍA DE HOY (Día 0) -> 6 incidentes
        // =========================================================================
        generator.generate(0, 6, null);

        // =========================================================================
        // 2. ÚLTIMOS 6 DÍAS DE LA SEMANA ACTUAL (Días 1 a 6) -> 70 incidentes
        // =========================================================================
        generator.generate(1, 9, null);  // Ayer (Domingo) -> 9
        generator.generate(2, 14, null); // Hace 2 días (Sábado) -> 14
        generator.generate(3, 22, null); // Hace 3 días (Viernes - PICO SEMANAL) -> 22
        generator.generate(4, 11, null); // Hace 4 días (Jueves) -> 11
        generator.generate(5, 8, null);  // Hace 5 días (Miércoles) -> 8
        generator.generate(6, 6, null);  // Hace 6 días (Martes) -> 6
        // Total semana: 6 + 9 + 14 + 22 + 11 + 8 + 6 = 76 incidentes

        // =========================================================================
        // 3. SEMANAS ANTERIORES DEL MES ACTUAL (Días 7 a 29) -> 45 incidentes
        // =========================================================================
        for (int day = 7; day <= 29; day += 2) {
            generator.generate(day, 3 + rnd.nextInt(3), Incident.Status.RESOLVED);
        }
        // Total mes: 76 + 45 = ~121 incidentes

        // =========================================================================
        // 4. MES ANTERIOR (Hace 30 a 60 días) -> 35 incidentes
        // =========================================================================
        for (int day = 30; day <= 58; day += 3) {
            generator.generate(day, 3 + rnd.nextInt(3), Incident.Status.RESOLVED);
        }

        // =========================================================================
        // 5. HACE 2 MESES (Hace 60 a 90 días) -> 25 incidentes
        // =========================================================================
        for (int day = 60; day <= 88; day += 4) {
            generator.generate(day, 2 + rnd.nextInt(3), Incident.Status.RESOLVED);
        }

        // Guardar todos los incidentes en lote en MongoDB Atlas
        incidentRepository.saveAll(seedList);
        log.info("✓ Siembra masiva completada: {} incidentes georreferenciados insertados en MongoDB Atlas a lo largo de 90 días.", seedList.size());
        return seedList.size();
    }

    @FunctionalInterface
    interface RunnableGenerator {
        void generate(int daysAgo, int count, Incident.Status defaultStatus);
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
