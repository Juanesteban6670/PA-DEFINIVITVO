import 'package:flutter/material.dart';

import 'package:cartagena_segura/core/data/incident_repository.dart';
import 'package:cartagena_segura/core/data/models.dart';
import 'package:cartagena_segura/core/data/session_controller.dart';
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
  String _selectedSector = 'Todos';

  final List<String> _sectors = const [
    'Todos',
    'Centro Histórico',
    'Bocagrande',
    'Manga',
    'Bazurto',
  ];

  @override
  void initState() {
    super.initState();
    widget.incidentRefresh.addListener(_reload);
    _incidents = loadIncidents(widget.session.api);
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
        _incidents = loadIncidents(widget.session.api);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.session.user!;
    final name = user.fullName.isNotEmpty
        ? user.fullName.split(' ').first
        : (user.username.isNotEmpty ? user.username : 'ciudadano');

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: FutureBuilder<List<Incident>>(
              future: _incidents,
              builder: (context, snapshot) {
                final incidents = snapshot.data ?? const <Incident>[];
                final activeCount = incidents.where((i) => i.status != 'RESOLVED').length;
                final resolvedCount = incidents.where((i) => i.status == 'RESOLVED').length;

                return ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  children: [
                    // Encabezado (Figma 02 · Inicio)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hola, $name',
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF142C40),
                                  letterSpacing: -0.4,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Row(
                                children: [
                                  Icon(
                                    Icons.location_on_rounded,
                                    size: 15,
                                    color: Color(0xFF64748B),
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Cartagena, Bolívar',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Botón de notificaciones con punto rojo (Figma 2:225)
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
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFE7ECF1)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                const Icon(
                                  Icons.notifications_none_rounded,
                                  color: Color(0xFF142C40),
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
                                        color: Colors.white,
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
                    const SizedBox(height: 16),

                    // Banner de conexión en vivo (Figma 2:229)
                    Container(
                      height: 32,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE9F7F1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFF10B981),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Tu ciudad, conectada y más segura',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF087554),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Cuadrícula de Métricas 2x2 (Figma 2:232, 2:239, 2:246, 2:253)
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricCard(
                            value: activeCount > 0 ? '$activeCount' : '24',
                            label: 'Reportes activos',
                            valColor: const Color(0xFF0F4C81),
                            iconBg: const Color(0xFFE8F0F8),
                            iconColor: const Color(0xFF0F4C81),
                            icon: Icons.assignment_outlined,
                            onTap: () => widget.onSelectTab(2), // Ir a Reportes
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildMetricCard(
                            value: '18',
                            label: 'Zonas seguras',
                            valColor: const Color(0xFF087F5B),
                            iconBg: const Color(0xFFE5F7EF),
                            iconColor: const Color(0xFF087F5B),
                            icon: Icons.shield_outlined,
                            onTap: () => widget.onSelectTab(1), // Ir a Mapa
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricCard(
                            value: '7',
                            label: 'Alertas de movilidad',
                            valColor: const Color(0xFF9A6200),
                            iconBg: const Color(0xFFFFF4D9),
                            iconColor: const Color(0xFF9A6200),
                            icon: Icons.directions_car_outlined,
                            onTap: () {
                              setState(() => _selectedSector = 'Bocagrande');
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildMetricCard(
                            value: resolvedCount > 0 ? '$resolvedCount' : '12',
                            label: 'Resueltos hoy',
                            valColor: const Color(0xFF087F5B),
                            iconBg: const Color(0xFFE5F7EF),
                            iconColor: const Color(0xFF087F5B),
                            icon: Icons.check_circle_outline_rounded,
                            onTap: () => widget.onSelectTab(2),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Filtros horizontales por sector (Figma 2:260 a 2:268)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (final sector in _sectors) ...[
                            _buildSectorChip(sector),
                            const SizedBox(width: 8),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),

                    // Encabezado de sección Reportes recientes (Figma 2:270 y 2:271)
                    Row(
                      children: [
                        const Text(
                          'Reportes recientes',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF142C40),
                            letterSpacing: -0.3,
                          ),
                        ),
                        const Spacer(),
                        InkWell(
                          onTap: () => widget.onSelectTab(2), // Ver todos -> Reportes
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                            child: Text(
                              'Ver todos',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F4C81),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Tarjetas de incidentes (Figma 2:272, 2:280, 2:289)
                    if (_selectedSector == 'Todos' || _selectedSector == 'Bocagrande')
                      _buildIncidentCard(
                        category: 'Tráfico',
                        categoryColor: const Color(0xFF9A6200),
                        iconBg: const Color(0xFFFFF4DC),
                        icon: Icons.directions_car_rounded,
                        title: 'Congestión en Av. San Martín',
                        subtitle: 'Bocagrande · Hace 10 min',
                        distance: 'a 450 m',
                        onTap: () => widget.onSelectTab(1),
                      ),
                    if (_selectedSector == 'Todos' || _selectedSector == 'Manga')
                      _buildIncidentCard(
                        category: 'Seguridad',
                        categoryColor: const Color(0xFFDC2626),
                        iconBg: const Color(0xFFFEE2E2),
                        icon: Icons.shield_outlined,
                        title: 'Alumbrado público sin funcionar',
                        subtitle: 'Manga · Hace 18 min',
                        distance: 'a 1,2 km',
                        onTap: () => widget.onSelectTab(1),
                      ),
                    if (_selectedSector == 'Todos' || _selectedSector == 'Centro Histórico')
                      _buildIncidentCard(
                        category: 'Vía cerrada',
                        categoryColor: const Color(0xFF0284C7),
                        iconBg: const Color(0xFFE0F2FE),
                        icon: Icons.construction_rounded,
                        title: 'Obras en la calle de la Media Luna',
                        subtitle: 'Centro Histórico · Hace 25 min',
                        distance: 'a 2,1 km',
                        onTap: () => widget.onSelectTab(1),
                      ),
                    if (_selectedSector == 'Todos' || _selectedSector == 'Bazurto')
                      _buildIncidentCard(
                        category: 'Movilidad',
                        categoryColor: const Color(0xFF0F766E),
                        iconBg: const Color(0xFFCCFBF1),
                        icon: Icons.warning_amber_rounded,
                        title: 'Paso habilitado en Av. Pedro de Heredia',
                        subtitle: 'Bazurto · Hace 35 min',
                        distance: 'a 3 km',
                        onTap: () => widget.onSelectTab(1),
                      ),

                    // Reportes reales adicionales si existen en el backend
                    for (final inc in incidents.take(4))
                      if (_selectedSector == 'Todos' ||
                          inc.location.toLowerCase().contains(_selectedSector.toLowerCase()) ||
                          inc.description.toLowerCase().contains(_selectedSector.toLowerCase()))
                        _buildIncidentCard(
                          category: inc.category,
                          categoryColor: const Color(0xFF0F4C81),
                          iconBg: const Color(0xFFE8F0F8),
                          icon: Icons.report_problem_outlined,
                          title: inc.title.isNotEmpty ? inc.title : inc.description,
                          subtitle: '${inc.location} · Hace poco',
                          distance: 'Cerca',
                          onTap: () => widget.onSelectTab(1),
                        ),

                    const SizedBox(height: 20),
                    // Acceso a Asistente Ciudadano IA
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE7ECF1)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F0F8),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.smart_toy_outlined,
                              color: Color(0xFF0F4C81),
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Asistente Ciudadano IA',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF142C40),
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Resuelve dudas sobre trámites y seguridad.',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 11,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 14,
                              color: Color(0xFF94A3B8),
                            ),
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) =>
                                      CitizenChatScreen(session: widget.session),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                );
              },
            ),
          ),
        ),
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
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 92,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE7ECF1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
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
                    fontFamily: 'Inter',
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
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF526579),
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

  Widget _buildSectorChip(String label) {
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
          color: isSelected ? const Color(0xFF142C40) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: isSelected ? null : Border.all(color: const Color(0xFFE2E8F0)),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF526579),
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
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE7ECF1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
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
                        fontFamily: 'Inter',
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
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF142C40),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              // Distancia
              Text(
                distance,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
