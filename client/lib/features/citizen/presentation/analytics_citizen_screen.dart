import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'package:cartagena_segura/core/data/api_client.dart';
import 'package:cartagena_segura/core/data/incident_repository.dart';
import 'package:cartagena_segura/core/data/models.dart';
import 'package:cartagena_segura/shared/responsive_layout.dart';
import 'package:cartagena_segura/shared/theme.dart';

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
  String _selectedPeriod = 'Esta semana';
  DateTimeRange? _customDateRange;

  final List<String> _periods = const [
    'Hoy',
    'Esta semana',
    'Este mes',
    '3 meses',
    'Histórico',
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

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2025, 1, 1),
      lastDate: now.add(const Duration(days: 1)),
      initialDateRange: _customDateRange ??
          DateTimeRange(
            start: now.subtract(const Duration(days: 7)),
            end: now,
          ),
      helpText: 'Seleccionar rango de fechas',
      confirmText: 'Aplicar filtro',
      cancelText: 'Cancelar',
    );

    if (picked != null) {
      setState(() {
        _customDateRange = picked;
        _selectedPeriod = 'Personalizado';
      });
    }
  }

  List<Incident> _filterByPeriod(List<Incident> all) {
    if (_customDateRange != null) {
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
      return all.where((i) {
        final d = i.createdAt;
        return d != null && d.isAfter(start.subtract(const Duration(seconds: 1))) && d.isBefore(end);
      }).toList();
    }

    final now = DateTime.now();
    switch (_selectedPeriod) {
      case 'Hoy':
        final startOfDay = DateTime(now.year, now.month, now.day);
        return all.where((i) {
          final date = i.createdAt;
          return date != null && date.isAfter(startOfDay);
        }).toList();
      case 'Esta semana':
        final weekAgo = now.subtract(const Duration(days: 7));
        return all.where((i) {
          final date = i.createdAt;
          return date != null && date.isAfter(weekAgo);
        }).toList();
      case 'Este mes':
        final monthAgo = now.subtract(const Duration(days: 30));
        return all.where((i) {
          final date = i.createdAt;
          return date != null && date.isAfter(monthAgo);
        }).toList();
      case '3 meses':
        final ninetyDaysAgo = now.subtract(const Duration(days: 90));
        return all.where((i) {
          final date = i.createdAt;
          return date != null && date.isAfter(ninetyDaysAgo);
        }).toList();
      case 'Histórico':
      default:
        return all;
    }
  }

  String get _periodLabel {
    if (_customDateRange != null) {
      return '${_customDateRange!.start.day}/${_customDateRange!.start.month}/${_customDateRange!.start.year} - ${_customDateRange!.end.day}/${_customDateRange!.end.month}/${_customDateRange!.end.year}';
    }
    return _selectedPeriod;
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
            horizontal: context.responsiveValue(mobile: 16.0, tablet: 24.0, desktop: 32.0),
            vertical: 16.0,
          ),
          child: FutureBuilder<List<Incident>>(
              future: _futureIncidents,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 40),
                          const SizedBox(height: 12),
                          Text(
                            'Error al conectar con la base de datos:\n${snapshot.error}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => setState(_loadData),
                            icon: const Icon(Icons.refresh_rounded, size: 18),
                            label: const Text('Reintentar'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final allIncidents = snapshot.data ?? const <Incident>[];
                final periodIncidents = _filterByPeriod(allIncidents);
                final total = periodIncidents.length;
                final resolvedCount = periodIncidents.where((i) => i.status == 'RESOLVED').length;
                final resolutionRate = total > 0 ? ((resolvedCount / total) * 100).round() : 0;

                // --- 1. Distribución semanal real (Últimos 7 días) ---
                final now = DateTime.now();
                final List<Map<String, dynamic>> dayStats = [];
                const dayLetters = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

                // Días 6 a 0 (de hace 6 días a hoy)
                int peakCount = 0;
                int peakIndex = -1;

                for (int i = 6; i >= 0; i--) {
                  final targetDay = now.subtract(Duration(days: i));
                  final weekdayIndex = targetDay.weekday - 1; // 0=Lunes, 6=Domingo
                  final letter = dayLetters[weekdayIndex.clamp(0, 6)];

                  final count = allIncidents.where((inc) {
                    final d = inc.createdAt;
                    if (d == null) return false;
                    return d.year == targetDay.year &&
                        d.month == targetDay.month &&
                        d.day == targetDay.day;
                  }).length;

                  if (count > peakCount) {
                    peakCount = count;
                    peakIndex = 6 - i;
                  }

                  dayStats.add({
                    'letter': letter,
                    'count': count,
                  });
                }

                // --- 2. Categorías reales para la dona ---
                int mobilityCount = 0;
                int securityCount = 0;
                int infraCount = 0;
                int otherCount = 0;

                for (final inc in periodIncidents) {
                  final t = inc.type.toUpperCase();
                  if (t.contains('TRAF') || t.contains('TRANSIT') || t.contains('VIA') || t.contains('OBSTACULO')) {
                    mobilityCount++;
                  } else if (t.contains('ROBO') || t.contains('HURTO') || t.contains('SEGURIDAD') || t.contains('SOS') || t.contains('PELEA') || t.contains('ALTERCADO')) {
                    securityCount++;
                  } else if (t.contains('INFRA') || t.contains('ALUMBR') || t.contains('HUECO') || t.contains('OBRA')) {
                    infraCount++;
                  } else {
                    otherCount++;
                  }
                }

                final safeTotal = total > 0 ? total : 1;
                final mobPct = ((mobilityCount / safeTotal) * 100).round();
                final secPct = ((securityCount / safeTotal) * 100).round();
                final infPct = ((infraCount / safeTotal) * 100).round();
                final othPct = total > 0 ? math.max(0, 100 - mobPct - secPct - infPct) : 0;

                // --- 3. Sectores con mayor reporte ---
                final Map<String, int> sectorCounts = {};
                const knownSectors = [
                  'Centro Histórico',
                  'Bocagrande',
                  'Manga',
                  'Getsemaní',
                  'Bazurto',
                  'Pie de la Popa',
                  'Olaya Herrera',
                ];

                for (final sec in knownSectors) {
                  final count = periodIncidents.where((inc) {
                    final loc = inc.location.toLowerCase();
                    final desc = inc.description.toLowerCase();
                    return loc.contains(sec.toLowerCase()) || desc.contains(sec.toLowerCase());
                  }).length;
                  if (count > 0) {
                    sectorCounts[sec] = count;
                  }
                }

                if (sectorCounts.isEmpty) {
                  for (final inc in periodIncidents) {
                    final key = inc.location.split(',').first.trim();
                    if (key.isNotEmpty) {
                      sectorCounts[key] = (sectorCounts[key] ?? 0) + 1;
                    }
                  }
                }

                final sortedSectors = sectorCounts.entries.toList()
                  ..sort((a, b) => b.value.compareTo(a.value));
                final topSectors = sortedSectors.take(3).toList();
                final maxSectorCount = topSectors.isNotEmpty ? topSectors.first.value : 1;

                return ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  children: [
                    // Encabezado (Figma Frame 2:434)
                    Text(
                      'Estadísticas Ciudadanas',
                      style: TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppColors.darkText : const Color(0xFF142C40),
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Panorama de seguridad y movilidad en tiempo real',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: isDark ? AppColors.darkTextMuted : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Selector de período Mejorado con Botón de Calendario (Figma 2:472)
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 38,
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkCard : const Color(0xFFE9EEF3),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  for (final period in _periods) ...[
                                    _buildPeriodOption(period, isDark),
                                    const SizedBox(width: 4),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Botón de Rango de Fechas Personalizado
                        InkWell(
                          onTap: _pickCustomRange,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            height: 38,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: _customDateRange != null
                                  ? const Color(0xFF0F4C81)
                                  : (isDark ? AppColors.darkCard : Colors.white),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _customDateRange != null
                                    ? const Color(0xFF0F4C81)
                                    : (isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_month_rounded,
                                  size: 16,
                                  color: _customDateRange != null
                                      ? Colors.white
                                      : (isDark ? AppColors.brightBlue : const Color(0xFF0F4C81)),
                                ),
                                if (_customDateRange != null) ...[
                                  const SizedBox(width: 6),
                                  Text(
                                    '${_customDateRange!.start.day}/${_customDateRange!.start.month} - ${_customDateRange!.end.day}/${_customDateRange!.end.month}',
                                    style: const TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  InkWell(
                                    onTap: () {
                                      setState(() {
                                        _customDateRange = null;
                                        _selectedPeriod = 'Esta semana';
                                      });
                                    },
                                    child: const Icon(
                                      Icons.close_rounded,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Etiqueta informativa del filtro activo
                    Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 4),
                      child: Row(
                        children: [
                          Icon(
                            Icons.filter_alt_outlined,
                            size: 13,
                            color: isDark ? AppColors.brightBlue : const Color(0xFF0F4C81),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Periodo: $_periodLabel · $total reportes filtrados',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.darkTextMuted : const Color(0xFF526579),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Indicadores Principales 1x2 DINÁMICOS (Figma Frame 2:435)
                    Row(
                      children: [
                        // Total Reportes (Figma 2:479)
                        Expanded(
                          child: Container(
                            height: 108,
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
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Total Reportes',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? AppColors.darkTextMuted : const Color(0xFF526579),
                                      ),
                                    ),
                                    Container(
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? AppColors.brightBlue.withValues(alpha: 0.2)
                                            : const Color(0xFFE8F0F8),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Icon(
                                        Icons.bar_chart_rounded,
                                        color: isDark ? AppColors.brightBlue : const Color(0xFF0F4C81),
                                        size: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                Text(
                                  '$total',
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w800,
                                    color: isDark ? AppColors.brightBlue : const Color(0xFF0F4C81),
                                    height: 1.0,
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? const Color(0xFF064E3B)
                                        : const Color(0xFFE6F7EF),
                                    borderRadius: BorderRadius.circular(7),
                                  ),
                                  child: Text(
                                    '$resolvedCount resueltos',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: isDark
                                          ? const Color(0xFF34D399)
                                          : const Color(0xFF087554),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Tasa de Resolución DINÁMICA (Figma 2:487)
                        Expanded(
                          child: Container(
                            height: 108,
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
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Tasa de Resolución',
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? AppColors.darkTextMuted : const Color(0xFF526579),
                                      ),
                                    ),
                                    Container(
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? const Color(0xFF064E3B)
                                            : const Color(0xFFE5F7EF),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Icon(
                                        Icons.check_circle_outline_rounded,
                                        color: Color(0xFF10B981),
                                        size: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                Text(
                                  '$resolutionRate%',
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w800,
                                    color: isDark ? const Color(0xFF34D399) : const Color(0xFF087F5B),
                                    height: 1.0,
                                  ),
                                ),
                                const Spacer(),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: LinearProgressIndicator(
                                    value: total > 0 ? (resolutionRate / 100).clamp(0.0, 1.0) : 0.0,
                                    minHeight: 6,
                                    backgroundColor: isDark
                                        ? const Color(0xFF1E293B)
                                        : const Color(0xFFE2E8F0),
                                    valueColor: const AlwaysStoppedAnimation<Color>(
                                      Color(0xFF10B981),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Actividad de reportes (Últimos 7 días) DINÁMICA (Figma Frame 2:436)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCard : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? AppColors.darkBorder : const Color(0xFFE7ECF1),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isDark
                                ? Colors.black.withValues(alpha: 0.2)
                                : const Color(0xFF0F2940).withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Actividad de reportes (Últimos 7 días)',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.darkText : const Color(0xFF142C40),
                            ),
                          ),
                          const SizedBox(height: 18),
                          SizedBox(
                            height: 140,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                // Eje Y con guías
                                SizedBox(
                                  width: 18,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${math.max(10, (peakCount * 1.2).ceil())}',
                                        style: TextStyle(
                                          fontSize: 9,
                                          color: isDark ? AppColors.darkTextMuted : const Color(0xFF94A3B8),
                                        ),
                                      ),
                                      Text(
                                        '${math.max(5, (peakCount * 0.6).ceil())}',
                                        style: TextStyle(
                                          fontSize: 9,
                                          color: isDark ? AppColors.darkTextMuted : const Color(0xFF94A3B8),
                                        ),
                                      ),
                                      Text(
                                        '0',
                                        style: TextStyle(
                                          fontSize: 9,
                                          color: isDark ? AppColors.darkTextMuted : const Color(0xFF94A3B8),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Barras diarias dinámicas
                                Expanded(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      for (int i = 0; i < dayStats.length; i++)
                                        _buildDayBar(
                                          dayStats[i]['letter'] as String,
                                          dayStats[i]['count'] as int,
                                          math.max(peakCount, 5),
                                          isDark: isDark,
                                          isPeak: i == peakIndex && peakCount > 0,
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Incidentes por categoría DINÁMICA (Donut Chart) (Figma 2:437)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCard : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? AppColors.darkBorder : const Color(0xFFE7ECF1),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Incidentes por categoría',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.darkText : const Color(0xFF142C40),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              // Donut Chart con Total en el centro
                              SizedBox(
                                width: 110,
                                height: 110,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    PieChart(
                                      PieChartData(
                                        sectionsSpace: 2,
                                        centerSpaceRadius: 36,
                                        startDegreeOffset: -90,
                                        sections: total == 0
                                            ? [
                                                PieChartSectionData(
                                                  value: 1,
                                                  color: isDark
                                                      ? const Color(0xFF334155)
                                                      : const Color(0xFFE2E8F0),
                                                  radius: 14,
                                                  showTitle: false,
                                                ),
                                              ]
                                            : [
                                                if (mobilityCount > 0)
                                                  PieChartSectionData(
                                                    value: mobilityCount.toDouble(),
                                                    color: isDark
                                                        ? AppColors.brightBlue
                                                        : const Color(0xFF0F4C81),
                                                    radius: 16,
                                                    showTitle: false,
                                                  ),
                                                if (securityCount > 0)
                                                  PieChartSectionData(
                                                    value: securityCount.toDouble(),
                                                    color: const Color(0xFF10B981),
                                                    radius: 16,
                                                    showTitle: false,
                                                  ),
                                                if (infraCount > 0)
                                                  PieChartSectionData(
                                                    value: infraCount.toDouble(),
                                                    color: const Color(0xFFF59E0B),
                                                    radius: 16,
                                                    showTitle: false,
                                                  ),
                                                if (otherCount > 0)
                                                  PieChartSectionData(
                                                    value: otherCount.toDouble(),
                                                    color: const Color(0xFFEF4444),
                                                    radius: 16,
                                                    showTitle: false,
                                                  ),
                                              ],
                                      ),
                                    ),
                                    Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          '$total',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800,
                                            color: isDark ? AppColors.darkText : const Color(0xFF142C40),
                                            height: 1.0,
                                          ),
                                        ),
                                        Text(
                                          'Total',
                                          style: TextStyle(
                                            fontSize: 9,
                                            color: isDark ? AppColors.darkTextMuted : const Color(0xFF64748B),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Leyenda dinámica
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildLegendItem(
                                      isDark ? AppColors.brightBlue : const Color(0xFF0F4C81),
                                      'Movilidad y tráfico',
                                      '$mobPct% ($mobilityCount)',
                                      isDark,
                                    ),
                                    const SizedBox(height: 8),
                                    _buildLegendItem(
                                      const Color(0xFF10B981),
                                      'Seguridad ciudadana',
                                      '$secPct% ($securityCount)',
                                      isDark,
                                    ),
                                    const SizedBox(height: 8),
                                    _buildLegendItem(
                                      const Color(0xFFF59E0B),
                                      'Infraestructura y vías',
                                      '$infPct% ($infraCount)',
                                      isDark,
                                    ),
                                    const SizedBox(height: 8),
                                    _buildLegendItem(
                                      const Color(0xFFEF4444),
                                      'Otros servicios',
                                      '$othPct% ($otherCount)',
                                      isDark,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Sectores con mayor reporte DINÁMICO (Figma 2:438)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCard : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? AppColors.darkBorder : const Color(0xFFE7ECF1),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sectores con mayor reporte',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.darkText : const Color(0xFF142C40),
                            ),
                          ),
                          const SizedBox(height: 14),
                          if (topSectors.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                'No hay datos suficientes para rankear sectores',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? AppColors.darkTextMuted : const Color(0xFF94A3B8),
                                ),
                              ),
                            )
                          else
                            for (int i = 0; i < topSectors.length; i++) ...[
                              _buildSectorRank(
                                '0${i + 1}',
                                topSectors[i].key,
                                topSectors[i].value,
                                maxSectorCount,
                                isDark,
                              ),
                              if (i < topSectors.length - 1) const SizedBox(height: 10),
                            ],
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
      );
    }

  Widget _buildPeriodOption(String title, bool isDark) {
    final isSelected = _selectedPeriod == title && _customDateRange == null;
    return InkWell(
      borderRadius: BorderRadius.circular(9),
      onTap: () {
        setState(() {
          _customDateRange = null;
          _selectedPeriod = title;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColors.brightBlue : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          title,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? Colors.white
                : (isDark ? AppColors.darkTextMuted : const Color(0xFF64748B)),
          ),
        ),
      ),
    );
  }

  Widget _buildDayBar(
    String label,
    int value,
    int maxValue, {
    required bool isDark,
    bool isPeak = false,
  }) {
    final ratio = maxValue > 0 ? (value / maxValue).clamp(0.05, 1.0) : 0.05;
    const maxBarHeight = 75.0;
    final barHeight = ratio * maxBarHeight;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (isPeak) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isDark ? AppColors.brightBlue : const Color(0xFF0F4C81),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '$value reportes',
              style: const TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 4),
        ] else ...[
          const SizedBox(height: 18),
        ],
        Container(
          width: 14,
          height: barHeight,
          decoration: BoxDecoration(
            color: isPeak
                ? (isDark ? AppColors.brightBlue : const Color(0xFF0F4C81))
                : (isDark ? const Color(0xFF334155) : const Color(0xFF8FAAC4)),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isPeak ? FontWeight.w700 : FontWeight.w500,
            color: isPeak
                ? (isDark ? AppColors.brightBlue : const Color(0xFF0F4C81))
                : (isDark ? AppColors.darkTextMuted : const Color(0xFF64748B)),
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(
    Color color,
    String label,
    String percentage,
    bool isDark,
  ) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.darkTextMuted : const Color(0xFF526579),
            ),
          ),
        ),
        Text(
          percentage,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.darkText : const Color(0xFF142C40),
          ),
        ),
      ],
    );
  }

  Widget _buildSectorRank(
    String rank,
    String sector,
    int count,
    int maxCount,
    bool isDark,
  ) {
    final progress = maxCount > 0 ? (count / maxCount).clamp(0.05, 1.0) : 0.05;

    return InkWell(
      onTap: widget.onSelectSector != null ? () => widget.onSelectSector!(sector) : null,
      child: Row(
        children: [
          SizedBox(
            width: 20,
            child: Text(
              rank,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkTextMuted : const Color(0xFF94A3B8),
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(
              sector,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkText : const Color(0xFF142C40),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 5,
                backgroundColor: isDark
                    ? const Color(0xFF1E293B)
                    : const Color(0xFFF1F5F9),
                valueColor: AlwaysStoppedAnimation<Color>(
                  isDark ? AppColors.brightBlue : const Color(0xFF0F4C81),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 24,
            child: Text(
              '$count',
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkText : const Color(0xFF142C40),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
