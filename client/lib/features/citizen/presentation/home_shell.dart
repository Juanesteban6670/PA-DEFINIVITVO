import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:cartagena_segura/core/data/location_service.dart';
import 'package:cartagena_segura/core/data/realtime_service.dart';
import 'package:cartagena_segura/core/data/report_draft_store.dart';
import 'package:cartagena_segura/core/data/session_controller.dart';
import 'package:cartagena_segura/core/localization/app_strings.dart';
import 'package:cartagena_segura/core/localization/language_widgets.dart';
import 'package:cartagena_segura/core/localization/locale_controller.dart';
import 'package:cartagena_segura/shared/live_status_badge.dart';
import 'package:cartagena_segura/shared/notifications_bell.dart';
import 'package:cartagena_segura/shared/theme.dart';

import 'analytics_citizen_screen.dart';
import 'incidents_map_screen.dart';
import 'my_reports_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';
import 'welcome_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({
    required this.session,
    this.initialIndex = 0,
    this.initialIncidentId,
    super.key,
  });

  final SessionController session;
  final int initialIndex;
  final String? initialIncidentId;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  late int _selectedIndex = widget.initialIndex;
  final _incidentRefresh = ValueNotifier<int>(0);
  late final ReportDraftStore _drafts;
  RealtimeAlertService? _realtimeService;

  @override
  void initState() {
    super.initState();
    _drafts = ReportDraftStore(
      storage: widget.session.storage,
      owner: widget.session.user?.username ?? 'ciudadano',
    );
    _realtimeService =
        RealtimeAlertService(baseUrl: widget.session.api.baseUrl);
    _realtimeService?.addIncidentListener(() {
      if (mounted) _incidentRefresh.value++;
    });
    _realtimeService?.addAlertListener(_onEmergencyAlertReceived);
    _realtimeService?.connect();
  }

  void _onEmergencyAlertReceived(Map<String, dynamic> alert) {
    if (!mounted) return;
    _incidentRefresh.value++;
    final type = alert['type']?.toString() ?? 'SOS';
    final loc = alert['location']?.toString() ?? 'Cartagena';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFFC0392B),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 6),
        content: Row(
          children: [
            const Icon(Icons.warning_amber_rounded,
                color: Colors.white, size: 24),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '🚨 ALERTA SOS EN TIEMPO REAL: $type en $loc',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _realtimeService?.dispose();
    _incidentRefresh.dispose();
    super.dispose();
  }

  void _selectTab(int index) {
    final location = switch (index) {
      0 => '/App',
      1 => '/App/Map',
      2 => '/App/Incidents',
      3 => '/App/Analytics',
      _ => '/App/Profile',
    };
    if (GoRouter.maybeOf(context) != null) {
      context.go(location);
    } else {
      setState(() => _selectedIndex = index);
    }
  }

  @override
  void didUpdateWidget(covariant HomeShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialIndex != widget.initialIndex) {
      _selectedIndex = widget.initialIndex;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LocaleController.instance,
      builder: (context, _) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final strings = LocaleController.instance.strings;
        final api = widget.session.api;
        final wideLayout = MediaQuery.sizeOf(context).width >= 700;
        final pages = [
          WelcomeScreen(
            session: widget.session,
            incidentRefresh: _incidentRefresh,
            onSelectTab: _selectTab,
          ),
          IncidentsMapScreen(api: api, incidentRefresh: _incidentRefresh),
          MyReportsScreen(
            api: api,
            drafts: _drafts,
            incidentRefresh: _incidentRefresh,
            onReportSubmitted: () => _incidentRefresh.value++,
            initialIncidentId: widget.initialIncidentId,
          ),
          AnalyticsCitizenScreen(api: api),
          ProfileScreen(session: widget.session),
        ];

        return Scaffold(
          backgroundColor: isDark ? AppColors.darkCanvas : AppColors.canvas,
          appBar: wideLayout
              ? AppBar(
            backgroundColor: isDark ? AppColors.darkCanvas : Colors.white,
            elevation: 0,
            scrolledUnderElevation: 0,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Divider(
                height: 1,
                color: isDark ? AppColors.darkBorder : AppColors.border,
              ),
            ),
            titleSpacing: 16,
            title: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.brightBlue.withValues(alpha: 0.12)
                        : AppColors.blue.withValues(alpha: 0.08),
                    border: Border.all(
                      color: isDark
                          ? AppColors.brightBlue.withValues(alpha: 0.25)
                          : AppColors.blue.withValues(alpha: 0.15),
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Image.asset('assets/brand/app-icon.png'),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cartagena Segura',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                          color: isDark ? AppColors.darkText : AppColors.navy,
                        ),
                      ),
                      Text(
                        'Ciudadano',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? AppColors.darkTextMuted
                              : AppColors.muted,
                          letterSpacing: -0.1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              if (wideLayout) ...[
                LiveStatusBadge(
                    realtimeService: _realtimeService, compact: true),
                const SizedBox(width: 4),
              ],
              // Botón SOS de Pánico
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: isDark ? AppColors.darkRed : AppColors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    visualDensity: VisualDensity.compact,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => _showSosDialog(context),
                  icon: const Icon(Icons.emergency_rounded, size: 16),
                  label: const Text(
                    'SOS 123',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, letterSpacing: -0.1),
                  ),
                ),
              ),
              if (wideLayout) ...[
                const SizedBox(width: 4),
                const LanguageToggleButton(),
              ],
              const SizedBox(width: 4),
              const ThemeToggleButton(),
              NotificationsBell(
                api: api,
                onPressed: () {
                  if (GoRouter.maybeOf(context) != null) {
                    context.push('/App/Notifications');
                  } else {
                    Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(
                        builder: (_) => NotificationsScreen(api: api),
                      ),
                    );
                  }
                },
              ),
              IconButton(
                tooltip: 'Perfil',
                onPressed: () => _selectTab(4),
                icon: CircleAvatar(
                  radius: 16,
                  backgroundColor: isDark ? AppColors.brightBlue : AppColors.blue,
                  child: Text(
                    (widget.session.user?.username.isNotEmpty ?? false)
                        ? widget.session.user!.username[0].toUpperCase()
                        : 'U',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
          ) : null,
          body: wideLayout
              ? Row(
                  children: [
                    NavigationRail(
                      selectedIndex: _selectedIndex,
                      onDestinationSelected: _selectTab,
                      backgroundColor: isDark ? const Color(0xFF121214) : AppColors.canvas,
                      extended: MediaQuery.sizeOf(context).width >= 1000,
                      labelType: MediaQuery.sizeOf(context).width >= 1000
                          ? null
                          : NavigationRailLabelType.all,
                      destinations: _buildRailDestinations(strings),
                    ),
                    VerticalDivider(
                      width: 1,
                      color: isDark ? AppColors.darkBorder : AppColors.border,
                    ),
                    Expanded(
                      child: IndexedStack(
                        index: _selectedIndex,
                        children: pages,
                      ),
                    ),
                  ],
                )
              : IndexedStack(index: _selectedIndex, children: pages),
          bottomNavigationBar: wideLayout
              ? null
              : Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF161618) : Colors.white,
                    border: Border(
                      top: BorderSide(
                        color: isDark ? AppColors.darkBorder : AppColors.border,
                        width: 0.8,
                      ),
                    ),
                  ),
                  child: NavigationBarTheme(
                    data: NavigationBarThemeData(
                      backgroundColor: isDark ? const Color(0xFF161618) : Colors.white,
                      elevation: 0,
                      height: 66,
                      indicatorColor: (isDark ? AppColors.brightBlue : AppColors.blue).withValues(alpha: 0.12),
                      indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      iconTheme: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.selected)) {
                          return IconThemeData(
                            color: isDark ? AppColors.brightBlue : AppColors.blue,
                            size: 22,
                          );
                        }
                        return IconThemeData(
                          color: isDark ? AppColors.darkTextMuted : AppColors.muted,
                          size: 22,
                        );
                      }),
                      labelTextStyle: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.selected)) {
                          return TextStyle(
                            color: isDark ? AppColors.brightBlue : AppColors.blue,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.1,
                          );
                        }
                        return TextStyle(
                          color: isDark ? AppColors.darkTextMuted : AppColors.muted,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          letterSpacing: -0.1,
                        );
                      }),
                    ),
                    child: NavigationBar(
                      selectedIndex: _selectedIndex,
                      onDestinationSelected: _selectTab,
                      destinations: _buildNavDestinations(strings),
                    ),
                  ),
                ),
        );
      },
    );
  }

  List<NavigationDestination> _buildNavDestinations(AppStrings strings) => [
        NavigationDestination(
          icon: const Icon(Icons.home_outlined),
          selectedIcon: const Icon(Icons.home_rounded),
          label: strings.navHome,
        ),
        NavigationDestination(
          icon: const Icon(Icons.map_outlined),
          selectedIcon: const Icon(Icons.map_rounded),
          label: strings.navMap,
        ),
        NavigationDestination(
          icon: const Icon(Icons.assignment_outlined),
          selectedIcon: const Icon(Icons.assignment_rounded),
          label: strings.navReports,
        ),
        NavigationDestination(
          icon: const Icon(Icons.bar_chart_rounded),
          selectedIcon: const Icon(Icons.bar_chart_rounded),
          label: strings.navAnalytics,
        ),
        NavigationDestination(
          icon: const Icon(Icons.person_outline_rounded),
          selectedIcon: const Icon(Icons.person_rounded),
          label: strings.navProfile,
        ),
      ];

  List<NavigationRailDestination> _buildRailDestinations(AppStrings strings) =>
      [
        NavigationRailDestination(
          icon: const Icon(Icons.home_outlined),
          selectedIcon: const Icon(Icons.home_rounded),
          label: Text(strings.navHome),
        ),
        NavigationRailDestination(
          icon: const Icon(Icons.map_outlined),
          selectedIcon: const Icon(Icons.map_rounded),
          label: Text(strings.navMap),
        ),
        NavigationRailDestination(
          icon: const Icon(Icons.assignment_outlined),
          selectedIcon: const Icon(Icons.assignment_rounded),
          label: Text(strings.navReports),
        ),
        NavigationRailDestination(
          icon: const Icon(Icons.bar_chart_rounded),
          selectedIcon: const Icon(Icons.bar_chart_rounded),
          label: Text(strings.navAnalytics),
        ),
        NavigationRailDestination(
          icon: const Icon(Icons.person_outline_rounded),
          selectedIcon: const Icon(Icons.person_rounded),
          label: Text(strings.navProfile),
        ),
      ];

  void _showSosDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        final isDark = Theme.of(dialogCtx).brightness == Brightness.dark;
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
          contentPadding: const EdgeInsets.symmetric(horizontal: 24),
          actionsPadding: const EdgeInsets.all(16),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.emergency_rounded,
                  color: AppColors.red,
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Modo de Pánico SOS',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Si te encuentras ante peligro inminente o requieres intervención urgente de la Policía Nacional:',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark
                      ? AppColors.darkTextMuted
                      : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () async {
                  final uri = Uri(scheme: 'tel', path: '123');
                  await launchUrl(uri);
                },
                icon: const Icon(Icons.phone_in_talk_rounded),
                label: const Text(
                  'Llamar al 123 (Policía Nacional)',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () async {
                  try {
                    final pos = await LocationService.currentPosition();
                    final link =
                        'https://maps.google.com/?q=${pos.latitude},${pos.longitude}';
                    await Clipboard.setData(
                      ClipboardData(
                        text:
                            '¡ALERTA SOS en Cartagena! Necesito ayuda urgente en mi ubicación: $link',
                      ),
                    );
                    if (context.mounted) {
                      Navigator.of(dialogCtx).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Ubicación GPS copiada al portapapeles. Pégala en WhatsApp o SMS.',
                          ),
                          duration: Duration(seconds: 4),
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'No fue posible obtener la ubicación GPS: $e',
                          ),
                        ),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.share_location_rounded),
                label: const Text(
                  'Copiar mi ubicación GPS para WhatsApp',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }
}
