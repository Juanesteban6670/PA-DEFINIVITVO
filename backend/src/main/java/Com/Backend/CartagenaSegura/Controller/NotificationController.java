package Com.Backend.CartagenaSegura.Controller;

import Com.Backend.CartagenaSegura.Dto.SharedDto.ApiResponse;
import Com.Backend.CartagenaSegura.Model.Notification;
import Com.Backend.CartagenaSegura.Service.NotificationService;
import Com.Backend.CartagenaSegura.Service.WhatsAppNotificationService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/Notifications")
@Tag(name = "Notificaciones", description = "Centro de notificaciones del usuario autenticado y canal WhatsApp")
@SecurityRequirement(name = "bearerAuth")
public class NotificationController {

    private final NotificationService notificationService;
    private final WhatsAppNotificationService whatsAppService;

    public NotificationController(NotificationService notificationService,
                                  @org.springframework.beans.factory.annotation.Autowired(required = false)
                                  WhatsAppNotificationService whatsAppService) {
        this.notificationService = notificationService;
        this.whatsAppService = whatsAppService;
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
            @Parameter(description = "ID de la notificación") @PathVariable String id,
            @AuthenticationPrincipal UserDetails userDetails) {
        return ResponseEntity.ok(ApiResponse.ok("Marcada como leída",
                notificationService.markAsRead(id, userDetails.getUsername())));
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
            @Parameter(description = "ID de la notificación") @PathVariable String id,
            @AuthenticationPrincipal UserDetails userDetails) {
        notificationService.delete(id, userDetails.getUsername());
        return ResponseEntity.ok(ApiResponse.ok("Notificación eliminada", null));
    }

    @GetMapping("/WhatsApp/Status")
    @Operation(summary = "Estado del canal WhatsApp", description = "Verifica si el servicio de mensajería CallMeBot / WhatsApp está habilitado y configurado en el servidor.")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getWhatsAppStatus() {
        boolean configured = whatsAppService != null && whatsAppService.isConfigured();
        boolean enabled = whatsAppService != null && whatsAppService.isEnabled();
        String phone = (whatsAppService != null && whatsAppService.getAdminPhone() != null && !whatsAppService.getAdminPhone().isBlank())
                ? maskPhone(whatsAppService.getAdminPhone())
                : "No configurado";

        Map<String, Object> status = Map.of(
                "enabled", enabled,
                "configured", configured,
                "adminPhone", phone,
                "provider", "CallMeBot API"
        );
        return ResponseEntity.ok(ApiResponse.ok("OK", status));
    }

    @PostMapping("/WhatsApp/Test")
    @PreAuthorize("hasRole('ADMIN')")
    @Operation(summary = "Probar envío de WhatsApp", description = "**Requiere rol ADMIN**. Envía un mensaje de prueba a través de CallMeBot. Puede recibir un JSON con `phone`, `apikey` y `message` opcionales.")
    public ResponseEntity<ApiResponse<Map<String, Object>>> testWhatsApp(
            @RequestBody(required = false) Map<String, String> request) {
        if (whatsAppService == null) {
            return ResponseEntity.badRequest().body(ApiResponse.error("Servicio de WhatsApp no instanciado"));
        }

        String phone = request != null ? request.get("phone") : null;
        String apikey = request != null ? request.get("apikey") : null;
        String message = request != null ? request.get("message") : null;

        if (message == null || message.isBlank()) {
            message = "🚨 *PRUEBA CARTAGENA SEGURA*\nEl canal de notificaciones por WhatsApp (CallMeBot) está funcionando correctamente en el servidor.";
        }

        if (phone == null || phone.isBlank()) {
            phone = whatsAppService.getAdminPhone();
        }

        Map<String, Object> result = whatsAppService.send(phone, message, apikey != null && !apikey.isBlank() ? apikey : "");
        boolean success = Boolean.TRUE.equals(result.get("success"));

        if (success) {
            return ResponseEntity.ok(ApiResponse.ok("Mensaje de WhatsApp despachado con éxito", result));
        } else {
            return ResponseEntity.badRequest().body(ApiResponse.error("Fallo al despachar mensaje de WhatsApp", result));
        }
    }

    private String maskPhone(String phone) {
        if (phone == null || phone.length() < 6) return "***";
        return phone.substring(0, 3) + "****" + phone.substring(phone.length() - 3);
    }
}
