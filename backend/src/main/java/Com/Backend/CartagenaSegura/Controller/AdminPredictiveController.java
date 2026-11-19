package Com.Backend.CartagenaSegura.Controller;

import Com.Backend.CartagenaSegura.Dto.PredictiveDto.*;
import Com.Backend.CartagenaSegura.Dto.SharedDto.ApiResponse;
import Com.Backend.CartagenaSegura.Service.PredictiveNeuralNetworkService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/Admin/Predictive")
@Tag(name = "Modelo Predictivo e IA", description = "Inferencia de red neuronal y minería de datos en tiempo real exclusiva para Administradores")
@SecurityRequirement(name = "bearerAuth")
@PreAuthorize("hasRole('ADMIN')")
public class AdminPredictiveController {

    private final PredictiveNeuralNetworkService predictiveService;

    public AdminPredictiveController(PredictiveNeuralNetworkService predictiveService) {
        this.predictiveService = predictiveService;
    }

    @GetMapping("/RiskForecast")
    @Operation(summary = "Pronóstico predictivo distrital a 12 horas",
            description = "Ejecuta minería de datos sobre incidentes reales y corre la inferencia de la Red Neuronal para predecir hotspots y niveles de riesgo por sector.")
    public ResponseEntity<ApiResponse<RiskForecastResponse>> getRiskForecast() {
        RiskForecastResponse forecast = predictiveService.generateForecast();
        return ResponseEntity.ok(ApiResponse.ok("Pronóstico predictivo generado con éxito", forecast));
    }

    @PostMapping("/Simulate")
    @Operation(summary = "Simular escenario táctico",
            description = "Permite al administrador variar variables operativas (aglomeración, clima, hora) y obtener la inferencia de la red neuronal en tiempo real.")
    public ResponseEntity<ApiResponse<SimulationResponse>> simulateScenario(@RequestBody SimulationRequest request) {
        SimulationResponse response = predictiveService.simulate(request);
        return ResponseEntity.ok(ApiResponse.ok("Simulación completada", response));
    }

    @GetMapping("/ModelCard")
    @Operation(summary = "Ficha técnica y observabilidad del modelo de IA",
            description = "Devuelve especificaciones de arquitectura, hiperparámetros, métricas de evaluación, matriz de confusión y monitoreo de Data Drift.")
    public ResponseEntity<ApiResponse<AiModelCardResponse>> getModelCard() {
        AiModelCardResponse card = predictiveService.getModelCard();
        return ResponseEntity.ok(ApiResponse.ok("Ficha técnica del modelo obtenida con éxito", card));
    }
}
