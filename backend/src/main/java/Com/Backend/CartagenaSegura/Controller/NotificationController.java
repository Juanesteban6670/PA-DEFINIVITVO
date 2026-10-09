package Com.Backend.CartagenaSegura.Controller;

import Com.Backend.CartagenaSegura.Dto.SharedDto.ApiResponse;
import Com.Backend.CartagenaSegura.Model.Notification;
import Com.Backend.CartagenaSegura.Service.NotificationService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/Notifications")
@Tag(name = "Notificaciones", description = "Centro de notificaciones del usuario autenticado")
@SecurityRequirement(name = "bearerAuth")
public class NotificationController {

    private final NotificationService notificationService;

    public NotificationController(NotificationService notificationService) {
        this.notificationService = notificationService;
    }

    @GetMapping
    @Operation(summary = "Mis notificaciones", description = "Todas las notificaciones del usuario, ordenadas por fecha descendente.")
    public ResponseEntity<ApiResponse<List<Notification>>> getMine(@AuthenticationPrincipal UserDetails userDetails) {
        return ResponseEntity.ok(ApiResponse.ok("OK",
                notificationService.getByUser(userDetails.getUsername())));
    }

    @GetMapping("/Unread")
    @Operation(summary = "Notificaciones no leídas")
    public ResponseEntity<ApiResponse<List<Notification>>> getUnread(@AuthenticationPrincipal UserDetails userDetails) {
        return ResponseEntity.ok(ApiResponse.ok("OK",
                notificationService.getUnreadByUser(userDetails.getUsername())));
    }

    @GetMapping("/Unread/Count")
    @Operation(summary = "Contador de no leídas", description = "Útil para mostrar el badge rojo en la campana de notificaciones.")
    public ResponseEntity<ApiResponse<Long>> countUnread(@AuthenticationPrincipal UserDetails userDetails) {
        return ResponseEntity.ok(ApiResponse.ok("OK",
                notificationService.countUnread(userDetails.getUsername())));
    }

    @PatchMapping("/{id}/Read")
    @Operation(summary = "Marcar como leída")
    public ResponseEntity<ApiResponse<Notification>> markAsRead(
            @Parameter(description = "ID de la notificación") @PathVariable String id) {
        return ResponseEntity.ok(ApiResponse.ok("Marcada como leída", notificationService.markAsRead(id)));
    }

    @PatchMapping("/ReadAll")
    @Operation(summary = "Marcar todas como leídas")
    public ResponseEntity<ApiResponse<Void>> markAllAsRead(@AuthenticationPrincipal UserDetails userDetails) {
        notificationService.markAllAsRead(userDetails.getUsername());
        return ResponseEntity.ok(ApiResponse.ok("Todas marcadas como leídas", null));
    }

    @DeleteMapping("/{id}")
    @Operation(summary = "Eliminar notificación")
    public ResponseEntity<ApiResponse<Void>> delete(
            @Parameter(description = "ID de la notificación") @PathVariable String id) {
        notificationService.delete(id);
        return ResponseEntity.ok(ApiResponse.ok("Notificación eliminada", null));
    }
}
