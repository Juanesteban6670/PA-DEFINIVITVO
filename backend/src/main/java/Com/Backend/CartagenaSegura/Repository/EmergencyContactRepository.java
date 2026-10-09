package Com.Backend.CartagenaSegura.Repository;

import Com.Backend.CartagenaSegura.Model.EmergencyContact;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface EmergencyContactRepository extends JpaRepository<EmergencyContact, Long> {
    List<EmergencyContact> findByActiveTrue();
    List<EmergencyContact> findByZoneAndActiveTrue(String zone);
    List<EmergencyContact> findByType(EmergencyContact.ContactType type);
    List<EmergencyContact> findByZoneAndType(String zone, EmergencyContact.ContactType type);
}
