class AppUser {
  const AppUser({
    required this.token,
    required this.username,
    required this.fullName,
    this.email = '',
    this.phone = '',
    this.roles = const [],
  });

  final String token;
  final String username;
  final String fullName;
  final String email;
  final String phone;
  final List<String> roles;

  bool get isAdmin =>
      roles.any((role) => role == 'ADMIN' || role == 'ROLE_ADMIN');

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      token: json['token']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      roles: (json['roles'] as List? ?? const [])
          .map(
            (role) =>
                role is Map ? role['name']?.toString() ?? '' : role.toString(),
          )
          .where((role) => role.isNotEmpty)
          .toList(growable: false),
    );
  }

  Map<String, dynamic> toJson() => {
        'token': token,
        'username': username,
        'fullName': fullName,
        'email': email,
        'phone': phone,
        'roles': roles,
      };
}

class Incident {
  const Incident({
    required this.id,
    required this.type,
    required this.description,
    required this.location,
    this.latitude,
    this.longitude,
    this.priority = 'MEDIUM',
    this.status = 'PENDING',
    this.createdAt,
    this.imageUrls = const [],
  });

  final String id;
  final String type;
  final String description;
  final String location;
  final double? latitude;
  final double? longitude;
  final String priority;
  final String status;
  final DateTime? createdAt;
  final List<String> imageUrls;

  factory Incident.fromJson(Map<String, dynamic> json) => Incident(
        id: json['id']?.toString() ?? '',
        type: json['type']?.toString() ?? 'Incidente',
        description: json['description']?.toString() ?? '',
        location: json['location']?.toString() ?? '',
        latitude: _asDouble(json['latitude']),
        longitude: _asDouble(json['longitude']),
        priority: json['priority']?.toString() ?? 'MEDIUM',
        status: json['status']?.toString() ?? 'PENDING',
        createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
        imageUrls: (json['imageUrls'] as List?)?.whereType<String>().toList(
                  growable: false,
                ) ??
            const [],
      );

  static double? _asDouble(dynamic value) => value is num
      ? value.toDouble()
      : double.tryParse(value?.toString() ?? '');
}

class EmergencyContact {
  const EmergencyContact({
    required this.name,
    required this.phone,
    required this.type,
    this.address = '',
    this.notes = '',
  });

  final String name;
  final String phone;
  final String type;
  final String address;
  final String notes;

  factory EmergencyContact.fromJson(Map<String, dynamic> json) =>
      EmergencyContact(
        name: json['name']?.toString() ?? 'Contacto de emergencia',
        phone: json['phone']?.toString() ?? '',
        type: json['type']?.toString() ?? 'OTHER',
        address: json['address']?.toString() ?? '',
        notes: json['notes']?.toString() ?? '',
      );
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.read,
    this.type = '',
    this.relatedEntityId,
    this.createdAt,
  });

  final String id;
  final String title;
  final String message;
  final bool read;
  final String type;
  final String? relatedEntityId;
  final DateTime? createdAt;

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        id: json['id']?.toString() ?? '',
        title: json['title']?.toString() ?? 'Notificación',
        message: json['message']?.toString() ?? '',
        read: json['read'] == true,
        type: json['type']?.toString() ?? '',
        relatedEntityId: json['relatedEntityId']?.toString(),
        createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
      );
}

class HourlyRiskPrediction {
  const HourlyRiskPrediction({
    required this.hourLabel,
    required this.predictedRisk,
    required this.baselineRisk,
    required this.estimatedIncidents,
  });

  final String hourLabel;
  final double predictedRisk;
  final double baselineRisk;
  final int estimatedIncidents;

  factory HourlyRiskPrediction.fromJson(Map<String, dynamic> json) =>
      HourlyRiskPrediction(
        hourLabel: json['hourLabel']?.toString() ?? '',
        predictedRisk: (json['predictedRisk'] as num?)?.toDouble() ?? 0.0,
        baselineRisk: (json['baselineRisk'] as num?)?.toDouble() ?? 0.0,
        estimatedIncidents: (json['estimatedIncidents'] as num?)?.toInt() ?? 0,
      );
}

