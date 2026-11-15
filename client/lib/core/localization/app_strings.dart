import 'package:flutter/widgets.dart';

enum AppLanguage {
  es('es', 'Español', 'CO'),
  en('en', 'English', 'US');

  const AppLanguage(this.code, this.label, this.countryCode);
  final String code;
  final String label;
  final String countryCode;
}

/// Diccionario fuertemente tipado de cadenas y traducciones para Cartagena Segura.
class AppStrings {
  const AppStrings({required this.language});

  final AppLanguage language;

  static const es = AppStrings(language: AppLanguage.es);
  static const en = AppStrings(language: AppLanguage.en);

  static AppStrings ofLanguage(AppLanguage lang) =>
      lang == AppLanguage.en ? en : es;

  bool get isEnglish => language == AppLanguage.en;

  // ==========================================
  // NAVEGACIÓN Y SHELL
  // ==========================================
  String get appTitle => 'Cartagena Segura';
  String get appSubtitle => isEnglish
      ? 'Citizen Safety & Real-Time Geospatial Monitoring'
      : 'Seguridad Ciudadana y Monitoreo Geoespacial';

  String get navHome => isEnglish ? 'Home' : 'Inicio';
  String get navReports => isEnglish ? 'Reports' : 'Reportes';
  String get navMap => isEnglish ? 'Map' : 'Mapa';
  String get navEmergency => isEnglish ? 'Emergency' : 'Emergencias';
  String get navProfile => isEnglish ? 'Profile' : 'Perfil';
  String get navNotifications => isEnglish ? 'Notifications' : 'Notificaciones';
  String get navAdmin => isEnglish ? 'Admin Console' : 'Consola Admin';

  String get greeting => isEnglish ? 'Hello' : 'Hola';
  String get districtBadge => isEnglish
      ? 'Distrito de Cartagena • Public Safety'
      : 'Distrito de Cartagena • Seguridad Pública';

  // ==========================================
  // BOTÓN DE PÁNICO Y EMERGENCIAS
  // ==========================================
  String get sosButton => 'SOS';
  String get sosHoldInstruction => isEnglish
      ? 'Hold for 2 seconds to trigger emergency'
      : 'Mantén presionado 2 segundos para activar';
  String get sosEmergencyCall =>
      isEnglish ? 'Emergency Call 123' : 'Llamada de Emergencia 123';
  String get sosConnectingPolice => isEnglish
      ? 'Connecting immediately to Cartagena Metropolitan Police...'
      : 'Enlazando de inmediato con la Policía Metropolitana de Cartagena...';
  String get sosDirectHelpTitle => isEnglish
      ? 'Immediate Police Assistance'
      : 'Asistencia Policial Inmediata';
  String get emergencyDirectoryTitle => isEnglish
      ? 'District Emergency Directory'
      : 'Directorio de Emergencias Distritales';
  String get callButton => isEnglish ? 'Call' : 'Llamar';

  String get contactPolice123 =>
      isEnglish ? 'National Police (123)' : 'Policía Nacional (123)';
  String get contactPoliceDesc => isEnglish
      ? 'Public safety, patrols and quadrant alerts'
      : 'Seguridad ciudadana, patrullas y cuadrantes';

  String get contactFirefighters =>
      isEnglish ? 'Fire Department (119)' : 'Cuerpo de Bomberos (119)';
  String get contactFirefightersDesc => isEnglish
      ? 'Fires, structural hazards, and rescue operations'
      : 'Incendios, rescate y emergencias estructurales';

  String get contactAmbulance => isEnglish
      ? 'Red Cross / CRUE Ambulance (125)'
      : 'Cruz Roja / Ambulancia CRUE (125)';
  String get contactAmbulanceDesc => isEnglish
      ? 'Urgent medical assistance and first response'
      : 'Atención prehospitalaria y urgencias médicas';

  String get contactCivilDefense =>
      isEnglish ? 'Civil Defense (144)' : 'Defensa Civil (144)';
  String get contactCivilDefenseDesc => isEnglish
      ? 'Floods, weather events, and disaster relief'
      : 'Inundaciones, desastres y auxilio ciudadano';

  String get contactCoastGuard =>
      isEnglish ? 'Navy Coast Guard (146)' : 'Guardacostas Armada (146)';
  String get contactCoastGuardDesc => isEnglish
      ? 'Maritime safety, beach emergencies, and island support'
      : 'Seguridad marítima, emergencias en playas e islas';

