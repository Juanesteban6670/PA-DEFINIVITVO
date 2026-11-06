import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:cartagena_segura/shared/theme.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  static final _featuresKey = GlobalKey();
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
