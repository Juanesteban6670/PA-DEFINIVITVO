package Com.Backend.CartagenaSegura.Controller;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.beans.factory.annotation.Value;
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

    @Value("${ANDROID_LATEST_VERSION:1.2.3}")
    private String androidLatestVersion;

    @GetMapping("/Version")
    @Operation(summary = "Verificar versión de la aplicación", description = "Retorna la última versión disponible, requerimientos y URL de actualización.")
    public ResponseEntity<Map<String, Object>> getVersion() {
        Map<String, Object> versionInfo = new HashMap<>();
        versionInfo.put("latestVersion", androidLatestVersion);
        versionInfo.put("minimumRequiredVersion", "1.0.0");
        versionInfo.put("forceUpdate", false);
        versionInfo.put("releaseNotes", "Actualiza Cartagena Segura desde el enlace oficial.");
        versionInfo.put("storeUrlAndroid", "https://github.com/Juanesteban6670/PA-DEFINIVITVO/releases/download/app-latest/app-release.apk");
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
