import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Paleta de colores oficial inspirada en las directrices de diseño de Apple
/// (Human Interface Guidelines - HIG para iOS, iPadOS y macOS).
abstract final class AppColors {
  // Apple Signature Blues
  static const blue = Color(0xFF0071E3); // Apple Blue (Web, macOS, iOS)
  static const brightBlue = Color(0xFF0A84FF); // Apple Dark System Blue
  static const navy = Color(0xFF1D1D1F); // Apple Primary Label Light
  static const navyBlue = Color(0xFF2C2C2E); // Apple Secondary Label Light / Fill
  static const sky = Color(0xFF64D2FF); // Apple System Cyan

  // Light Mode Surfaces (Apple Clean Light HIG)
  static const canvas = Color(0xFFF5F5F7); // Apple System Gray 6 / Signature Canvas
  static const surface = Colors.white; // Apple Pure White Surface
  static const border = Color(0xFFE5E5EA); // Apple System Gray 5 Separator / Hairline Border
  static const borderSubtle = Color(0xFFF2F2F7);
  static const muted = Color(0xFF86868B); // Apple Secondary Label Light

  // Status & Priority Accents (Apple HIG System Colors)
  static const red = Color(0xFFFF3B30); // Apple System Red
  static const green = Color(0xFF34C759); // Apple System Green
  static const amber = Color(0xFFFF9500); // Apple System Orange / Warning
  static const yellow = Color(0xFFFFCC00); // Apple System Yellow
  static const purple = Color(0xFFAF52DE); // Apple System Purple
  static const indigo = Color(0xFF5856D6); // Apple System Indigo

  // Dark Mode Tokens (Apple Pure OLED Black & Space Gray HIG)
  static const darkCanvas = Color(0xFF000000); // Apple System Background (Pure OLED Black)
  static const darkSurface = Color(0xFF1C1C1E); // Apple Secondary System Background
  static const darkCard = Color(0xFF1C1C1E); // Apple Grouped Card
  static const darkCardHover = Color(0xFF2C2C2E); // Apple Tertiary System Background
  static const darkBorder = Color(0xFF38383A); // Apple Dark Separator
  static const darkBorderSubtle = Color(0xFF2C2C2E); // Apple Dark Subtle Separator
  static const darkText = Color(0xFFF5F5F7); // Apple Dark Primary Label
  static const darkTextMuted = Color(0xFF86868B); // Apple Dark Secondary Label

  // Dark System Accents
  static const darkRed = Color(0xFFFF453A);
  static const darkGreen = Color(0xFF30D158);
  static const darkAmber = Color(0xFFFF9F0A);
  static const darkPurple = Color(0xFFBF5AF2);
  static const darkYellow = Color(0xFFFFD60A);
}

/// Fallback tipográfico optimizado para renderizar SF Pro Display/Text nativo de Apple.
const List<String> appleFontFallbacks = [
  'SF Pro Display',
  'SF Pro Text',
  '-apple-system',
  'BlinkMacSystemFont',
  'system-ui',
  'Segoe UI',
  'Helvetica Neue',
  'sans-serif',
];

TextTheme _buildAppleTextTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  final primaryColor = isDark ? AppColors.darkText : AppColors.navy;
  final secondaryColor = isDark ? AppColors.darkTextMuted : AppColors.muted;

  return TextTheme(
    displayLarge: TextStyle(
      fontSize: 34,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.8,
      color: primaryColor,
      fontFamilyFallback: appleFontFallbacks,
    ),
    displayMedium: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.6,
      color: primaryColor,
      fontFamilyFallback: appleFontFallbacks,
    ),
    displaySmall: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.5,
      color: primaryColor,
      fontFamilyFallback: appleFontFallbacks,
    ),
    headlineMedium: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.4,
      color: primaryColor,
      fontFamilyFallback: appleFontFallbacks,
    ),
    titleLarge: TextStyle(
      fontSize: 17,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.4,
      color: primaryColor,
      fontFamilyFallback: appleFontFallbacks,
    ),
    titleMedium: TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.2,
      color: primaryColor,
      fontFamilyFallback: appleFontFallbacks,
    ),
    titleSmall: TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.1,
      color: primaryColor,
      fontFamilyFallback: appleFontFallbacks,
    ),
    bodyLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      letterSpacing: -0.2,
      color: primaryColor,
      fontFamilyFallback: appleFontFallbacks,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      letterSpacing: -0.2,
      color: primaryColor,
      fontFamilyFallback: appleFontFallbacks,
    ),
    bodySmall: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.0,
      color: secondaryColor,
      fontFamilyFallback: appleFontFallbacks,
    ),
    labelLarge: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.1,
      color: primaryColor,
      fontFamilyFallback: appleFontFallbacks,
    ),
    labelMedium: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.0,
      color: secondaryColor,
      fontFamilyFallback: appleFontFallbacks,
    ),
    labelSmall: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
      color: secondaryColor,
      fontFamilyFallback: appleFontFallbacks,
    ),
  );
}

