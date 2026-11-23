package Com.Backend.CartagenaSegura.Service;

import Com.Backend.CartagenaSegura.Model.Incident;
import Com.Backend.CartagenaSegura.Model.Notification;
import Com.Backend.CartagenaSegura.Model.User;
import Com.Backend.CartagenaSegura.Repository.NotificationRepository;
import Com.Backend.CartagenaSegura.Repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Service;
import org.springframework.http.HttpStatus;
import org.springframework.web.server.ResponseStatusException;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Service
public class NotificationService {

    private final NotificationRepository notificationRepository;
    private final UserRepository userRepository;
    private final SimpMessagingTemplate messagingTemplate;

    public NotificationService(
            NotificationRepository notificationRepository,
            UserRepository userRepository,
            @Autowired(required = false) SimpMessagingTemplate messagingTemplate) {
        this.notificationRepository = notificationRepository;
        this.userRepository = userRepository;
        this.messagingTemplate = messagingTemplate;
    }

    public void notifyUser(String userId, String title, String message,
                           Notification.NotificationType type,
                           String relatedEntityId, String relatedEntityType) {
        Notification notification = new Notification(
                userId, title, message, type, relatedEntityId, relatedEntityType
        );
        notificationRepository.save(notification);
    }

    public void notifyAdmins(String title, String message, Incident incident, String reportedBy) {
        try {
            List<User> admins = userRepository.findAllAdminsAndOfficers();
            for (User admin : admins) {
                Notification notification = new Notification(
                        admin.getUsername(),
                        title,
                        message,
                        Notification.NotificationType.INCIDENT_CREATED,
                        incident.getId(),
                        "Incident"
                );
                notification.setCategory(incident.getType() != null ? incident.getType() : "Seguridad");
                notification.setLocation(incident.getLocation() != null ? incident.getLocation() : "Cartagena");
                notification.setReportedBy(reportedBy != null ? reportedBy : "Ciudadano");
                notification.setHasPhotos(incident.getImageUrls() != null && !incident.getImageUrls().isEmpty());
                notification.setIncidentStatus(incident.getStatus() != null ? incident.getStatus().name() : "PENDING");
                notificationRepository.save(notification);
            }

            if (messagingTemplate != null) {
                Map<String, Object> payload = new HashMap<>();
                payload.put("title", title);
                payload.put("message", "Hay novedades en los reportes de Cartagena.");
                payload.put("category", incident.getType());
                payload.put("location", "Cartagena");
                payload.put("incidentStatus", incident.getStatus() != null ? incident.getStatus().name() : "PENDING");
                payload.put("incidentId", incident.getId());
                payload.put("timestamp", System.currentTimeMillis());

                messagingTemplate.convertAndSend("/topic/admin/notifications", payload);
                messagingTemplate.convertAndSend("/topic/notifications", payload);
            }
        } catch (Exception ignored) {}
    }

    public List<Notification> getByUser(String userId) {
        return notificationRepository.findByUserIdOrderByCreatedAtDesc(userId);
    }

    public List<Notification> getUnreadByUser(String userId) {
        return notificationRepository.findByUserIdAndReadFalse(userId);
    }

    public long countUnread(String userId) {
        return notificationRepository.countByUserIdAndReadFalse(userId);
    }

    public Notification markAsRead(String notificationId, String userId) {
        Notification notification = notificationRepository.findByIdAndUserId(notificationId, userId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Notificación no encontrada"));
        notification.setRead(true);
        notification.setReadAt(LocalDateTime.now());
        return notificationRepository.save(notification);
    }

    public void markAllAsRead(String userId) {
        List<Notification> unread = notificationRepository.findByUserIdAndReadFalse(userId);
        unread.forEach(n -> {
            n.setRead(true);
            n.setReadAt(LocalDateTime.now());
        });
        notificationRepository.saveAll(unread);
    }

    public void delete(String notificationId, String userId) {
        Notification notification = notificationRepository.findByIdAndUserId(notificationId, userId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Notificación no encontrada"));
        notificationRepository.delete(notification);
    }
}