  // ==========================================
  // RUTAS SEGURAS (WAZE COMUNITARIO)
  // ==========================================
  String get safeRouteTitle =>
      isEnglish ? 'Safe Route Assistant' : 'Asistente de Rutas Seguras';
  String get safeRouteSubtitle => isEnglish
      ? 'Avoid crime hotspots and high-risk zones'
      : 'Evita focos delictivos y polígonos de riesgo';
  String get searchDestinationHint => isEnglish
      ? 'Where are you going in Cartagena?...'
      : '¿A dónde te diriges en Cartagena?...';
  String get calculateSafeRoute =>
      isEnglish ? 'Calculate Safe Route' : 'Calcular Ruta Segura';
  String get routeSafetyGuaranteed => isEnglish
      ? 'Path optimized for maximum safety over shortest distance'
      : 'Ruta ponderada priorizando seguridad física sobre distancia';
  String get startNavigation =>
      isEnglish ? 'Start Navigation' : 'Iniciar Navegación';
  String get closeRoute => isEnglish ? 'Close Route' : 'Cerrar Ruta';

  // ==========================================
  // REPORTE DE INCIDENTES
  // ==========================================
  String get reportIncidentTitle =>
      isEnglish ? 'Report Incident' : 'Reportar Incidente';
  String get reportIncidentSubtitle => isEnglish
      ? 'Capture GPS location and photo evidence'
      : 'Captura ubicación satelital y evidencia fotográfica';
  String get incidentCategory => isEnglish ? 'Category' : 'Categoría';
  String get incidentTitleLabel => isEnglish ? 'Brief Title' : 'Título breve';
  String get incidentDescLabel =>
      isEnglish ? 'Detailed Description' : 'Descripción detallada';
  String get incidentDescHint => isEnglish
      ? 'Detail what is happening (people, vehicles, circumstances)...'
      : 'Detalla lo ocurrido (personas, vehículos, circunstancias)...';
  String get attachPhotoEvidence =>
      isEnglish ? 'Attach Photo Evidence' : 'Adjuntar Evidencia Fotográfica';
  String get takePhotoCamera => isEnglish ? 'Take Photo' : 'Tomar Foto';
  String get pickFromGallery => isEnglish ? 'Gallery' : 'Galería';
  String get gpsLocationAcquired => isEnglish
      ? 'GPS satellite location fixed'
      : 'Coordenada satelital fijada';
  String get gpsLocationWaiting =>
      isEnglish ? 'Acquiring GPS location...' : 'Obteniendo coordenada GPS...';
  String get submitReportButton =>
      isEnglish ? 'Submit Incident Report' : 'Publicar Reporte Ciudadano';
  String get reportSubmittedSuccess => isEnglish
      ? 'Incident report submitted successfully'
      : 'Reporte ciudadano enviado con éxito';
  String get reportSavedOffline => isEnglish
      ? 'Report saved locally (Offline mode). It will sync automatically when online.'
      : 'Reporte guardado en borrador local. Se enviará automáticamente al reconectar.';

  // Tipos de Incidente
  String get typeTheft => isEnglish ? 'Theft / Robbery' : 'Hurto / Robo';
  String get typeAccident =>
      isEnglish ? 'Traffic Accident' : 'Accidente de Tránsito';
  String get typeDisturbance =>
      isEnglish ? 'Public Brawl / Disturbance' : 'Riña / Alteración del Orden';
  String get typeSuspicious =>
      isEnglish ? 'Suspicious Activity' : 'Actividad Sospechosa';
  String get typeVandalism => isEnglish ? 'Vandalism' : 'Vandalismo';
  String get typeFlooding =>
      isEnglish ? 'Flooding / Weather Hazard' : 'Inundación / Alerta Climática';
  String get typeOther => isEnglish ? 'Other Hazard' : 'Otra Novedad';

  // ==========================================
  // ASISTENTE DE IA (RAG TERRITORIAL)
  // ==========================================
  String get aiAssistantTitle => isEnglish
      ? 'Cartagena AI Safety Assistant'
      : 'Asistente IA de Seguridad Cartagena';
  String get aiAssistantSubtitle => isEnglish
      ? 'Territorial guidance, quadrant info and safe recommendations'
      : 'Guía territorial, cuadrantes policiales y prevención';
  String get aiChatPlaceholder => isEnglish
      ? 'Ask about safety in Getsemaní, Bocagrande, Bazurto...'
      : 'Pregunta sobre seguridad en Getsemaní, Bocagrande, Bazurto...';
  String get aiChatDisclaimer => isEnglish
      ? 'Territorial safety advisor. In immediate danger dial 123.'
      : 'Asistente preventivo distrital. Ante peligro inminente llama al 123.';