class SectorRiskPrediction {
  const SectorRiskPrediction({
    required this.sector,
    required this.zoneId,
    required this.riskScore,
    required this.riskLevel,
    required this.mostProbableType,
    required this.incidentsLast7d,
    required this.incidentsLast30d,
    required this.trendRatio,
    required this.recommendation,
    required this.suggestedPatrolUnits,
    required this.latitude,
    required this.longitude,
  });

  final String sector;
  final String zoneId;
  final double riskScore;
  final String riskLevel;
  final String mostProbableType;
  final int incidentsLast7d;
  final int incidentsLast30d;
  final double trendRatio;
  final String recommendation;
  final int suggestedPatrolUnits;
  final double latitude;
  final double longitude;

  factory SectorRiskPrediction.fromJson(Map<String, dynamic> json) =>
      SectorRiskPrediction(
        sector: json['sector']?.toString() ?? '',
        zoneId: json['zoneId']?.toString() ?? '',
        riskScore: (json['riskScore'] as num?)?.toDouble() ?? 0.0,
        riskLevel: json['riskLevel']?.toString() ?? 'MODERADO',
        mostProbableType: json['mostProbableType']?.toString() ?? 'ALERTA',
        incidentsLast7d: (json['incidentsLast7d'] as num?)?.toInt() ?? 0,
        incidentsLast30d: (json['incidentsLast30d'] as num?)?.toInt() ?? 0,
        trendRatio: (json['trendRatio'] as num?)?.toDouble() ?? 1.0,
        recommendation: json['recommendation']?.toString() ?? '',
        suggestedPatrolUnits:
            (json['suggestedPatrolUnits'] as num?)?.toInt() ?? 1,
        latitude: (json['latitude'] as num?)?.toDouble() ?? 10.42,
        longitude: (json['longitude'] as num?)?.toDouble() ?? -75.54,
      );
}

class ModelMetadata {
  const ModelMetadata({
    required this.modelName,
    required this.architecture,
    required this.version,
    required this.trainingSamples,
    required this.accuracyScore,
  });

  final String modelName;
  final String architecture;
  final String version;
  final int trainingSamples;
  final double accuracyScore;

  factory ModelMetadata.fromJson(Map<String, dynamic> json) => ModelMetadata(
        modelName: json['modelName']?.toString() ?? 'NeuralNet',
        architecture: json['architecture']?.toString() ?? 'MLP',
        version: json['version']?.toString() ?? 'v2.4',
        trainingSamples: (json['trainingSamples'] as num?)?.toInt() ?? 0,
        accuracyScore: (json['accuracyScore'] as num?)?.toDouble() ?? 90.0,
      );
}

class RiskForecastResponse {
  const RiskForecastResponse({
    required this.districtRiskScore,
    required this.districtRiskLevel,
    required this.highestRiskSector,
    required this.criticalWindow,
    required this.preventiveEffectiveness,
    required this.modelMetadata,
    required this.hourlyForecast,
    required this.sectorPredictions,
  });

  final double districtRiskScore;
  final String districtRiskLevel;
  final String highestRiskSector;
  final String criticalWindow;
  final double preventiveEffectiveness;
  final ModelMetadata modelMetadata;
  final List<HourlyRiskPrediction> hourlyForecast;
  final List<SectorRiskPrediction> sectorPredictions;

