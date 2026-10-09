package Com.Backend.CartagenaSegura.Repository;

import Com.Backend.CartagenaSegura.Model.Zone;
import org.springframework.data.mongodb.repository.MongoRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface ZoneRepository extends MongoRepository<Zone, String> {
    List<Zone> findByActiveTrue();
    List<Zone> findByRiskLevel(Zone.RiskLevel riskLevel);
    Optional<Zone> findByName(String name);
    List<Zone> findByRiskLevelAndActiveTrue(Zone.RiskLevel riskLevel);
}
