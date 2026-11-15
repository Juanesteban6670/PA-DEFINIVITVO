import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cartagena_segura/core/data/api_client.dart';
import 'package:cartagena_segura/shared/theme.dart';

class AdminAiOperationsCenter extends StatefulWidget {
  const AdminAiOperationsCenter({
    required this.api,
    required this.data,
    required this.onRefresh,
    super.key,
  });

  final ApiClient api;
  final List<dynamic> data;
  final VoidCallback onRefresh;

  @override
  State<AdminAiOperationsCenter> createState() =>
      _AdminAiOperationsCenterState();
}

class _AdminAiOperationsCenterState extends State<AdminAiOperationsCenter> {
  int _activeTab =
      0; // 0: Resumen & Diagnóstico, 1: Plan Táctico, 2: Anomalías, 3: Copiloto & Clasificador

  Map<String, dynamic> _map(dynamic val) {
    if (val is Map<String, dynamic>) return val;
    if (val is Map) return Map<String, dynamic>.from(val);
    return <String, dynamic>{};
  }

  List<dynamic> _list(dynamic val) {
    if (val is List) return val;
    return const [];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = MediaQuery.sizeOf(context).width < 768;

    // Extracción segura de los 4 conjuntos de datos de IA
    final summaryObj = widget.data.isNotEmpty ? widget.data[0] : null;
    final zonesObj = widget.data.length > 1 ? widget.data[1] : null;
    final patrolObj = widget.data.length > 2 ? widget.data[2] : null;
    final anomaliesObj = widget.data.length > 3 ? widget.data[3] : null;

    final summaryText = summaryObj is Map
        ? (summaryObj['summary']?.toString() ?? 'Sin resumen disponible')
        : summaryObj?.toString() ?? 'Sin resumen disponible';

    final zonesMap = _map(zonesObj);
    final zonesList = _list(zonesMap['zones']);

    final patrolMap = _map(patrolObj);
    final patrolAssignments = _list(patrolMap['assignments']);
    final tacticalRecs = _list(patrolMap['tacticalRecommendations']);

    final anomaliesMap = _map(anomaliesObj);
    final anomaliesList = _list(anomaliesMap['anomalies']);
    final anomalyScore = (anomaliesMap['anomalyScore'] as num?)?.toInt() ?? 18;
    final threatStatus =
        anomaliesMap['threatStatus']?.toString() ?? 'NORMAL ESTABLE';

    return Padding(
      padding: EdgeInsets.all(isMobile ? 12 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Banner de Estado del Motor de IA
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                    : [const Color(0xFFEFF6FF), const Color(0xFFDBEAFE)],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? AppColors.darkBorder
                    : AppColors.blue.withValues(alpha: 0.25),
              ),
            ),
            child: Wrap(
              spacing: 12,
              runSpacing: 8,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: AppColors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Cartagena Segura AI Core v2.2',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: isDark ? Colors.white : AppColors.navy,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.brightBlue.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'Llama-3.1 + RAG Distrital',
                        style: TextStyle(
                          color: AppColors.brightBlue,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                FilledButton.tonalIcon(
                  onPressed: widget.onRefresh,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Re-analizar Sistema'),
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    textStyle: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Navegador de pestañas de Inteligencia Artificial
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.border,
              ),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _tabButton(0, Icons.analytics_outlined,
                      'Resumen y Diagnóstico', isDark),
                  const SizedBox(width: 6),
                  _tabButton(1, Icons.local_police_outlined,
                      'Plan Táctico de Patrullaje', isDark),
                  const SizedBox(width: 6),
                  _tabButton(2, Icons.warning_amber_rounded,
                      'Detección de Anomalías ($anomalyScore/100)', isDark),
                  const SizedBox(width: 6),
                  _tabButton(3, Icons.auto_awesome_rounded,
                      'Copiloto y Clasificador', isDark),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Contenido de la pestaña activa
          _buildActiveAiTab(
            isDark: isDark,
            isMobile: isMobile,
            summaryText: summaryText,
            zonesList: zonesList,
            patrolMap: patrolMap,
            patrolAssignments: patrolAssignments,
            tacticalRecs: tacticalRecs,
            anomaliesMap: anomaliesMap,
            anomaliesList: anomaliesList,
            anomalyScore: anomalyScore,
            threatStatus: threatStatus,
          ),
        ],
      ),
    );
  }

  Widget _tabButton(int index, IconData icon, String label, bool isDark) {
    final active = _activeTab == index;
    return InkWell(
      onTap: () => setState(() => _activeTab = index),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active
              ? (isDark
                  ? AppColors.blue.withValues(alpha: 0.35)
                  : AppColors.blue)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active ? AppColors.brightBlue : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: active
                  ? Colors.white
                  : (isDark ? AppColors.darkTextMuted : AppColors.navy),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: active
                    ? Colors.white
                    : (isDark ? AppColors.darkText : AppColors.navy),
                fontSize: 12,
                fontWeight: active ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveAiTab({
    required bool isDark,
    required bool isMobile,
    required String summaryText,
    required List<dynamic> zonesList,
    required Map<String, dynamic> patrolMap,
    required List<dynamic> patrolAssignments,
    required List<dynamic> tacticalRecs,
    required Map<String, dynamic> anomaliesMap,
    required List<dynamic> anomaliesList,
    required int anomalyScore,
    required String threatStatus,
  }) {
    switch (_activeTab) {
      case 0:
        return _buildSummaryTab(isDark, isMobile, summaryText, zonesList);
      case 1:
        return _buildPatrolTab(
            isDark, isMobile, patrolMap, patrolAssignments, tacticalRecs);
      case 2:
        return _buildAnomaliesTab(isDark, isMobile, anomaliesMap, anomaliesList,
            anomalyScore, threatStatus);
      case 3:
        return _buildCopilotTab(isDark, isMobile);
      default:
        return const SizedBox.shrink();
    }
  }

  // ===========================================================================
  // TAB 0: RESUMEN EJECUTIVO Y DIAGNÓSTICO
  // ===========================================================================
  Widget _buildSummaryTab(
      bool isDark, bool isMobile, String summaryText, List<dynamic> zonesList) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.description_outlined,
                        color: AppColors.brightBlue, size: 22),
                    const SizedBox(width: 10),
                    Text(
                      'Informe Ejecutivo Distrital Generado por IA',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkSurface
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark
                          ? AppColors.darkBorder
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: SelectableText(
                    summaryText,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.6,
                      color: isDark ? AppColors.darkText : AppColors.navy,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.map_rounded,
                        color: AppColors.amber, size: 22),
                    const SizedBox(width: 10),
                    Text(
                      'Directivas Estratégicas por Cuadrante',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                for (final item in zonesList) ...[
                  if (item is Map) ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurface : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color:
                              isDark ? AppColors.darkBorder : AppColors.border,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _riskColor(
                                      item['riskLevel']?.toString() ?? '')
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              item['riskLevel']?.toString().toUpperCase() ??
                                  'MODERATE',
                              style: TextStyle(
                                color: _riskColor(
                                    item['riskLevel']?.toString() ?? ''),
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['name']?.toString() ?? 'Sector',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item['recommendation']?.toString() ??
                                      'Sin recomendación',
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
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // TAB 1: PLAN TÁCTICO DE PATRULLAJE
  // ===========================================================================
  Widget _buildPatrolTab(
    bool isDark,
    bool isMobile,
    Map<String, dynamic> patrolMap,
    List<dynamic> assignments,
    List<dynamic> tacticalRecs,
  ) {
    final threat = patrolMap['districtThreatLevel']?.toString() ?? 'ESTABLE';
    final generatedAt = patrolMap['generatedAt']?.toString() ?? 'Reciente';
    final notes = patrolMap['executiveNotes']?.toString() ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Resumen del Plan Táctico
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.local_police,
                        color: AppColors.brightBlue, size: 24),
                    const SizedBox(width: 10),
                    Text(
                      'Plan Táctico de Patrullaje Distrital',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: threat.contains('ELEVADO')
                            ? AppColors.red.withValues(alpha: 0.15)
                            : AppColors.green.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        threat,
                        style: TextStyle(
                          color: threat.contains('ELEVADO')
                              ? AppColors.red
                              : AppColors.green,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Generado el $generatedAt mediante modelado predictivo de incidentes y cuadrantes.',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.darkTextMuted : AppColors.muted,
                  ),
                ),
                if (notes.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    notes,
                    style: const TextStyle(fontSize: 13, height: 1.5),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Asignaciones por Cuadrante
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Despliegue Operativo Sugerido por Sectores',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 16),
                for (final item in assignments) ...[
                  if (item is Map) ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurface : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color:
                              isDark ? AppColors.darkBorder : AppColors.border,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                item['zoneName']?.toString() ?? 'Sector',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800, fontSize: 15),
                              ),
                              const SizedBox(width: 8),
                              _riskBadge(
                                  item['riskLevel']?.toString() ?? 'LOW'),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.brightBlue
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${item['suggestedUnits'] ?? 2} Patrullas',
                                  style: const TextStyle(
                                    color: AppColors.brightBlue,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Icon(Icons.schedule,
                                  size: 14, color: AppColors.amber),
                              const SizedBox(width: 6),
                              Text(
                                'Horario Crítico: ${item['priorityTimeWindow'] ?? '18:00 - 02:00'}',
                                style: const TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.shield,
                                  size: 14, color: AppColors.green),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Unidad: ${item['unitType'] ?? 'Patrulla de Cuadrante'}',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Foco Operacional: ${item['focusArea'] ?? 'Vigilancia preventiva'}',
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
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Directivas Tácticas
        if (tacticalRecs.isNotEmpty) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.check_circle_outline,
                          color: AppColors.green, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Directivas Tácticas Oficiales para Oficiales de Cuadrante',
                        style: TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  for (final rec in tacticalRecs) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.arrow_right,
                              size: 20, color: AppColors.brightBlue),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              rec.toString(),
                              style: const TextStyle(fontSize: 13, height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ===========================================================================
  // TAB 2: DETECCIÓN DE ANOMALÍAS
  // ===========================================================================
  Widget _buildAnomaliesTab(
    bool isDark,
    bool isMobile,
    Map<String, dynamic> anomaliesMap,
    List<dynamic> anomaliesList,
    int anomalyScore,
    String threatStatus,
  ) {
    final diagnosis =
        anomaliesMap['systemDiagnosis']?.toString() ?? 'Monitoreo activo.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Medidor de Puntuación de Riesgo / Anomalía
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.radar, color: AppColors.amber, size: 24),
                    const SizedBox(width: 10),
                    Text(
                      'Puntuación de Anomalía Distrital: $anomalyScore / 100',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color:
                            _scoreColor(anomalyScore).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        threatStatus,
                        style: TextStyle(
                          color: _scoreColor(anomalyScore),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: anomalyScore / 100.0,
                    minHeight: 8,
                    backgroundColor: isDark ? Colors.white10 : Colors.black12,
                    valueColor: AlwaysStoppedAnimation<Color>(
                        _scoreColor(anomalyScore)),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  diagnosis,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.darkTextMuted : AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Lista de Anomalías Detectadas
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Eventos Anómalos y Alertas Tempranas (${anomaliesList.length})',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 16),
                if (anomaliesList.isEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.green.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.check_circle,
                            color: AppColors.green, size: 28),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'No se detectan desviaciones anómalas en este momento. Todos los cuadrantes operan dentro de los parámetros estándar de seguridad.',
                            style: TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  for (final item in anomaliesList) ...[
                    if (item is Map) ...[
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurface : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isDark
                                ? AppColors.darkBorder
                                : AppColors.border,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                _severityBadge(
                                    item['severity']?.toString() ?? 'MEDIUM'),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    item['anomalyType']?.toString() ??
                                        'Anomalía',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 14),
                                  ),
                                ),
                                Text(
                                  item['quadrantOrCategory']?.toString() ?? '',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? AppColors.darkTextMuted
                                        : AppColors.muted,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              item['description']?.toString() ?? '',
                              style: const TextStyle(fontSize: 13, height: 1.4),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.blue
                                    .withValues(alpha: isDark ? 0.2 : 0.08),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.bolt,
                                      size: 16, color: AppColors.brightBlue),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'Acción recomendada: ${item['immediateAction'] ?? 'Verificar cuadrante.'}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: isDark
                                            ? AppColors.brightBlue
                                            : AppColors.navy,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // TAB 3: COPILOTO Y CLASIFICADOR IA
  // ===========================================================================
  Widget _buildCopilotTab(bool isDark, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _AdminClassifier(api: widget.api),
        const SizedBox(height: 16),
        _AdminChat(api: widget.api),
      ],
    );
  }

  Color _scoreColor(int score) {
    if (score >= 60) return AppColors.red;
    if (score >= 35) return AppColors.amber;
    return AppColors.green;
  }

  Widget _severityBadge(String severity) {
    final s = severity.toUpperCase();
    final color = switch (s) {
      'CRITICAL' => AppColors.red,
      'HIGH' => Colors.deepOrange,
      _ => AppColors.amber,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        s,
        style:
            TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w800),
      ),
    );
  }

  Widget _riskBadge(String riskLevel) {
    final color = _riskColor(riskLevel);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        riskLevel.toUpperCase(),
        style:
            TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w800),
      ),
    );
  }

  Color _riskColor(String riskLevel) {
    return switch (riskLevel.toUpperCase()) {
      'CRITICAL' => AppColors.red,
      'HIGH' => Colors.deepOrange,
      'MODERATE' => AppColors.amber,
      _ => AppColors.green,
    };
  }
}