ThemeData buildAppTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.blue,
    brightness: Brightness.light,
    surface: Colors.white,
    onSurface: AppColors.navy,
    primary: AppColors.blue,
    onPrimary: Colors.white,
    secondary: AppColors.navyBlue,
    error: AppColors.red,
  );

  return ThemeData(
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.canvas,
    useMaterial3: true,
    brightness: Brightness.light,
    textTheme: _buildAppleTextTheme(Brightness.light),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.canvas,
      foregroundColor: AppColors.navy,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(
        color: AppColors.navy,
        fontSize: 17,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.4,
        fontFamilyFallback: appleFontFallbacks,
      ),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppColors.border, width: 0.8),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
          fontFamilyFallback: appleFontFallbacks,
        ),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.navy,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.border, width: 0.8),
        ),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
          fontFamilyFallback: appleFontFallbacks,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.blue,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.border, width: 1.0),
        ),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.1,
          fontFamilyFallback: appleFontFallbacks,
        ),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.border, width: 0.8),
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
      hintStyle: const TextStyle(
        color: AppColors.muted,
        fontSize: 14,
        letterSpacing: -0.1,
        fontFamilyFallback: appleFontFallbacks,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border, width: 1.0),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border, width: 1.0),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.blue, width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.red, width: 1.0),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.red, width: 1.8),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      elevation: 0,
      indicatorColor: AppColors.blue.withValues(alpha: 0.1),
      indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.1,
          fontFamilyFallback: appleFontFallbacks,
          color: states.contains(WidgetState.selected)
              ? AppColors.blue
              : AppColors.muted,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          size: 22,
          color: states.contains(WidgetState.selected)
              ? AppColors.blue
              : AppColors.muted,
        ),
      ),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: AppColors.canvas,
      elevation: 0,
      indicatorColor: AppColors.blue.withValues(alpha: 0.1),
      indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      selectedIconTheme: const IconThemeData(color: AppColors.blue, size: 22),
      unselectedIconTheme: const IconThemeData(color: AppColors.muted, size: 22),
      selectedLabelTextStyle: const TextStyle(
        color: AppColors.blue,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        fontFamilyFallback: appleFontFallbacks,
      ),
      unselectedLabelTextStyle: const TextStyle(
        color: AppColors.muted,
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.1,
        fontFamilyFallback: appleFontFallbacks,
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: const WidgetStatePropertyAll(Colors.white),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? AppColors.green
            : const Color(0xFFE5E5EA),
      ),
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.border,
      thickness: 0.8,
      space: 1,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.border, width: 0.8),
      ),
      backgroundColor: AppColors.navy,
      contentTextStyle: const TextStyle(
        color: Colors.white,
        fontSize: 13,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.1,
        fontFamilyFallback: appleFontFallbacks,
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
    secondary: AppColors.darkTextMuted,
    error: AppColors.darkRed,
  );

  return ThemeData(
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.darkCanvas,
    useMaterial3: true,
    brightness: Brightness.dark,
    textTheme: _buildAppleTextTheme(Brightness.dark),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.darkCanvas,
      foregroundColor: AppColors.darkText,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(
        color: AppColors.darkText,
        fontSize: 17,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.4,
        fontFamilyFallback: appleFontFallbacks,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.darkCard,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppColors.darkBorder, width: 0.8),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.brightBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
          fontFamilyFallback: appleFontFallbacks,
        ),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.darkCard,
        foregroundColor: AppColors.darkText,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.darkBorder, width: 0.8),
        ),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
          fontFamilyFallback: appleFontFallbacks,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.brightBlue,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.darkBorder, width: 1.0),
        ),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.1,
          fontFamilyFallback: appleFontFallbacks,
        ),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.darkCard,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.darkBorder, width: 0.8),
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
      fillColor: AppColors.darkCardHover,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: const TextStyle(
        color: AppColors.darkTextMuted,
        fontSize: 14,
        letterSpacing: -0.1,
        fontFamilyFallback: appleFontFallbacks,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.darkBorder, width: 1.0),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.darkBorder, width: 1.0),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.brightBlue, width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.darkRed, width: 1.0),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.darkRed, width: 1.8),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: const Color(0xFF161618),
      elevation: 0,
      indicatorColor: AppColors.brightBlue.withValues(alpha: 0.16),
      indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.1,
          fontFamilyFallback: appleFontFallbacks,
          color: states.contains(WidgetState.selected)
              ? AppColors.brightBlue
              : AppColors.darkTextMuted,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          size: 22,
          color: states.contains(WidgetState.selected)
              ? AppColors.brightBlue
              : AppColors.darkTextMuted,
        ),
      ),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: const Color(0xFF121214),
      elevation: 0,
      indicatorColor: AppColors.brightBlue.withValues(alpha: 0.16),
      indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      selectedIconTheme: const IconThemeData(color: AppColors.brightBlue, size: 22),
      unselectedIconTheme: const IconThemeData(color: AppColors.darkTextMuted, size: 22),
      selectedLabelTextStyle: const TextStyle(
        color: AppColors.brightBlue,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        fontFamilyFallback: appleFontFallbacks,
      ),
      unselectedLabelTextStyle: const TextStyle(
        color: AppColors.darkTextMuted,
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.1,
        fontFamilyFallback: appleFontFallbacks,
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: const WidgetStatePropertyAll(Colors.white),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? AppColors.darkGreen
            : const Color(0xFF38383A),
      ),
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.darkBorder,
      thickness: 0.8,
      space: 1,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.darkBorder, width: 0.8),
      ),
      backgroundColor: AppColors.darkCard,
      contentTextStyle: const TextStyle(
        color: AppColors.darkText,
        fontSize: 13,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.1,
        fontFamilyFallback: appleFontFallbacks,
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
