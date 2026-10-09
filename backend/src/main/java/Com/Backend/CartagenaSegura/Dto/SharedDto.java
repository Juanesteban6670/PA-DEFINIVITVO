package Com.Backend.CartagenaSegura.Dto;

import Com.Backend.CartagenaSegura.Model.Notification;
import Com.Backend.CartagenaSegura.Model.Zone;
import java.time.LocalDateTime;

public class SharedDto {

    // ===== COMMENT =====
    public record CreateCommentRequest(String content, boolean isInternal) {}

    public record CommentResponse(
            String id,
            String incidentId,
            String userId,
            String username,
            String content,
            boolean isInternal,
            LocalDateTime createdAt
    ) {}

    // ===== NOTIFICATION =====
    public record NotificationResponse(
            String id,
            String title,
            String message,
            Notification.NotificationType type,
            String relatedEntityId,
            boolean read,
            LocalDateTime createdAt
    ) {}

    // ===== ZONE =====
    public record CreateZoneRequest(
            String name,
            String description,
            Double centerLatitude,
            Double centerLongitude
    ) {}

    public record ZoneResponse(
            String id,
            String name,
            String description,
            Zone.RiskLevel riskLevel,
            Double centerLatitude,
            Double centerLongitude,
            int totalIncidents,
            int pendingIncidents,
            int resolvedIncidents,
            boolean active
    ) {}

    // ===== GENERIC API RESPONSE =====
    public record ApiResponse<T>(boolean success, String message, T data) {
        public static <T> ApiResponse<T> ok(String message, T data) {
            return new ApiResponse<>(true, message, data);
        }
        public static <T> ApiResponse<T> error(String message) {
            return new ApiResponse<>(false, message, null);
        }
    }
}
