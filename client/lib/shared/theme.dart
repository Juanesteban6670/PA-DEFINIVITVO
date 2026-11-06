import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract final class AppColors {
  // Brand Blues
  static const navy = Color(0xFF0F172A);
  static const navyBlue = Color(0xFF1E3A5F);
  static const blue = Color(0xFF1D4ED8);
  static const brightBlue = Color(0xFF3B82F6);
  static const sky = Color(0xFF38BDF8);

  // Light Mode Surfaces
  static const canvas = Color(0xFFF8FAFC);
  static const surface = Colors.white;
  static const border = Color(0xFFE2E8F0);
  static const muted = Color(0xFF94A3B8);

  // Status & Priority Accents
  static const red = Color(0xFFEF4444);
  static const green = Color(0xFF10B981);
  static const amber = Color(0xFFF59E0B);

  // Dark Mode Tokens (Deep Obsidian / Cyber Minimalist)
  static const darkCanvas = Color(0xFF090D16);
  static const darkSurface = Color(0xFF111827);
  static const darkCard = Color(0xFF161F33);
  static const darkCardHover = Color(0xFF1E293B);
  static const darkBorder = Color(0xFF1F293D);
  static const darkBorderSubtle = Color(0xFF334155);
  static const darkText = Color(0xFFF8FAFC);
  static const darkTextMuted = Color(0xFF94A3B8);
}

ThemeData buildAppTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.blue,
    brightness: Brightness.light,
    surface: Colors.white,
    onSurface: AppColors.navy,
    primary: AppColors.blue,
    onPrimary: Colors.white,
    secondary: AppColors.brightBlue,
    error: AppColors.red,
  );

  return ThemeData(
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.canvas,
    useMaterial3: true,
    brightness: Brightness.light,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: AppColors.navy,
      elevation: 0,
      centerTitle: false,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(
        color: AppColors.navy,
        fontSize: 16,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
      ),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppColors.border),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: AppColors.border),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: const TextStyle(color: AppColors.muted, fontSize: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.blue, width: 1.5),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: AppColors.blue.withValues(alpha: 0.08),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
          color: states.contains(WidgetState.selected)
              ? AppColors.blue
              : AppColors.muted,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? AppColors.blue
              : AppColors.muted,
        ),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.border,
      thickness: 1,
      space: 1,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.border),
      ),
      backgroundColor: AppColors.navy,
      contentTextStyle: const TextStyle(
        color: Colors.white,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
      elevation: 4,
    ),
  );
}

ThemeData buildDarkAppTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.brightBlue,
    brightness: Brightness.dark,
    surface: AppColors.darkSurface,
    onSurface: AppColors.darkText,
    primary: AppColors.brightBlue,
    onPrimary: Colors.white,
    secondary: AppColors.sky,
    error: AppColors.red,
  );

  return ThemeData(
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.darkCanvas,
    useMaterial3: true,
    brightness: Brightness.dark,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.darkCanvas,
      foregroundColor: AppColors.darkText,
      elevation: 0,
      centerTitle: false,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(
        color: AppColors.darkText,
        fontSize: 16,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.darkCard,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppColors.darkBorder),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.darkCard,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: AppColors.darkBorder),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.darkCard,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.darkSurface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: const TextStyle(color: AppColors.darkTextMuted, fontSize: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.darkBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.darkBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.brightBlue, width: 1.5),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.darkCanvas,
      indicatorColor: AppColors.brightBlue.withValues(alpha: 0.15),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
          color: states.contains(WidgetState.selected)
              ? AppColors.brightBlue
              : AppColors.darkTextMuted,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? AppColors.brightBlue
              : AppColors.darkTextMuted,
        ),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.darkBorder,
      thickness: 1,
      space: 1,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.darkBorder),
      ),
      backgroundColor: AppColors.darkCard,
      contentTextStyle: const TextStyle(
        color: AppColors.darkText,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
      elevation: 6,
    ),
  );
}

/// Gestor de estado reactivo para la preferencia de modo claro/oscuro.
class ThemeModeController extends ChangeNotifier {
  ThemeModeController({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage() {
    _loadTheme();
  }

  static final ThemeModeController instance = ThemeModeController();

  final FlutterSecureStorage _storage;
  static const _storageKey = 'cartagena_theme_mode';
  ThemeMode _mode = ThemeMode.system;

  ThemeMode get mode => _mode;

  Future<void> _loadTheme() async {
    try {
      final saved = await _storage.read(key: _storageKey);
      if (saved == 'light') {
        _mode = ThemeMode.light;
      } else if (saved == 'dark') {
        _mode = ThemeMode.dark;
      } else {
        _mode = ThemeMode.system;
      }
      notifyListeners();
    } catch (_) {
      // Si falla storage, se mantiene system
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _mode = mode;
    notifyListeners();
    try {
      final value = switch (mode) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        ThemeMode.system => 'system',
      };
      await _storage.write(key: _storageKey, value: value);
    } catch (_) {}
  }

  Future<void> toggleTheme(BuildContext context) async {
    final currentBrightness = Theme.of(context).brightness;
    if (_mode == ThemeMode.system) {
      await setThemeMode(
        currentBrightness == Brightness.dark ? ThemeMode.light : ThemeMode.dark,
      );
    } else if (_mode == ThemeMode.dark) {
      await setThemeMode(ThemeMode.light);
    } else {
      await setThemeMode(ThemeMode.dark);
    }
  }
}

final themeModeProvider = ChangeNotifierProvider<ThemeModeController>((ref) {
  return ThemeModeController.instance;
});

/// Botón estilizado para alternar rápidamente entre modo claro y oscuro.
class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({
    this.compact = false,
    this.showBackground = false,
    super.key,
  });

  final bool compact;
  final bool showBackground;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeModeController.instance,
      builder: (context, _) {
        final isDark = Theme.of(context).brightness == Brightness.dark;

        Widget button = IconButton(
          tooltip: isDark ? 'Cambiar a modo claro' : 'Cambiar a modo oscuro',
          onPressed: () => ThemeModeController.instance.toggleTheme(context),
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (child, animation) => RotationTransition(
              turns: animation,
              child: FadeTransition(opacity: animation, child: child),
            ),
            child: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              key: ValueKey(isDark),
              size: compact ? 19 : 22,
              color: isDark ? const Color(0xFFFBBF24) : AppColors.navy,
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

/// Selector de apariencia de 3 vías (Sistema, Claro, Oscuro) para Ajustes y Perfil.
class ThemeModeSelector extends StatelessWidget {
  const ThemeModeSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeModeController.instance,
      builder: (context, _) {
        final currentMode = ThemeModeController.instance.mode;

        return SegmentedButton<ThemeMode>(
          segments: const [
            ButtonSegment(
              value: ThemeMode.system,
              icon: Icon(Icons.brightness_auto, size: 18),
              label: Text('Sistema'),
            ),
            ButtonSegment(
              value: ThemeMode.light,
              icon: Icon(Icons.light_mode, size: 18),
              label: Text('Claro'),
            ),
            ButtonSegment(
              value: ThemeMode.dark,
              icon: Icon(Icons.dark_mode, size: 18),
              label: Text('Oscuro'),
            ),
          ],
          selected: {currentMode},
          onSelectionChanged: (newSelection) {
            if (newSelection.isNotEmpty) {
              ThemeModeController.instance.setThemeMode(newSelection.first);
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
