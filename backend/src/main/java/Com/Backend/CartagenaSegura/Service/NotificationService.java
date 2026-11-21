package Com.Backend.CartagenaSegura.Service;

import Com.Backend.CartagenaSegura.Model.Incident;
import Com.Backend.CartagenaSegura.Model.Notification;
import Com.Backend.CartagenaSegura.Repository.UserRepository;
import org.springframework.dao.DuplicateKeyException;
import java.nio.charset.StandardCharsets;
import java.util.UUID;
import Com.Backend.CartagenaSegura.Repository.NotificationRepository;
import org.springframework.stereotype.Service;
import org.springframework.http.HttpStatus;
import org.springframework.web.server.ResponseStatusException;

import java.time.LocalDateTime;
import java.util.List;

@Service
public class NotificationService {

    private final NotificationRepository notificationRepository;

    private final UserRepository userRepository;

    public NotificationService(NotificationRepository notificationRepository, UserRepository userRepository) {
        this.notificationRepository = notificationRepository;
        this.userRepository = userRepository;
    }

    public void notifyAdministratorsOfNewIncident(Incident incident) {
        for (String username : userRepository.findAdministratorUsernames()) {
            Notification notification = new Notification(username, "Nuevo reporte",
                    incident.getType() + " en " + incident.getLocation(),
                    Notification.NotificationType.ADMIN_INCIDENT_CREATED, incident.getId(), "Incident");
            String eventKey = "admin-incident:" + incident.getId() + ":" + username;
            notification.setId(UUID.nameUUIDFromBytes(eventKey.getBytes(StandardCharsets.UTF_8)).toString());
            try {
                notificationRepository.insert(notification);
            } catch (DuplicateKeyException alreadyDelivered) {
                // A concurrent delivery must not reset an existing notification.
            }
        }
    }

    public void notifyUser(String userId, String title, String message,
                           Notification.NotificationType type,
                           String relatedEntityId, String relatedEntityType) {
        Notification notification = new Notification(
                userId, title, message, type, relatedEntityId, relatedEntityType
        );
        notificationRepository.save(notification);
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
