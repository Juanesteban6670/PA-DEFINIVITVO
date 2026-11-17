package Com.Backend.CartagenaSegura.Dto;

import java.util.List;
import java.util.Map;

public class PredictiveDto {

    public record HourlyRiskPrediction(
            String hourLabel,
            double predictedRisk,
            double baselineRisk,
            int estimatedIncidents
    ) {}

    public record SectorRiskPrediction(
            String sector,
            String zoneId,
            double riskScore,
            String riskLevel,
            String mostProbableType,
            int incidentsLast7d,
            int incidentsLast30d,
            double trendRatio,
            String recommendation,
            int suggestedPatrolUnits,
            double latitude,
            double longitude
    ) {}

    public record ModelMetadata(
            String modelName,
            String architecture,
            String version,
            int trainingSamples,
            long lastMiningSyncEpoch,
            double accuracyScore
    ) {}

    public record RiskForecastResponse(
            double districtRiskScore,
            String districtRiskLevel,
            String highestRiskSector,
            String criticalWindow,
            double preventiveEffectiveness,
            ModelMetadata modelMetadata,
            List<HourlyRiskPrediction> hourlyForecast,
            List<SectorRiskPrediction> sectorPredictions
    ) {}

    public record SimulationRequest(
            String sector,
            int hourOfDay,
            boolean isWeekendOrHoliday,
            String crowdLevel,
            String weatherCondition
    ) {}

    public record SimulationResponse(
            String sector,
            int hourOfDay,
            double predictedRiskScore,
            String riskLevel,
            String primaryThreat,
            String tacticalAdvice,
            Map<String, Double> neuralActivations,
            long inferenceLatencyMs
    ) {}
}
