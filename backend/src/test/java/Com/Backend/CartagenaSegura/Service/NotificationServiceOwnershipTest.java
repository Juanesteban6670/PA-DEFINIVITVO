package Com.Backend.CartagenaSegura.Service;

import Com.Backend.CartagenaSegura.Model.Incident;
import Com.Backend.CartagenaSegura.Model.Notification;
import Com.Backend.CartagenaSegura.Repository.NotificationRepository;
import Com.Backend.CartagenaSegura.Repository.UserRepository;
import org.springframework.dao.DuplicateKeyException;
import java.util.HashSet;
import java.util.List;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.HttpStatus;
import org.springframework.web.server.ResponseStatusException;

import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class NotificationServiceOwnershipTest {

    @Mock
    private NotificationRepository notificationRepository;

    @Mock
    private UserRepository userRepository;

    @InjectMocks
    private NotificationService service;

    @Test
    void persistsOneNotificationPerAdminAndIncidentEvenWhenRetried() {
        Incident incident = new Incident("ROBO", "Reporte", "Centro", null, null,
                "citizen", Incident.Priority.HIGH);
        incident.setId("report-id");
        when(userRepository.findAdministratorUsernames()).thenReturn(List.of("admin-1", "admin-2"));
        var deliveredIds = new HashSet<String>();
        when(notificationRepository.insert(any(Notification.class))).thenAnswer(call -> {
            Notification notification = call.getArgument(0);
            assertEquals("report-id", notification.getRelatedEntityId());
            assertEquals(Notification.NotificationType.ADMIN_INCIDENT_CREATED, notification.getType());
            if (!deliveredIds.add(notification.getId())) {
                throw new DuplicateKeyException("already delivered");
            }
            return notification;
        });

        service.notifyAdministratorsOfNewIncident(incident);
        service.notifyAdministratorsOfNewIncident(incident);

        assertEquals(2, deliveredIds.size());
    }

    @Test
    void refusesToMarkAnotherUsersNotificationAsRead() {
        when(notificationRepository.findByIdAndUserId("notification-1", "citizen"))
                .thenReturn(Optional.empty());

        ResponseStatusException error = assertThrows(
                ResponseStatusException.class,
                () -> service.markAsRead("notification-1", "citizen")
        );

        assertEquals(HttpStatus.NOT_FOUND, error.getStatusCode());
        verify(notificationRepository, never()).save(any());
    }

    @Test
    void refusesToDeleteAnotherUsersNotification() {
        when(notificationRepository.findByIdAndUserId("notification-1", "citizen"))
                .thenReturn(Optional.empty());

        ResponseStatusException error = assertThrows(
                ResponseStatusException.class,
                () -> service.delete("notification-1", "citizen")
        );

        assertEquals(HttpStatus.NOT_FOUND, error.getStatusCode());
        verify(notificationRepository, never()).delete(any());
    }
}
