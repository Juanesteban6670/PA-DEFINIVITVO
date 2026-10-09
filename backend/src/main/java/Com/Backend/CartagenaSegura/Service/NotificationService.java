package Com.Backend.CartagenaSegura.Service;

import Com.Backend.CartagenaSegura.Model.Notification;
import Com.Backend.CartagenaSegura.Repository.NotificationRepository;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;

@Service
public class NotificationService {

    private final NotificationRepository notificationRepository;

    public NotificationService(NotificationRepository notificationRepository) {
        this.notificationRepository = notificationRepository;
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

    public Notification markAsRead(String notificationId) {
        Notification notification = notificationRepository.findById(notificationId)
                .orElseThrow(() -> new RuntimeException("Notificación no encontrada"));
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

    public void delete(String notificationId) {
        notificationRepository.deleteById(notificationId);
    }
}
