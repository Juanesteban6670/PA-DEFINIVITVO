import 'package:flutter/material.dart';

/// Painter que dibuja la capa semitranslúcida oscura y recorta el área del elemento en foco
/// con un borde brillante y pulsación viva estilo Liquid Glass.
class SpotlightPainter extends CustomPainter {
  const SpotlightPainter({
    required this.targetRect,
    required this.borderRadius,
    required this.pulseValue,
    required this.scrimColor,
    required this.glowColor,
  });

  final Rect? targetRect;
  final double borderRadius;
  final double pulseValue; // 0.0 .. 1.0
  final Color scrimColor;
  final Color glowColor;

  @override
  void paint(Canvas canvas, Size size) {
    final screenRect = Offset.zero & size;

    if (targetRect == null) {
      canvas.drawRect(screenRect, Paint()..color = scrimColor);
      return;
    }

    final cutoutRRect = RRect.fromRectAndRadius(
      targetRect!,
      Radius.circular(borderRadius),
    );

    // 1. Recorte con PathOperation.difference
    final screenPath = Path()..addRect(screenRect);
    final cutoutPath = Path()..addRRect(cutoutRRect);
    final combinedPath = Path.combine(
      PathOperation.difference,
      screenPath,
      cutoutPath,
    );

    canvas.drawPath(combinedPath, Paint()..color = scrimColor);

    // 2. Halo difuso exterior con pulsación
    final glowRadius = 4.0 + (pulseValue * 4.0);
    final glowPaint = Paint()
      ..color = glowColor.withValues(alpha: 0.30 + (pulseValue * 0.25))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, glowRadius);

    canvas.drawRRect(cutoutRRect, glowPaint);

    // 3. Borde nítido especular
    final borderPaint = Paint()
      ..color = glowColor.withValues(alpha: 0.90)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;

    canvas.drawRRect(cutoutRRect, borderPaint);
  }

  @override
  bool shouldRepaint(covariant SpotlightPainter oldDelegate) {
    return oldDelegate.targetRect != targetRect ||
        oldDelegate.borderRadius != borderRadius ||
        oldDelegate.pulseValue != pulseValue ||
        oldDelegate.scrimColor != scrimColor ||
        oldDelegate.glowColor != glowColor;
  }
}
