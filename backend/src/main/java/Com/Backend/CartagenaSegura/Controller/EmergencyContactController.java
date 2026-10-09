package Com.Backend.CartagenaSegura.Controller;

import Com.Backend.CartagenaSegura.Dto.SharedDto.ApiResponse;
import Com.Backend.CartagenaSegura.Model.EmergencyContact;
import Com.Backend.CartagenaSegura.Service.EmergencyContactService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.ExampleObject;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.security.SecurityRequirements;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/EmergencyContacts")
@Tag(name = "Contactos de Emergencia", description = "Directorio de entidades de respuesta: Policía, Bomberos, Guardacostas, etc.")
public class EmergencyContactController {

    private final EmergencyContactService service;

    public EmergencyContactController(EmergencyContactService service) {
        this.service = service;
    }

    @GetMapping
    @SecurityRequirements // Público
    @Operation(summary = "Listar contactos activos", description = "**Público** - No requiere autenticación. Retorna todos los contactos de emergencia activos.")
    public ResponseEntity<ApiResponse<List<EmergencyContact>>> getAll() {
        return ResponseEntity.ok(ApiResponse.ok("OK", service.getAll()));
    }

    @GetMapping("/Zone/{zone}")
    @SecurityRequirements
    @Operation(summary = "Contactos por zona", description = "**Público**. Filtra contactos por nombre de zona. Ej: `Bocagrande`, `Getsemaní`")
    public ResponseEntity<ApiResponse<List<EmergencyContact>>> getByZone(
            @Parameter(description = "Nombre de la zona", example = "Bocagrande") @PathVariable String zone) {
        return ResponseEntity.ok(ApiResponse.ok("OK", service.getByZone(zone)));
    }

    @GetMapping("/Type/{type}")
    @SecurityRequirements
    @Operation(
            summary = "Contactos por tipo",
            description = "**Público**. Tipos disponibles: `POLICE`, `FIRE_STATION`, `CIVIL_DEFENSE`, `HOSPITAL`, `AMBULANCE`, `COAST_GUARD`, `MUNICIPALITY`, `OTHER`"
    )
    public ResponseEntity<ApiResponse<List<EmergencyContact>>> getByType(
            @Parameter(description = "Tipo de entidad", example = "POLICE") @PathVariable EmergencyContact.ContactType type) {
        return ResponseEntity.ok(ApiResponse.ok("OK", service.getByType(type)));
    }

    @GetMapping("/{id}")
    @SecurityRequirements
    @Operation(summary = "Obtener contacto por ID")
    public ResponseEntity<ApiResponse<EmergencyContact>> getById(@PathVariable Long id) {
        return ResponseEntity.ok(ApiResponse.ok("OK", service.getById(id)));
    }

    @PostMapping
    @PreAuthorize("hasRole('ADMIN')")
    @SecurityRequirement(name = "bearerAuth")
    @Operation(summary = "Crear contacto", description = "**Solo ADMIN**.")
    @io.swagger.v3.oas.annotations.parameters.RequestBody(
            content = @Content(examples = @ExampleObject(value = """
            {
              "name": "Policía Nacional - Bocagrande",
              "phone": "6047890000",
              "alternativePhone": "123",
              "type": "POLICE",
              "zone": "Bocagrande",
              "address": "Cra 1 con Calle 8",
              "notes": "Disponible 24/7"
            }
        """))
    )
    public ResponseEntity<ApiResponse<EmergencyContact>> create(
            @RequestBody EmergencyContact contact,
            @AuthenticationPrincipal UserDetails userDetails) {
        return ResponseEntity.ok(ApiResponse.ok("Contacto creado",
                service.create(contact, userDetails.getUsername())));
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    @SecurityRequirement(name = "bearerAuth")
    @Operation(summary = "Actualizar contacto", description = "**Solo ADMIN**.")
    public ResponseEntity<ApiResponse<EmergencyContact>> update(
            @PathVariable Long id,
            @RequestBody EmergencyContact contact,
            @AuthenticationPrincipal UserDetails userDetails) {
        return ResponseEntity.ok(ApiResponse.ok("Contacto actualizado",
                service.update(id, contact, userDetails.getUsername())));
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    @SecurityRequirement(name = "bearerAuth")
    @Operation(summary = "Desactivar contacto", description = "**Solo ADMIN**. Soft delete.")
    public ResponseEntity<ApiResponse<Void>> deactivate(
            @PathVariable Long id,
            @AuthenticationPrincipal UserDetails userDetails) {
        service.deactivate(id, userDetails.getUsername());
        return ResponseEntity.ok(ApiResponse.ok("Contacto desactivado", null));
    }
}
