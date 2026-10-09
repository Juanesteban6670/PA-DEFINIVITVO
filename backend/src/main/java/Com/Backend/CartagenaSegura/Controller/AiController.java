package Com.Backend.CartagenaSegura.Controller;

import Com.Backend.CartagenaSegura.Dto.AiDto;
import Com.Backend.CartagenaSegura.Service.AiService;
import Com.Backend.CartagenaSegura.Service.ChatbotAgent;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.authority.SimpleGrantedAuthority;

@RestController
@RequestMapping("/api/Ai")
@Tag(name = "Inteligencia Artificial", description = "Servicios de IA: Chatbot, clasificación y análisis de datos")
@RequiredArgsConstructor
public class AiController {

    private final AiService aiService;
    private final ChatbotAgent chatbotAgent;

    /**
     * Chatbot conversacional para ciudadanos y agentes (Context-Aware)
     */
    @PostMapping("/Chat")
    public ResponseEntity<AiDto.ChatResponse> chat(@RequestBody AiDto.Request request, Authentication auth) {
        // Detectamos si el usuario tiene el rol ADMIN
        boolean isAdmin = auth != null && auth.getAuthorities().contains(new SimpleGrantedAuthority("ROLE_ADMIN"));
        String userName = auth != null ? auth.getName() : "Ciudadano";
        return ResponseEntity.ok(chatbotAgent.processMessage(request.getMessage(), isAdmin, userName));
    }

    /**
     * Auto-clasificación de incidentes basada en descripción
     */
    @PostMapping("/Classify")
    public ResponseEntity<AiDto.ClassifyResponse> classify(@RequestBody AiDto.Request request) {
        return ResponseEntity.ok(aiService.classify(request.getDescription()));
    }

    /**
     * Generar resumen narrativo del sistema (Solo ADMIN)
     */
    @GetMapping("/Summary")
    public ResponseEntity<AiDto.SummaryResponse> getSummary() {
        return ResponseEntity.ok(aiService.generateSummary());
    }

    /**
     * Análisis estratégico de zonas de riesgo (Solo ADMIN)
     */
    @GetMapping("/Zones/Analysis")
    public ResponseEntity<AiDto.ZoneAnalysis> getZonesAnalysis() {
        return ResponseEntity.ok(aiService.analyzeZones());
    }
}

