import 'package:flutter/material.dart';

import 'package:cartagena_segura/shared/theme.dart';
import 'app_strings.dart';
import 'locale_controller.dart';

/// Botón estilizado y compacto para alternar rápidamente entre Español e Inglés en cualquier pantalla.
class LanguageToggleButton extends StatelessWidget {
  const LanguageToggleButton({
    this.compact = false,
    this.showBackground = false,
    super.key,
  });

  final bool compact;
  final bool showBackground;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LocaleController.instance,
      builder: (context, _) {
        final isEnglish = LocaleController.instance.isEnglish;
        final isDark = Theme.of(context).brightness == Brightness.dark;

        Widget button = Tooltip(
          message: isEnglish
              ? 'Cambiar a Español (Switch to Spanish)'
              : 'Switch to English (Cambiar a Inglés)',
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => LocaleController.instance.toggleLanguage(),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 8 : 10,
                vertical: compact ? 4 : 6,
              ),
              decoration: BoxDecoration(
                color: isDark
                    ? (showBackground ? AppColors.darkCard : Colors.transparent)
                    : (showBackground ? Colors.white : Colors.transparent),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark
                      ? (isEnglish
                          ? AppColors.brightBlue
                          : AppColors.darkBorder)
                      : (isEnglish ? AppColors.blue : AppColors.border),
                  width: isEnglish ? 1.5 : 1.0,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.translate_rounded,
                    size: compact ? 15 : 17,
                    color: isEnglish
                        ? (isDark ? AppColors.sky : AppColors.blue)
                        : (isDark ? AppColors.darkTextMuted : AppColors.muted),
                  ),
                  const SizedBox(width: 5),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (child, animation) =>
                        ScaleTransition(scale: animation, child: child),
                    child: Text(
                      isEnglish ? 'EN' : 'ES',
                      key: ValueKey(isEnglish),
                      style: TextStyle(
                        fontSize: compact ? 11 : 12,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? (isEnglish ? AppColors.sky : AppColors.darkText)
                            : (isEnglish ? AppColors.blue : AppColors.navy),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        return button;
      },
    );
  }
}

/// Selector segmentado de idioma (Español / English) para perfiles y ajustes.
class LanguageSelector extends StatelessWidget {
  const LanguageSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LocaleController.instance,
      builder: (context, _) {
        final currentLang = LocaleController.instance.language;

        return SegmentedButton<AppLanguage>(
          segments: const [
            ButtonSegment(
              value: AppLanguage.es,
              icon: Icon(Icons.language, size: 18),
              label: Text('Español (ES)'),
            ),
            ButtonSegment(
              value: AppLanguage.en,
              icon: Icon(Icons.language, size: 18),
              label: Text('English (EN)'),
            ),
          ],
          selected: {currentLang},
          onSelectionChanged: (newSelection) {
            if (newSelection.isNotEmpty) {
              LocaleController.instance.setLanguage(newSelection.first);
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
