import 'package:flutter/material.dart';

import 'package:cartagena_segura/core/data/session_controller.dart';

import 'app_tour_keys.dart';
import 'app_tour_model.dart';
import 'spotlight_tour_overlay.dart';

class AppTourController {
  AppTourController._();
  static final AppTourController instance = AppTourController._();

  static const _storageKey = 'citizen.tour_completed';

  bool _isActive = false;
  int _currentStepIndex = 0;
  OverlayEntry? _overlayEntry;
  ValueChanged<int>? _onSwitchTab;
  SessionStorage? _storage;

  bool get isActive => _isActive;
  int get currentStepIndex => _currentStepIndex;

  /// Definición de los pasos del tutorial ciudadano
  List<TourStep> get defaultSteps => [
        TourStep(
          id: 'map_zones',
          title: 'Mapa Distrital y Zonas de Riesgo',
          description:
              'Visualiza en tiempo real el nivel de seguridad de los barrios de Cartagena y los incidentes reportados por otros ciudadanos.',
          icon: Icons.map_rounded,
          targetKey: AppTourKeys.navMapKey,
          targetTabIndex: 0,
          preferredPosition: TooltipPosition.top,
          borderRadius: 18,
          padding: 6,
        ),
        TourStep(
          id: 'safe_routes',
          title: 'Rutas Seguras Inteligentes',
          description:
              'Escribe tu destino y trazaremos la ruta óptima esquivando zonas críticas y calles con poca iluminación.',
          icon: Icons.alt_route_rounded,
          targetKey: AppTourKeys.safeRouteKey,
          targetTabIndex: 0,
          preferredPosition: TooltipPosition.bottom,
          borderRadius: 20,
          padding: 8,
        ),
        TourStep(
          id: 'sos_emergencies',
          title: 'Botón de Pánico y SOS 123',
          description:
              'En caso de urgencia médica, atraco o accidente, llama al instante a la Policía (123), CRUE Ambulancias (125) o Tránsito DATT (127).',
          icon: Icons.emergency_rounded,
          targetKey: AppTourKeys.sosButtonKey,
          preferredPosition: TooltipPosition.bottom,
          borderRadius: 16,
          padding: 6,
        ),
        TourStep(
          id: 'citizen_reports',
          title: 'Radicar Reportes Comunitarios',
          description:
              'Reporta hechos delictivos, iluminación deficiente o accidentes con foto y ubicación exacta para proteger a tu comunidad.',
          icon: Icons.campaign_rounded,
          targetKey: AppTourKeys.navReportsKey,
          preferredPosition: TooltipPosition.top,
          borderRadius: 18,
          padding: 6,
        ),
        TourStep(
          id: 'ai_and_glass',
          title: 'Orientador IA & Liquid Glass',
          description:
              'Pregúntale a Cartagena Segura AI qué hacer ante cualquier imprevisto y personaliza la apariencia con el estilo Liquid Glass.',
          icon: Icons.auto_awesome_rounded,
          targetKey: AppTourKeys.aiAssistantKey,
          preferredPosition: TooltipPosition.bottom,
          borderRadius: 18,
          padding: 6,
        ),
      ];

  Future<bool> isTourCompleted(SessionStorage storage) async {
    try {
      final value = await storage.read(_storageKey);
      return value == 'true';
    } catch (_) {
      return false;
    }
  }

  Future<void> markCompleted(SessionStorage storage) async {
    try {
      await storage.write(_storageKey, 'true');
    } catch (_) {}
  }

  Future<void> resetTour(SessionStorage storage) async {
    try {
      await storage.delete(_storageKey);
    } catch (_) {}
  }

  /// Inicia el recorrido interactivo
  Future<void> startTour(
    BuildContext context, {
    required SessionStorage storage,
    bool force = false,
    ValueChanged<int>? onSwitchTab,
  }) async {
    if (_isActive) return;

    _storage = storage;
    _onSwitchTab = onSwitchTab;

    if (!force) {
      final completed = await isTourCompleted(storage);
      if (completed) return;
    }

    if (!context.mounted) return;

    _isActive = true;
    _currentStepIndex = 0;

    _overlayEntry = OverlayEntry(
      builder: (ctx) => SpotlightTourOverlay(
        steps: defaultSteps,
        currentStepIndex: _currentStepIndex,
        onNext: _nextStep,
        onPrev: _prevStep,
        onSkip: _dismissTour,
        onFinish: _finishTour,
      ),
    );

    final overlay = Overlay.of(context);
    overlay.insert(_overlayEntry!);
  }

  void _nextStep() {
    if (!_isActive) return;
    if (_currentStepIndex < defaultSteps.length - 1) {
      _currentStepIndex++;
      final step = defaultSteps[_currentStepIndex];
      if (step.targetTabIndex != null && _onSwitchTab != null) {
        _onSwitchTab!(step.targetTabIndex!);
      }
      _overlayEntry?.markNeedsBuild();
    } else {
      _finishTour();
    }
  }

  void _prevStep() {
    if (!_isActive) return;
    if (_currentStepIndex > 0) {
      _currentStepIndex--;
      final step = defaultSteps[_currentStepIndex];
      if (step.targetTabIndex != null && _onSwitchTab != null) {
        _onSwitchTab!(step.targetTabIndex!);
      }
      _overlayEntry?.markNeedsBuild();
    }
  }

  void _finishTour() {
    if (_storage != null) {
      markCompleted(_storage!);
    }
    _dismissTour();
  }

  void _dismissTour() {
    _isActive = false;
    _currentStepIndex = 0;
    _overlayEntry?.remove();
    _overlayEntry = null;
  }
}
