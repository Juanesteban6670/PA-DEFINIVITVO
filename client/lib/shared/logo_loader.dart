import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Pantalla de carga interactiva de Cartagena Segura con el ciclo:
/// Trazado de contornos (0-2650ms) -> Crossfade a relleno (3100-3800ms) -> Sostenido (3800-5000ms) -> Desvanecimiento (5000-5600ms).
/// Incluye controles accesibles de Reproducir/Pausar y Reiniciar, y respeta prefers-reduced-motion.
class LogoLoaderScreen extends StatefulWidget {
  const LogoLoaderScreen({super.key});

  @override
  State<LogoLoaderScreen> createState() => _LogoLoaderScreenState();
}

class _LogoLoaderScreenState extends State<LogoLoaderScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _isPaused = false;

  static const int cycleDurationMs = 7600;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: cycleDurationMs),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePause() {
    setState(() {
      if (_isPaused) {
        _controller.repeat();
        _isPaused = false;
      } else {
        _controller.stop();
        _isPaused = true;
      }
    });
  }

  void _replay() {
    setState(() {
      _controller.forward(from: 0.0);
      _controller.repeat();
      _isPaused = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isReducedMotion = MediaQuery.of(context).disableAnimations;
    final screenWidth = MediaQuery.sizeOf(context).width;

    final logoWidth = screenWidth < 500
        ? screenWidth * 0.84
        : (screenWidth * 0.58).clamp(280.0, 620.0);

    return Scaffold(
      backgroundColor: const Color(0xFF182B35),
      body: Stack(
        children: [
          // Center Animated Lockup and Statement
          Center(
            child: Semantics(
              label: 'Cargando Cartagena Segura — Sistema Distrital de Seguridad Ciudadana',
              image: true,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: logoWidth,
                    child: AspectRatio(
                      aspectRatio: 96 / 32,
                      child: isReducedMotion
                          ? const _StaticFilledLogo()
                          : AnimatedBuilder(
                              animation: _controller,
                              builder: (context, _) {
                                final elapsed =
                                    _controller.value * cycleDurationMs;
                                return CustomPaint(
                                  painter: _LogoPainter(elapsed: elapsed),
                                );
                              },
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, _) {
                      final elapsed = _controller.value * cycleDurationMs;
                      double textOpacity = 1.0;
                      if (!isReducedMotion) {
                        if (elapsed < 3400) {
                          textOpacity = 0.0;
                        } else if (elapsed <= 4000) {
                          textOpacity = (elapsed - 3400) / 600.0;
                        } else if (elapsed > 7000 && elapsed <= 7600) {
                          textOpacity =
                              (1.0 - (elapsed - 7000) / 600.0).clamp(0.0, 1.0);
                        } else if (elapsed > 7600) {
                          textOpacity = 0.0;
                        }
                      }
                      return Opacity(
                        opacity: textOpacity,
                        child: Column(
                          children: [
                            Text(
                              'Sistema Distrital de Seguridad Ciudadana',
                              style: TextStyle(
                                color: const Color(0xFFFAF6F9),
                                fontSize: screenWidth < 500 ? 14 : 16,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Cartagena de Indias · Línea 123 y Red Distrital',
                              style: TextStyle(
                                color: const Color(0xFFFAF6F9).withValues(alpha: 0.72),
                                fontSize: screenWidth < 500 ? 11.5 : 13,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // Accessible Controls in bottom-right corner
          Positioned(
            bottom: 24,
            right: 24,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ControlButton(
                  icon: _isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                  label: _isPaused ? 'Reanudar' : 'Pausar',
                  onPressed: isReducedMotion ? null : _togglePause,
                  tooltip: _isPaused
                      ? 'Reanudar animación'
                      : 'Pausar animación',
                ),
                const SizedBox(width: 8),
                _ControlButton(
                  icon: Icons.replay_rounded,
                  label: 'Reiniciar',
                  onPressed: isReducedMotion ? null : _replay,
                  tooltip: 'Reiniciar animación desde el inicio',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.tooltip,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFFAF6F9),
          backgroundColor: Colors.white.withValues(alpha: 0.08),
          side: BorderSide(
            color: Colors.white.withValues(alpha: 0.16),
          ),
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          textStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
        icon: Icon(icon, size: 14),
        label: Text(label),
      ),
    );
  }
}

class _StaticFilledLogo extends StatelessWidget {
  const _StaticFilledLogo();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _LogoPainter(elapsed: 4000), // Solid hold time
    );
  }
}

class _LogoPainter extends CustomPainter {
  _LogoPainter({required this.elapsed});

  final double elapsed;

  static const int drawDurationMs = 2650;
  static const int crossfadeStartMs = 3100;
  static const int crossfadeEndMs = 3800;
  static const int holdEndMs = 7000;
  static const int fadeEndMs = 7600;

  // Cosine easing: 0.5 - 0.5 * cos(pi * clamp(v, 0, 1))
  static double _easeCos(double v) {
    final clamped = v.clamp(0.0, 1.0);
    return 0.5 - 0.5 * math.cos(math.pi * clamped);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / 96.0;
    final scaleY = size.height / 32.0;

    canvas.save();
    canvas.scale(scaleX, scaleY);

    // Timeline calculation
    double outlineOpacity = 1.0;
    double fillOpacity = 0.0;
    double overallOpacity = 1.0;

    if (elapsed < crossfadeStartMs) {
      outlineOpacity = 1.0;
      fillOpacity = 0.0;
    } else if (elapsed <= crossfadeEndMs) {
      final t = _easeCos((elapsed - crossfadeStartMs) / (crossfadeEndMs - crossfadeStartMs));
      outlineOpacity = 1.0 - t;
      fillOpacity = t;
    } else {
      outlineOpacity = 0.0;
      fillOpacity = 1.0;
    }

    if (elapsed > holdEndMs && elapsed <= fadeEndMs) {
      final t = _easeCos((elapsed - holdEndMs) / (fadeEndMs - holdEndMs));
      overallOpacity = (1.0 - t).clamp(0.0, 1.0);
    } else if (elapsed > fadeEndMs) {
      overallOpacity = 0.0;
    }

    // Draw Filled Group
    if (fillOpacity > 0 && overallOpacity > 0) {
      final fillPaint = Paint()
        ..color = Color.fromRGBO(250, 246, 249, (fillOpacity * overallOpacity).clamp(0.0, 1.0));

      final shieldGrad = Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0071E3), Color(0xFF063970)],
        ).createShader(const Rect.fromLTWH(6, 4, 22, 25))
        ..color = Color.fromRGBO(255, 255, 255, (fillOpacity * overallOpacity).clamp(0.0, 1.0));

      // Shield base
      final shieldPath = Path()
        ..moveTo(6, 4)
        ..cubicTo(13.5, 2, 20.5, 2, 28, 4)
        ..cubicTo(28, 16.5, 23, 25.5, 17, 29)
        ..cubicTo(11, 25.5, 6, 16.5, 6, 4)
        ..close();
      canvas.drawPath(shieldPath, shieldGrad);

      // Inner shield tint
      final innerShield = Path()
        ..moveTo(9, 6.5)
        ..cubicTo(14.5, 5, 19.5, 5, 25, 6.5)
        ..cubicTo(25, 15.5, 21, 23, 17, 26)
        ..cubicTo(13, 23, 9, 15.5, 9, 6.5)
        ..close();
      canvas.drawPath(
        innerShield,
        Paint()..color = Colors.white.withValues(alpha: 0.14 * fillOpacity * overallOpacity),
      );

      // Star
      final starPath = Path()
        ..moveTo(17, 9)
        ..lineTo(18.6, 13.8)
        ..lineTo(23.5, 15.5)
        ..lineTo(18.6, 17.2)
        ..lineTo(17, 22)
        ..lineTo(15.4, 17.2)
        ..lineTo(10.5, 15.5)
        ..lineTo(15.4, 13.8)
        ..close();
      canvas.drawPath(
        starPath,
        Paint()
          ..shader = const LinearGradient(
            colors: [Color(0xFF38BDF8), Color(0xFFF5EDDE)],
          ).createShader(const Rect.fromLTWH(10.5, 9, 13, 13))
          ..color = Color.fromRGBO(255, 255, 255, (fillOpacity * overallOpacity).clamp(0.0, 1.0)),
      );

      // Text Lines
      _drawText(canvas, 'CARTAGENA', 36, 6, 7.5, FontWeight.w600, 1.8, fillPaint);
      _drawText(canvas, 'SEGURA', 36, 15, 12.5, FontWeight.w800, -0.3, fillPaint);
    }

    // Draw Outline Group (Stroke drawing)
    if (outlineOpacity > 0 && overallOpacity > 0) {
      final strokePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = Color.fromRGBO(245, 237, 222, (outlineOpacity * overallOpacity).clamp(0.0, 1.0));

      final List<_ContourItem> contours = [
        // Shield Contours (delays 0, 90, 180, 270, 360)
        _ContourItem(
          path: Path()
            ..moveTo(6, 4)
            ..cubicTo(13.5, 2, 20.5, 2, 28, 4)
            ..cubicTo(28, 16.5, 23, 25.5, 17, 29)
            ..cubicTo(11, 25.5, 6, 16.5, 6, 4)
            ..close(),
          delay: 0,
          strokeWidth: 1.2,
        ),
        _ContourItem(
          path: Path()
            ..moveTo(9, 6.5)
            ..cubicTo(14.5, 5, 19.5, 5, 25, 6.5)
            ..cubicTo(25, 15.5, 21, 23, 17, 26)
            ..cubicTo(13, 23, 9, 15.5, 9, 6.5)
            ..close(),
          delay: 90,
          strokeWidth: 0.8,
        ),
        _ContourItem(
          path: Path()
            ..moveTo(17, 9)
            ..lineTo(18.6, 13.8)
            ..lineTo(23.5, 15.5)
            ..lineTo(18.6, 17.2)
            ..lineTo(17, 22)
            ..lineTo(15.4, 17.2)
            ..lineTo(10.5, 15.5)
            ..lineTo(15.4, 13.8)
            ..close(),
          delay: 180,
          strokeWidth: 0.9,
        ),
        _ContourItem(
          path: Path()
            ..moveTo(10, 10.5)
            ..lineTo(12, 10.5)
            ..lineTo(12, 12.5)
            ..lineTo(14, 12.5)
            ..lineTo(14, 10.5)
            ..lineTo(16, 10.5)
            ..lineTo(16, 12.5)
            ..lineTo(18, 12.5)
            ..lineTo(18, 10.5)
            ..lineTo(20, 10.5)
            ..lineTo(20, 12.5)
            ..lineTo(22, 12.5)
            ..lineTo(22, 10.5)
            ..lineTo(24, 10.5),
          delay: 270,
          strokeWidth: 0.65,
        ),
        _ContourItem(
          path: Path()
            ..moveTo(12, 19.5)
            ..cubicTo(14.5, 22, 19.5, 22, 22, 19.5),
          delay: 360,
          strokeWidth: 0.8,
        ),

        // Line 1 Contours (CARTAGENA)
        _ContourItem(
          path: Path()
            ..moveTo(40, 7.5)
            ..cubicTo(39, 6.5, 36.5, 6.5, 35.5, 7.5)
            ..cubicTo(34.5, 8.8, 34.5, 10.7, 35.5, 12)
            ..cubicTo(36.5, 13.2, 39, 13.2, 40, 12),
          delay: 120,
          strokeWidth: 0.75,
        ),
        _ContourItem(
          path: Path()
            ..moveTo(41.5, 12.5)
            ..lineTo(43.5, 6.5)
            ..lineTo(45.5, 12.5)
            ..moveTo(42.2, 10.8)
            ..lineTo(44.8, 10.8),
          delay: 145,
          strokeWidth: 0.75,
        ),
        _ContourItem(
          path: Path()
            ..moveTo(47, 12.5)
            ..lineTo(47, 6.5)
            ..lineTo(49.5, 6.5)
            ..cubicTo(51, 6.5, 51, 9, 49.5, 9)
            ..lineTo(47, 9)
            ..moveTo(48.8, 9)
            ..lineTo(51, 12.5),
          delay: 170,
          strokeWidth: 0.75,
        ),
        _ContourItem(
          path: Path()
            ..moveTo(52, 6.5)
            ..lineTo(56.5, 6.5)
            ..moveTo(54.2, 6.5)
            ..lineTo(54.2, 12.5),
          delay: 195,
          strokeWidth: 0.75,
        ),
        _ContourItem(
          path: Path()
            ..moveTo(57.5, 12.5)
            ..lineTo(59.5, 6.5)
            ..lineTo(61.5, 12.5)
            ..moveTo(58.2, 10.8)
            ..lineTo(60.8, 10.8),
          delay: 220,
          strokeWidth: 0.75,
        ),
        _ContourItem(
          path: Path()
            ..moveTo(66.5, 7.5)
            ..cubicTo(65.5, 6.5, 63, 6.5, 62, 7.5)
            ..cubicTo(61, 8.8, 61, 10.7, 62, 12)
            ..cubicTo(63, 13.2, 65.5, 13.2, 66.5, 12)
            ..lineTo(66.5, 9.8)
            ..lineTo(64.2, 9.8),
          delay: 250,
          strokeWidth: 0.75,
        ),
        _ContourItem(
          path: Path()
            ..moveTo(71.5, 6.5)
            ..lineTo(68, 6.5)
            ..lineTo(68, 12.5)
            ..lineTo(71.5, 12.5)
            ..moveTo(68, 9.5)
            ..lineTo(70.8, 9.5),
          delay: 280,
          strokeWidth: 0.75,
        ),
        _ContourItem(
          path: Path()
            ..moveTo(73, 12.5)
            ..lineTo(73, 6.5)
            ..lineTo(77, 12.5)
            ..lineTo(77, 6.5),
          delay: 310,
          strokeWidth: 0.75,
        ),
        _ContourItem(
          path: Path()
            ..moveTo(78.5, 12.5)
            ..lineTo(80.5, 6.5)
            ..lineTo(82.5, 12.5)
            ..moveTo(79.2, 10.8)
            ..lineTo(81.8, 10.8),
          delay: 340,
          strokeWidth: 0.75,
        ),

        // Line 2 Contours (SEGURA)
        _ContourItem(
          path: Path()
            ..moveTo(42, 18)
            ..cubicTo(40.8, 16.5, 36.5, 16.5, 35.8, 18.5)
            ..cubicTo(35, 20.8, 42.5, 21.2, 41.8, 24)
            ..cubicTo(41, 26.8, 35.5, 26.8, 34.8, 24.5),
          delay: 120,
          strokeWidth: 1.3,
        ),
        _ContourItem(
          path: Path()
            ..moveTo(49.5, 16.5)
            ..lineTo(44.5, 16.5)
            ..lineTo(44.5, 26.5)
            ..lineTo(49.5, 26.5)
            ..moveTo(44.5, 21.5)
            ..lineTo(48.5, 21.5),
          delay: 145,
          strokeWidth: 1.3,
        ),
        _ContourItem(
          path: Path()
            ..moveTo(57, 18.5)
            ..cubicTo(55.8, 16.5, 51.5, 16.5, 50.5, 18.5)
            ..cubicTo(49.5, 20.5, 49.5, 23.5, 50.5, 25.5)
            ..cubicTo(51.5, 27.2, 56, 27.2, 57, 25)
            ..lineTo(57, 21.5)
            ..lineTo(53.5, 21.5),
          delay: 170,
          strokeWidth: 1.3,
        ),
        _ContourItem(
          path: Path()
            ..moveTo(59.5, 16.5)
            ..lineTo(59.5, 23.5)
            ..cubicTo(59.5, 26.8, 65, 26.8, 65, 23.5)
            ..lineTo(65, 16.5),
          delay: 195,
          strokeWidth: 1.3,
        ),
        _ContourItem(
          path: Path()
            ..moveTo(67.5, 26.5)
            ..lineTo(67.5, 16.5)
            ..lineTo(71.8, 16.5)
            ..cubicTo(74.5, 16.5, 74.5, 21, 71.8, 21)
            ..lineTo(67.5, 21)
            ..moveTo(71, 21)
            ..lineTo(74.5, 26.5),
          delay: 225,
          strokeWidth: 1.3,
        ),
        _ContourItem(
          path: Path()
            ..moveTo(76.5, 26.5)
            ..lineTo(80.5, 16.5)
            ..lineTo(84.5, 26.5)
            ..moveTo(78, 23.5)
            ..lineTo(83, 23.5),
          delay: 252,
          strokeWidth: 1.3,
        ),
      ];

      for (final item in contours) {
        final localElapsed = elapsed - item.delay;
        if (localElapsed <= 0) continue;

        final progress = _easeCos(localElapsed / drawDurationMs);
        strokePaint.strokeWidth = item.strokeWidth;

        // Animate stroke trimming using PathMetric
        final metrics = item.path.computeMetrics();
        for (final metric in metrics) {
          final extract = metric.extractPath(0, metric.length * progress);
          canvas.drawPath(extract, strokePaint);
        }
      }
    }

    canvas.restore();
  }

  void _drawText(
    Canvas canvas,
    String text,
    double x,
    double y,
    double fontSize,
    FontWeight fontWeight,
    double letterSpacing,
    Paint paint,
  ) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: paint.color,
          fontSize: fontSize,
          fontWeight: fontWeight,
          letterSpacing: letterSpacing,
          fontFamily: 'SF Pro Display',
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(x, y));
  }

  @override
  bool shouldRepaint(covariant _LogoPainter oldDelegate) {
    return oldDelegate.elapsed != elapsed;
  }
}

class _ContourItem {
  _ContourItem({
    required this.path,
    required this.delay,
    required this.strokeWidth,
  });

  final Path path;
  final double delay;
  final double strokeWidth;
}
