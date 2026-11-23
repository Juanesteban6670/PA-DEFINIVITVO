import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:cartagena_segura/shared/theme.dart';

/// Tarjeta moderna para mostrar indicadores clave de rendimiento (KPIs)
class KpiMetricCard extends StatelessWidget {
  const KpiMetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.isDark,
    this.badgeText,
    this.badgeColor,
    this.onTap,
    super.key,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool isDark;
  final String? badgeText;
  final Color? badgeColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: isDark ? 0.2 : 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color, size: 18),
                  ),
                  if (badgeText != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: (badgeColor ?? color).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        badgeText!,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: badgeColor ?? color,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.darkText : AppColors.navy,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkTextMuted : AppColors.muted,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 10,
                  color: isDark
                      ? AppColors.darkTextMuted
                      : const Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Gráfico de Barras: Cantidad de reportes por categoría
class CategoryBarChartWidget extends StatelessWidget {
  const CategoryBarChartWidget({
    required this.categories,
    required this.isDark,
    super.key,
  });

  final Map<String, int> categories;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return const SizedBox(
        height: 180,
        child: Center(child: Text('Sin datos de categorías')),
      );
    }

    final entries = categories.entries.toList();
    final maxVal = entries.map((e) => e.value).fold<int>(0, math.max);
    final topLimit = maxVal > 0 ? (maxVal * 1.25).ceil().toDouble() : 5.0;

    final colors = [
      isDark ? AppColors.darkRed : AppColors.red,
      isDark ? AppColors.darkAmber : AppColors.amber,
      isDark ? AppColors.sky : AppColors.blue,
      isDark ? AppColors.darkPurple : AppColors.purple,
    ];

    return SizedBox(
      height: 220,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: topLimit,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final catName = entries[group.x.toInt()].key;
                return BarTooltipItem(
                  '$catName\n',
                  TextStyle(
                    color: isDark ? AppColors.darkText : Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  children: [
                    TextSpan(
                      text: '${rod.toY.toInt()} reportes',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (val, meta) {
                  final idx = val.toInt();
                  if (idx < 0 || idx >= entries.length) {
                    return const SizedBox.shrink();
                  }
                  final name = entries[idx].key;
                  final shortName = name.length > 7
                      ? '${name.substring(0, 6)}.'
                      : name;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      shortName,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.darkTextMuted
                            : AppColors.muted,
                      ),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (val, meta) {
                  if (val == meta.max || val == 0) {
                    return const SizedBox.shrink();
                  }
                  return Text(
                    '${val.toInt()}',
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark ? AppColors.darkTextMuted : AppColors.muted,
                    ),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: math.max(1, (topLimit / 4).roundToDouble()),
            getDrawingHorizontalLine: (val) => FlLine(
              color: isDark ? AppColors.darkBorder : AppColors.border,
              strokeWidth: 0.8,
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: [
            for (int i = 0; i < entries.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: entries[i].value.toDouble(),
                    color: colors[i % colors.length],
                    width: 20,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(6),
                    ),
                    backDrawRodData: BackgroundBarChartRodData(
                      show: true,
                      toY: topLimit,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.04)
                          : Colors.black.withValues(alpha: 0.03),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// Gráfico de Líneas: Evolución temporal de incidentes
class TimelineLineChartWidget extends StatelessWidget {
  const TimelineLineChartWidget({
    required this.timelinePoints,
    required this.isDark,
    super.key,
  });

  final List<Map<String, dynamic>>
  timelinePoints; // {'label': 'Lun', 'count': 5}
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    if (timelinePoints.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('Sin datos temporales')),
      );
    }

    final maxVal = timelinePoints
        .map((p) => p['count'] as int)
        .fold<int>(0, math.max);
    final topLimit = maxVal > 0 ? (maxVal * 1.3).ceil().toDouble() : 5.0;

    final lineSpots = <FlSpot>[
      for (int i = 0; i < timelinePoints.length; i++)
        FlSpot(i.toDouble(), (timelinePoints[i]['count'] as int).toDouble()),
    ];

    final lineColor = isDark ? AppColors.brightBlue : AppColors.blue;

    return SizedBox(
      height: 220,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: topLimit,
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final idx = spot.x.toInt();
                  final label = idx >= 0 && idx < timelinePoints.length
                      ? timelinePoints[idx]['label']
                      : '';
                  return LineTooltipItem(
                    '$label: ${spot.y.toInt()} casos',
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  );
                }).toList();
              },
            ),
          ),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (val, meta) {
                  final idx = val.toInt();
                  if (idx < 0 || idx >= timelinePoints.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      timelinePoints[idx]['label'] as String,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.darkTextMuted
                            : AppColors.muted,
                      ),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                getTitlesWidget: (val, meta) {
                  if (val == meta.max || val == 0) {
                    return const SizedBox.shrink();
                  }
                  return Text(
                    '${val.toInt()}',
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark ? AppColors.darkTextMuted : AppColors.muted,
                    ),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: math.max(1, (topLimit / 3).roundToDouble()),
            getDrawingHorizontalLine: (_) => FlLine(
              color: isDark ? AppColors.darkBorder : AppColors.border,
              strokeWidth: 0.8,
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: lineSpots,
              isCurved: true,
              curveSmoothness: 0.35,
              color: lineColor,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: Colors.white,
                    strokeWidth: 2.5,
                    strokeColor: lineColor,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    lineColor.withValues(alpha: isDark ? 0.35 : 0.25),
                    lineColor.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Gráfico Comparativo: Recibidos vs Resueltos
class ComparisonChartWidget extends StatelessWidget {
  const ComparisonChartWidget({
    required this.receivedCount,
    required this.resolvedCount,
    required this.isDark,
    super.key,
  });

  final int receivedCount;
  final int resolvedCount;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final maxVal = math.max(receivedCount, resolvedCount);
    final topLimit = maxVal > 0 ? (maxVal * 1.25).ceil().toDouble() : 5.0;

    return SizedBox(
      height: 180,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceEvenly,
          maxY: topLimit,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final label = group.x == 0
                    ? 'Reportes Recibidos'
                    : 'Casos Resueltos';
                return BarTooltipItem(
                  '$label: ${rod.toY.toInt()}',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (val, meta) {
                  final label = val.toInt() == 0 ? 'Recibidos' : 'Resueltos';
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.darkText : AppColors.navy,
                      ),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 26,
                getTitlesWidget: (val, meta) {
                  if (val == meta.max || val == 0) {
                    return const SizedBox.shrink();
                  }
                  return Text(
                    '${val.toInt()}',
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark ? AppColors.darkTextMuted : AppColors.muted,
                    ),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => FlLine(
              color: isDark ? AppColors.darkBorder : AppColors.border,
              strokeWidth: 0.8,
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: [
            BarChartGroupData(
              x: 0,
              barRods: [
                BarChartRodData(
                  toY: receivedCount.toDouble(),
                  color: isDark ? AppColors.brightBlue : AppColors.blue,
                  width: 38,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(8),
                  ),
                ),
              ],
            ),
            BarChartGroupData(
              x: 1,
              barRods: [
                BarChartRodData(
                  toY: resolvedCount.toDouble(),
                  color: isDark ? AppColors.darkGreen : AppColors.green,
                  width: 38,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
