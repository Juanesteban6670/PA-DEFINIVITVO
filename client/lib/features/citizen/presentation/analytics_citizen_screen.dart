import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'package:cartagena_segura/core/data/api_client.dart';

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
  final List<String> _periods = const ['Hoy', 'Esta semana', 'Este mes'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              children: [
                // Encabezado (Figma Frame 2:434)
                const Text(
                  'Estadísticas Ciudadanas',
                  style: TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF142C40),
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Panorama de seguridad y movilidad',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 16),

                // Selector de período (Figma 2:472)
                Container(
                  height: 36,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE9EEF3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      for (final period in _periods) ...[
                        Expanded(
                          child: _buildPeriodOption(period),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Indicadores Principales 1x2 (Figma Frame 2:435)
                Row(
                  children: [
                    // Total Reportes (Figma 2:479)
                    Expanded(
                      child: Container(
                        height: 108,
                        padding: const EdgeInsets.all(12),
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Total Reportes',
                                  style: TextStyle(
                                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF526579),
                                  ),
                                ),
                                Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE8F0F8),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Icon(
                                    Icons.bar_chart_rounded,
                                    color: Color(0xFF0F4C81),
                                    size: 14,
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            const Text(
                              '142',
                              style: TextStyle(
                                            fontSize: 32,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F4C81),
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
                                color: const Color(0xFFE6F7EF),
                                borderRadius: BorderRadius.circular(7),
                              ),
                              child: const Text(
                                '+12% frente a la semana anterior',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                                fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF087554),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Tasa de Resolución (Figma 2:487)
                    Expanded(
                      child: Container(
                        height: 108,
                        padding: const EdgeInsets.all(12),
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Tasa de Resolución',
                                  style: TextStyle(
                                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF526579),
                                  ),
                                ),
                                Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE5F7EF),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Icon(
                                    Icons.check_circle_outline_rounded,
                                    color: Color(0xFF087F5B),
                                    size: 14,
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            const Text(
                              '78%',
                              style: TextStyle(
                                            fontSize: 32,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F4C81),
                                height: 1.0,
                              ),
                            ),
                            const Spacer(),
                            // Barra de progreso 78% (Figma 2:493)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: Container(
                                height: 7,
                                color: const Color(0xFFDDF4EA),
                                child: FractionallySizedBox(
                                  alignment: Alignment.centerLeft,
                                  widthFactor: 0.78,
                                  child: Container(
                                    color: const Color(0xFF10B981),
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
                const SizedBox(height: 18),

                // Actividad de reportes (Últimos 7 días) (Figma Frame 2:436)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE7ECF1)),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0F2940).withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Actividad de reportes (Últimos 7 días)',
                        style: TextStyle(
                                fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF142C40),
                        ),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        height: 140,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            // Eje Y con guías
                            const SizedBox(
                              width: 18,
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '40',
                                    style: TextStyle(
                                                        fontSize: 9,
                                      color: Color(0xFF94A3B8),
                                    ),
                                  ),
                                  Text(
                                    '20',
                                    style: TextStyle(
                                                        fontSize: 9,
                                      color: Color(0xFF94A3B8),
                                    ),
                                  ),
                                  Text(
                                    '0',
                                    style: TextStyle(
                                                        fontSize: 9,
                                      color: Color(0xFF94A3B8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Barras diarias (Figma 2:503 a 2:514)
                            Expanded(
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  _buildDayBar('L', 14, 40),
                                  _buildDayBar('M', 18, 40),
                                  _buildDayBar('X', 22, 40),
                                  _buildDayBar('J', 16, 40),
                                  _buildDayBar('V', 34, 40, isPeak: true),
                                  _buildDayBar('S', 24, 40),
                                  _buildDayBar('D', 14, 40),
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

                // Incidentes por categoría (Donut Chart) (Figma 2:437)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE7ECF1)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Incidentes por categoría',
                        style: TextStyle(
                                fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF142C40),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          // Donut Chart con "142 Total" en el centro
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
                                    sections: [
                                      PieChartSectionData(
                                        value: 46,
                                        color: const Color(0xFF0F4C81),
                                        radius: 16,
                                        showTitle: false,
                                      ),
                                      PieChartSectionData(
                                        value: 30,
                                        color: const Color(0xFF10B981),
                                        radius: 16,
                                        showTitle: false,
                                      ),
                                      PieChartSectionData(
                                        value: 15,
                                        color: const Color(0xFFF59E0B),
                                        radius: 16,
                                        showTitle: false,
                                      ),
                                      PieChartSectionData(
                                        value: 12,
                                        color: const Color(0xFFEF4444),
                                        radius: 16,
                                        showTitle: false,
                                      ),
                                    ],
                                  ),
                                ),
                                const Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '142',
                                      style: TextStyle(
                                                            fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF142C40),
                                        height: 1.0,
                                      ),
                                    ),
                                    Text(
                                      'Total',
                                      style: TextStyle(
                                                            fontSize: 9,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Leyenda de categorías
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLegendItem(
                                  const Color(0xFF0F4C81),
                                  'Movilidad y tráfico',
                                  '46%',
                                ),
                                const SizedBox(height: 8),
                                _buildLegendItem(
                                  const Color(0xFF10B981),
                                  'Seguridad ciudadana',
                                  '30%',
                                ),
                                const SizedBox(height: 8),
                                _buildLegendItem(
                                  const Color(0xFFF59E0B),
                                  'Infraestructura y vías',
                                  '15%',
                                ),
                                const SizedBox(height: 8),
                                _buildLegendItem(
                                  const Color(0xFFEF4444),
                                  'Otros servicios',
                                  '12%',
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

                // Sectores con mayor reporte (Figma 2:438)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE7ECF1)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Sectores con mayor reporte',
                        style: TextStyle(
                                fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF142C40),
                        ),
                      ),
                      const SizedBox(height: 14),
                      _buildSectorRank('01', 'Centro Histórico', 46, 50),
                      const SizedBox(height: 10),
                      _buildSectorRank('02', 'Bocagrande', 38, 50),
                      const SizedBox(height: 10),
                      _buildSectorRank('03', 'Manga', 29, 50),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodOption(String title) {
    final isSelected = _selectedPeriod == title;
    return InkWell(
      borderRadius: BorderRadius.circular(9),
      onTap: () {
        setState(() {
          _selectedPeriod = title;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
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
            color: isSelected ? const Color(0xFF0F4C81) : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  Widget _buildDayBar(String day, int count, int maxVal, {bool isPeak = false}) {
    final heightRatio = (count / maxVal).clamp(0.05, 1.0);
    const maxBarHeight = 90.0;
    final barHeight = maxBarHeight * heightRatio;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (isPeak) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF0F4C81),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              '34 reportes',
              style: TextStyle(
                    fontSize: 8,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 4),
        ],
        Container(
          width: 22,
          height: barHeight,
          decoration: BoxDecoration(
            color: const Color(0xFF0F4C81),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(5),
              topRight: Radius.circular(5),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          day,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isPeak ? FontWeight.w700 : FontWeight.w500,
            color: const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label, String pct) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
                fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Color(0xFF142C40),
            ),
          ),
        ),
        Text(
          '($pct)',
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Color(0xFF526579),
          ),
        ),
      ],
    );
  }

  Widget _buildSectorRank(String rank, String sector, int count, int maxVal) {
    final factor = (count / maxVal).clamp(0.05, 1.0);
    return Row(
      children: [
        Text(
          rank,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Color(0xFF94A3B8),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 105,
          child: Text(
            sector,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF142C40),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Container(
              height: 6,
              color: const Color(0xFFE2E8F0),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: factor,
                child: Container(
                  color: const Color(0xFF0F4C81),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '$count',
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F4C81),
          ),
        ),
      ],
    );
  }
}
