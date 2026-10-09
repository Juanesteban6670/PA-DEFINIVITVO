package Com.Backend.CartagenaSegura.Controller;

import Com.Backend.CartagenaSegura.Dto.SharedDto.*;
import Com.Backend.CartagenaSegura.Model.Zone;
import Com.Backend.CartagenaSegura.Service.ZoneService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.ExampleObject;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/Zones")
@Tag(name = "Zonas", description = "Gestión de zonas geográficas de Cartagena con niveles de riesgo")
@SecurityRequirement(name = "bearerAuth")
public class ZoneController {

    private final ZoneService zoneService;

    public ZoneController(ZoneService zoneService) {
        this.zoneService = zoneService;
    }

    @PostMapping
    @PreAuthorize("hasRole('ADMIN')")
    @Operation(summary = "Crear zona", description = "**Solo ADMIN**. Registra una nueva zona geográfica.")
    @io.swagger.v3.oas.annotations.parameters.RequestBody(
            content = @Content(examples = @ExampleObject(value = """
            {
              "name": "Getsemaní",
              "description": "Barrio histórico y turístico",
              "centerLatitude": 10.4224,
              "centerLongitude": -75.5531
            }
        """))
    )
    public ResponseEntity<ApiResponse<Zone>> create(
            @RequestBody CreateZoneRequest request,
            @AuthenticationPrincipal UserDetails userDetails) {
        return ResponseEntity.ok(ApiResponse.ok("Zona creada", zoneService.create(request, userDetails.getUsername())));
    }

    @GetMapping
    @Operation(summary = "Listar zonas activas", description = "Retorna todas las zonas activas con sus estadísticas de incidentes.")
    public ResponseEntity<ApiResponse<List<Zone>>> getAll() {
        return ResponseEntity.ok(ApiResponse.ok("OK", zoneService.getAll()));
    }

    @GetMapping("/{id}")
    @Operation(summary = "Obtener zona por ID")
    public ResponseEntity<ApiResponse<Zone>> getById(
            @Parameter(description = "ID de la zona", example = "64abc1234567890def")
            @PathVariable String id) {
        return ResponseEntity.ok(ApiResponse.ok("OK", zoneService.getById(id)));
    }

    @GetMapping("/Risk/{level}")
    @Operation(
            summary = "Filtrar por nivel de riesgo",
            description = "Valores posibles: `LOW`, `MODERATE`, `HIGH`, `CRITICAL`"
    )
    public ResponseEntity<ApiResponse<List<Zone>>> getByRisk(
            @Parameter(description = "Nivel de riesgo", example = "HIGH")
            @PathVariable Zone.RiskLevel level) {
        return ResponseEntity.ok(ApiResponse.ok("OK", zoneService.getByRiskLevel(level)));
    }

    @PatchMapping("/{id}/Risk")
    @PreAuthorize("hasRole('ADMIN')")
    @Operation(summary = "Actualizar nivel de riesgo", description = "**Solo ADMIN**. Modifica el nivel de riesgo de una zona.")
    public ResponseEntity<ApiResponse<Zone>> updateRisk(
            @PathVariable String id,
            @Parameter(description = "Nuevo nivel de riesgo", example = "CRITICAL")
            @RequestParam Zone.RiskLevel riskLevel,
            @AuthenticationPrincipal UserDetails userDetails) {
        return ResponseEntity.ok(ApiResponse.ok("Riesgo actualizado",
                zoneService.updateRiskLevel(id, riskLevel, userDetails.getUsername())));
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    @Operation(summary = "Desactivar zona", description = "**Solo ADMIN**. Desactiva una zona (soft delete).")
    public ResponseEntity<ApiResponse<Void>> deactivate(
            @PathVariable String id,
            @AuthenticationPrincipal UserDetails userDetails) {
        zoneService.deactivate(id, userDetails.getUsername());
        return ResponseEntity.ok(ApiResponse.ok("Zona desactivada", null));
    }
}
