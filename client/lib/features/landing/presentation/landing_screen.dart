import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:cartagena_segura/shared/theme.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  static final _featuresKey = GlobalKey();
  static final _chartsKey = GlobalKey();
  static final _missionKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 900;
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            title: Row(
              children: [
                Image.asset('assets/brand/app-icon.png', width: 36, height: 36),
                const SizedBox(width: 10),
                const Text('Cartagena Segura'),
              ],
            ),
            actions: [
              if (wide) ...[
                TextButton(
                  onPressed: () => _scrollTo(_featuresKey),
                  child: const Text('Funciones'),
                ),
                TextButton(
                  onPressed: () => _scrollTo(_chartsKey),
                  child: const Text('Métricas en Vivo'),
                ),
                TextButton(
                  onPressed: () => _scrollTo(_missionKey),
                  child: const Text('Nuestra misión'),
                ),
              ],
              const ThemeToggleButton(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: FilledButton(
                  onPressed: () => context.go('/Login'),
                  child: const Text('Ingresar'),
                ),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                _hero(context, wide),
                _features(context),
                _dynamicCharts(context),
                _mission(context),
                _howItWorks(context),
                _faq(context),
                _footer(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _hero(BuildContext context, bool wide) => Container(
    width: double.infinity,
    padding: EdgeInsets.symmetric(
      horizontal: wide ? 48 : 24,
      vertical: wide ? 96 : 56,
    ),
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.navy, AppColors.navyBlue, AppColors.blue],
      ),
    ),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1120),
        child: Wrap(
          spacing: 48,
          runSpacing: 32,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: wide ? 520 : 700,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Chip(
                    avatar: Icon(Icons.shield_outlined, size: 18),
                    label: Text('Seguridad ciudadana'),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Una ciudad más segura empieza contigo',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      height: 1.08,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Reporta incidentes, consulta información y encuentra ayuda de emergencia en Cartagena.',
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(color: Colors.white70, height: 1.55),
                  ),
                  const SizedBox(height: 26),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      FilledButton.icon(
                        onPressed: () => context.go('/Register'),
                        icon: const Icon(Icons.person_add_alt_1),
                        label: const Text('Crear cuenta'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => context.go('/Login'),
                        icon: const Icon(Icons.login),
                        label: const Text('Iniciar sesión'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white54),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 36),
                  const _AnimatedHeroStats(),
                ],
              ),
            ),
            SizedBox(
              width: wide ? 460 : 700,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Image.asset(
                  'assets/brand/login-background.png',
                  height: wide ? 320 : 220,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 250,
                    color: Colors.white12,
                    child: const Center(
                      child: Icon(
                        Icons.location_city,
                        color: Colors.white,
                        size: 96,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _features(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _section(
      context,
      sectionKey: _featuresKey,
      title: 'Herramientas para cuidarnos entre todos',
      subtitle: 'Información clara, inteligencia artificial y canales de atención para actuar a tiempo.',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 840;
          return Column(
            children: [
              if (wide) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: _BentoCard(
                        icon: Icons.map_rounded,
                        accentColor: AppColors.brightBlue,
                        badge: 'Tiempo Real',
                        title: 'Mapa Geoespacial Interactivo',
                        description: 'Visualiza incidentes reportados, cuadrantes policiales, sectores de riesgo distritales y cálculo de rutas seguras tipo Waze.',
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: _BentoCard(
                        icon: Icons.auto_awesome_rounded,
                        accentColor: const Color(0xFF8B5CF6),
                        badge: 'IA Contextual',
                        title: 'Asistente Ciudadano IA',
                        description: 'Orientación inmediata 24/7 sobre números de emergencia, rutas preventivas y protocolos distritales.',
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: _BentoCard(
                        icon: Icons.emergency_rounded,
                        accentColor: AppColors.red,
                        badge: 'Respuesta Rápida',
                        title: 'SOS 123 y Directorio',
                        description: 'Llamada rápida y copia instantánea de coordenadas GPS exactas para compartir con autoridades o familiares.',
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 3,
                      child: _BentoCard(
                        icon: Icons.campaign_rounded,
                        accentColor: AppColors.amber,
                        badge: 'Participación Activa',
                        title: 'Reporte y Alertas Ciudadanas',
                        description: 'Crea reportes geolocalizados con evidencia fotográfica. La comunidad y las autoridades reciben alertas prioritarias.',
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
              ] else ...[
                _BentoCard(
                  icon: Icons.map_rounded,
                  accentColor: AppColors.brightBlue,
                  badge: 'Tiempo Real',
                  title: 'Mapa Geoespacial Interactivo',
                  description: 'Visualiza incidentes reportados, cuadrantes policiales y rutas seguras tipo Waze.',
                  isDark: isDark,
                ),
                const SizedBox(height: 14),
                _BentoCard(
                  icon: Icons.auto_awesome_rounded,
                  accentColor: const Color(0xFF8B5CF6),
                  badge: 'IA Contextual',
                  title: 'Asistente Ciudadano IA',
                  description: 'Orientación inmediata 24/7 sobre cuadrantes y protocolos distritales.',
                  isDark: isDark,
                ),
                const SizedBox(height: 14),
                _BentoCard(
                  icon: Icons.emergency_rounded,
                  accentColor: AppColors.red,
                  badge: 'Respuesta Rápida',
                  title: 'SOS 123 y Directorio',
                  description: 'Llamada rápida y copia instantánea de coordenadas GPS exactas.',
                  isDark: isDark,
                ),
                const SizedBox(height: 14),
                _BentoCard(
                  icon: Icons.campaign_rounded,
                  accentColor: AppColors.amber,
                  badge: 'Participación Activa',
                  title: 'Reporte y Alertas Ciudadanas',
                  description: 'Crea reportes geolocalizados con evidencia fotográfica y seguimiento oficial.',
                  isDark: isDark,
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _dynamicCharts(BuildContext context) => _section(
    context,
    sectionKey: _chartsKey,
    title: 'Métricas de Impacto y Seguridad Distrital',
    subtitle: 'Monitoreo interactivo en tiempo real de cuadrantes, respuesta a emergencias y resolución ciudadana.',
    child: const _DynamicAnalyticsDashboard(),
  );

  Widget _mission(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      color: isDark ? AppColors.darkSurface : const Color(0xFFF1F5F9),
      child: _section(
        context,
        sectionKey: _missionKey,
        title: 'Una comunidad conectada',
        subtitle: 'Cartagena Segura facilita la comunicación entre la ciudadanía y las autoridades, con herramientas accesibles desde el teléfono o el computador.',
        child: const SizedBox.shrink(),
      ),
    );
  }

  Widget _howItWorks(BuildContext context) => _section(
    context,
    title: '¿Cómo empezar?',
    subtitle: 'Tres pasos sencillos para participar.',
    child: const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          leading: CircleAvatar(child: Text('1')),
          title: Text('Crea tu cuenta'),
          subtitle: Text('Regístrate con tus datos de contacto.'),
        ),
        ListTile(
          leading: CircleAvatar(child: Text('2')),
          title: Text('Consulta o reporta'),
          subtitle: Text('Describe la situación y su ubicación.'),
        ),
        ListTile(
          leading: CircleAvatar(child: Text('3')),
          title: Text('Sigue la información'),
          subtitle: Text('Consulta el estado de tus reportes.'),
        ),
      ],
    ),
  );

  Widget _faq(BuildContext context) => _section(
    context,
    title: 'Preguntas frecuentes',
    subtitle: 'Información para usar la plataforma.',
    child: const Column(
      children: [
        ExpansionTile(
          title: Text('¿Necesito permitir mi ubicación?'),
          children: [
            Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'No. Puedes escribir una dirección o referencia; compartir GPS es opcional.',
              ),
            ),
          ],
        ),
        ExpansionTile(
          title: Text('¿Qué hago ante una emergencia inmediata?'),
          children: [
            Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Comunícate directamente con los servicios de emergencia de tu zona.',
              ),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _footer(BuildContext context) => Container(
    width: double.infinity,
    color: AppColors.navy,
    padding: const EdgeInsets.all(28),
    child: const Text(
      'Cartagena Segura · Participación ciudadana',
      textAlign: TextAlign.center,
      style: TextStyle(color: Colors.white70),
    ),
  );

  Widget _section(
    BuildContext context, {
    Key? sectionKey,
    required String title,
    required String subtitle,
    required Widget child,
  }) => Padding(
    key: sectionKey,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(subtitle, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 20),
            child,
          ],
        ),
      ),
    ),
  );

  void _scrollTo(GlobalKey key) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final target = key.currentContext;
      if (target == null) return;
      Scrollable.ensureVisible(
        target,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    });
  }
}

class _AnimatedHeroStats extends StatelessWidget {
  const _AnimatedHeroStats();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 24,
      runSpacing: 16,
      children: const [
        _CounterItem(value: 25, prefix: '+', label: 'Incidentes gestionados'),
        _CounterItem(value: 10, label: 'Sectores monitoreados'),
        _TextStatItem(value: '24/7', label: 'Asistencia IA'),
        _TextStatItem(value: '100%', label: 'Gratuito y público'),
      ],
    );
  }
}

class _CounterItem extends StatelessWidget {
  const _CounterItem({
    required this.value,
    required this.label,
    this.prefix = '',
  });

  final int value;
  final String label;
  final String prefix;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: const Duration(milliseconds: 1600),
      curve: Curves.easeOutCubic,
      builder: (context, val, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$prefix${val.toInt()}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TextStatItem extends StatelessWidget {
  const _TextStatItem({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _BentoCard extends StatelessWidget {
  const _BentoCard({
    required this.icon,
    required this.accentColor,
    required this.badge,
    required this.title,
    required this.description,
    required this.isDark,
  });

  final IconData icon;
  final Color accentColor;
  final String badge;
  final String title;
  final String description;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: isDark ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: accentColor.withValues(alpha: isDark ? 0.35 : 0.2),
                  ),
                ),
                child: Icon(icon, color: accentColor, size: 22),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: isDark ? 0.18 : 0.08),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: accentColor.withValues(alpha: isDark ? 0.3 : 0.15),
                  ),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: isDark ? AppColors.darkText : AppColors.navy,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: isDark ? AppColors.darkTextMuted : AppColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _DynamicAnalyticsDashboard extends StatefulWidget {
  const _DynamicAnalyticsDashboard();

  @override
  State<_DynamicAnalyticsDashboard> createState() =>
      _DynamicAnalyticsDashboardState();
}

class _DynamicAnalyticsDashboardState
    extends State<_DynamicAnalyticsDashboard> {
  int _selectedPeriod = 0; // 0: 7 Días, 1: 30 Días, 2: Histórico 2026
  int _selectedChart = 0; // 0: Tendencia, 1: Sectores, 2: Tipología
  int _touchedPieIndex = -1;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = MediaQuery.sizeOf(context).width < 768;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Live status header
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.green.withValues(alpha: isDark ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: AppColors.green.withValues(alpha: 0.35),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.fiber_manual_record, color: AppColors.green, size: 10),
                  SizedBox(width: 6),
                  Text(
                    'Monitoreo Distrital en Vivo',
                    style: TextStyle(
                      color: AppColors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            Text(
              'Actualizado cada 30s',
              style: TextStyle(
                color: isDark ? AppColors.darkTextMuted : AppColors.muted,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),

        // 4 KPI Summary Cards
        LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = constraints.maxWidth >= 900
                ? (constraints.maxWidth - 36) / 4
                : constraints.maxWidth >= 600
                    ? (constraints.maxWidth - 12) / 2
                    : constraints.maxWidth;

            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _kpiCard(
                  title: 'Tiempo de Respuesta',
                  value: '3.2 min',
                  badge: '⚡ -18% vs mes anterior',
                  badgeColor: AppColors.green,
                  icon: Icons.timer_outlined,
                  isDark: isDark,
                  width: cardWidth,
                ),
                _kpiCard(
                  title: 'Tasa de Resolución',
                  value: '97.4%',
                  badge: '🛡️ Alta efectividad',
                  badgeColor: AppColors.brightBlue,
                  icon: Icons.verified_user_outlined,
                  isDark: isDark,
                  width: cardWidth,
                ),
                _kpiCard(
                  title: 'Cuadrantes Activos',
                  value: '14 / 14',
                  badge: '📍 100% Cobertura',
                  badgeColor: AppColors.sky,
                  icon: Icons.share_location_rounded,
                  isDark: isDark,
                  width: cardWidth,
                ),
                _kpiCard(
                  title: 'Alertas Gestionadas',
                  value: '+1,280',
                  badge: '🤝 Red ciudadana',
                  badgeColor: AppColors.amber,
                  icon: Icons.notifications_active_outlined,
                  isDark: isDark,
                  width: cardWidth,
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 24),

        // Toolbar: Chart type switcher & Period selector
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.border,
            ),
          ),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Chart Type Switcher
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _chartTabButton(0, '📈 Tendencia y Resolución', isDark),
                    const SizedBox(width: 8),
                    _chartTabButton(1, '📊 Actividad por Sectores', isDark),
                    const SizedBox(width: 8),
                    _chartTabButton(2, '🍩 Tipología de Alertas', isDark),
                  ],
                ),
              ),

              // Period Switcher
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 0, label: Text('7 Días')),
                  ButtonSegment(value: 1, label: Text('30 Días')),
                  ButtonSegment(value: 2, label: Text('2026 Histórico')),
                ],
                selected: {_selectedPeriod},
                onSelectionChanged: (val) {
                  setState(() => _selectedPeriod = val.first);
                },
                style: SegmentedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Main Chart Box
        Container(
          height: isMobile ? 360 : 420,
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.border,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.04),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _buildActiveChart(isDark, isMobile),
          ),
        ),
      ],
    );
  }

  Widget _chartTabButton(int index, String label, bool isDark) {
    final active = _selectedChart == index;
    return InkWell(
      onTap: () => setState(() => _selectedChart = index),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active
              ? (isDark ? AppColors.blue.withValues(alpha: 0.3) : AppColors.blue)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active
                ? AppColors.brightBlue
                : (isDark ? AppColors.darkBorder : AppColors.border),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active
                ? Colors.white
                : (isDark ? AppColors.darkTextMuted : AppColors.navy),
            fontSize: 12,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _kpiCard({
    required String title,
    required String value,
    required String badge,
    required Color badgeColor,
    required IconData icon,
    required bool isDark,
    required double width,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: badgeColor, size: 18),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    color: badgeColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: isDark ? AppColors.darkText : AppColors.navy,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.darkTextMuted : AppColors.muted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveChart(bool isDark, bool isMobile) {
    switch (_selectedChart) {
      case 0:
        return _buildLineChart(isDark, isMobile);
      case 1:
        return _buildBarChart(isDark, isMobile);
      case 2:
        return _buildPieChart(isDark, isMobile);
      default:
        return const SizedBox.shrink();
    }
  }

  // 1. Line Chart (Tendencia y Resolución)
  Widget _buildLineChart(bool isDark, bool isMobile) {
    final List<FlSpot> reportados;
    final List<FlSpot> resueltos;
    final List<String> labels;

    if (_selectedPeriod == 0) {
      // 7 Días
      labels = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
      reportados = const [
        FlSpot(0, 14),
        FlSpot(1, 19),
        FlSpot(2, 12),
        FlSpot(3, 24),
        FlSpot(4, 18),
        FlSpot(5, 29),
        FlSpot(6, 22),
      ];
      resueltos = const [
        FlSpot(0, 13),
        FlSpot(1, 18),
        FlSpot(2, 12),
        FlSpot(3, 23),
        FlSpot(4, 17),
        FlSpot(5, 27),
        FlSpot(6, 21),
      ];
    } else if (_selectedPeriod == 1) {
      // 30 Días (4 semanas)
      labels = ['Sem 1', 'Sem 2', 'Sem 3', 'Sem 4'];
      reportados = const [
        FlSpot(0, 110),
        FlSpot(1, 145),
        FlSpot(2, 125),
        FlSpot(3, 160),
      ];
      resueltos = const [
        FlSpot(0, 105),
        FlSpot(1, 140),
        FlSpot(2, 122),
        FlSpot(3, 155),
      ];
    } else {
      // Histórico 2026 (6 meses)
      labels = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun'];
      reportados = const [
        FlSpot(0, 320),
        FlSpot(1, 410),
        FlSpot(2, 380),
        FlSpot(3, 490),
        FlSpot(4, 460),
        FlSpot(5, 520),
      ];
      resueltos = const [
        FlSpot(0, 310),
        FlSpot(1, 395),
        FlSpot(2, 372),
        FlSpot(3, 475),
        FlSpot(4, 452),
        FlSpot(5, 510),
      ];
    }

    return Column(
      key: ValueKey('line_$_selectedPeriod'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Incidentes Reportados vs Atendidos con Éxito',
                  style: TextStyle(
                    fontSize: isMobile ? 13 : 15,
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppColors.darkText : AppColors.navy,
                  ),
                ),
                Text(
                  'Evolución temporal con verificación de cuadrantes policiales',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.darkTextMuted : AppColors.muted,
                  ),
                ),
              ],
            ),
            const Spacer(),
            // Legend
            _legendItem('Reportados', AppColors.sky),
            const SizedBox(width: 12),
            _legendItem('Resueltos', AppColors.green),
          ],
        ),
        const SizedBox(height: 20),
        Expanded(
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: _selectedPeriod == 0 ? 5 : (_selectedPeriod == 1 ? 40 : 100),
                getDrawingHorizontalLine: (value) => FlLine(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.black.withValues(alpha: 0.05),
                  strokeWidth: 1,
                ),
              ),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 36,
                    getTitlesWidget: (val, meta) => Text(
                      val.toInt().toString(),
                      style: TextStyle(
                        fontSize: 10,
                        color: isDark ? AppColors.darkTextMuted : AppColors.muted,
                      ),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (val, meta) {
                      final idx = val.toInt();
                      if (idx >= 0 && idx < labels.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            labels[idx],
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.darkTextMuted : AppColors.navy,
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                // Reportados
                LineChartBarData(
                  spots: reportados,
                  isCurved: true,
                  color: AppColors.sky,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: true),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.sky.withValues(alpha: 0.28),
                        AppColors.sky.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
                // Resueltos
                LineChartBarData(
                  spots: resueltos,
                  isCurved: true,
                  color: AppColors.green,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: true),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.green.withValues(alpha: 0.22),
                        AppColors.green.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 2. Bar Chart (Sectores y Cuadrantes)
  Widget _buildBarChart(bool isDark, bool isMobile) {
    final sectors = ['Centro', 'Bocagrande', 'Getsemaní', 'Manga', 'Olaya H.', 'El Pozón'];
    final counts = _selectedPeriod == 0
        ? [28.0, 22.0, 18.0, 14.0, 34.0, 39.0]
        : _selectedPeriod == 1
            ? [120.0, 95.0, 78.0, 64.0, 145.0, 168.0]
            : [480.0, 390.0, 320.0, 270.0, 590.0, 680.0];

    final colors = [
      AppColors.green,
      AppColors.brightBlue,
      AppColors.sky,
      const Color(0xFF06B6D4), // Cyan
      AppColors.amber,
      AppColors.red,
    ];

    return Column(
      key: ValueKey('bar_$_selectedPeriod'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Volumen de Atención por Sectores Distritales',
                  style: TextStyle(
                    fontSize: isMobile ? 13 : 15,
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppColors.darkText : AppColors.navy,
                  ),
                ),
                Text(
                  'Comportamiento por cuadrantes turísticos y residenciales prioritarios',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.darkTextMuted : AppColors.muted,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),
        Expanded(
          child: BarChart(
            BarChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (val) => FlLine(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.black.withValues(alpha: 0.05),
                  strokeWidth: 1,
                ),
              ),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 36,
                    getTitlesWidget: (val, meta) => Text(
                      val.toInt().toString(),
                      style: TextStyle(
                        fontSize: 10,
                        color: isDark ? AppColors.darkTextMuted : AppColors.muted,
                      ),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (val, meta) {
                      final idx = val.toInt();
                      if (idx >= 0 && idx < sectors.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            sectors[idx],
                            style: TextStyle(
                              fontSize: isMobile ? 9 : 11,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.darkTextMuted : AppColors.navy,
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              barGroups: [
                for (int i = 0; i < sectors.length; i++)
                  BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: counts[i],
                        color: colors[i],
                        width: isMobile ? 16 : 28,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 3. Pie Chart (Tipología de Alertas)
  Widget _buildPieChart(bool isDark, bool isMobile) {
    final categories = [
      {'name': 'Seguridad y Vigilancia', 'pct': 38, 'color': AppColors.brightBlue, 'icon': Icons.shield_outlined},
      {'name': 'Alumbrado y Vías', 'pct': 26, 'color': AppColors.amber, 'icon': Icons.lightbulb_outline},
      {'name': 'Convivencia y Ruido', 'pct': 20, 'color': const Color(0xFF8B5CF6), 'icon': Icons.volume_up_outlined},
      {'name': 'Emergencias SOS', 'pct': 16, 'color': AppColors.red, 'icon': Icons.emergency_outlined},
    ];

    return Column(
      key: const ValueKey('pie_chart'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Distribución por Tipología de Incidentes',
                  style: TextStyle(
                    fontSize: isMobile ? 13 : 15,
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppColors.darkText : AppColors.navy,
                  ),
                ),
                Text(
                  'Toca o pasa el cursor para expandir cada categoría',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.darkTextMuted : AppColors.muted,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: PieChart(
                  PieChartData(
                    pieTouchData: PieTouchData(
                      touchCallback: (FlTouchEvent event, pieTouchResponse) {
                        setState(() {
                          if (!event.isInterestedForInteractions ||
                              pieTouchResponse == null ||
                              pieTouchResponse.touchedSection == null) {
                            _touchedPieIndex = -1;
                            return;
                          }
                          _touchedPieIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                        });
                      },
                    ),
                    borderData: FlBorderData(show: false),
                    sectionsSpace: 3,
                    centerSpaceRadius: isMobile ? 32 : 55,
                    sections: [
                      for (int i = 0; i < categories.length; i++) ...[
                        PieChartSectionData(
                          color: categories[i]['color'] as Color,
                          value: (categories[i]['pct'] as int).toDouble(),
                          title: '${categories[i]['pct']}%',
                          radius: (_touchedPieIndex == i) ? (isMobile ? 55 : 68) : (isMobile ? 42 : 54),
                          titleStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 4,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (int i = 0; i < categories.length; i++) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: categories[i]['color'] as Color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                categories[i]['name'] as String,
                                style: TextStyle(
                                  fontSize: isMobile ? 11 : 13,
                                  fontWeight: _touchedPieIndex == i
                                      ? FontWeight.w800
                                      : FontWeight.w500,
                                  color: isDark ? AppColors.darkText : AppColors.navy,
                                ),
                              ),
                            ),
                            Text(
                              '${categories[i]['pct']}%',
                              style: TextStyle(
                                fontSize: isMobile ? 11 : 13,
                                fontWeight: FontWeight.w800,
                                color: categories[i]['color'] as Color,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _legendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
