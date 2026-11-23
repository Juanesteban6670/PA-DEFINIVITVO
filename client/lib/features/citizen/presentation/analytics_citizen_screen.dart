import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:cartagena_segura/core/data/api_client.dart';
import 'package:cartagena_segura/core/data/incident_repository.dart';
import 'package:cartagena_segura/core/data/models.dart';
import 'package:cartagena_segura/features/citizen/presentation/widgets/analytics_charts.dart';
import 'package:cartagena_segura/shared/responsive_layout.dart';
import 'package:cartagena_segura/shared/theme.dart';

/// Dashboard analítico e interactivo de estadísticas de seguridad y convivencia ciudadana
class AnalyticsCitizenScreen extends StatefulWidget {
  const AnalyticsCitizenScreen({
    required this.api,
    this.onSelectSector,
    super.key,
  });

  final ApiClient api;
  final ValueChanged<String>? onSelectSector;

  @override
  State<AnalyticsCitizenScreen> createState() => _AnalyticsCitizenScreenState();
}

class _AnalyticsCitizenScreenState extends State<AnalyticsCitizenScreen> {
  String _selectedPeriod = 'Últimos 7 días';
  DateTimeRange? _customDateRange;

  String _selectedCategory = 'Todas';
  String _selectedSector = 'Todos';
  String _selectedStatus = 'Todos';

  final List<String> _periods = const [
    'Hoy',
    'Últimos 7 días',
    'Últimos 30 días',
    'Últimos 6 meses',
    'Último año',
    'Personalizado',
  ];

  final List<String> _categories = const [
    'Todas',
    'Seguridad',
    'Tráfico',
    'Servicios',
    'Otros',
  ];

  final List<String> _sectors = const [
    'Todos',
    'Centro Histórico',
    'Bocagrande',
    'Manga',
    'Getsemaní',
    'Bazurto',
    'Pie de la Popa',
    'Olaya Herrera',
  ];

  final List<String> _statuses = const [
    'Todos',
    'Pendientes',
    'En atención',
    'Resueltos',
  ];

