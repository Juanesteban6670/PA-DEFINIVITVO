import 'package:flutter/material.dart';

import 'package:cartagena_segura/core/data/safe_route_service.dart';

/// Tarjeta flotante interactiva estilo Waze que se muestra en la parte inferior del mapa
/// con la información de la ruta activa, tiempo, distancia y evaluación de seguridad ciudadana.
class SafeRouteSheet extends StatefulWidget {
  const SafeRouteSheet({
    required this.routes,
    required this.selectedRouteIndex,
    required this.destinationName,
    required this.onSelectRoute,
    required this.onCloseRoute,
    required this.onCenterRoute,
    super.key,
  });

  final List<SafeRoute> routes;
  final int selectedRouteIndex;
  final String destinationName;
  final ValueChanged<int> onSelectRoute;
  final VoidCallback onCloseRoute;
  final VoidCallback onCenterRoute;

  @override
  State<SafeRouteSheet> createState() => _SafeRouteSheetState();
}

class _SafeRouteSheetState extends State<SafeRouteSheet> {
  bool _expandedAlerts = false;

  SafeRoute get _currentRoute =>
      widget.routes.isNotEmpty && widget.selectedRouteIndex < widget.routes.length
          ? widget.routes[widget.selectedRouteIndex]
          : widget.routes.first;

  @override
  Widget build(BuildContext context) {
    final route = _currentRoute;
    final theme = Theme.of(context);

    final (badgeBg, badgeFg, badgeBorder, badgeIcon) = switch (route.safetyLevel) {
      SafetyLevel.safe => (
        const Color(0xFFECFDF5),
        const Color(0xFF047857),
        const Color(0xFFA7F3D0),
        Icons.verified_user_outlined,
      ),
      SafetyLevel.moderate => (
        const Color(0xFFFFFBEB),
        const Color(0xFFB45309),
        const Color(0xFFFDE68A),
        Icons.shield_outlined,
      ),
      SafetyLevel.risky => (
        const Color(0xFFFEF2F2),
        const Color(0xFFB91C1C),
        const Color(0xFFFECACA),
        Icons.warning_amber_rounded,
      ),
    };

    return Container(
      constraints: const BoxConstraints(maxWidth: 600),
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Barra de título con Destino y Botón de cierre
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 12, 8),
            child: Row(
              children: [
                const Icon(Icons.navigation, color: Color(0xFF1D4ED8), size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'DESTINO',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF64748B),
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        widget.destinationName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Centrar en el mapa',
                  icon: const Icon(Icons.center_focus_strong_outlined, size: 20),
                  onPressed: widget.onCenterRoute,
                ),
                IconButton(
                  tooltip: 'Cancelar ruta',
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: widget.onCloseRoute,
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Resumen: Tiempo, Distancia e Índice de Seguridad
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          route.formattedDuration,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          route.formattedDistance,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Seguridad estimada: ${route.safetyScore}%',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: badgeFg,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: badgeBorder),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(badgeIcon, color: badgeFg, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        route.safetyBadgeText,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: badgeFg,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Selector de alternativas (si hay más de 1 ruta)
          if (widget.routes.length > 1) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (var i = 0; i < widget.routes.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          selected: widget.selectedRouteIndex == i,
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                widget.routes[i].safetyLevel == SafetyLevel.safe
                                    ? Icons.security
                                    : Icons.directions_car,
                                size: 14,
                                color: widget.selectedRouteIndex == i
                                    ? Colors.white
                                    : const Color(0xFF475569),
                              ),
                              const SizedBox(width: 6),
                              Text(widget.routes[i].label),
                            ],
                          ),
                          selectedColor: const Color(0xFF1D4ED8),
                          labelStyle: TextStyle(
                            color: widget.selectedRouteIndex == i
                                ? Colors.white
                                : const Color(0xFF1E293B),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          onSelected: (_) => widget.onSelectRoute(i),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],

          // Alertas de incidentes detectados en el trayecto
          if (route.hazardsOnRoute.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => setState(() => _expandedAlerts = !_expandedAlerts),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.notification_important_outlined,
                        color: Color(0xFFB45309),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${route.hazardsOnRoute.length} reporte(s) de seguridad en esta ruta',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFB45309),
                          ),
                        ),
                      ),
                      Icon(
                        _expandedAlerts ? Icons.expand_less : Icons.expand_more,
                        color: const Color(0xFFB45309),
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (_expandedAlerts)
              Container(
                constraints: const BoxConstraints(maxHeight: 140),
                margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: route.hazardsOnRoute.length,
                  itemBuilder: (context, idx) {
                    final h = route.hazardsOnRoute[idx];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFFDC2626),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${h.type}: ${h.description.isNotEmpty ? h.description : h.location}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 11, color: Color(0xFF334155)),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            h.priority,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFDC2626),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ] else ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: const [
                  Icon(Icons.check_circle_outline, color: Color(0xFF059669), size: 15),
                  SizedBox(width: 6),
                  Text(
                    'No hay reportes de peligro activos sobre este trayecto.',
                    style: TextStyle(fontSize: 11, color: Color(0xFF059669)),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
