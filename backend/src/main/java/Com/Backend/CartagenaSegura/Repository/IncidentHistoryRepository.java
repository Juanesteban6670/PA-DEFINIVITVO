package Com.Backend.CartagenaSegura.Repository;

import Com.Backend.CartagenaSegura.Model.IncidentHistory;
import org.springframework.data.mongodb.repository.MongoRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface IncidentHistoryRepository extends MongoRepository<IncidentHistory, String> {
    List<IncidentHistory> findByIncidentIdOrderByChangedAtDesc(String incidentId);
    List<IncidentHistory> findByChangedBy(String changedBy);
}