  late Future<List<Incident>> _futureIncidents;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    _futureIncidents = loadIncidents(widget.api, mine: false);
  }

  Future<void> _handleRefresh() async {
    setState(() {
      _loadData();
    });
    await _futureIncidents;
  }

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2025, 1, 1),
      lastDate: now.add(const Duration(days: 1)),
      initialDateRange:
          _customDateRange ??
          DateTimeRange(start: now.subtract(const Duration(days: 7)), end: now),
      helpText: 'Seleccionar rango de fechas',
      confirmText: 'Aplicar',
      cancelText: 'Cancelar',
    );

    if (picked != null) {
      setState(() {
        _customDateRange = picked;
        _selectedPeriod = 'Personalizado';
      });
    }
  }

  List<Incident> _applyAllFilters(List<Incident> all) {
    final now = DateTime.now();

    return all.where((inc) {
      // 1. Filtro temporal
      if (_customDateRange != null && _selectedPeriod == 'Personalizado') {
        final start = DateTime(
          _customDateRange!.start.year,
          _customDateRange!.start.month,
          _customDateRange!.start.day,
        );
        final end = DateTime(
          _customDateRange!.end.year,
          _customDateRange!.end.month,
          _customDateRange!.end.day,
          23,
          59,
          59,
        );
        final d = inc.createdAt;
        if (d == null || d.isBefore(start) || d.isAfter(end)) return false;
      } else {
        final d = inc.createdAt;
        if (d == null) return false;
        switch (_selectedPeriod) {
          case 'Hoy':
            final startOfDay = DateTime(now.year, now.month, now.day);
            if (d.isBefore(startOfDay)) return false;
            break;
          case 'Últimos 7 días':
            if (d.isBefore(now.subtract(const Duration(days: 7)))) return false;
            break;
          case 'Últimos 30 días':
            if (d.isBefore(now.subtract(const Duration(days: 30)))) {
              return false;
            }
            break;
          case 'Últimos 6 meses':
            if (d.isBefore(now.subtract(const Duration(days: 180)))) {
              return false;
            }
            break;
          case 'Último año':
            if (d.isBefore(now.subtract(const Duration(days: 365)))) {
              return false;
            }
            break;
        }
      }

      // 2. Filtro de categoría
      if (_selectedCategory != 'Todas') {
        final t = inc.type.toUpperCase();
        if (_selectedCategory == 'Seguridad') {
          if (!t.contains('ROBO') &&
              !t.contains('HURTO') &&
              !t.contains('SEGURIDAD') &&
              !t.contains('SOS') &&
              !t.contains('PELEA')) {
            return false;
          }
        } else if (_selectedCategory == 'Tráfico') {
          if (!t.contains('TRAF') &&
              !t.contains('TRANSIT') &&
              !t.contains('VIA') &&
              !t.contains('OBSTACULO') &&
              !t.contains('CONGESTION')) {
            return false;
          }
        } else if (_selectedCategory == 'Servicios') {
          if (!t.contains('INFRA') &&
              !t.contains('ALUMBR') &&
              !t.contains('HUECO') &&
              !t.contains('AGUA') &&
              !t.contains('BASURA')) {
            return false;
          }
        } else if (_selectedCategory == 'Otros') {
          if (t.contains('ROBO') ||
              t.contains('TRAF') ||
              t.contains('INFRA') ||
              t.contains('SEGURIDAD')) {
            return false;
          }
        }
      }

      // 3. Filtro de sector
      if (_selectedSector != 'Todos') {
        final loc = inc.location.toLowerCase();
        final desc = inc.description.toLowerCase();
        final sec = _selectedSector.toLowerCase();
        if (!loc.contains(sec) && !desc.contains(sec)) return false;
      }

      // 4. Filtro de estado
      if (_selectedStatus != 'Todos') {
        final st = inc.status.toUpperCase();
        if (_selectedStatus == 'Pendientes' && st != 'PENDING') return false;
        if (_selectedStatus == 'En atención' && st != 'IN_PROGRESS') {
          return false;
        }
        if (_selectedStatus == 'Resueltos' && st != 'RESOLVED') return false;
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkCanvas : AppColors.canvas,
      body: SafeArea(
        child: ResponsiveContent(
          maxWidth: Breakpoints.maxContentWidth,
          padding: EdgeInsets.symmetric(
            horizontal: context.responsiveValue(
              mobile: 16.0,
              tablet: 24.0,
              desktop: 32.0,
            ),
            vertical: 14.0,
          ),
          child: FutureBuilder<List<Incident>>(
            future: _futureIncidents,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        size: 40,
                        color: isDark ? AppColors.darkRed : AppColors.red,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Error al cargar datos estadísticos',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.darkText : AppColors.navy,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: () => setState(_loadData),
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Reintentar'),
                      ),
                    ],
                  ),
                );
              }

              final allIncidents = snapshot.data ?? const <Incident>[];
              final filtered = _applyAllFilters(allIncidents);

              // Cálculos KPI
              final total = filtered.length;
              final pendingCount = filtered
                  .where((i) => i.status.toUpperCase() == 'PENDING')
                  .length;
              final inProgressCount = filtered
                  .where((i) => i.status.toUpperCase() == 'IN_PROGRESS')
                  .length;
              final resolvedCount = filtered
                  .where((i) => i.status.toUpperCase() == 'RESOLVED')
                  .length;
              final resolutionRate = total > 0
                  ? ((resolvedCount / total) * 100).round()
                  : 0;

              // Conteo por categorías para el BarChart
              int segCount = 0;
              int trafCount = 0;
              int servCount = 0;
              int otrosCount = 0;

              for (final inc in filtered) {
                final t = inc.type.toUpperCase();
                if (t.contains('ROBO') ||
                    t.contains('HURTO') ||
                    t.contains('SEGURIDAD') ||
                    t.contains('SOS') ||
                    t.contains('PELEA')) {
                  segCount++;
                } else if (t.contains('TRAF') ||
                    t.contains('TRANSIT') ||
                    t.contains('VIA') ||
                    t.contains('CONGESTION')) {
                  trafCount++;
                } else if (t.contains('INFRA') ||
                    t.contains('ALUMBR') ||
                    t.contains('HUECO') ||
                    t.contains('AGUA')) {
                  servCount++;
                } else {
                  otrosCount++;
                }
              }

              final categoryStats = {
                'Seguridad': segCount,
                'Tráfico': trafCount,
                'Servicios': servCount,
                'Otros': otrosCount,
              };

              // Evolución temporal para el LineChart (últimos 7 cortes o días)
              final now = DateTime.now();
              final List<Map<String, dynamic>> timelinePoints = [];
              const dayLetters = [
                'Lun',
                'Mar',
                'Mié',
                'Jue',
                'Vie',
                'Sáb',
                'Dom',
              ];

              for (int i = 6; i >= 0; i--) {
                final targetDay = now.subtract(Duration(days: i));
                final label = dayLetters[(targetDay.weekday - 1).clamp(0, 6)];
                final count = filtered.where((inc) {
                  final d = inc.createdAt;
                  if (d == null) return false;
                  return d.year == targetDay.year &&
                      d.month == targetDay.month &&
                      d.day == targetDay.day;
                }).length;
                timelinePoints.add({'label': label, 'count': count});
              }

              // Sectores con mayor concentración
              final Map<String, int> sectorMap = {};
              for (final sec in _sectors) {
                if (sec == 'Todos') continue;
                final count = filtered.where((inc) {
                  final loc = inc.location.toLowerCase();
                  final desc = inc.description.toLowerCase();
                  return loc.contains(sec.toLowerCase()) ||
                      desc.contains(sec.toLowerCase());
                }).length;
                if (count > 0) sectorMap[sec] = count;
              }

              final sortedSectors = sectorMap.entries.toList()
                ..sort((a, b) => b.value.compareTo(a.value));
              final maxSectorVal = sortedSectors.isNotEmpty
                  ? sortedSectors.first.value
                  : 1;

              return RefreshIndicator(
                color: isDark ? AppColors.brightBlue : AppColors.blue,
                backgroundColor: isDark ? AppColors.darkCard : Colors.white,
                onRefresh: _handleRefresh,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    // Título y descripción
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Estadísticas y Analítica',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: isDark
                                      ? AppColors.darkText
                                      : AppColors.navy,
                                  letterSpacing: -0.4,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Monitoreo de incidentes y resolución en tiempo real',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? AppColors.darkTextMuted
                                      : AppColors.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Barra horizontal de selección de período
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (final p in _periods) ...[
                            _buildPeriodChip(
                              label:
                                  p == 'Personalizado' &&
                                      _customDateRange != null
                                  ? '${_customDateRange!.start.day}/${_customDateRange!.start.month} - ${_customDateRange!.end.day}/${_customDateRange!.end.month}'
                                  : p,
                              isSelected: _selectedPeriod == p,
                              onTap: () {
                                if (p == 'Personalizado') {
                                  _pickCustomRange();
                                } else {
                                  setState(() {
                                    _selectedPeriod = p;
                                    _customDateRange = null;
                                  });
                                }
                              },
                              isDark: isDark,
                            ),
                            const SizedBox(width: 8),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Filtros secundarios: Categoría, Sector y Estado
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          // Dropdown Sector
                          _buildDropdownFilter(
                            label: 'Sector: $_selectedSector',
                            items: _sectors,
                            currentValue: _selectedSector,
                            onChanged: (val) =>
                                setState(() => _selectedSector = val),
                            isDark: isDark,
                          ),
                          const SizedBox(width: 8),

                          // Dropdown Categoría
                          _buildDropdownFilter(
                            label: 'Categoría: $_selectedCategory',
                            items: _categories,
                            currentValue: _selectedCategory,
                            onChanged: (val) =>
                                setState(() => _selectedCategory = val),
                            isDark: isDark,
                          ),
                          const SizedBox(width: 8),

                          // Dropdown Estado
                          _buildDropdownFilter(
                            label: 'Estado: $_selectedStatus',
                            items: _statuses,
                            currentValue: _selectedStatus,
                            onChanged: (val) =>
                                setState(() => _selectedStatus = val),
                            isDark: isDark,
                          ),
                          if (_selectedCategory != 'Todas' ||
                              _selectedSector != 'Todos' ||
                              _selectedStatus != 'Todos') ...[
                            const SizedBox(width: 8),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _selectedCategory = 'Todas';
                                  _selectedSector = 'Todos';
                                  _selectedStatus = 'Todos';
                                });
                              },
                              child: const Text(
                                'Limpiar',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Tarjetas KPI (Grid adaptable)
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth >= 600;
                        final cardWidth = isWide
                            ? (constraints.maxWidth - 36) / 4
                            : (constraints.maxWidth - 12) / 2;

                        return Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            SizedBox(
                              width: cardWidth,
                              child: KpiMetricCard(
                                title: 'Total Reportes',
                                value: '$total',
                                subtitle: 'Registrados en base de datos',
                                icon: Icons.assignment_outlined,
                                color: isDark
                                    ? AppColors.brightBlue
                                    : AppColors.blue,
                                isDark: isDark,
                              ),
                            ),
                            SizedBox(
                              width: cardWidth,
                              child: KpiMetricCard(
                                title: 'En Revisión',
                                value: '$pendingCount',
                                subtitle: '$inProgressCount en atención activa',
                                icon: Icons.hourglass_top_rounded,
                                color: isDark
                                    ? AppColors.darkAmber
                                    : AppColors.amber,
                                badgeText: 'Pendientes',
                                isDark: isDark,
                              ),
                            ),
                            SizedBox(
                              width: cardWidth,
                              child: KpiMetricCard(
                                title: 'Casos Atendidos',
                                value: '$resolvedCount',
                                subtitle: '$resolutionRate% tasa de solución',
                                icon: Icons.check_circle_outline_rounded,
                                color: isDark
                                    ? AppColors.darkGreen
                                    : AppColors.green,
                                badgeText: '$resolutionRate%',
                                badgeColor: isDark
                                    ? AppColors.darkGreen
                                    : AppColors.green,
                                isDark: isDark,
                              ),
                            ),
                            SizedBox(
                              width: cardWidth,
                              child: KpiMetricCard(
                                title: 'Tiempo Promedio',
                                value: '2.8 h',
                                subtitle: 'Meta de cuadrante < 4h',
                                icon: Icons.speed_rounded,
                                color: isDark
                                    ? AppColors.sky
                                    : const Color(0xFF0284C7),
                                badgeText: 'Óptimo',
                                badgeColor: isDark
                                    ? AppColors.darkGreen
                                    : AppColors.green,
                                isDark: isDark,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 20),

                    // 1. Gráfico de Barras: Reportes por Categoría
                    _buildSectionCard(
                      title: 'Reportes por Categoría',
                      subtitle: 'Distribución por tipo de incidencia',
                      isDark: isDark,
                      child: CategoryBarChartWidget(
                        categories: categoryStats,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 2. Gráfico de Líneas: Evolución Temporal
                    _buildSectionCard(
                      title: 'Evolución de Incidentes',
                      subtitle: 'Flujo temporal en el período seleccionado',
                      isDark: isDark,
                      child: TimelineLineChartWidget(
                        timelinePoints: timelinePoints,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 3. Gráfico Circular (Donut) y Comparativo de Resolución
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth >= 700;
                        if (isWide) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _buildSectionCard(
                                  title: 'Distribución Porcentual',
                                  subtitle: 'Participación por categorías',
                                  isDark: isDark,
                                  child: _buildDonutChart(
                                    segCount,
                                    trafCount,
                                    servCount,
                                    otrosCount,
                                    total,
                                    isDark,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: _buildSectionCard(
                                  title: 'Recibidos vs Resueltos',
                                  subtitle: 'Comparativo de atención policial y ciudadana',
                                  isDark: isDark,
                                  child: ComparisonChartWidget(
                                    receivedCount: total,
                                    resolvedCount: resolvedCount,
                                    isDark: isDark,
                                  ),
                                ),
                              ),
                            ],
                          );
                        } else {
                          return Column(
                            children: [
                              _buildSectionCard(
                                title: 'Distribución Porcentual',
                                subtitle: 'Participación por categorías',
                                isDark: isDark,
                                child: _buildDonutChart(
                                  segCount,
                                  trafCount,
                                  servCount,
                                  otrosCount,
                                  total,
                                  isDark,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildSectionCard(
                                title: 'Recibidos vs Resueltos',
                                subtitle: 'Comparativo de atención policial y ciudadana',
                                isDark: isDark,
                                child: ComparisonChartWidget(
                                  receivedCount: total,
                                  resolvedCount: resolvedCount,
                                  isDark: isDark,
                                ),
                              ),
                            ],
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // 4. Ranking de Barrios y Sectores con Mayor Concentración
                    _buildSectionCard(
                      title: 'Ranking de Sectores con Mayor Concentración',
                      subtitle:
                          'Identificación de focos de incidentes en Cartagena',
                      isDark: isDark,
                      child: Column(
                        children: [
                          if (sortedSectors.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(20),
                              child: Text(
                                'No hay incidentes reportados en los sectores principales.',
                              ),
                            )
                          else
                            for (final entry in sortedSectors.take(6)) ...[
                              _buildSectorBar(
                                name: entry.key,
                                count: entry.value,
                                max: maxSectorVal,
                                isDark: isDark,
                                onTap: () {
                                  setState(() => _selectedSector = entry.key);
                                },
                              ),
                              const SizedBox(height: 10),
                            ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    final activeBg = isDark ? AppColors.brightBlue : AppColors.blue;
    final inactiveBg = isDark ? AppColors.darkCard : Colors.white;

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? activeBg : inactiveBg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected
                ? activeBg
                : (isDark ? AppColors.darkBorder : AppColors.border),
            width: 0.8,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected
                ? Colors.white
                : (isDark ? AppColors.darkText : AppColors.navy),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownFilter({
    required String label,
    required List<String> items,
    required String currentValue,
    required ValueChanged<String> onChanged,
    required bool isDark,
  }) {
    final isSelected = currentValue != 'Todos' && currentValue != 'Todas';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      decoration: BoxDecoration(
        color: isSelected
            ? (isDark
                  ? AppColors.brightBlue.withValues(alpha: 0.15)
                  : AppColors.blue.withValues(alpha: 0.1))
            : (isDark ? AppColors.darkCard : Colors.white),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isSelected
              ? (isDark ? AppColors.brightBlue : AppColors.blue)
              : (isDark ? AppColors.darkBorder : AppColors.border),
          width: 0.8,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: currentValue,
          isDense: true,
          dropdownColor: isDark ? AppColors.darkCard : Colors.white,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 16,
            color: isDark ? AppColors.darkText : AppColors.navy,
          ),
          items: items.map((item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(
                item,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkText : AppColors.navy,
                ),
              ),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) onChanged(val);
          },
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required String subtitle,
    required Widget child,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: isDark ? AppColors.darkText : AppColors.navy,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? AppColors.darkTextMuted : AppColors.muted,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildDonutChart(
    int seg,
    int traf,
    int serv,
    int otros,
    int total,
    bool isDark,
  ) {
    if (total == 0) {
      return const SizedBox(
        height: 180,
        child: Center(child: Text('Sin incidentes en este período')),
      );
    }

    final segPct = ((seg / total) * 100).round();
    final trafPct = ((traf / total) * 100).round();
    final servPct = ((serv / total) * 100).round();
    final otrosPct = math.max(0, 100 - segPct - trafPct - servPct);

    final sections = <PieChartSectionData>[
      if (seg > 0)
        PieChartSectionData(
          value: seg.toDouble(),
          color: isDark ? AppColors.darkRed : AppColors.red,
          radius: 28,
          showTitle: false,
        ),
      if (traf > 0)
        PieChartSectionData(
          value: traf.toDouble(),
          color: isDark ? AppColors.darkAmber : AppColors.amber,
          radius: 28,
          showTitle: false,
        ),
      if (serv > 0)
        PieChartSectionData(
          value: serv.toDouble(),
          color: isDark ? AppColors.sky : AppColors.blue,
          radius: 28,
          showTitle: false,
        ),
      if (otros > 0)
        PieChartSectionData(
          value: otros.toDouble(),
          color: isDark ? AppColors.darkPurple : AppColors.purple,
          radius: 28,
          showTitle: false,
        ),
    ];

    return Column(
      children: [
        SizedBox(
          height: 140,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  sections: sections,
                  centerSpaceRadius: 42,
                  sectionsSpace: 3,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$total',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppColors.darkText : AppColors.navy,
                    ),
                  ),
                  Text(
                    'Total',
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark ? AppColors.darkTextMuted : AppColors.muted,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 6,
          alignment: WrapAlignment.center,
          children: [
            _buildLegendItem(
              'Seguridad ($segPct%)',
              isDark ? AppColors.darkRed : AppColors.red,
              isDark,
            ),
            _buildLegendItem(
              'Tráfico ($trafPct%)',
              isDark ? AppColors.darkAmber : AppColors.amber,
              isDark,
            ),
            _buildLegendItem(
              'Servicios ($servPct%)',
              isDark ? AppColors.sky : AppColors.blue,
              isDark,
            ),
            if (otros > 0)
              _buildLegendItem(
                'Otros ($otrosPct%)',
                isDark ? AppColors.darkPurple : AppColors.purple,
                isDark,
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.darkText : AppColors.navy,
          ),
        ),
      ],
    );
  }

  Widget _buildSectorBar({
    required String name,
    required int count,
    required int max,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    final pct = (count / max).clamp(0.05, 1.0);
    final isCritical = count > 15;
    final isModerate = count > 7;
    final barColor = isCritical
        ? (isDark ? AppColors.darkRed : AppColors.red)
        : (isModerate
              ? (isDark ? AppColors.darkAmber : AppColors.amber)
              : (isDark ? AppColors.brightBlue : AppColors.blue));

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkText : AppColors.navy,
                  ),
                ),
                Text(
                  '$count incidentes',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: barColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 6,
                backgroundColor: isDark
                    ? AppColors.darkBorder
                    : const Color(0xFFE2E8F0),
                valueColor: AlwaysStoppedAnimation<Color>(barColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
