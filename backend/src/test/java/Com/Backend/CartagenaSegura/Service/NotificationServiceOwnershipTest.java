package Com.Backend.CartagenaSegura.Service;

import Com.Backend.CartagenaSegura.Repository.NotificationRepository;
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

    @InjectMocks
    private NotificationService service;

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
