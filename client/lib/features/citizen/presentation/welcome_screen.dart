import 'package:flutter/material.dart';

import 'package:cartagena_segura/core/data/incident_repository.dart';
import 'package:cartagena_segura/core/data/models.dart';
import 'package:cartagena_segura/core/data/session_controller.dart';
import 'package:cartagena_segura/shared/responsive_layout.dart';
import 'package:cartagena_segura/shared/theme.dart';

import 'citizen_chat_screen.dart';
import 'notifications_screen.dart';

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
  List<dynamic> _zones = [];
  String _selectedSector = 'Todos';

  final List<String> _sectors = const [
    'Todos',
    'Centro Histórico',
    'Bocagrande',
    'Manga',
    'Getsemaní',
    'Bazurto',
    'Olaya Herrera',
  ];

  @override
  void initState() {
    super.initState();
    widget.incidentRefresh.addListener(_reload);
    _incidents = loadIncidents(widget.session.api, mine: false);
    _loadZones();
  }

  Future<void> _loadZones() async {
    try {
      final res = await widget.session.api.get('Zones');
      final list = res is List
          ? res
          : (res is Map<String, dynamic> && res['data'] is List ? res['data'] as List : null);
      if (list != null && mounted) {
        setState(() => _zones = list);
      }
    } catch (_) {}
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
        _incidents = loadIncidents(widget.session.api, mine: false);
        _loadZones();
      });
    }
  }

  String _formatTimeAgo(DateTime? date) {
    if (date == null) return 'Reciente';
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) {
      final mins = diff.inMinutes <= 0 ? 1 : diff.inMinutes;
      return 'Hace $mins min';
    }
    if (diff.inHours < 24) {
      return 'Hace ${diff.inHours} h';
    }
    if (diff.inDays == 1) {
      return 'Ayer';
    }
    return 'Hace ${diff.inDays} d';
  }

  (String, Color, Color, IconData) _getCategoryMeta(String type, bool isDark) {
    final t = type.toUpperCase();
    if (t.contains('TRAF') || t.contains('TRANSIT') || t.contains('CONGESTION')) {
      return (
        'Tráfico',
        isDark ? const Color(0xFFFBBF24) : const Color(0xFF9A6200),
        isDark ? const Color(0xFF451A03) : const Color(0xFFFFF4DC),
        Icons.directions_car_rounded,
      );
    }
    if (t.contains('ROBO') || t.contains('HURTO') || t.contains('SEGURIDAD') || t.contains('SOS') || t.contains('PELEA') || t.contains('ALTERCADO')) {
      return (
        'Seguridad',
        isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626),
        isDark ? const Color(0xFF450A0A) : const Color(0xFFFEE2E2),
        Icons.shield_outlined,
      );
    }
    if (t.contains('VIA') || t.contains('OBRA') || t.contains('OBSTACULO') || t.contains('PAVIMENT')) {
      return (
        'Vía cerrada',
        isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
        isDark ? const Color(0xFF082F49) : const Color(0xFFE0F2FE),
        Icons.construction_rounded,
      );
    }
    if (t.contains('ALUMBR') || t.contains('LUZ') || t.contains('INFRA')) {
      return (
        'Servicios',
        isDark ? const Color(0xFF2DD4BF) : const Color(0xFF0F766E),
        isDark ? const Color(0xFF042F2E) : const Color(0xFFCCFBF1),
        Icons.lightbulb_outline_rounded,
      );
    }
    return (
      'Alerta',
      isDark ? const Color(0xFF60A5FA) : const Color(0xFF0F4C81),
      isDark ? const Color(0xFF1E3A5F) : const Color(0xFFE8F0F8),
      Icons.warning_amber_rounded,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = widget.session.user;
    final name = (user != null && user.fullName.isNotEmpty)
        ? user.fullName
        : (user != null && user.username.isNotEmpty ? user.username : 'ciudadano');

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkCanvas : AppColors.canvas,
      body: SafeArea(
        child: ResponsiveContent(
          maxWidth: Breakpoints.maxContentWidth,
          padding: EdgeInsets.symmetric(
            horizontal: context.responsiveValue(mobile: 16.0, tablet: 24.0, desktop: 32.0),
            vertical: 16.0,
          ),
          child: FutureBuilder<List<Incident>>(
            future: _incidents,
            builder: (context, snapshot) {
              final incidents = snapshot.data ?? const <Incident>[];
              final activeCount = incidents.where((i) => i.status != 'RESOLVED').length;
              final resolvedCount = incidents.where((i) => i.status == 'RESOLVED').length;
              final mobilityCount = incidents.where((i) {
                final t = i.type.toUpperCase();
                return t.contains('TRAF') || t.contains('TRANSIT') || t.contains('VIA') || t.contains('OBSTACULO');
              }).length;
              final safeZonesCount = _zones.isNotEmpty
                  ? _zones.where((z) => z is Map && (z['riskLevel'] == 'LOW' || z['active'] == true)).length
                  : 5;

              // Filtrar incidentes por sector seleccionado
              final filteredIncidents = _selectedSector == 'Todos'
                  ? incidents
                  : incidents.where((inc) {
                      final loc = inc.location.toLowerCase();
                      final desc = inc.description.toLowerCase();
                      final sec = _selectedSector.toLowerCase();
                      return loc.contains(sec) || desc.contains(sec);
                    }).toList();

              final isWide = context.isWide;
              final isDesktop = context.isDesktop;

              final m1 = _buildMetricCard(
                value: '$activeCount',
                label: 'Reportes activos',
                valColor: isDark ? const Color(0xFF60A5FA) : const Color(0xFF0F4C81),
                iconBg: isDark ? const Color(0xFF1E3A5F) : const Color(0xFFE8F0F8),
                iconColor: isDark ? const Color(0xFF60A5FA) : const Color(0xFF0F4C81),
                icon: Icons.assignment_outlined,
                isDark: isDark,
                onTap: () => widget.onSelectTab(2),
              );
              final m2 = _buildMetricCard(
                value: '$safeZonesCount',
                label: 'Zonas seguras',
                valColor: isDark ? const Color(0xFF34D399) : const Color(0xFF087F5B),
                iconBg: isDark ? const Color(0xFF064E3B) : const Color(0xFFE5F7EF),
                iconColor: isDark ? const Color(0xFF34D399) : const Color(0xFF087F5B),
                icon: Icons.shield_outlined,
                isDark: isDark,
                onTap: () => widget.onSelectTab(1),
              );
              final m3 = _buildMetricCard(
                value: '$mobilityCount',
                label: 'Alertas movilidad',
                valColor: isDark ? const Color(0xFFFBBF24) : const Color(0xFF9A6200),
                iconBg: isDark ? const Color(0xFF451A03) : const Color(0xFFFFF4D9),
                iconColor: isDark ? const Color(0xFFFBBF24) : const Color(0xFF9A6200),
                icon: Icons.directions_car_outlined,
                isDark: isDark,
                onTap: () => setState(() => _selectedSector = 'Bocagrande'),
              );
              final m4 = _buildMetricCard(
                value: '$resolvedCount',
                label: 'Resueltos',
                valColor: isDark ? const Color(0xFF34D399) : const Color(0xFF087F5B),
                iconBg: isDark ? const Color(0xFF064E3B) : const Color(0xFFE5F7EF),
                iconColor: isDark ? const Color(0xFF34D399) : const Color(0xFF087F5B),
                icon: Icons.check_circle_outline_rounded,
                isDark: isDark,
                onTap: () => widget.onSelectTab(2),
              );

              return ListView(
                padding: EdgeInsets.zero,
                children: [
                  // Encabezado adaptable
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hola, $name',
                              style: TextStyle(
                                fontSize: isWide ? 28 : 24,
                                fontWeight: FontWeight.w800,
                                color: isDark ? AppColors.darkText : const Color(0xFF142C40),
                                letterSpacing: -0.4,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on_rounded,
                                  size: 15,
                                  color: isDark ? AppColors.darkTextMuted : const Color(0xFF64748B),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Cartagena de Indias, Bolívar',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: isDark ? AppColors.darkTextMuted : const Color(0xFF64748B),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? const Color(0xFF064E3B).withValues(alpha: 0.35)
                                        : const Color(0xFFE9F7F1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF10B981),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Distrito Conectado',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: isDark ? const Color(0xFF6EE7B7) : const Color(0xFF087554),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => NotificationsScreen(
                                api: widget.session.api,
                                isAdmin: widget.session.user?.isAdmin ?? false,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkCard : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark ? AppColors.darkBorder : const Color(0xFFE7ECF1),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Icon(
                                Icons.notifications_none_rounded,
                                color: isDark ? AppColors.darkText : const Color(0xFF142C40),
                                size: 22,
                              ),
                              Positioned(
                                top: 10,
                                right: 11,
                                child: Container(
                                  width: 7,
                                  height: 7,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEF4444),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isDark ? AppColors.darkCard : Colors.white,
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Fila o cuadrícula de métricas según resolución
                  if (isWide)
                    Row(
                      children: [
                        Expanded(child: m1),
                        const SizedBox(width: 14),
                        Expanded(child: m2),
                        const SizedBox(width: 14),
                        Expanded(child: m3),
                        const SizedBox(width: 14),
                        Expanded(child: m4),
                      ],
                    )
                  else
                    Column(
                      children: [
                        Row(
                          children: [
                            Expanded(child: m1),
                            const SizedBox(width: 12),
                            Expanded(child: m2),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(child: m3),
                            const SizedBox(width: 12),
                            Expanded(child: m4),
                          ],
                        ),
                      ],
                    ),
                  const SizedBox(height: 24),

                  // CONTENIDO PRINCIPAL: Split de 2 columnas en Desktop o flujo continuo en Móvil
                  if (isDesktop)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Columna Izquierda: Reportes e Incidentes de la Comunidad
                        Expanded(
                          flex: 7,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'Reportes recientes en la comunidad',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: isDark ? AppColors.darkText : const Color(0xFF142C40),
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  const Spacer(),
                                  InkWell(
                                    onTap: () => widget.onSelectTab(2),
                                    child: Text(
                                      'Ver todos',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: isDark ? AppColors.brightBlue : const Color(0xFF0F4C81),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    for (final sector in _sectors) ...[
                                      _buildSectorChip(sector, isDark),
                                      const SizedBox(width: 8),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              if (snapshot.connectionState == ConnectionState.waiting)
                                const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(24),
                                    child: CircularProgressIndicator(),
                                  ),
                                )
                              else if (filteredIncidents.isEmpty)
                                _buildEmptySectorBanner(isDark)
                              else
                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    final w = (constraints.maxWidth - 14) / 2;
                                    return Wrap(
                                      spacing: 14,
                                      runSpacing: 12,
                                      children: [
                                        for (final inc in filteredIncidents)
                                          SizedBox(
                                            width: w,
                                            child: _buildIncidentCardFromData(inc, isDark),
                                          ),
                                      ],
                                    );
                                  },
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 24),
                        // Columna Derecha: Accesos rápidos y Asistente IA
                        Expanded(
                          flex: 4,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildDesktopActionPanel(isDark),
                              const SizedBox(height: 16),
                              _buildAiAssistantCard(isDark),
                            ],
                          ),
                        ),
                      ],
                    )
                  else ...[
                    // Vista Móvil / Tablet
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (final sector in _sectors) ...[
                            _buildSectorChip(sector, isDark),
                            const SizedBox(width: 8),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Text(
                          'Reportes recientes',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: isDark ? AppColors.darkText : const Color(0xFF142C40),
                            letterSpacing: -0.3,
                          ),
                        ),
                        const Spacer(),
                        InkWell(
                          onTap: () => widget.onSelectTab(2),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                            child: Text(
                              'Ver todos',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: isDark ? AppColors.brightBlue : const Color(0xFF0F4C81),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (snapshot.connectionState == ConnectionState.waiting)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (filteredIncidents.isEmpty)
                      _buildEmptySectorBanner(isDark)
                    else
                      for (final inc in filteredIncidents)
                        _buildIncidentCardFromData(inc, isDark),
                    const SizedBox(height: 20),
                    _buildAiAssistantCard(isDark),
                    const SizedBox(height: 24),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildEmptySectorBanner(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : const Color(0xFFE7ECF1),
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.check_circle_outline_rounded,
            color: Color(0xFF10B981),
            size: 28,
          ),
          const SizedBox(height: 8),
          Text(
            'Sin reportes activos en $_selectedSector',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: isDark ? AppColors.darkText : const Color(0xFF142C40),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Sector seguro y sin novedades reportadas',
            style: TextStyle(
              fontSize: 11,
              color: isDark ? AppColors.darkTextMuted : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncidentCardFromData(Incident inc, bool isDark) {
    final (catName, catColor, catBg, catIcon) = _getCategoryMeta(inc.type, isDark);
    final title = inc.description.isNotEmpty ? inc.description : inc.type;
    final subtitle = '${inc.location} · ${_formatTimeAgo(inc.createdAt)}';

    return _buildIncidentCard(
      category: catName,
      categoryColor: catColor,
      iconBg: catBg,
      icon: catIcon,
      title: title,
      subtitle: subtitle,
      distance: inc.status == 'RESOLVED' ? 'Resuelto' : 'En proceso',
      isDark: isDark,
      onTap: () => widget.onSelectTab(1),
    );
  }

  Widget _buildDesktopActionPanel(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : const Color(0xFFE7ECF1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
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
              Icon(
                Icons.alt_route_rounded,
                color: isDark ? AppColors.brightBlue : const Color(0xFF0F4C81),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Rutas Seguras Cartagena',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.darkText : const Color(0xFF142C40),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Calcula la ruta más segura evitando zonas de riesgo y con navegación GPS asistida por voz.',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.darkTextMuted : const Color(0xFF64748B),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? const Color(0xFF1E3A5F) : const Color(0xFF0F4C81),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => widget.onSelectTab(1),
              icon: const Icon(Icons.explore_rounded, size: 18),
              label: const Text(
                'Abrir Mapa y Navegación',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiAssistantCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : const Color(0xFFE7ECF1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E3A5F) : const Color(0xFFE8F0F8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.smart_toy_outlined,
              color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF0F4C81),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Asistente Ciudadano IA',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkText : const Color(0xFF142C40),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Orientación en trámites, seguridad y emergencias.',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.darkTextMuted : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: isDark ? AppColors.darkTextMuted : const Color(0xFF94A3B8),
            ),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => CitizenChatScreen(session: widget.session),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String value,
    required String label,
    required Color valColor,
    required Color iconBg,
    required Color iconColor,
    required IconData icon,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 92,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : const Color(0xFFE7ECF1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: valColor,
                    height: 1.1,
                  ),
                ),
                const Spacer(),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkTextMuted : const Color(0xFF526579),
                  ),
                ),
              ],
            ),
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                width: 33,
                height: 33,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectorChip(String label, bool isDark) {
    final isSelected = _selectedSector == label;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        setState(() {
          _selectedSector = label;
        });
      },
      child: Container(
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColors.brightBlue : const Color(0xFF142C40))
              : (isDark ? AppColors.darkCard : Colors.white),
          borderRadius: BorderRadius.circular(14),
          border: isSelected
              ? null
              : Border.all(
                  color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
                ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? Colors.white
                : (isDark ? AppColors.darkTextMuted : const Color(0xFF526579)),
          ),
        ),
      ),
    );
  }

  Widget _buildIncidentCard({
    required String category,
    required Color categoryColor,
    required Color iconBg,
    required IconData icon,
    required String title,
    required String subtitle,
    required String distance,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : const Color(0xFFE7ECF1),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Icono de categoría
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: categoryColor, size: 20),
              ),
              const SizedBox(width: 12),
              // Textos
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: categoryColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.darkText : const Color(0xFF142C40),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? AppColors.darkTextMuted : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              // Distancia / Estado
              Text(
                distance,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isDark ? AppColors.darkTextMuted : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