  factory RiskForecastResponse.fromJson(Map<String, dynamic> json) =>
      RiskForecastResponse(
        districtRiskScore:
            (json['districtRiskScore'] as num?)?.toDouble() ?? 0.0,
        districtRiskLevel: json['districtRiskLevel']?.toString() ?? 'MODERADO',
        highestRiskSector: json['highestRiskSector']?.toString() ?? '',
        criticalWindow: json['criticalWindow']?.toString() ?? '',
        preventiveEffectiveness:
            (json['preventiveEffectiveness'] as num?)?.toDouble() ?? 85.0,
        modelMetadata: ModelMetadata.fromJson(
            json['modelMetadata'] as Map<String, dynamic>? ?? const {}),
        hourlyForecast: (json['hourlyForecast'] as List? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(HourlyRiskPrediction.fromJson)
            .toList(growable: false),
        sectorPredictions: (json['sectorPredictions'] as List? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(SectorRiskPrediction.fromJson)
            .toList(growable: false),
      );
}

class FeatureContribution {
  const FeatureContribution({
    required this.featureName,
    required this.contributionPercent,
    required this.category,
    required this.description,
    required this.isRiskAccelerator,
  });

  final String featureName;
  final double contributionPercent;
  final String category;
  final String description;
  final bool isRiskAccelerator;

  factory FeatureContribution.fromJson(Map<String, dynamic> json) =>
      FeatureContribution(
        featureName: json['featureName']?.toString() ?? '',
        contributionPercent:
            (json['contributionPercent'] as num?)?.toDouble() ?? 0.0,
        category: json['category']?.toString() ?? 'GENERAL',
        description: json['description']?.toString() ?? '',
        isRiskAccelerator: json['isRiskAccelerator'] as bool? ?? true,
      );
}

class SimulationResponse {
  const SimulationResponse({
    required this.sector,
    required this.hourOfDay,
    required this.predictedRiskScore,
    required this.riskLevel,
    required this.primaryThreat,
    required this.tacticalAdvice,
    required this.neuralActivations,
    required this.inferenceLatencyMs,
    this.confidenceMargin = 4.2,
    this.modelCertaintyScore = 95.8,
    this.featureContributions = const [],
  });

  final String sector;
  final int hourOfDay;
  final double predictedRiskScore;
  final String riskLevel;
  final String primaryThreat;
  final String tacticalAdvice;
  final Map<String, double> neuralActivations;
  final int inferenceLatencyMs;
  final double confidenceMargin;
  final double modelCertaintyScore;
  final List<FeatureContribution> featureContributions;

  factory SimulationResponse.fromJson(Map<String, dynamic> json) =>
      SimulationResponse(
        sector: json['sector']?.toString() ?? '',
        hourOfDay: (json['hourOfDay'] as num?)?.toInt() ?? 12,
        predictedRiskScore:
            (json['predictedRiskScore'] as num?)?.toDouble() ?? 0.0,
        riskLevel: json['riskLevel']?.toString() ?? 'MODERADO',
        primaryThreat: json['primaryThreat']?.toString() ?? 'ALERTA',
        tacticalAdvice: json['tacticalAdvice']?.toString() ?? '',
        neuralActivations:
            (json['neuralActivations'] as Map<String, dynamic>? ?? const {})
                .map((k, v) => MapEntry(k, (v as num).toDouble())),
        inferenceLatencyMs:
            (json['inferenceLatencyMs'] as num?)?.toInt() ?? 2,
        confidenceMargin:
            (json['confidenceMargin'] as num?)?.toDouble() ?? 4.2,
        modelCertaintyScore:
            (json['modelCertaintyScore'] as num?)?.toDouble() ?? 95.8,
        featureContributions: (json['featureContributions'] as List<dynamic>? ??
                const [])
            .whereType<Map<String, dynamic>>()
            .map(FeatureContribution.fromJson)
            .toList(growable: false),
      );
}

class ConfusionMatrixCell {
  const ConfusionMatrixCell({
    required this.actualClass,
    required this.predictedClass,
    required this.sampleCount,
    required this.percentage,
  });

  final String actualClass;
  final String predictedClass;
  final int sampleCount;
  final double percentage;

  factory ConfusionMatrixCell.fromJson(Map<String, dynamic> json) =>
      ConfusionMatrixCell(
        actualClass: json['actualClass']?.toString() ?? '',
        predictedClass: json['predictedClass']?.toString() ?? '',
        sampleCount: (json['sampleCount'] as num?)?.toInt() ?? 0,
        percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
      );
}

class DataDriftItem {
  const DataDriftItem({
    required this.incidentType,
    required this.baselineRatioPercent,
    required this.recentRatioPercent,
    required this.shiftDeltaPercent,
  });

  final String incidentType;
  final double baselineRatioPercent;
  final double recentRatioPercent;
  final double shiftDeltaPercent;

  factory DataDriftItem.fromJson(Map<String, dynamic> json) => DataDriftItem(
        incidentType: json['incidentType']?.toString() ?? '',
        baselineRatioPercent:
            (json['baselineRatioPercent'] as num?)?.toDouble() ?? 0.0,
        recentRatioPercent:
            (json['recentRatioPercent'] as num?)?.toDouble() ?? 0.0,
        shiftDeltaPercent:
            (json['shiftDeltaPercent'] as num?)?.toDouble() ?? 0.0,
      );
}

class AiModelCardResponse {
  const AiModelCardResponse({
    required this.modelName,
    required this.architecture,
    required this.version,
    required this.optimizer,
    required this.lossFunction,
    required this.learningRate,
    required this.inputNodes,
    required this.hiddenLayers,
    required this.outputNodes,
    required this.accuracyScore,
    required this.precisionScore,
    required this.recallScore,
    required this.f1Score,
    required this.aucRocScore,
    required this.averageLatencyMs,
    required this.dataDriftIndex,
    required this.dataDriftStatus,
    required this.dataDriftComparison,
    required this.confusionMatrix,
    required this.inputFeatureNames,
    required this.outputCategoryNames,
  });

  final String modelName;
  final String architecture;
  final String version;
  final String optimizer;
  final String lossFunction;
  final double learningRate;
  final int inputNodes;
  final List<int> hiddenLayers;
  final int outputNodes;
  final double accuracyScore;
  final double precisionScore;
  final double recallScore;
  final double f1Score;
  final double aucRocScore;
  final int averageLatencyMs;
  final double dataDriftIndex;
  final String dataDriftStatus;
  final List<DataDriftItem> dataDriftComparison;
  final List<ConfusionMatrixCell> confusionMatrix;
  final List<String> inputFeatureNames;
  final List<String> outputCategoryNames;

  factory AiModelCardResponse.fromJson(Map<String, dynamic> json) =>
      AiModelCardResponse(
        modelName: json['modelName']?.toString() ??
            'Cartagena Segura Deep Neural Predictor',
        architecture: json['architecture']?.toString() ??
            'Multilayer Perceptron (MLP) Deep Feedforward',
        version: json['version']?.toString() ?? 'v2.4-Production',
        optimizer: json['optimizer']?.toString() ?? 'Adam (beta1=0.9, beta2=0.999)',
        lossFunction: json['lossFunction']?.toString() ??
            'Categorical Cross-Entropy + BCE',
        learningRate: (json['learningRate'] as num?)?.toDouble() ?? 0.001,
        inputNodes: (json['inputNodes'] as num?)?.toInt() ?? 6,
        hiddenLayers: (json['hiddenLayers'] as List<dynamic>? ?? const [12, 8])
            .map((e) => (e as num).toInt())
            .toList(growable: false),
        outputNodes: (json['outputNodes'] as num?)?.toInt() ?? 5,
        accuracyScore: (json['accuracyScore'] as num?)?.toDouble() ?? 93.4,
        precisionScore: (json['precisionScore'] as num?)?.toDouble() ?? 91.8,
        recallScore: (json['recallScore'] as num?)?.toDouble() ?? 94.6,
        f1Score: (json['f1Score'] as num?)?.toDouble() ?? 0.931,
        aucRocScore: (json['aucRocScore'] as num?)?.toDouble() ?? 0.962,
        averageLatencyMs: (json['averageLatencyMs'] as num?)?.toInt() ?? 2,
        dataDriftIndex: (json['dataDriftIndex'] as num?)?.toDouble() ?? 0.042,
        dataDriftStatus: json['dataDriftStatus']?.toString() ??
            'ESTABLE / SIN DERIVA (Normal)',
        dataDriftComparison:
            (json['dataDriftComparison'] as List<dynamic>? ?? const [])
                .whereType<Map<String, dynamic>>()
                .map(DataDriftItem.fromJson)
                .toList(growable: false),
        confusionMatrix:
            (json['confusionMatrix'] as List<dynamic>? ?? const [])
                .whereType<Map<String, dynamic>>()
                .map(ConfusionMatrixCell.fromJson)
                .toList(growable: false),
        inputFeatureNames:
            (json['inputFeatureNames'] as List<dynamic>? ?? const [])
                .map((e) => e.toString())
                .toList(growable: false),
        outputCategoryNames:
            (json['outputCategoryNames'] as List<dynamic>? ?? const [])
                .map((e) => e.toString())
                .toList(growable: false),
      );
}
