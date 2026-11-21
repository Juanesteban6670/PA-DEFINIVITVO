package Com.Backend.CartagenaSegura.Controller;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/System")
@Tag(name = "Sistema", description = "Información del sistema, versiones y estado del servicio")
public class SystemController {

    @GetMapping("/Version")
    @Operation(summary = "Verificar versión de la aplicación", description = "Retorna la última versión disponible, requerimientos y URL de actualización.")
    public ResponseEntity<Map<String, Object>> getVersion() {
        Map<String, Object> versionInfo = new HashMap<>();
        versionInfo.put("latestVersion", "1.2.0");
        versionInfo.put("minimumRequiredVersion", "1.0.0");
        versionInfo.put("forceUpdate", false);
        versionInfo.put("releaseNotes", "Sincronización en segundo plano, refresco dinámico y mejoras de estabilidad.");
        versionInfo.put("storeUrlAndroid", "https://play.google.com/store/apps/details?id=com.cartagenasegura");
        versionInfo.put("storeUrlIos", "https://apps.apple.com/app/cartagena-segura/id123456789");
        return ResponseEntity.ok(versionInfo);
    }

    @GetMapping("/Health")
    @Operation(summary = "Chequeo de salud del servicio")
    public ResponseEntity<Map<String, String>> getHealth() {
        Map<String, String> status = new HashMap<>();
        status.put("status", "UP");
        status.put("service", "Cartagena Segura API");
        return ResponseEntity.ok(status);
    }
}
