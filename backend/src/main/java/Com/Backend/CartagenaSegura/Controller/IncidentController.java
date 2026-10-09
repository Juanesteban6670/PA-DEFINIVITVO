package Com.Backend.CartagenaSegura.Controller;

import Com.Backend.CartagenaSegura.Dto.IncidentDto.*;
import Com.Backend.CartagenaSegura.Dto.SharedDto.ApiResponse;
import Com.Backend.CartagenaSegura.Model.Incident;
import Com.Backend.CartagenaSegura.Model.IncidentHistory;
import Com.Backend.CartagenaSegura.Service.IncidentService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.ExampleObject;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/Incidents")
@Tag(name = "Incidentes", description = "Gestión de incidentes de seguridad ciudadana")
@SecurityRequirement(name = "bearerAuth")
public class IncidentController {

    private final IncidentService incidentService;

    public IncidentController(IncidentService incidentService) {
        this.incidentService = incidentService;
    }

    @PostMapping
    @Operation(summary = "Reportar incidente", description = "Crea un nuevo reporte de incidente. El campo `reportedBy` se asigna automáticamente al usuario autenticado.")
    @io.swagger.v3.oas.annotations.parameters.RequestBody(
            content = @Content(examples = @ExampleObject(value = """
            {
              "type": "ROBO",
              "description": "Se observó un robo a mano armada",
              "location": "Carrera 3 con Calle 10, Getsemaní",
              "latitude": 10.4224,
              "longitude": -75.5531,
              "zoneId": "64abc123",
              "priority": "HIGH",
              "imageUrls": []
            }
        """))
    )
    public ResponseEntity<ApiResponse<Incident>> create(
            @RequestBody CreateIncidentRequest request,
            @AuthenticationPrincipal UserDetails userDetails) {
        return ResponseEntity.ok(ApiResponse.ok("Incidente creado",
                incidentService.create(request, userDetails.getUsername())));
    }

    @GetMapping
    @Operation(summary = "Listar todos los incidentes")
    public ResponseEntity<ApiResponse<List<Incident>>> getAll() {
        return ResponseEntity.ok(ApiResponse.ok("OK", incidentService.getAll()));
    }

    @GetMapping("/{id}")
    @Operation(summary = "Obtener incidente por ID")
    @ApiResponses({
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "200", description = "Incidente encontrado"),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "404", description = "Incidente no encontrado")
    })
    public ResponseEntity<ApiResponse<Incident>> getById(
            @Parameter(description = "ID del incidente (MongoDB ObjectId)", example = "64abc1234567890def")
            @PathVariable String id) {
        return ResponseEntity.ok(ApiResponse.ok("OK", incidentService.getById(id)));
    }

    @GetMapping("/My")
    @Operation(summary = "Mis incidentes", description = "Retorna los incidentes reportados por el usuario autenticado.")
    public ResponseEntity<ApiResponse<List<Incident>>> getMine(@AuthenticationPrincipal UserDetails userDetails) {
        return ResponseEntity.ok(ApiResponse.ok("OK", incidentService.getByUser(userDetails.getUsername())));
    }

    @GetMapping("/Status/{status}")
    @Operation(summary = "Filtrar por estado")
    public ResponseEntity<ApiResponse<List<Incident>>> getByStatus(
            @Parameter(description = "Estado del incidente", example = "PENDING")
            @PathVariable Incident.Status status) {
        return ResponseEntity.ok(ApiResponse.ok("OK", incidentService.getByStatus(status)));
    }

    @GetMapping("/Zone/{zoneId}")
    @Operation(summary = "Filtrar por zona")
    public ResponseEntity<ApiResponse<List<Incident>>> getByZone(
            @Parameter(description = "ID de la zona", example = "64abc123")
            @PathVariable String zoneId) {
        return ResponseEntity.ok(ApiResponse.ok("OK", incidentService.getByZone(zoneId)));
    }

    @GetMapping("/Assigned")
    @Operation(summary = "Incidentes asignados a mí", description = "Retorna incidentes asignados al agente autenticado.")
    public ResponseEntity<ApiResponse<List<Incident>>> getAssigned(@AuthenticationPrincipal UserDetails userDetails) {
        return ResponseEntity.ok(ApiResponse.ok("OK", incidentService.getByAssignedTo(userDetails.getUsername())));
    }

    @PatchMapping("/{id}/Status")
    @PreAuthorize("hasRole('ADMIN')")
    @Operation(summary = "Actualizar estado/prioridad", description = "**Solo ADMIN**. Actualiza el estado, prioridad o agente asignado. Genera historial automáticamente.")
    @io.swagger.v3.oas.annotations.parameters.RequestBody(
            content = @Content(examples = @ExampleObject(value = """
            {
              "status": "IN_PROGRESS",
              "priority": "CRITICAL",
              "assignedTo": "agente01",
              "changeReason": "Se asignó patrulla al sector"
            }
        """))
    )
    public ResponseEntity<ApiResponse<Incident>> updateStatus(
            @PathVariable String id,
            @RequestBody UpdateStatusRequest request,
            @AuthenticationPrincipal UserDetails userDetails) {
        return ResponseEntity.ok(ApiResponse.ok("Estado actualizado",
                incidentService.updateStatus(id, request, userDetails.getUsername())));
    }

    @GetMapping("/{id}/History")
    @PreAuthorize("hasRole('ADMIN')")
    @Operation(summary = "Historial de cambios", description = "**Solo ADMIN**. Muestra todos los cambios de estado y prioridad del incidente.")
    public ResponseEntity<ApiResponse<List<IncidentHistory>>> getHistory(@PathVariable String id) {
        return ResponseEntity.ok(ApiResponse.ok("OK", incidentService.getHistory(id)));
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    @Operation(summary = "Eliminar incidente", description = "**Solo ADMIN**. Elimina permanentemente el incidente.")
    @ApiResponses({
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "200", description = "Eliminado exitosamente"),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "403", description = "Sin permisos de ADMIN")
    })
    public ResponseEntity<ApiResponse<Void>> delete(
            @PathVariable String id,
            @AuthenticationPrincipal UserDetails userDetails) {
        incidentService.delete(id, userDetails.getUsername());
        return ResponseEntity.ok(ApiResponse.ok("Incidente eliminado", null));
    }
}
