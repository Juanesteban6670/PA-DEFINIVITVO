package Com.Backend.CartagenaSegura.Service;

import Com.Backend.CartagenaSegura.Model.EmergencyContact;
import Com.Backend.CartagenaSegura.Repository.EmergencyContactRepository;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class EmergencyContactService {

    private final EmergencyContactRepository repository;
    private final LogService logService;

    public EmergencyContactService(EmergencyContactRepository repository, LogService logService) {
        this.repository = repository;
        this.logService = logService;
    }

    public EmergencyContact create(EmergencyContact contact, String createdBy) {
        EmergencyContact saved = repository.save(contact);
        logService.log("CREATE_EMERGENCY_CONTACT", createdBy,
                "Contacto creado: " + contact.getName(), "EmergencyContact", String.valueOf(saved.getId()));
        return saved;
    }

    public List<EmergencyContact> getAll() {
        return repository.findByActiveTrue();
    }

    public List<EmergencyContact> getByZone(String zone) {
        return repository.findByZoneAndActiveTrue(zone);
    }

    public List<EmergencyContact> getByType(EmergencyContact.ContactType type) {
        return repository.findByType(type);
    }

    public EmergencyContact getById(Long id) {
        return repository.findById(id)
                .orElseThrow(() -> new RuntimeException("Contacto no encontrado: " + id));
    }

    public EmergencyContact update(Long id, EmergencyContact updated, String updatedBy) {
        EmergencyContact existing = getById(id);
        existing.setName(updated.getName());
        existing.setPhone(updated.getPhone());
        existing.setAlternativePhone(updated.getAlternativePhone());
        existing.setType(updated.getType());
        existing.setZone(updated.getZone());
        existing.setAddress(updated.getAddress());
        existing.setNotes(updated.getNotes());
        EmergencyContact saved = repository.save(existing);
        logService.log("UPDATE_EMERGENCY_CONTACT", updatedBy,
                "Contacto actualizado: " + updated.getName(), "EmergencyContact", String.valueOf(id));
        return saved;
    }

    public void deactivate(Long id, String deactivatedBy) {
        EmergencyContact contact = getById(id);
        contact.setActive(false);
        repository.save(contact);
        logService.log("DEACTIVATE_EMERGENCY_CONTACT", deactivatedBy,
                "Contacto desactivado: " + contact.getName(), "EmergencyContact", String.valueOf(id));
    }
}
