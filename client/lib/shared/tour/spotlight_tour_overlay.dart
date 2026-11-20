import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:cartagena_segura/shared/theme.dart';

import 'app_tour_model.dart';
import 'app_tour_painter.dart';

class SpotlightTourOverlay extends StatefulWidget {
  const SpotlightTourOverlay({
    required this.steps,
    required this.currentStepIndex,
    required this.onNext,
    required this.onPrev,
    required this.onSkip,
    required this.onFinish,
    super.key,
  });

  final List<TourStep> steps;
  final int currentStepIndex;
  final VoidCallback onNext;
  final VoidCallback onPrev;
  final VoidCallback onSkip;
  final VoidCallback onFinish;

  @override
  State<SpotlightTourOverlay> createState() => _SpotlightTourOverlayState();
}

class _SpotlightTourOverlayState extends State<SpotlightTourOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Rect? _getTargetRect(TourStep step) {
    final key = step.targetKey;
    if (key == null) return null;
    final ctx = key.currentContext;
    if (ctx == null) return null;
    final renderBox = ctx.findRenderObject();
    if (renderBox is! RenderBox || !renderBox.hasSize) return null;

    final offset = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;
    return (offset & size).inflate(step.padding);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenSize = MediaQuery.sizeOf(context);
    final step = widget.steps[widget.currentStepIndex];
    final isLastStep = widget.currentStepIndex == widget.steps.length - 1;
    final targetRect = _getTargetRect(step);

    // Color de acento para el foco (azul iOS / celeste según modo)
    final accentColor = isDark ? AppColors.brightBlue : AppColors.blue;

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, _) {
        return Stack(
          children: [
            // 1. Capa de recorte Spotlight y oscurecimiento de fondo
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {}, // Bloquear toques detrás del tutorial
                child: CustomPaint(
                  painter: SpotlightPainter(
                    targetRect: targetRect,
                    borderRadius: step.borderRadius,
                    pulseValue: _pulseController.value,
                    scrimColor: Colors.black.withValues(alpha: isDark ? 0.76 : 0.65),
                    glowColor: accentColor,
                  ),
                ),
              ),
            ),

            // 2. Tarjeta flotante interactiva de explicación
            _buildFloatingTooltipCard(
              context: context,
              step: step,
              targetRect: targetRect,
              screenSize: screenSize,
              isDark: isDark,
              accentColor: accentColor,
              isLastStep: isLastStep,
            ),
          ],
        );
      },
    );
  }

  Widget _buildFloatingTooltipCard({
    required BuildContext context,
    required TourStep step,
    required Rect? targetRect,
    required Size screenSize,
    required bool isDark,
    required Color accentColor,
    required bool isLastStep,
  }) {
    const cardMaxWidth = 360.0;
    final cardWidth = math.min(cardMaxWidth, screenSize.width - 32);

    // Calcular posición vertical óptima
    double top = 0;
    if (targetRect == null) {
      top = (screenSize.height / 2) - 120;
    } else {
      final spaceBelow = screenSize.height - targetRect.bottom;
      final spaceAbove = targetRect.top;

      if (step.preferredPosition == TooltipPosition.top) {
        top = targetRect.top - 230;
      } else if (step.preferredPosition == TooltipPosition.bottom) {
        top = targetRect.bottom + 16;
      } else {
        // Auto: donde haya más espacio disponible
        if (spaceBelow >= 220) {
          top = targetRect.bottom + 16;
        } else if (spaceAbove >= 220) {
          top = targetRect.top - 230;
        } else {
          top = math.max(16, targetRect.bottom + 12);
        }
      }
    }

    // Clamp para evitar que se desborde fuera de la pantalla
    final maxTop = math.max(16.0, screenSize.height - 240);
    top = top.clamp(16.0, maxTop);

    // Centrar horizontalmente respecto al objetivo, o respecto a la pantalla
    double left = (screenSize.width - cardWidth) / 2;
    if (targetRect != null) {
      final idealLeft = targetRect.center.dx - (cardWidth / 2);
      final maxLeft = math.max(16.0, screenSize.width - cardWidth - 16.0);
      left = idealLeft.clamp(16.0, maxLeft);
    }

    return Positioned(
      top: top,
      left: left,
      width: cardWidth,
      child: Material(
        color: Colors.transparent,
        child: LiquidGlassContainer(
          borderRadius: BorderRadius.circular(22),
          elevation: 5,
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Encabezado: Icono, Badge de Paso y Botón Saltar
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: isDark ? 0.20 : 0.12),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: accentColor.withValues(alpha: 0.45),
                        width: 1.2,
                      ),
                    ),
                    child: Icon(step.icon, color: accentColor, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'Paso ${widget.currentStepIndex + 1} de ${widget.steps.length}',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: accentColor,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          step.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                            color: isDark ? AppColors.darkText : AppColors.navy,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Saltar tutorial',
                    iconSize: 18,
                    visualDensity: VisualDensity.compact,
                    icon: Icon(
                      Icons.close_rounded,
                      color: isDark ? Colors.white60 : Colors.black45,
                    ),
                    onPressed: widget.onSkip,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Cuerpo: Explicación para el ciudadano
              Text(
                step.description,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white70 : const Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 16),

              // Pie: Indicador de puntos (dots) y Botones de acción
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Dots indicadores
                  Row(
                    children: List.generate(
                      widget.steps.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.only(right: 5),
                        width: i == widget.currentStepIndex ? 16 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: i == widget.currentStepIndex
                              ? accentColor
                              : (isDark ? Colors.white24 : Colors.black12),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),

                  // Botones de Anterior / Siguiente
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.currentStepIndex > 0) ...[
                        TextButton(
                          onPressed: widget.onPrev,
                          style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            foregroundColor: isDark ? Colors.white70 : Colors.black54,
                          ),
                          child: const Text('Anterior', style: TextStyle(fontSize: 12)),
                        ),
                        const SizedBox(width: 4),
                      ],
                      FilledButton.icon(
                        onPressed: isLastStep ? widget.onFinish : widget.onNext,
                        style: FilledButton.styleFrom(
                          backgroundColor: accentColor,
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: Icon(
                          isLastStep ? Icons.check_rounded : Icons.arrow_forward_rounded,
                          size: 14,
                        ),
                        label: Text(
                          isLastStep ? '¡Comenzar!' : 'Siguiente',
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