class _AdminChat extends StatefulWidget {
  const _AdminChat({required this.api});

  final ApiClient api;

  @override
  State<_AdminChat> createState() => _AdminChatState();
}

class _AdminChatState extends State<_AdminChat> {
  final _controller = TextEditingController();
  final _messages = <(bool, String)>[
    (
      false,
      '¡Hola Oficial! Soy el asistente táctico de Cartagena Segura. Puedo responder consultas de cuadrantes, generar planes de patrullaje y auditar incidentes en tiempo real.'
    ),
  ];
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send([String? customPrompt]) async {
    final text = customPrompt ?? _controller.text.trim();
    if (text.isEmpty || _sending) return;
    if (customPrompt == null) _controller.clear();
    setState(() {
      _sending = true;
      _messages.add((true, text));
    });
    try {
      final response = await widget.api.post('Ai/Chat', {'message': text});
      if (!mounted) return;
      setState(() => _messages.add((false, _responseText(response))));
    } on Exception catch (error) {
      if (!mounted) return;
      setState(
        () =>
            _messages.add((false, 'No se pudo completar la consulta: $error')),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  String _responseText(dynamic response) {
    if (response is String) return response;
    if (response is Map<String, dynamic>) {
      return (response['response'] ?? response['message'] ?? response['reply'])
              ?.toString() ??
          response.toString();
    }
    return response?.toString() ?? 'La API no devolvió una respuesta.';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.smart_toy_outlined,
                    color: AppColors.brightBlue, size: 22),
                const SizedBox(width: 10),
                Text(
                  'Copiloto Táctico y Asistente Administrativo IA',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Limpiar conversación',
                  icon: const Icon(Icons.cleaning_services_outlined, size: 18),
                  onPressed: () {
                    setState(() {
                      _messages.clear();
                      _messages.add((
                        false,
                        'Conversación reiniciada. ¿Qué información operativa requieres?'
                      ));
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Chips de consulta rápida
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _promptChip('🚓 ¿Cuáles cuadrantes requieren refuerzo hoy?'),
                _promptChip('📊 Resumen de incidentes activos'),
                _promptChip('🚨 Evaluar riesgo en Getsemaní'),
                _promptChip('⏱️ ¿Cuál es el tiempo de respuesta promedio?'),
              ],
            ),
            const SizedBox(height: 14),

            // Historial de mensajes
            for (final message in _messages)
              Align(
                alignment:
                    message.$1 ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 680),
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: message.$1
                        ? (isDark
                            ? AppColors.blue.withValues(alpha: 0.3)
                            : AppColors.blue.withValues(alpha: 0.12))
                        : (isDark
                            ? AppColors.darkSurface
                            : const Color(0xFFF1F5F9)),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: message.$1
                          ? AppColors.brightBlue.withValues(alpha: 0.3)
                          : (isDark
                              ? AppColors.darkBorder
                              : const Color(0xFFE2E8F0)),
                    ),
                  ),
                  child: SelectableText(
                    message.$2,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.45,
                      color: isDark ? AppColors.darkText : AppColors.navy,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    enabled: !_sending,
                    onSubmitted: (_) => _send(),
                    decoration: const InputDecoration(
                      labelText:
                          'Pregunta táctica sobre el sistema o cuadrantes',
                      hintText:
                          'Ej: Recomendar patrullas para Centro Histórico...',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  tooltip: 'Enviar consulta',
                  onPressed: _sending ? null : () => _send(),
                  icon: _sending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _promptChip(String text) {
    return ActionChip(
      label: Text(text),
      labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      onPressed: _sending ? null : () => _send(text),
    );
  }
}

class _AdminClassifier extends StatefulWidget {
  const _AdminClassifier({required this.api});

  final ApiClient api;

  @override
  State<_AdminClassifier> createState() => _AdminClassifierState();
}

class _AdminClassifierState extends State<_AdminClassifier> {
  final _description = TextEditingController();
  bool _loading = false;
  Map<String, dynamic>? _resultMap;
  String? _rawResult;

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  Future<void> _classify([String? sampleText]) async {
    if (sampleText != null) {
      _description.text = sampleText;
    }
    final description = _description.text.trim();
    if (description.isEmpty || _loading) return;
    setState(() {
      _loading = true;
      _resultMap = null;
      _rawResult = null;
    });
    try {
      final response = await widget.api.post('Ai/Classify', {
        'description': description,
      });
      if (!mounted) return;
      if (response is Map<String, dynamic>) {
        setState(() => _resultMap = response);
      } else if (response is Map) {
        setState(() => _resultMap = Map<String, dynamic>.from(response));
      } else {
        setState(() => _rawResult = response.toString());
      }
    } on Exception catch (error) {
      if (!mounted) return;
      setState(() => _rawResult = 'No se pudo clasificar: $error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_fix_high,
                    color: AppColors.brightBlue, size: 22),
                const SizedBox(width: 10),
                Text(
                  'Auto-Clasificador Neuronal de Incidentes',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Ingresa una descripción libre o selecciona un caso de prueba para clasificar tipología, prioridad y confianza con el modelo LLM.',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.darkTextMuted : AppColors.muted,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _sampleChip('🚨 Hurto con arma en moto en Bocagrande'),
                _sampleChip('💡 Luminaria fundida en callejón Getsemaní'),
                _sampleChip('🚗 Colisión múltiple con herido en Olaya'),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _description,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Descripción del incidente o reporte de campo',
              ),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: _loading ? null : () => _classify(),
                icon: const Icon(Icons.bolt, size: 16),
                label: Text(
                    _loading ? 'Clasificando con IA…' : 'Clasificar con IA'),
              ),
            ),
            if (_resultMap != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color:
                      isDark ? AppColors.darkSurface : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color:
                        isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Tipo detectado: ${_resultMap!['type'] ?? 'OTRO'}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 14),
                        ),
                        const Spacer(),
                        _priorityPill(
                            _resultMap!['priority']?.toString() ?? 'MEDIUM'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text('Confianza del modelo: ',
                            style: TextStyle(fontSize: 12)),
                        Text(
                          '${((_resultMap!['confidence'] as num?)?.toDouble() ?? 0.92) * 100}%',
                          style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                              color: AppColors.brightBlue),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ] else if (_rawResult != null) ...[
              const SizedBox(height: 10),
              SelectableText(_rawResult!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _sampleChip(String text) {
    return ActionChip(
      label: Text(text),
      labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
      onPressed: _loading ? null : () => _classify(text),
    );
  }

  Widget _priorityPill(String priority) {
    final p = priority.toUpperCase();
    final color = switch (p) {
      'CRITICAL' => AppColors.red,
      'HIGH' => Colors.deepOrange,
      'MEDIUM' => AppColors.amber,
      _ => AppColors.green,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        p,
        style:
            TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w800),
      ),
    );
  }
}
