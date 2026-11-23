import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'theme.dart';

/// Modos de intensidad para el motor visual "Liquid Glass"
enum LiquidGlassMode {
  /// Superficies sólidas estándar (Rendimiento máximo)
  off,

  /// Desenfoque equilibrado y bordes sutilmente translúcidos
  subtle,

  /// Estética iOS 27 hiper-pulida: refracción profunda, reflejos especulares y sombras orgánicas
  full,
}

/// Controlador global y reactivo para la estética Liquid Glass.
/// Permite alternar la intensidad del vidrio líquido en tiempo real y persiste la preferencia.
class LiquidGlassController extends ChangeNotifier {
  LiquidGlassController({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage() {
    _loadPreference();
  }

  static final LiquidGlassController instance = LiquidGlassController();

  final FlutterSecureStorage _storage;
  static const _storageKey = 'cartagena_liquid_glass_mode';

  LiquidGlassMode _mode = LiquidGlassMode.full;

  LiquidGlassMode get mode => _mode;
  bool get isEnabled => _mode != LiquidGlassMode.off;
  bool get isFull => _mode == LiquidGlassMode.full;

  Future<void> _loadPreference() async {
    try {
      final saved = await _storage.read(key: _storageKey);
      if (saved == 'off') {
        _mode = LiquidGlassMode.off;
      } else if (saved == 'subtle') {
        _mode = LiquidGlassMode.subtle;
      } else {
        _mode = LiquidGlassMode.full;
      }
      notifyListeners();
    } catch (_) {
      _mode = LiquidGlassMode.full;
    }
  }

  Future<void> setMode(LiquidGlassMode mode) async {
    if (_mode == mode) return;
    _mode = mode;
    notifyListeners();
    try {
      final value = switch (mode) {
        LiquidGlassMode.off => 'off',
        LiquidGlassMode.subtle => 'subtle',
        LiquidGlassMode.full => 'full',
      };
      await _storage.write(key: _storageKey, value: value);
    } catch (_) {}
  }

  Future<void> cycleMode() async {
    final next = switch (_mode) {
      LiquidGlassMode.full => LiquidGlassMode.subtle,
      LiquidGlassMode.subtle => LiquidGlassMode.off,
      LiquidGlassMode.off => LiquidGlassMode.full,
    };
    await setMode(next);
  }

  String get label => switch (_mode) {
    LiquidGlassMode.off => 'Desactivado',
    LiquidGlassMode.subtle => 'Sutil (Equilibrado)',
    LiquidGlassMode.full => 'Liquid Glass (iOS 27)',
  };
}

/// Provider de Riverpod para interactuar reactivamente con el controlador Liquid Glass
final liquidGlassProvider = ChangeNotifierProvider<LiquidGlassController>((
  ref,
) {
  return LiquidGlassController.instance;
});

/// Tokens de diseño y constantes de estilo para "Liquid Glass"
abstract final class LiquidGlassTokens {
  // Sigmas de desenfoque calibrados
  static const double blurSigmaFull = 24.0;
  static const double blurSigmaSubtle = 12.0;

  // Radios de curvatura orgánica (Continuous Curves)
  static const double radiusSmall = 14.0;
  static const double radiusMedium = 20.0;
  static const double radiusLarge = 28.0;
  static const double radiusPill = 999.0;

  // Sombras multicapa difusas con brillo especular
  static List<BoxShadow> getShadows({
    required bool isDark,
    required LiquidGlassMode mode,
    double elevation = 1.0,
  }) {
    if (mode == LiquidGlassMode.off) {
      return [
        BoxShadow(
          color: Colors.black.withValues(
            alpha: isDark ? 0.35 : 0.05 * elevation,
          ),
          blurRadius: 10 * elevation,
          offset: Offset(0, 3 * elevation),
        ),
      ];
    }

    final ambientAlpha = isDark ? 0.38 : 0.06;
    final causticAlpha = isDark ? 0.16 : 0.04;

    return [
      // Sombra ambiental difusa
      BoxShadow(
        color: Colors.black.withValues(alpha: ambientAlpha),
        blurRadius: mode == LiquidGlassMode.full ? 24 : 14,
        offset: Offset(0, mode == LiquidGlassMode.full ? 8 : 4),
        spreadRadius: -2,
      ),
      // Resplandor de refracción líquida (Cáustica tenue azulada)
      BoxShadow(
        color: (isDark ? AppColors.brightBlue : AppColors.sky).withValues(
          alpha: causticAlpha,
        ),
        blurRadius: mode == LiquidGlassMode.full ? 32 : 16,
        offset: const Offset(0, 2),
      ),
    ];
  }

  // Gradiente de fondo translúcido (Liquid Ice vs Obsidian Glass)
  static Decoration getDecoration({
    required bool isDark,
    required LiquidGlassMode mode,
    required BorderRadius borderRadius,
    Color? tintColor,
    Border? customBorder,
  }) {
    if (mode == LiquidGlassMode.off) {
      return BoxDecoration(
        color: tintColor ?? (isDark ? AppColors.darkCard : Colors.white),
        borderRadius: borderRadius,
        border:
            customBorder ??
            Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.border,
              width: 0.8,
            ),
      );
    }

    final isFull = mode == LiquidGlassMode.full;

    // Colores según modo claro (Liquid Ice) u oscuro (Obsidian Glass)
    final gradientColors = isDark
        ? [
            (tintColor ?? const Color(0xFF1E1E22)).withValues(
              alpha: isFull ? 0.72 : 0.86,
            ),
            (tintColor ?? const Color(0xFF121214)).withValues(
              alpha: isFull ? 0.58 : 0.80,
            ),
          ]
        : [
            (tintColor ?? Colors.white).withValues(alpha: isFull ? 0.76 : 0.90),
            (tintColor ?? const Color(0xFFF0F4FA)).withValues(
              alpha: isFull ? 0.52 : 0.80,
            ),
          ];

    final border =
        customBorder ??
        Border.all(
          color: Colors.white.withValues(
            alpha: isDark ? (isFull ? 0.20 : 0.14) : (isFull ? 0.75 : 0.60),
          ),
          width: isFull ? 1 : 0.8,
        );

    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: gradientColors,
      ),
      borderRadius: borderRadius,
      border: border,
    );
  }
}

