package Com.Backend.CartagenaSegura.Controller;

import Com.Backend.CartagenaSegura.Dto.SharedDto.ApiResponse;
import Com.Backend.CartagenaSegura.Model.LogEntry;
import Com.Backend.CartagenaSegura.Service.LogService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.List;

@RestController
@RequestMapping("/api/Logs")
@PreAuthorize("hasRole('ADMIN')")
@Tag(name = "Logs (Admin)", description = "**Solo ADMIN**. Auditoría completa de acciones en el sistema.")
@SecurityRequirement(name = "bearerAuth")
public class LogController {

    private final LogService logService;

    public LogController(LogService logService) {
        this.logService = logService;
    }

    @GetMapping
    @Operation(summary = "Todos los logs", description = "Retorna el historial completo de acciones del sistema.")
    public ResponseEntity<ApiResponse<List<LogEntry>>> getAll() {
        return ResponseEntity.ok(ApiResponse.ok("OK", logService.getAllLogs()));
    }

    @GetMapping("/User/{username}")
    @Operation(summary = "Logs por usuario")
    public ResponseEntity<ApiResponse<List<LogEntry>>> getByUser(
            @Parameter(description = "Username del usuario", example = "juanperez")
            @PathVariable String username) {
        return ResponseEntity.ok(ApiResponse.ok("OK", logService.getLogsByUser(username)));
    }

    @GetMapping("/Level/{level}")
    @Operation(
            summary = "Logs por nivel de severidad",
            description = "Niveles disponibles: `INFO`, `WARN`, `ERROR`"
    )
    public ResponseEntity<ApiResponse<List<LogEntry>>> getByLevel(
            @Parameter(description = "Nivel del log", example = "ERROR")
            @PathVariable LogEntry.LogLevel level) {
        return ResponseEntity.ok(ApiResponse.ok("OK", logService.getLogsByLevel(level)));
    }

    @GetMapping("/Range")
    @Operation(
            summary = "Logs por rango de fechas",
            description = "Formato ISO: `2024-01-15T00:00:00`"
    )
    public ResponseEntity<ApiResponse<List<LogEntry>>> getByDateRange(
            @Parameter(description = "Fecha inicio", example = "2024-01-01T00:00:00")
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime from,
            @Parameter(description = "Fecha fin", example = "2024-12-31T23:59:59")
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime to) {
        return ResponseEntity.ok(ApiResponse.ok("OK", logService.getLogsByDateRange(from, to)));
    }

    @GetMapping("/Entity/{type}/{id}")
    @Operation(
            summary = "Logs por entidad",
            description = "Rastrea todos los cambios sobre un objeto específico. Ej: `type=Incident`, `id=64abc123`"
    )
    public ResponseEntity<ApiResponse<List<LogEntry>>> getByEntity(
            @Parameter(description = "Tipo de entidad", example = "Incident") @PathVariable String type,
            @Parameter(description = "ID del objeto", example = "64abc1234567890def") @PathVariable String id) {
        return ResponseEntity.ok(ApiResponse.ok("OK", logService.getLogsByEntity(type, id)));
    }
}
