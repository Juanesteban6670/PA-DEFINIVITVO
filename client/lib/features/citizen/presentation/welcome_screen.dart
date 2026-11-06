import 'package:flutter/material.dart';

import 'package:cartagena_segura/core/data/incident_repository.dart';
import 'package:cartagena_segura/core/data/models.dart';
import 'package:cartagena_segura/core/data/session_controller.dart';
import 'package:cartagena_segura/shared/theme.dart';

import 'citizen_chat_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({
    required this.session,
    required this.incidentRefresh,
    required this.onSelectTab,
    super.key,
  });

  final SessionController session;
  final ValueNotifier<int> incidentRefresh;
  final ValueChanged<int> onSelectTab;

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  late Future<List<Incident>> _incidents;

  @override
  void initState() {
    super.initState();
    widget.incidentRefresh.addListener(_reload);
    _incidents = loadIncidents(widget.session.api, mine: true);
  }

  @override
  void didUpdateWidget(covariant WelcomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.incidentRefresh != widget.incidentRefresh) {
      oldWidget.incidentRefresh.removeListener(_reload);
      widget.incidentRefresh.addListener(_reload);
    }
  }

  @override
  void dispose() {
    widget.incidentRefresh.removeListener(_reload);
    super.dispose();
  }

  void _reload() {
    if (mounted) {
      setState(() {
        _incidents = loadIncidents(widget.session.api, mine: true);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.session.user!;
    final now = DateTime.now();
    final greeting = now.hour < 12
        ? 'Buenos días'
        : now.hour < 18
        ? 'Buenas tardes'
        : 'Buenas noches';
    final name = user.fullName.isEmpty ? user.username : user.fullName;
    return FutureBuilder<List<Incident>>(
      future: _incidents,
      builder: (context, snapshot) {
        final incidents = snapshot.data ?? const <Incident>[];
        final stats = [
          _Stat('Total', incidents.length, AppColors.brightBlue),
          _Stat(
            'Pendientes',
            incidents.where((item) => item.status == 'PENDING').length,
            AppColors.amber,
          ),
          _Stat(
            'En progreso',
            incidents.where((item) => item.status == 'IN_PROGRESS').length,
            AppColors.blue,
          ),
          _Stat(
            'Resueltos',
            incidents.where((item) => item.status == 'RESOLVED').length,
            AppColors.green,
          ),
        ];
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            _HeroBanner(
              greeting: greeting,
              name: name,
              onReport: () => widget.onSelectTab(1),
            ),
            const SizedBox(height: 18),
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth < 420 ? 2 : 4;
                final cardWidth =
                    (constraints.maxWidth - 8 * (columns - 1)) / columns;
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final stat in stats)
                      SizedBox(
                        width: cardWidth,
                        child: _StatCard(
                          stat: stat,
                          loading:
                              snapshot.connectionState ==
                              ConnectionState.waiting,
                        ),
                      ),
                  ],
                );
              },
            ),
            if (snapshot.hasError) ...[
              const SizedBox(height: 12),
              _InlineError(
                message: snapshot.error.toString(),
                onRetry: _reload,
              ),
            ],
            const SizedBox(height: 22),
            const _SectionLabel('Accesos rápidos'),
            const SizedBox(height: 10),
            _QuickAction(
              icon: Icons.assignment_outlined,
              label: 'Mis reportes',
              subtitle: 'Consulta el estado de tus casos',
              accent: AppColors.amber,
              onTap: () => widget.onSelectTab(1),
            ),
            const SizedBox(height: 10),
            _QuickAction(
              icon: Icons.map_outlined,
              label: 'Mapa ciudadano',
              subtitle: 'Explora incidentes reportados',
              accent: AppColors.blue,
              onTap: () => widget.onSelectTab(2),
            ),
            const SizedBox(height: 10),
            _QuickAction(
              icon: Icons.phone_outlined,
              label: 'Emergencias',
              subtitle: 'Encuentra contactos de ayuda',
              accent: AppColors.red,
              onTap: () => widget.onSelectTab(3),
            ),
            const SizedBox(height: 10),
            _QuickAction(
              icon: Icons.chat_bubble_outline,
              label: 'Asistente ciudadano',
              subtitle: 'Resuelve dudas sobre seguridad',
              accent: AppColors.brightBlue,
              onTap: () => Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => CitizenChatScreen(session: widget.session),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF2A1111)
                    : const Color(0xFFFFF5F5),
                border: Border.all(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF5C1D1D)
                      : const Color(0xFFFEE2E2),
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, color: AppColors.red),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Si existe un peligro inmediato, comunícate directamente con la línea de emergencias 123.',
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFFFCA5A5)
                            : const Color(0xFF991B1B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner({
    required this.greeting,
    required this.name,
    required this.onReport,
  });

  final String greeting;
  final String name;
  final VoidCallback onReport;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.navy, AppColors.navyBlue, AppColors.blue],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.circle, size: 9, color: Color(0xFF34D399)),
              SizedBox(width: 7),
              Text(
                'SISTEMA ACTIVO',
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(greeting, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 2),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Ciudadano activo · Cartagena Segura',
            style: TextStyle(color: Colors.white60, fontSize: 12),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.blue,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: onReport,
            icon: const Icon(Icons.add, size: 18),
            label: const Text(
              'Nuevo reporte',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat {
  const _Stat(this.label, this.value, this.color);

  final String label;
  final int value;
  final Color color;
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.stat, required this.loading});

  final _Stat stat;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 5),
        child: Column(
          children: [
            if (loading)
              const SizedBox(
                height: 26,
                width: 26,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Text(
                '${stat.value}',
                style: TextStyle(
                  color: stat.color,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            const SizedBox(height: 4),
            Text(
              stat.label.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 8,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.title);

  final String title;

  @override
  Widget build(BuildContext context) => Text(
    title.toUpperCase(),
    style: const TextStyle(
      color: AppColors.muted,
      fontSize: 11,
      fontWeight: FontWeight.w800,
      letterSpacing: 1,
    ),
  );
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.accent,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: accent.withValues(alpha: 0.1),
          foregroundColor: accent,
          child: Icon(icon),
        ),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right, color: AppColors.muted),
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'No se pudo cargar tu resumen',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 5),
          Text(message, style: const TextStyle(color: AppColors.muted)),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ),
        ],
      ),
    ),
  );
}