/// Contenedor de cristal líquido hiper-pulido con `BackdropFilter` y `RepaintBoundary`.
/// Se adapta dinámicamente al modo seleccionado en `LiquidGlassController`.
class LiquidGlassContainer extends StatelessWidget {
  const LiquidGlassContainer({
    required this.child,
    this.borderRadius = const BorderRadius.all(
      Radius.circular(LiquidGlassTokens.radiusMedium),
    ),
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.elevation = 1.0,
    this.tintColor,
    this.customBlur,
    this.border,
    this.clipBehavior = Clip.antiAlias,
    super.key,
  });

  final Widget child;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final double elevation;
  final Color? tintColor;
  final double? customBlur;
  final Border? border;
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LiquidGlassController.instance,
      builder: (context, _) {
        final mode = LiquidGlassController.instance.mode;
        final isDark = Theme.of(context).brightness == Brightness.dark;

        if (mode == LiquidGlassMode.off) {
          Widget solidBox = Container(
            width: width,
            height: height,
            margin: margin,
            padding: padding,
            decoration: LiquidGlassTokens.getDecoration(
              isDark: isDark,
              mode: mode,
              borderRadius: borderRadius,
              tintColor: tintColor,
              customBorder: border,
            ),
            child: child,
          );
          return RepaintBoundary(child: solidBox);
        }

        final double sigma =
            customBlur ??
            (mode == LiquidGlassMode.full
                ? LiquidGlassTokens.blurSigmaFull
                : LiquidGlassTokens.blurSigmaSubtle);

        final shadows = LiquidGlassTokens.getShadows(
          isDark: isDark,
          mode: mode,
          elevation: elevation,
        );

        Widget glassBox = Container(
          width: width,
          height: height,
          margin: margin,
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            boxShadow: shadows,
          ),
          child: ClipRRect(
            borderRadius: borderRadius,
            clipBehavior: clipBehavior,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
              child: Container(
                padding: padding,
                decoration: LiquidGlassTokens.getDecoration(
                  isDark: isDark,
                  mode: mode,
                  borderRadius: borderRadius,
                  tintColor: tintColor,
                  customBorder: border,
                ),
                child: child,
              ),
            ),
          ),
        );

        return RepaintBoundary(child: glassBox);
      },
    );
  }
}

