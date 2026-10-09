package Com.Backend.CartagenaSegura.Model;

import jakarta.persistence.*;

@Entity
@Table(name = "emergency_contacts")
public class EmergencyContact {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String name;             // Ej: "Policía Nacional - Bocagrande"

    private String phone;            // Número de contacto

    private String alternativePhone; // Número alternativo

    private ContactType type;

    private String zone;             // Zona a la que pertenece (nombre o ID)

    private String address;

    private boolean active = true;

    private String notes;            // Información adicional

    public enum ContactType {
        POLICE,          // Policía
        FIRE_STATION,    // Bomberos
        CIVIL_DEFENSE,   // Defensa Civil
        HOSPITAL,        // Hospital / Clínica
        AMBULANCE,       // Ambulancias
        COAST_GUARD,     // Guardacostas (relevante para Cartagena)
        MUNICIPALITY,    // Alcaldía / Entidades distritales
        OTHER
    }

    public EmergencyContact() {}

    public EmergencyContact(String name, String phone, ContactType type, String zone) {
        this.name = name;
        this.phone = phone;
        this.type = type;
        this.zone = zone;
    }

    // Getters y Setters
    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public String getName() { return name; }
    public void setName(String name) { this.name = name; }

    public String getPhone() { return phone; }
    public void setPhone(String phone) { this.phone = phone; }

    public String getAlternativePhone() { return alternativePhone; }
    public void setAlternativePhone(String alternativePhone) { this.alternativePhone = alternativePhone; }

    public ContactType getType() { return type; }
    public void setType(ContactType type) { this.type = type; }

    public String getZone() { return zone; }
    public void setZone(String zone) { this.zone = zone; }

    public String getAddress() { return address; }
    public void setAddress(String address) { this.address = address; }

    public boolean isActive() { return active; }
    public void setActive(boolean active) { this.active = active; }

    public String getNotes() { return notes; }
    public void setNotes(String notes) { this.notes = notes; }
}
