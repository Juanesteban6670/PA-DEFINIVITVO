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
  });

  final String sector;
  final int hourOfDay;
  final double predictedRiskScore;
  final String riskLevel;
  final String primaryThreat;
  final String tacticalAdvice;
  final Map<String, double> neuralActivations;
  final int inferenceLatencyMs;

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
      );
}
