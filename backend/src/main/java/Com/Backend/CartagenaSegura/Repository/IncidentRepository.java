package Com.Backend.CartagenaSegura.Repository;

import Com.Backend.CartagenaSegura.Model.Incident;
import org.springframework.data.mongodb.repository.MongoRepository;
import org.springframework.data.mongodb.repository.Query;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface IncidentRepository extends MongoRepository<Incident, String> {

    List<Incident> findByStatus(Incident.Status status);
    List<Incident> findByPriority(Incident.Priority priority);
    List<Incident> findByReportedBy(String reportedBy);
    List<Incident> findByZoneId(String zoneId);
    List<Incident> findByAssignedTo(String assignedTo);
    List<Incident> findByType(String type);

    List<Incident> findByStatusAndPriority(Incident.Status status, Incident.Priority priority);
    List<Incident> findByZoneIdAndStatus(String zoneId, Incident.Status status);

    List<Incident> findByCreatedAtBetween(LocalDateTime from, LocalDateTime to);
    List<Incident> findByZoneIdAndCreatedAtBetween(String zoneId, LocalDateTime from, LocalDateTime to);

    long countByStatus(Incident.Status status);
    long countByZoneId(String zoneId);
    long countByZoneIdAndStatus(String zoneId, Incident.Status status);

    // Buscar incidentes cercanos por coordenadas (radio aproximado)
    @Query("{ 'latitude': { $gte: ?0, $lte: ?1 }, 'longitude': { $gte: ?2, $lte: ?3 } }")
    List<Incident> findByLocationArea(double minLat, double maxLat, double minLng, double maxLng);
}