  // ==========================================
  // ESTADOS Y SEVERIDAD
  // ==========================================
  String get statusReported => isEnglish ? 'Reported' : 'Reportado';
  String get statusInReview => isEnglish ? 'In Review' : 'En Revisión';
  String get statusAssigned => isEnglish ? 'Assigned' : 'Asignado';
  String get statusInProgress => isEnglish ? 'In Progress' : 'En Proceso';
  String get statusResolved => isEnglish ? 'Resolved' : 'Resuelto';
  String get statusRejected => isEnglish ? 'Rejected' : 'Rechazado';

  String get priorityLow => isEnglish ? 'Low' : 'Baja';
  String get priorityMedium => isEnglish ? 'Medium' : 'Media';
  String get priorityHigh => isEnglish ? 'High' : 'Alta';
  String get priorityCritical => isEnglish ? 'Critical' : 'Crítica';

  // ==========================================
  // AJUSTES, TEMA E IDIOMA
  // ==========================================
  String get settingsTitle => isEnglish ? 'Settings' : 'Ajustes';
  String get languageTitle =>
      isEnglish ? 'Language & Region' : 'Idioma y Región';
  String get languageSubtitle => isEnglish
      ? 'Select English or Spanish for alerts and navigation'
      : 'Selecciona Español o Inglés para interfaz y alertas';
  String get themeTitle =>
      isEnglish ? 'Appearance & Theme' : 'Apariencia y Tema';
  String get themeSubtitle => isEnglish
      ? 'Toggle between Obsidian dark mode and daylight light mode'
      : 'Alterna entre modo oscuro Obsidian y modo claro diurno';
  String get themeSystem => isEnglish ? 'System' : 'Sistema';
  String get themeLight => isEnglish ? 'Light' : 'Claro';
  String get themeDark => isEnglish ? 'Dark' : 'Oscuro';

  String get logoutButton => isEnglish ? 'Sign Out' : 'Cerrar Sesión';
  String get logoutConfirmQuestion => isEnglish
      ? 'Are you sure you want to sign out?'
      : '¿Estás seguro de que deseas cerrar sesión?';
  String get cancel => isEnglish ? 'Cancel' : 'Cancelar';
  String get confirm => isEnglish ? 'Confirm' : 'Confirmar';

  // ==========================================
  // LANDING Y ACCESO PÚBLICO
  // ==========================================
  String get landingHeroTag => isEnglish
      ? '24/7 Citizen & Tourist Safety'
      : 'Seguridad Ciudadana y Turística 24/7';
  String get landingHeroTitle => isEnglish
      ? 'Live Geospatial Protection for Cartagena de Indias'
      : 'Protección Geoespacial en Vivo para Cartagena de Indias';
  String get landingHeroDesc => isEnglish
      ? 'Real-time incident reporting with GPS, verified photo evidence, smart safe routes, and emergency 123 dispatch.'
      : 'Reportes ciudadanos con GPS, evidencias fotográficas certificadas, rutas seguras tipo Waze y auxilio 123 en tiempo real.';
  String get tryAppButton =>
      isEnglish ? 'Open Safety App' : 'Entrar a la Plataforma';
  String get viewLiveMapButton =>
      isEnglish ? 'View Live Map' : 'Ver Mapa en Vivo';
  String get officialDocumentation =>
      isEnglish ? 'API Documentation' : 'Documentación API';

  // Quick helper for categories
  String getCategoryName(String raw) {
    final clean = raw.trim().toUpperCase();
    if (clean.contains('ROBO') ||
        clean.contains('HURTO') ||
        clean.contains('THEFT')) {
      return typeTheft;
    }
    if (clean.contains('ACCIDENT')) return typeAccident;
    if (clean.contains('RINA') ||
        clean.contains('RIÑA') ||
        clean.contains('DISTURB')) {
      return typeDisturbance;
    }
    if (clean.contains('SOSPECH') || clean.contains('SUSPIC')) {
      return typeSuspicious;
    }
    if (clean.contains('VANDAL')) return typeVandalism;
    if (clean.contains('INUND') || clean.contains('FLOOD')) return typeFlooding;
    return raw;
  }
}

/// Extensión para acceder fácilmente a `context.l10n` en cualquier widget
extension AppStringsContext on BuildContext {
  AppStrings get l10n {
    // Si se accede fuera de contexto o sin provider, se retorna español seguro
    return AppStrings.es;
  }
}
