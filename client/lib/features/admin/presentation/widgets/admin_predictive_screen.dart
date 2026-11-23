import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'package:cartagena_segura/core/data/api_client.dart';
import 'package:cartagena_segura/core/data/models.dart';
import 'package:cartagena_segura/features/admin/presentation/widgets/ai_model_card_view.dart';
import 'package:cartagena_segura/features/admin/presentation/widgets/ai_prediction_breakdown.dart';
import 'package:cartagena_segura/features/admin/presentation/widgets/neural_network_visualizer.dart';
import 'package:cartagena_segura/shared/theme.dart';

class AdminPredictiveScreen extends StatefulWidget {
  const AdminPredictiveScreen({required this.api, super.key});

  final ApiClient api;

  @override
  State<AdminPredictiveScreen> createState() => _AdminPredictiveScreenState();
}

class _AdminPredictiveScreenState extends State<AdminPredictiveScreen> {
  late Future<RiskForecastResponse> _forecastFuture;
  int _selectedView =
      0; // 0: Simulador & Red Neuronal, 1: Ficha Técnica & Observabilidad

  // Variables del Simulador
  String _simSector = 'Centro Histórico';
  double _simHour = 20.0;
  bool _simWeekend = true;
  String _simCrowd = 'ALTO';
  String _simWeather = 'DESPEJADO';
  SimulationResponse? _simResult;
  bool _simulating = false;

  final List<String> _cartagenaSectors = const [
    'Centro Histórico',
    'Bazurto',
    'Olaya Herrera',
    'Getsemaní',
    'Bocagrande',
    'Manga',
    'Pie de la Popa',
    'El Cabrero',
  ];

  @override
  void initState() {
    super.initState();
    _loadForecast();
  }

  void _loadForecast() {
    setState(() {
      _forecastFuture = widget.api
          .get('Admin/Predictive/RiskForecast')
          .then(
            (data) =>
                RiskForecastResponse.fromJson(data as Map<String, dynamic>),
          );
    });
  }

