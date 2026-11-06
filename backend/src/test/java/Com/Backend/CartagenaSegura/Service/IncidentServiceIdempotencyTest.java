package Com.Backend.CartagenaSegura.Service;

import Com.Backend.CartagenaSegura.Dto.IncidentDto.CreateIncidentRequest;
import Com.Backend.CartagenaSegura.Model.Incident;
import Com.Backend.CartagenaSegura.Repository.IncidentHistoryRepository;
import Com.Backend.CartagenaSegura.Repository.IncidentRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.dao.DuplicateKeyException;

import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertSame;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class IncidentServiceIdempotencyTest {

    @Mock
    private IncidentRepository incidentRepository;
    @Mock
    private IncidentHistoryRepository historyRepository;
    @Mock
    private NotificationService notificationService;
    @Mock
    private ZoneService zoneService;
    @Mock
    private LogService logService;

    private IncidentService service;

    @BeforeEach
    void setUp() {
        service = new IncidentService(
                incidentRepository,
                historyRepository,
                notificationService,
                zoneService,
                logService
        );
    }

    @Test
    void retryWithSameKeyAndPayloadReturnsExistingIncidentWithoutRepeatingSideEffects() {
        CreateIncidentRequest request = request("the-same-key", List.of("https://files.test/a.jpg"));
        Incident existing = incident(request, "citizen-1");
        when(incidentRepository.findByReportedByAndIdempotencyKey("citizen-1", "the-same-key"))
                .thenReturn(Optional.of(existing));

        Incident result = service.create(request, "citizen-1");

        assertSame(existing, result);
        verify(incidentRepository, never()).insert(any(Incident.class));
        verifyNoInteractions(notificationService, zoneService, logService);
    }

    @Test
    void rejectsReuseOfKeyWithDifferentPayload() {
        CreateIncidentRequest original = request("the-same-key", List.of("https://files.test/a.jpg"));
        Incident existing = incident(original, "citizen-1");
        when(incidentRepository.findByReportedByAndIdempotencyKey("citizen-1", "the-same-key"))
                .thenReturn(Optional.of(existing));
        CreateIncidentRequest changed = new CreateIncidentRequest(
                "ROBO", "changed description", "Centro", 10.4, -75.5,
                null, Incident.Priority.HIGH, List.of("https://files.test/a.jpg"), "the-same-key"
        );

        IllegalArgumentException error = assertThrows(
                IllegalArgumentException.class,
                () -> service.create(changed, "citizen-1")
        );

        assertEquals(
                "Esta clave de envío ya se usó con datos distintos; crea un nuevo borrador.",
                error.getMessage()
        );
        verify(incidentRepository, never()).insert(any(Incident.class));
        verifyNoInteractions(notificationService, zoneService, logService);
    }

    @Test
    void newIdempotentReportIsSavedAndNotifiedOnce() {
        CreateIncidentRequest request = request("new-key", List.of());
        when(incidentRepository.findByReportedByAndIdempotencyKey("citizen-1", "new-key"))
                .thenReturn(Optional.empty());
        when(incidentRepository.insert(any(Incident.class)))
                .thenAnswer(invocation -> invocation.getArgument(0));

        Incident result = service.create(request, "citizen-1");

        assertEquals("new-key", result.getIdempotencyKey());
        assertEquals("citizen-1", result.getReportedBy());
        verify(incidentRepository).insert(any(Incident.class));
        verify(notificationService).notifyUser(
                eq("citizen-1"),
                eq("Reporte recibido"),
                anyString(),
                any(),
                eq(result.getId()),
                eq("Incident")
        );
    }

    @Test
    void handlesConcurrentDuplicateInsertWithoutRepeatingNotifications() {
        CreateIncidentRequest request = request("racing-key", List.of());
        Incident existing = incident(request, "citizen-1");
        when(incidentRepository.findByReportedByAndIdempotencyKey("citizen-1", "racing-key"))
                .thenReturn(Optional.empty(), Optional.of(existing));
        when(incidentRepository.insert(any(Incident.class)))
                .thenThrow(new DuplicateKeyException("duplicate id"));

        assertSame(existing, service.create(request, "citizen-1"));

        verify(incidentRepository).insert(any(Incident.class));
        verifyNoInteractions(notificationService, zoneService, logService);
    }

    private static CreateIncidentRequest request(String key, List<String> imageUrls) {
        return new CreateIncidentRequest(
                "ROBO", "descripción", "Centro", 10.4, -75.5,
                null, Incident.Priority.HIGH, imageUrls, key
        );
    }

    private static Incident incident(CreateIncidentRequest request, String owner) {
        Incident existing = new Incident(
                request.type(), request.description(), request.location(),
                request.latitude(), request.longitude(), owner, request.priority()
        );
        existing.setId("existing-id");
        existing.setIdempotencyKey(request.idempotencyKey());
        existing.setImageUrls(request.imageUrls());
        return existing;
    }
}