/// Tarjeta táctil interactiva basada en Liquid Glass con micro-animación en hover / press.
class LiquidGlassCard extends StatefulWidget {
  const LiquidGlassCard({
    required this.child,
    this.onTap,
    this.borderRadius = const BorderRadius.all(
      Radius.circular(LiquidGlassTokens.radiusMedium),
    ),
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.width,
    this.height,
    this.elevation = 1.0,
    this.tintColor,
    this.border,
    super.key,
  });

  final Widget child;
  final VoidCallback? onTap;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final double elevation;
  final Color? tintColor;
  final Border? border;

  @override
  State<LiquidGlassCard> createState() => _LiquidGlassCardState();
}

class _LiquidGlassCardState extends State<LiquidGlassCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LiquidGlassController.instance,
      builder: (context, _) {
        final isDark = Theme.of(context).brightness == Brightness.dark;

        Widget content = LiquidGlassContainer(
          borderRadius: widget.borderRadius,
          padding: widget.padding,
          margin: widget.margin,
          width: widget.width,
          height: widget.height,
          elevation: _hovered ? widget.elevation * 1.6 : widget.elevation,
          tintColor: _hovered
              ? (isDark
                    ? AppColors.brightBlue.withValues(alpha: 0.12)
                    : Colors.white)
              : widget.tintColor,
          border: widget.border,
          child: widget.child,
        );

        if (widget.onTap != null) {
          content = MouseRegion(
            cursor: SystemMouseCursors.click,
            onEnter: (_) => setState(() => _hovered = true),
            onExit: (_) => setState(() => _hovered = false),
            child: GestureDetector(onTap: widget.onTap, child: content),
          );
        }

        return content;
      },
    );
  }
}

/// Botón en barra de navegación para alternar rápidamente el modo Liquid Glass
class LiquidGlassToggleButton extends StatelessWidget {
  const LiquidGlassToggleButton({
    this.compact = false,
    this.showBackground = false,
    super.key,
  });

  final bool compact;
  final bool showBackground;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LiquidGlassController.instance,
      builder: (context, _) {
        final controller = LiquidGlassController.instance;
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final mode = controller.mode;

        final (icon, color, tooltip) = switch (mode) {
          LiquidGlassMode.full => (
            Icons.blur_on_rounded,
            isDark ? AppColors.sky : AppColors.blue,
            'Liquid Glass: iOS 27 (Máximo)',
          ),
          LiquidGlassMode.subtle => (
            Icons.blur_linear_rounded,
            isDark ? AppColors.darkText : AppColors.navy,
            'Liquid Glass: Sutil',
          ),
          LiquidGlassMode.off => (
            Icons.blur_off_rounded,
            AppColors.muted,
            'Liquid Glass: Desactivado',
          ),
        };

        Widget button = IconButton(
          tooltip: tooltip,
          onPressed: () => controller.cycleMode(),
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            transitionBuilder: (child, animation) => ScaleTransition(
              scale: animation,
              child: FadeTransition(opacity: animation, child: child),
            ),
            child: Icon(
              icon,
              key: ValueKey(mode),
              size: compact ? 19 : 22,
              color: color,
            ),
          ),
        );

        if (showBackground) {
          return Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.border,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: button,
          );
        }

        return button;
      },
    );
  }
}

/// Selector segmentado de 3 vías (Desactivado, Sutil, iOS 27) para Perfil y Ajustes.
class LiquidGlassSelector extends StatelessWidget {
  const LiquidGlassSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LiquidGlassController.instance,
      builder: (context, _) {
        final currentMode = LiquidGlassController.instance.mode;

        return SegmentedButton<LiquidGlassMode>(
          segments: const [
            ButtonSegment(
              value: LiquidGlassMode.off,
              icon: Icon(Icons.blur_off_rounded, size: 16),
              label: Text('Plano'),
            ),
            ButtonSegment(
              value: LiquidGlassMode.subtle,
              icon: Icon(Icons.blur_linear_rounded, size: 16),
              label: Text('Sutil'),
            ),
            ButtonSegment(
              value: LiquidGlassMode.full,
              icon: Icon(Icons.blur_on_rounded, size: 16),
              label: Text('iOS 27'),
            ),
          ],
          selected: {currentMode},
          onSelectionChanged: (newSelection) {
            if (newSelection.isNotEmpty) {
              LiquidGlassController.instance.setMode(newSelection.first);
            }
          },
          style: ButtonStyle(
            visualDensity: VisualDensity.compact,
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        );
      },
    );
  }
}