  Future<void> _runSimulation() async {
    setState(() => _simulating = true);
    try {
      final res = await widget.api.post('Admin/Predictive/Simulate', {
        'sector': _simSector,
        'hourOfDay': _simHour.round(),
        'isWeekendOrHoliday': _simWeekend,
        'crowdLevel': _simCrowd,
        'weatherCondition': _simWeather,
      });
      if (mounted) {
        setState(() {
          _simResult = SimulationResponse.fromJson(res as Map<String, dynamic>);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error en la simulación neuronal: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _simulating = false);
    }
  }

  Color _getRiskColor(String level, bool isDark) {
    return switch (level.toUpperCase()) {
      'CRÍTICO' => isDark ? AppColors.darkRed : AppColors.red,
      'ALTO' => isDark ? AppColors.darkAmber : AppColors.amber,
      'MODERADO' => isDark ? AppColors.darkYellow : AppColors.yellow,
      _ => isDark ? AppColors.darkGreen : AppColors.green,
    };
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FutureBuilder<RiskForecastResponse>(
      future: _forecastFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.cloud_off_outlined,
                    size: 48,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Error al cargar el modelo predictivo',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.darkText : AppColors.navy,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isDark
                          ? AppColors.darkTextMuted
                          : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _loadForecast,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          );
        }

        final data = snapshot.data!;
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // 1. ENCABEZADO Y STATUS DEL MODELO
            _buildHeader(data, isDark),
            const SizedBox(height: 16),

            // Selector de Vistas de IA (Liquid Glass)
            _buildViewSelector(isDark),
            const SizedBox(height: 20),

            if (_selectedView == 0) ...[
              // 2. TARJETAS KPI DISTRITALES
              _buildKpiGrid(data, isDark),
              const SizedBox(height: 24),

              // 3. GRÁFICO DINÁMICO FL_CHART (Curva predictiva 12 horas)
              _buildChartSection(data, isDark),
              const SizedBox(height: 24),

              // 4. SIMULADOR TÁCTICO INTERACTIVO + RED NEURONAL + XAI
              _buildSimulatorCard(isDark),
              const SizedBox(height: 24),

              // 5. MATRIZ DE RIESGO Y DESPLIEGUE POR SECTOR
              _buildSectorMatrix(data, isDark),
            ] else ...[
              // FICHA TÉCNICA Y OBSERVABILIDAD DEL MODELO DE IA
              AiModelCardView(api: widget.api),
            ],
          ],
        );
      },
    );
  }

  Widget _buildHeader(RiskForecastResponse data, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.brightBlue.withValues(alpha: 0.15)
                          : AppColors.blue.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.psychology_outlined,
                      color: isDark ? AppColors.brightBlue : AppColors.blue,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Red Neuronal Predictiva y Minería de Datos',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: isDark ? AppColors.darkText : AppColors.navy,
                        ),
                      ),
                      Text(
                        'Inferencia en tiempo real sobre incidentes distritales y hotspots criminales',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.darkTextMuted
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _StatusChip(
                    icon: Icons.check_circle_outline,
                    label: data.modelMetadata.version,
                    color: Colors.green,
                    isDark: isDark,
                  ),
                  _StatusChip(
                    icon: Icons.dataset_outlined,
                    label:
                        '${data.modelMetadata.trainingSamples} eventos minados',
                    color: Colors.blue,
                    isDark: isDark,
                  ),
                  _StatusChip(
                    icon: Icons.speed_rounded,
                    label: 'Latencia: ~3ms',
                    color: Colors.purple,
                    isDark: isDark,
                  ),
                  _StatusChip(
                    icon: Icons.verified_outlined,
                    label: 'Precisión: ${data.modelMetadata.accuracyScore}%',
                    color: Colors.teal,
                    isDark: isDark,
                  ),
                ],
              ),
            ],
          ),
        ),
        IconButton.filledTonal(
          onPressed: _loadForecast,
          icon: const Icon(Icons.refresh_rounded),
          tooltip: 'Actualizar inferencia en vivo',
        ),
      ],
    );
  }

  Widget _buildKpiGrid(RiskForecastResponse data, bool isDark) {
    final riskColor = _getRiskColor(data.districtRiskLevel, isDark);

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 750;
        final count = wide ? 4 : 2;
        return GridView.count(
          crossAxisCount: count,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: wide ? 1.7 : 1.35,
          children: [
            _KpiCard(
              title: 'Riesgo Distrital Global',
              value: '${data.districtRiskScore}%',
              subtitle: 'Nivel: ${data.districtRiskLevel}',
              accentColor: riskColor,
              icon: Icons.shield_outlined,
              isDark: isDark,
            ),
            _KpiCard(
              title: 'Hotspot Más Vulnerable',
              value: data.highestRiskSector,
              subtitle: 'Mayor probabilidad de ocurrencia',
              accentColor: isDark ? AppColors.darkRed : AppColors.red,
              icon: Icons.warning_amber_rounded,
              isDark: isDark,
            ),
            _KpiCard(
              title: 'Ventana Horaria Crítica',
              value: data.criticalWindow,
              subtitle: 'Pico de probabilidad proyectado',
              accentColor: isDark ? AppColors.darkAmber : AppColors.amber,
              icon: Icons.access_time_rounded,
              isDark: isDark,
            ),
            _KpiCard(
              title: 'Eficacia Preventiva',
              value: '${data.preventiveEffectiveness}%',
              subtitle: 'Impacto estimado de patrullaje',
              accentColor: isDark ? AppColors.darkGreen : AppColors.green,
              icon: Icons.health_and_safety_outlined,
              isDark: isDark,
            ),
          ],
        );
      },
    );
  }

  Widget _buildChartSection(RiskForecastResponse data, bool isDark) {
    final spotsPredicted = <FlSpot>[];
    final spotsBaseline = <FlSpot>[];

    for (var i = 0; i < data.hourlyForecast.length; i++) {
      spotsPredicted.add(
        FlSpot(i.toDouble(), data.hourlyForecast[i].predictedRisk),
      );
      spotsBaseline.add(
        FlSpot(i.toDouble(), data.hourlyForecast[i].baselineRisk),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Curva de Tendencia Predictiva (Próximas 12 Horas)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.darkText : AppColors.navy,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Índice de riesgo estimado (0–100)',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.darkTextMuted
                          : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  _LegendIndicator(
                    color: isDark ? AppColors.brightBlue : AppColors.blue,
                    text: 'Red Neuronal (Predicción)',
                    isDark: isDark,
                  ),
                  const SizedBox(width: 14),
                  _LegendIndicator(
                    color: isDark
                        ? const Color(0xFF64748B)
                        : const Color(0xFF94A3B8),
                    text: 'Referencia calculada',
                    isDark: isDark,
                    isDashed: true,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 260,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: 100,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: isDark
                        ? const Color(0xFF1F293D)
                        : const Color(0xFFF1F5F9),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 36,
                      interval: 20,
                      getTitlesWidget: (val, meta) => Text(
                        '${val.toInt()}%',
                        style: TextStyle(
                          color: isDark
                              ? AppColors.darkTextMuted
                              : const Color(0xFF94A3B8),
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (val, meta) {
                        final idx = val.toInt();
                        if (idx >= 0 && idx < data.hourlyForecast.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              data.hourlyForecast[idx].hourLabel,
                              style: TextStyle(
                                color: isDark
                                    ? AppColors.darkTextMuted
                                    : const Color(0xFF64748B),
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
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
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => isDark
                        ? const Color(0xFF0F172A)
                        : const Color(0xFF1E293B),
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final idx = spot.x.toInt();
                        final hourItem = data.hourlyForecast[idx];
                        if (spot.barIndex == 0) {
                          return LineTooltipItem(
                            'Hora: ${hourItem.hourLabel}\nRiesgo Predicho: ${spot.y.toStringAsFixed(1)}%\nIncidentes est.: ~${hourItem.estimatedIncidents}',
                            const TextStyle(color: Colors.white, fontSize: 11),
                          );
                        }
                        return LineTooltipItem(
                          'Línea base: ${spot.y.toStringAsFixed(1)}%',
                          const TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 11,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
                lineBarsData: [
                  // 1. Línea Neuronal
                  LineChartBarData(
                    spots: spotsPredicted,
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: isDark ? AppColors.brightBlue : AppColors.blue,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: (isDark ? AppColors.brightBlue : AppColors.blue)
                          .withValues(alpha: isDark ? 0.15 : 0.08),
                    ),
                  ),
                  // 2. Línea Base
                  LineChartBarData(
                    spots: spotsBaseline,
                    isCurved: true,
                    dashArray: [5, 4],
                    color: isDark
                        ? const Color(0xFF64748B)
                        : const Color(0xFF94A3B8),
                    barWidth: 2,
                    dotData: const FlDotData(show: false),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimulatorCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.tune_rounded,
                color: isDark ? AppColors.brightBlue : AppColors.blue,
                size: 22,
              ),
              const SizedBox(width: 10),
              Text(
                'Simulador Táctico de Escenarios (Inferencia On-Demand)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.darkText : AppColors.navy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Modifica las variables ambientales y operativas para probar la respuesta de la Red Neuronal en tiempo real.',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.darkTextMuted : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 700;
              return wide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildSimulatorControls(isDark)),
                        const SizedBox(width: 20),
                        Expanded(child: _buildSimulatorOutput(isDark)),
                      ],
                    )
                  : Column(
                      children: [
                        _buildSimulatorControls(isDark),
                        const SizedBox(height: 16),
                        _buildSimulatorOutput(isDark),
                      ],
                    );
            },
          ),
          const SizedBox(height: 24),

          // Grafo Sináptico Interactivo de la Red Neuronal (60 FPS)
          NeuralNetworkVisualizer(
            riskScore: _simResult?.predictedRiskScore ?? 62.0,
            riskLevel: _simResult?.riskLevel ?? 'ALTO',
            primaryThreat:
                _simResult?.primaryThreat ?? 'Hurto / Robo a Transeúntes',
            activations: _simResult?.neuralActivations ?? const {},
            sector: _simSector,
            hourOfDay: _simHour.round(),
            crowdLevel: _simCrowd,
            weather: _simWeather,
            isWeekend: _simWeekend,
          ),
          const SizedBox(height: 24),

          // Desglose Multivariable XAI (Explainable AI & Ponderación SHAP-like)
          AiPredictionBreakdown(
            predictedRiskScore: _simResult?.predictedRiskScore ?? 62.0,
            riskLevel: _simResult?.riskLevel ?? 'ALTO',
            primaryThreat:
                _simResult?.primaryThreat ?? 'Hurto / Robo a Transeúntes',
            confidenceMargin: _simResult?.confidenceMargin ?? 4.2,
            modelCertaintyScore: _simResult?.modelCertaintyScore ?? 95.8,
            featureContributions: _simResult?.featureContributions ?? const [],
            sector: _simSector,
            hourOfDay: _simHour.round(),
          ),
        ],
      ),
    );
  }

  Widget _buildViewSelector(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _viewTabButton(
              index: 0,
              icon: Icons.hub_rounded,
              label: 'Simulador Táctico & Red Neuronal',
              isDark: isDark,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _viewTabButton(
              index: 1,
              icon: Icons.fact_check_outlined,
              label: 'Ficha Técnica y Observabilidad (Model Card)',
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _viewTabButton({
    required int index,
    required IconData icon,
    required String label,
    required bool isDark,
  }) {
    final active = _selectedView == index;
    return InkWell(
      onTap: () => setState(() => _selectedView = index),
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: active
              ? (isDark
                    ? AppColors.blue.withValues(alpha: 0.35)
                    : AppColors.blue)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active ? AppColors.brightBlue : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: active
                  ? Colors.white
                  : (isDark ? AppColors.darkTextMuted : AppColors.navy),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                  color: active
                      ? Colors.white
                      : (isDark ? AppColors.darkText : AppColors.navy),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimulatorControls(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sector selector
        Text(
          'Sector de Cartagena',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.darkText : AppColors.navy,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: _simSector,
          isDense: true,
          decoration: InputDecoration(
            filled: true,
            fillColor: isDark ? AppColors.darkSurface : const Color(0xFFF8FAFC),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
          items: _cartagenaSectors
              .map((s) => DropdownMenuItem(value: s, child: Text(s)))
              .toList(),
          onChanged: (val) {
            if (val != null) setState(() => _simSector = val);
          },
        ),
        const SizedBox(height: 14),

        // Hour slider
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Hora del día: ${_simHour.round()}:00 hrs',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkText : AppColors.navy,
              ),
            ),
            Text(
              _simHour < 6
                  ? 'Madrugada'
                  : _simHour < 12
                  ? 'Mañana'
                  : _simHour < 18
                  ? 'Tarde'
                  : 'Noche',
              style: TextStyle(
                fontSize: 11,
                color: isDark ? AppColors.brightBlue : AppColors.blue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        Slider(
          value: _simHour,
          min: 0,
          max: 23,
          divisions: 23,
          label: '${_simHour.round()}:00',
          onChanged: (val) => setState(() => _simHour = val),
        ),
        const SizedBox(height: 10),

        // Extras: Weekend toggle & Crowd & Weather
        Row(
          children: [
            Expanded(
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: const Text(
                  'Fin de semana / Festivo',
                  style: TextStyle(fontSize: 12),
                ),
                value: _simWeekend,
                onChanged: (val) => setState(() => _simWeekend = val),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Aglomeración',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<String>(
                    initialValue: _simCrowd,
                    isDense: true,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: isDark
                          ? AppColors.darkSurface
                          : const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'BAJO', child: Text('Bajo')),
                      DropdownMenuItem(value: 'MEDIO', child: Text('Medio')),
                      DropdownMenuItem(value: 'ALTO', child: Text('Alto')),
                      DropdownMenuItem(value: 'MASIVO', child: Text('Masivo')),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => _simCrowd = v);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Clima',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<String>(
                    initialValue: _simWeather,
                    isDense: true,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: isDark
                          ? AppColors.darkSurface
                          : const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'DESPEJADO',
                        child: Text('Despejado'),
                      ),
                      DropdownMenuItem(value: 'LLUVIA', child: Text('Lluvia')),
                      DropdownMenuItem(
                        value: 'TORMENTA',
                        child: Text('Tormenta'),
                      ),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => _simWeather = v);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),

        SizedBox(
          width: double.infinity,
          height: 44,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F4C81),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: _simulating ? null : _runSimulation,
            icon: _simulating
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.bolt_rounded),
            label: Text(
              _simulating
                  ? 'Computando tensores...'
                  : 'Ejecutar Inferencia Neuronal',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSimulatorOutput(bool isDark) {
    if (_simResult == null) {
      return Container(
        height: 240,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.memory_rounded,
              size: 40,
              color: isDark ? AppColors.darkTextMuted : const Color(0xFF94A3B8),
            ),
            const SizedBox(height: 10),
            Text(
              'Ajusta las variables y haz clic en\n"Ejecutar Inferencia Neuronal"',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? AppColors.darkTextMuted
                    : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      );
    }

    final res = _simResult!;
    final riskColor = _getRiskColor(res.riskLevel, isDark);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: riskColor.withValues(alpha: 0.5), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Resultado de Inferencia',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.darkText : AppColors.navy,
                ),
              ),
              Text(
                '${res.inferenceLatencyMs} ms',
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: riskColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: riskColor.withValues(alpha: 0.4)),
                ),
                child: Column(
                  children: [
                    Text(
                      '${res.predictedRiskScore.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: riskColor,
                      ),
                    ),
                    Text(
                      res.riskLevel,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: riskColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Amenaza Principal:',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? AppColors.darkTextMuted
                            : const Color(0xFF64748B),
                      ),
                    ),
                    Text(
                      res.primaryThreat,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppColors.darkText : AppColors.navy,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      res.tacticalAdvice,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? AppColors.darkText
                            : const Color(0xFF334155),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 8),
          Text(
            'Activaciones de Capas Ocultas (Tensores):',
            style: TextStyle(
              fontSize: 10,
              color: isDark ? AppColors.darkTextMuted : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: res.neuralActivations.entries.take(6).map((e) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : Colors.white,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${e.key.replaceAll('capa_oculta_', 'c')}: ${e.value}',
                  style: const TextStyle(fontSize: 9, fontFamily: 'monospace'),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSectorMatrix(RiskForecastResponse data, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Matriz de Riesgo y Despliegue Táctico por Sector',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.darkText : AppColors.navy,
                  ),
                ),
                Text(
                  'Priorización basada en minería histórica de 7d/30d y scoring neuronal',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.darkTextMuted
                        : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 850;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: wide ? 2 : 1,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: wide ? 2.5 : 2.1,
              ),
              itemCount: data.sectorPredictions.length,
              itemBuilder: (context, index) {
                final sp = data.sectorPredictions[index];
                final riskColor = _getRiskColor(sp.riskLevel, isDark);
                return Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.border,
                      width: 0.8,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_rounded,
                                size: 18,
                                color: riskColor,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                sp.sector,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.3,
                                  color: isDark
                                      ? AppColors.darkText
                                      : AppColors.navy,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: riskColor.withValues(
                                alpha: isDark ? 0.2 : 0.12,
                              ),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: riskColor.withValues(
                                  alpha: isDark ? 0.45 : 0.25,
                                ),
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              '${sp.riskScore}% · ${sp.riskLevel}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.1,
                                color: riskColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      // Progress bar estilo Apple Capsule
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: (sp.riskScore / 100.0).clamp(0.0, 1.0),
                          backgroundColor: isDark
                              ? const Color(0xFF2C2C2E)
                              : const Color(0xFFE5E5EA),
                          color: riskColor,
                          minHeight: 5,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            'Amenaza: ${sp.mostProbableType}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.1,
                              color: isDark
                                  ? AppColors.brightBlue
                                  : AppColors.blue,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '7d: ${sp.incidentsLast7d} | 30d: ${sp.incidentsLast30d}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: isDark
                                  ? AppColors.darkTextMuted
                                  : AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '🛡️ ${sp.recommendation} (${sp.suggestedPatrolUnits} patrullas)',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          height: 1.3,
                          color: isDark
                              ? AppColors.darkTextMuted
                              : AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.accentColor,
    required this.icon,
    required this.isDark,
  });

  final String title;
  final String value;
  final String subtitle;
  final Color accentColor;
  final IconData icon;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
          width: 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.1,
                    color: isDark ? AppColors.darkTextMuted : AppColors.muted,
                  ),
                ),
              ),
              Icon(icon, size: 20, color: accentColor),
            ],
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: isDark ? AppColors.darkText : AppColors.navy,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.1,
              color: accentColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.isDark,
  });

  final IconData icon;
  final String label;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.18 : 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.35 : 0.2),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isDark ? color : color.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendIndicator extends StatelessWidget {
  const _LegendIndicator({
    required this.color,
    required this.text,
    required this.isDark,
    this.isDashed = false,
  });

  final Color color;
  final String text;
  final bool isDark;
  final bool isDashed;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            fontSize: 11,
            color: isDark ? AppColors.darkTextMuted : const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }
}
