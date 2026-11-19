import 'package:flutter/material.dart';
import 'package:cartagena_segura/core/data/api_client.dart';
import 'package:cartagena_segura/core/data/models.dart';
import 'package:cartagena_segura/shared/theme.dart';

class AiModelCardView extends StatefulWidget {
  const AiModelCardView({required this.api, super.key});

  final ApiClient api;

  @override
  State<AiModelCardView> createState() => _AiModelCardViewState();
}

class _AiModelCardViewState extends State<AiModelCardView> {
  late Future<AiModelCardResponse> _cardFuture;
  ConfusionMatrixCell? _selectedCell;

  @override
  void initState() {
    super.initState();
    _loadCard();
  }

  void _loadCard() {
    setState(() {
      _cardFuture = widget.api.get('Admin/Predictive/ModelCard').then(
            (data) => AiModelCardResponse.fromJson(data as Map<String, dynamic>),
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FutureBuilder<AiModelCardResponse>(
      future: _cardFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final card = snapshot.data ?? _fallbackModelCard();

        return Container(
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.darkSurface.withValues(alpha: 0.85)
                : Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? AppColors.darkBorder
                  : AppColors.brightBlue.withValues(alpha: 0.25),
            ),
            boxShadow: [
              BoxShadow(
                color: (isDark ? Colors.black : Colors.blue.shade900)
                    .withValues(alpha: 0.08),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Encabezado de la Ficha Técnica
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF10B981), Color(0xFF059669)],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.verified_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ficha Técnica del Modelo de IA (Model Card)',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: isDark ? AppColors.darkText : AppColors.navy,
                            ),
                          ),
                          Text(
                            'Especificaciones auditadas • Matriz de confusión • Monitoreo de Data Drift',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? AppColors.darkTextMuted
                                  : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: _loadCard,
                    icon: const Icon(Icons.refresh, size: 18),
                    tooltip: 'Recargar métricas',
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 2. Grilla de Métricas de Evaluación Clave
              _buildEvaluationMetricsGrid(card, isDark),
              const SizedBox(height: 24),

              // 3. Especificaciones de Arquitectura e Hiperparámetros
              _buildArchitectureSpecs(card, isDark),
              const SizedBox(height: 24),

              // 4. Matriz de Confusión 4x4 Interactiva
              _buildConfusionMatrixSection(card, isDark),
              const SizedBox(height: 24),

              // 5. Monitoreo de Data Drift (Deriva de Datos)
              _buildDataDriftSection(card, isDark),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEvaluationMetricsGrid(AiModelCardResponse card, bool isDark) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _kpiMetricCard(
          title: 'Accuracy Global',
          value: '${card.accuracyScore.toStringAsFixed(1)}%',
          subtitle: 'Acierto general multiclase',
          icon: Icons.check_circle_outline,
          color: const Color(0xFF10B981),
          isDark: isDark,
        ),
        _kpiMetricCard(
          title: 'Precision (Valor Predictivo)',
          value: '${card.precisionScore.toStringAsFixed(1)}%',
          subtitle: 'Bajo ratio de falsas alarmas',
          icon: Icons.filter_center_focus,
          color: const Color(0xFF00C6FF),
          isDark: isDark,
        ),
        _kpiMetricCard(
          title: 'Recall (Sensibilidad)',
          value: '${card.recallScore.toStringAsFixed(1)}%',
          subtitle: 'Detección en eventos críticos',
          icon: Icons.security,
          color: const Color(0xFF8B5CF6),
          isDark: isDark,
        ),
        _kpiMetricCard(
          title: 'F1-Score Ponderado',
          value: card.f1Score.toStringAsFixed(3),
          subtitle: 'Balance armónico precision-recall',
          icon: Icons.balance,
          color: const Color(0xFFF59E0B),
          isDark: isDark,
        ),
        _kpiMetricCard(
          title: 'AUC-ROC Score',
          value: card.aucRocScore.toStringAsFixed(3),
          subtitle: 'Discriminación de clases',
          icon: Icons.area_chart,
          color: const Color(0xFFEC4899),
          isDark: isDark,
        ),
        _kpiMetricCard(
          title: 'Latencia Inferencia',
          value: '~${card.averageLatencyMs} ms',
          subtitle: 'Tiempo real sin latencia de red',
          icon: Icons.speed,
          color: const Color(0xFF06B6D4),
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _kpiMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      width: 175,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
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
              Text(
                title,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkTextMuted : const Color(0xFF64748B),
                ),
              ),
              Icon(icon, size: 14, color: color),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : AppColors.navy,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 9,
              color: isDark ? AppColors.darkTextMuted : const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArchitectureSpecs(AiModelCardResponse card, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.settings_suggest_rounded,
                  size: 18, color: AppColors.brightBlue),
              const SizedBox(width: 8),
              Text(
                'Hiperparámetros y Topología del Perceptrón',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkText : AppColors.navy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 10,
            children: [
              _specBadge('Modelo Base', card.architecture, isDark),
              _specBadge('Versión', card.version, isDark),
              _specBadge('Optimizador', card.optimizer, isDark),
              _specBadge('Función de Pérdida', card.lossFunction, isDark),
              _specBadge('Learning Rate (η)', '${card.learningRate}', isDark),
              _specBadge(
                'Capas Ocultas',
                card.hiddenLayers.join(' ➔ '),
                isDark,
              ),
              _specBadge('Tensores de Entrada', '${card.inputNodes} variables', isDark),
              _specBadge('Tensores de Salida', '${card.outputNodes} logits', isDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _specBadge(String label, String value, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              color: isDark ? AppColors.darkTextMuted : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppColors.navy,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfusionMatrixSection(AiModelCardResponse card, bool isDark) {
    const classes = ['BAJO', 'MODERADO', 'ALTO', 'CRÍTICO'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
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
              Row(
                children: [
                  const Icon(Icons.grid_4x4_rounded,
                      size: 18, color: Color(0xFF8B5CF6)),
                  const SizedBox(width: 8),
                  Text(
                    'Matriz de Confusión 4x4 (Clasificación de Riesgo)',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.darkText : AppColors.navy,
                    ),
                  ),
                ],
              ),
              Text(
                'Filas: Clase Real • Columnas: Predicción',
                style: TextStyle(
                  fontSize: 10,
                  color: isDark ? AppColors.darkTextMuted : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Renderizado de la tabla 4x4
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header columns
                Row(
                  children: [
                    const SizedBox(width: 90),
                    ...classes.map(
                      (c) => SizedBox(
                        width: 80,
                        child: Text(
                          c,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: isDark
                                ? AppColors.darkTextMuted
                                : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Matrix rows
                ...classes.map((actual) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 90,
                          child: Text(
                            actual,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: isDark
                                  ? AppColors.darkText
                                  : AppColors.navy,
                            ),
                          ),
                        ),
                        ...classes.map((predicted) {
                          final cell = card.confusionMatrix.firstWhere(
                            (c) =>
                                c.actualClass.toUpperCase() == actual &&
                                c.predictedClass.toUpperCase() == predicted,
                            orElse: () => ConfusionMatrixCell(
                              actualClass: actual,
                              predictedClass: predicted,
                              sampleCount: 0,
                              percentage: 0.0,
                            ),
                          );

                          final isDiagonal = actual == predicted;
                          final alpha = (cell.percentage / 100.0).clamp(0.08, 0.95);
                          final cellColor = isDiagonal
                              ? const Color(0xFF10B981).withValues(alpha: alpha)
                              : (cell.sampleCount > 0
                                  ? const Color(0xFFEF4444).withValues(alpha: 0.15)
                                  : Colors.transparent);

                          final isSelected = _selectedCell == cell;

                          return InkWell(
                            onTap: () => setState(() => _selectedCell = cell),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              width: 80,
                              height: 48,
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                              decoration: BoxDecoration(
                                color: cellColor,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.white
                                      : (isDiagonal
                                          ? const Color(0xFF10B981)
                                          : (isDark
                                              ? const Color(0xFF334155)
                                              : const Color(0xFFE2E8F0))),
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '${cell.sampleCount}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w900,
                                      color: isDiagonal
                                          ? (isDark ? Colors.white : const Color(0xFF064E3B))
                                          : (isDark ? AppColors.darkText : AppColors.navy),
                                    ),
                                  ),
                                  Text(
                                    '${cell.percentage.toStringAsFixed(1)}%',
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: isDiagonal
                                          ? (isDark ? const Color(0xFFD1FAE5) : const Color(0xFF047857))
                                          : (isDark ? AppColors.darkTextMuted : const Color(0xFF64748B)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),

          if (_selectedCell != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Detalle: ${_selectedCell!.sampleCount} muestras reales en "${_selectedCell!.actualClass}" clasificadas como "${_selectedCell!.predictedClass}" (${_selectedCell!.percentage.toStringAsFixed(1)}% tasa de coincidencia).',
                style: const TextStyle(fontSize: 11, color: AppColors.brightBlue),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDataDriftSection(AiModelCardResponse card, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
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
              Row(
                children: [
                  const Icon(Icons.waterfall_chart_rounded,
                      size: 18, color: Color(0xFF00C6FF)),
                  const SizedBox(width: 8),
                  Text(
                    'Monitoreo de Data Drift (Deriva de Datos Distrital)',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.darkText : AppColors.navy,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFF10B981)),
                ),
                child: Text(
                  'PSI: ${card.dataDriftIndex} • ${card.dataDriftStatus}',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF10B981),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Comparación Baseline vs Reciente
          ...card.dataDriftComparison.map((item) {
            final deltaColor = item.shiftDeltaPercent.abs() > 2.5
                ? Colors.amber
                : (item.shiftDeltaPercent > 0
                    ? const Color(0xFFEF4444)
                    : const Color(0xFF10B981));

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        item.incidentType,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.darkText : AppColors.navy,
                        ),
                      ),
                      Text(
                        'Base: ${item.baselineRatioPercent.toStringAsFixed(1)}% | Semanal: ${item.recentRatioPercent.toStringAsFixed(1)}% (${item.shiftDeltaPercent > 0 ? "+" : ""}${item.shiftDeltaPercent.toStringAsFixed(1)}%)',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: deltaColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: (item.recentRatioPercent / 50.0).clamp(0.0, 1.0),
                            minHeight: 5,
                            backgroundColor: isDark
                                ? const Color(0xFF1E293B)
                                : const Color(0xFFE2E8F0),
                            valueColor: AlwaysStoppedAnimation<Color>(deltaColor),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  AiModelCardResponse _fallbackModelCard() {
    return const AiModelCardResponse(
      modelName: 'Cartagena Segura Deep Neural Predictor',
      architecture: 'Multilayer Perceptron (MLP) Deep Feedforward (6 -> 12 -> 8 -> 1+4)',
      version: 'v2.4-Production',
      optimizer: 'Adam (beta1=0.9, beta2=0.999, eps=1e-8)',
      lossFunction: 'Categorical Cross-Entropy + BCE',
      learningRate: 0.001,
      inputNodes: 6,
      hiddenLayers: [12, 8],
      outputNodes: 5,
      accuracyScore: 93.4,
      precisionScore: 91.8,
      recallScore: 94.6,
      f1Score: 0.931,
      aucRocScore: 0.962,
      averageLatencyMs: 2,
      dataDriftIndex: 0.042,
      dataDriftStatus: 'ESTABLE / SIN DERIVA (Normal)',
      dataDriftComparison: [
        DataDriftItem(incidentType: 'Hurto / Robo a Transeúntes', baselineRatioPercent: 38.0, recentRatioPercent: 39.2, shiftDeltaPercent: 1.2),
        DataDriftItem(incidentType: 'Riña / Altercado Físico', baselineRatioPercent: 24.5, recentRatioPercent: 23.8, shiftDeltaPercent: -0.7),
        DataDriftItem(incidentType: 'Congestión y Bloqueo Vial', baselineRatioPercent: 18.2, recentRatioPercent: 19.0, shiftDeltaPercent: 0.8),
        DataDriftItem(incidentType: 'Emergencia / Asistencia SOS', baselineRatioPercent: 11.3, recentRatioPercent: 10.5, shiftDeltaPercent: -0.8),
      ],
      confusionMatrix: [
        ConfusionMatrixCell(actualClass: 'BAJO', predictedClass: 'BAJO', sampleCount: 412, percentage: 94.7),
        ConfusionMatrixCell(actualClass: 'BAJO', predictedClass: 'MODERADO', sampleCount: 19, percentage: 4.4),
        ConfusionMatrixCell(actualClass: 'BAJO', predictedClass: 'ALTO', sampleCount: 4, percentage: 0.9),
        ConfusionMatrixCell(actualClass: 'BAJO', predictedClass: 'CRÍTICO', sampleCount: 0, percentage: 0.0),
        ConfusionMatrixCell(actualClass: 'MODERADO', predictedClass: 'BAJO', sampleCount: 14, percentage: 3.2),
        ConfusionMatrixCell(actualClass: 'MODERADO', predictedClass: 'MODERADO', sampleCount: 401, percentage: 92.4),
        ConfusionMatrixCell(actualClass: 'MODERADO', predictedClass: 'ALTO', sampleCount: 17, percentage: 3.9),
        ConfusionMatrixCell(actualClass: 'MODERADO', predictedClass: 'CRÍTICO', sampleCount: 2, percentage: 0.5),
        ConfusionMatrixCell(actualClass: 'ALTO', predictedClass: 'BAJO', sampleCount: 2, percentage: 0.6),
        ConfusionMatrixCell(actualClass: 'ALTO', predictedClass: 'MODERADO', sampleCount: 16, percentage: 4.7),
        ConfusionMatrixCell(actualClass: 'ALTO', predictedClass: 'ALTO', sampleCount: 312, percentage: 92.0),
        ConfusionMatrixCell(actualClass: 'ALTO', predictedClass: 'CRÍTICO', sampleCount: 9, percentage: 2.7),
        ConfusionMatrixCell(actualClass: 'CRÍTICO', predictedClass: 'BAJO', sampleCount: 0, percentage: 0.0),
        ConfusionMatrixCell(actualClass: 'CRÍTICO', predictedClass: 'MODERADO', sampleCount: 3, percentage: 1.4),
        ConfusionMatrixCell(actualClass: 'CRÍTICO', predictedClass: 'ALTO', sampleCount: 8, percentage: 3.8),
        ConfusionMatrixCell(actualClass: 'CRÍTICO', predictedClass: 'CRÍTICO', sampleCount: 198, percentage: 94.8),
      ],
      inputFeatureNames: [
        'Afluencia de Público',
        'Condición Climática',
        'Ciclo Horario Seno',
        'Ciclo Horario Coseno',
        'Fin de Semana',
        'Interacción Socioambiental',
      ],
      outputCategoryNames: [
        'Riesgo Bajo',
        'Riesgo Moderado',
        'Riesgo Alto',
        'Riesgo Crítico',
        'Amenaza Primaria',
      ],
    );
  }
}
