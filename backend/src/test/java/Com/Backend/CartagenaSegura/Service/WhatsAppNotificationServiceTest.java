package Com.Backend.CartagenaSegura.Service;

import Com.Backend.CartagenaSegura.Model.Incident;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.net.http.HttpClient;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.*;

@ExtendWith(MockitoExtension.class)
class WhatsAppNotificationServiceTest {

    @Mock
    private HttpClient httpClient;

    private WhatsAppNotificationService service;

    @BeforeEach
    void setUp() {
        service = new WhatsAppNotificationService(httpClient);
    }

    @Test
    void isConfiguredReturnsFalseByDefault() {
        assertFalse(service.isConfigured());
        assertFalse(service.isEnabled());
    }

    @Test
    void sendReturnsErrorWhenPhoneOrKeyIsMissing() {
        Map<String, Object> resultEmptyPhone = service.send("", "Hola", "apikey123");
        assertFalse((Boolean) resultEmptyPhone.get("success"));

        Map<String, Object> resultEmptyKey = service.send("+573001234567", "Hola", "");
        assertFalse((Boolean) resultEmptyKey.get("success"));
    }

    @Test
    void buildIncidentAlertMessageContainsCoreInformation() {
        Incident incident = new Incident();
        incident.setType("ROBO_A_MANO_ARMADA");
        incident.setPriority(Incident.Priority.CRITICAL);
        incident.setLocation("Bocagrande Carrera 3 con Calle 6");
        incident.setLatitude(10.3985);
        incident.setLongitude(-75.5562);
        incident.setDescription("Sujeto armado despoja pertenencias a turista");
        incident.setReportedBy("ciudadano.test");

        String message = service.buildIncidentAlertMessage(incident);

        assertNotNull(message);
        assertTrue(message.contains("ALERTA CARTAGENA SEGURA"));
        assertTrue(message.contains("ROBO_A_MANO_ARMADA"));
        assertTrue(message.contains("CRITICAL"));
        assertTrue(message.contains("Bocagrande"));
        assertTrue(message.contains("https://maps.google.com/?q=10.3985,-75.5562"));
        assertTrue(message.contains("ciudadano.test"));
    }
}
