import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:cartagena_segura/shared/theme.dart';

class NeuralNodeInfo {
  const NeuralNodeInfo({
    required this.id,
    required this.layerName,
    required this.nodeName,
    required this.activationFunction,
    required this.bias,
    required this.activationValue,
    required this.description,
  });

  final String id;
  final String layerName;
  final String nodeName;
  final String activationFunction;
  final double bias;
  final double activationValue;
  final String description;
}

class NeuralNetworkVisualizer extends StatefulWidget {
  const NeuralNetworkVisualizer({
    required this.riskScore,
    required this.riskLevel,
    required this.primaryThreat,
    this.activations = const {},
    this.sector = 'Centro Histórico',
    this.hourOfDay = 20,
    this.crowdLevel = 'ALTO',
    this.weather = 'DESPEJADO',
    this.isWeekend = true,
    super.key,
  });

  final double riskScore;
  final String riskLevel;
  final String primaryThreat;
  final Map<String, double> activations;
  final String sector;
  final int hourOfDay;
  final String crowdLevel;
  final String weather;
  final bool isWeekend;

  @override
  State<NeuralNetworkVisualizer> createState() => _NeuralNetworkVisualizerState();
}

class _NeuralNetworkVisualizerState extends State<NeuralNetworkVisualizer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  NeuralNodeInfo? _selectedNode;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  // Pesos representativos de la red
  static const List<List<double>> _weights01 = [
    [0.38, 0.42, 0.28, 0.44, 0.26, 0.35, -0.12, 0.18],
    [0.32, 0.38, 0.32, 0.36, 0.22, 0.38, 0.10, -0.06],
    [0.18, 0.07, 0.11, 0.16, -0.07, 0.09, -0.12, 0.15],
    [-0.09, 0.11, -0.04, -0.07, 0.18, -0.05, 0.15, 0.16],
    [0.17, 0.13, 0.22, 0.11, 0.10, 0.20, 0.19, 0.08],
    [0.34, 0.24, 0.20, 0.16, 0.22, 0.27, 0.18, -0.04],
  ];

  static const List<List<double>> _weights12 = [
    [0.28, -0.10, 0.22, 0.18, 0.31, 0.15],
    [0.24, 0.19, 0.14, -0.08, 0.26, 0.21],
    [0.12, 0.25, 0.30, 0.16, 0.11, 0.09],
    [0.35, -0.05, 0.27, 0.22, 0.19, 0.33],
    [0.18, 0.16, 0.09, 0.24, 0.14, 0.08],
    [0.21, 0.11, 0.18, 0.15, 0.29, 0.17],
    [-0.14, 0.22, 0.08, -0.12, 0.16, 0.05],
    [0.19, -0.08, 0.15, 0.20, 0.12, 0.24],
  ];

  static const List<List<double>> _weights23 = [
    [-0.35, 0.15, 0.42, 0.65, 0.38],
    [-0.22, 0.28, 0.36, 0.48, 0.25],
    [0.45, 0.20, -0.18, -0.32, -0.15],
    [-0.40, 0.10, 0.48, 0.72, 0.42],
    [-0.18, 0.32, 0.29, 0.41, 0.21],
    [-0.25, 0.18, 0.38, 0.58, 0.33],
  ];

  double _getCrowdNorm() {
    return switch (widget.crowdLevel.toUpperCase()) {
      'MASIVO' => 1.0,
      'ALTO' => 0.75,
      'BAJO' => 0.25,
      _ => 0.5,
    };
  }

  double _getWeatherNorm() {
    return switch (widget.weather.toUpperCase()) {
      'TORMENTA' => 0.85,
      'LLUVIA' => 0.65,
      _ => 0.35,
    };
  }

  List<double> _getInputValues() {
    final crowd = _getCrowdNorm();
    final weather = _getWeatherNorm();
    final hourSin = (math.sin(2 * math.pi * widget.hourOfDay / 24.0) + 1.0) / 2.0;
    final hourCos = (math.cos(2 * math.pi * widget.hourOfDay / 24.0) + 1.0) / 2.0;
    final weekend = widget.isWeekend ? 1.0 : 0.0;
    final interaction = (crowd + weather) / 2.0;
    return [crowd, weather, hourSin, hourCos, weekend, interaction];
  }

  List<double> _getHidden1Values() {
    final inputs = _getInputValues();
    final values = <double>[];
    for (int j = 0; j < 8; j++) {
      final key = 'capa_oculta_1_n${j + 1}';
      if (widget.activations.containsKey(key)) {
        values.add(widget.activations[key]!.clamp(0.0, 1.0));
      } else {
        // Cálculo feedforward local reactivo
        double sum = 0.02;
        for (int i = 0; i < inputs.length; i++) {
          sum += inputs[i] * _weights01[i][j];
        }
        values.add((sum > 0 ? sum : 0.01 * sum).clamp(0.0, 1.0));
      }
    }
    return values;
  }

  List<double> _getHidden2Values() {
    final h1 = _getHidden1Values();
    final values = <double>[];
    for (int k = 0; k < 6; k++) {
      final key = 'capa_oculta_2_n${k + 1}';
      if (widget.activations.containsKey(key)) {
        values.add(widget.activations[key]!.clamp(0.0, 1.0));
      } else {
        double sum = 0.01;
        for (int j = 0; j < h1.length; j++) {
          sum += h1[j] * _weights12[j][k];
        }
        values.add(math.max(0.0, sum).clamp(0.0, 1.0));
      }
    }
    return values;
  }

  List<double> _getOutputValues() {
    final scoreNorm = (widget.riskScore / 100.0).clamp(0.0, 1.0);
    // Probabilidades relativas para Bajo, Moderado, Alto, Crítico
    double pBajo = (1.0 - scoreNorm * 1.6).clamp(0.05, 0.95);
    double pMod = (1.0 - (scoreNorm - 0.45).abs() * 2.2).clamp(0.05, 0.95);
    double pAlto = (1.0 - (scoreNorm - 0.72).abs() * 2.2).clamp(0.05, 0.95);
    double pCrit = (scoreNorm * 1.5 - 0.5).clamp(0.05, 0.98);

    final sum = pBajo + pMod + pAlto + pCrit;
    return [
      pBajo / sum,
      pMod / sum,
      pAlto / sum,
      pCrit / sum,
      scoreNorm, // Amenaza principal / severidad
    ];
  }

  void _onNodeSelected(NeuralNodeInfo info) {
    setState(() {
      _selectedNode = info;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inputs = _getInputValues();
    final h1 = _getHidden1Values();
    final h2 = _getHidden2Values();
    final outputs = _getOutputValues();

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
          // Encabezado del Visualizador Sináptico
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0072FF), Color(0xFF00C6FF)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.hub_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Grafo Sináptico y Red Neuronal',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: isDark ? AppColors.darkText : AppColors.navy,
                        ),
                      ),
                      Text(
                        'Feedforward 60 FPS • Topología 6 -> 8 -> 6 -> 5',
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF064E3B).withValues(alpha: 0.4)
                      : const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF059669)
                        : const Color(0xFF86EFAC),
                  ),
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
                      'Live Tensor Flow',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: isDark
                            ? const Color(0xFF6EE7B7)
                            : const Color(0xFF065F46),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Leyenda interactiva de la red
          Wrap(
            spacing: 16,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _legendItem(
                iconColor: const Color(0xFF00C6FF),
                label: 'Sinapsis Excitatoria (+w)',
                isDark: isDark,
              ),
              _legendItem(
                iconColor: const Color(0xFFEC4899),
                label: 'Sinapsis Inhibitoria (-w)',
                isDark: isDark,
              ),
              _legendItem(
                iconColor: const Color(0xFF10B981),
                label: 'Fotones de Inferencia Feedforward',
                isDark: isDark,
              ),
              Text(
                '• Toca cualquier neurona para inspeccionar tensores',
                style: TextStyle(
                  fontSize: 10,
                  fontStyle: FontStyle.italic,
                  color: isDark ? AppColors.darkTextMuted : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Canvas Interactivo del Grafo de la Red Neuronal
          SizedBox(
            height: 380,
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return LayoutBuilder(
                  builder: (context, constraints) {
                    final canvasWidth = math.max(constraints.maxWidth, 360.0);
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: canvasWidth,
                        height: 380,
                        child: GestureDetector(
                          onTapUp: (details) {
                            _handleTap(details.localPosition, Size(canvasWidth, 380), inputs, h1, h2, outputs);
                          },
                          child: CustomPaint(
                            size: Size(canvasWidth, 380),
                            painter: _NeuralNetworkPainter(
                              pulseProgress: _pulseController.value,
                              inputs: inputs,
                              h1: h1,
                              h2: h2,
                              outputs: outputs,
                              weights01: _weights01,
                              weights12: _weights12,
                              weights23: _weights23,
                              isDark: isDark,
                              selectedNodeId: _selectedNode?.id,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Panel Inspector de Neurona Seleccionada (Liquid Glass)
          if (_selectedNode != null) ...[
            const SizedBox(height: 16),
            _buildNodeInspector(_selectedNode!, isDark),
          ],
        ],
      ),
    );
  }

  Widget _legendItem({
    required Color iconColor,
    required String label,
    required bool isDark,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: iconColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: iconColor.withValues(alpha: 0.6),
                blurRadius: 4,
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isDark ? AppColors.darkText : const Color(0xFF334155),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildNodeInspector(NeuralNodeInfo node, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkCard.withValues(alpha: 0.95)
            : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? AppColors.brightBlue.withValues(alpha: 0.5)
              : AppColors.blue.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.brightBlue.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.memory, color: AppColors.brightBlue, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${node.layerName} • ${node.nodeName}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppColors.darkText : AppColors.navy,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 16),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => setState(() => _selectedNode = null),
                    ),
                  ],
                ),
                Text(
                  node.description,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.darkTextMuted : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 6,
                  children: [
                    _inspectorMetric('Activación (f)', node.activationFunction, isDark),
                    _inspectorMetric('Bias (b)', '${node.bias > 0 ? "+" : ""}${node.bias.toStringAsFixed(3)}', isDark),
                    _inspectorMetric('Valor Tensor (a)', node.activationValue.toStringAsFixed(3), isDark),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: node.activationValue.clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor: isDark
                        ? const Color(0xFF1E293B)
                        : const Color(0xFFCBD5E1),
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.brightBlue),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _inspectorMetric(String label, String value, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: RichText(
        text: TextSpan(
          text: '$label: ',
          style: TextStyle(
            fontSize: 10,
            color: isDark ? AppColors.darkTextMuted : const Color(0xFF64748B),
          ),
          children: [
            TextSpan(
              text: value,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : AppColors.navy,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleTap(
    Offset tapPos,
    Size size,
    List<double> inputs,
    List<double> h1,
    List<double> h2,
    List<double> outputs,
  ) {
    final layerX = [
      size.width * 0.10,
      size.width * 0.38,
      size.width * 0.64,
      size.width * 0.90,
    ];

    const inputNames = [
      'Afluencia Peatonal',
      'Factor Climático',
      'Ciclo Horario (Seno)',
      'Ciclo Horario (Coseno)',
      'Fin de Semana',
      'Entorno Socioambiental',
    ];

    const outputNames = [
      'Riesgo Bajo (0-37%)',
      'Riesgo Moderado (38-59%)',
      'Riesgo Alto (60-79%)',
      'Riesgo Crítico (80-100%)',
      'Amenaza Predominante',
    ];

    // Check layer 0
    final l0Y = _getLayerY(inputs.length, size.height);
    for (int i = 0; i < inputs.length; i++) {
      if ((tapPos - Offset(layerX[0], l0Y[i])).distance <= 18) {
        _onNodeSelected(
          NeuralNodeInfo(
            id: 'in_$i',
            layerName: 'Capa de Entrada (Input Layer)',
            nodeName: inputNames[i],
            activationFunction: 'Linear Normalizada [0, 1]',
            bias: 0.0,
            activationValue: inputs[i],
            description: 'Variable predictiva calibrada para ${widget.sector}.',
          ),
        );
        return;
      }
    }

    // Check layer 1
    final l1Y = _getLayerY(h1.length, size.height);
    for (int j = 0; j < h1.length; j++) {
      if ((tapPos - Offset(layerX[1], l1Y[j])).distance <= 18) {
        _onNodeSelected(
          NeuralNodeInfo(
            id: 'h1_$j',
            layerName: 'Capa Oculta 1 (Hidden 1)',
            nodeName: 'Neurona H1-$j',
            activationFunction: 'LeakyReLU (α = 0.01)',
            bias: 0.02,
            activationValue: h1[j],
            description: 'Detector de patrones espaciotemporales combinados.',
          ),
        );
        return;
      }
    }

    // Check layer 2
    final l2Y = _getLayerY(h2.length, size.height);
    for (int k = 0; k < h2.length; k++) {
      if ((tapPos - Offset(layerX[2], l2Y[k])).distance <= 18) {
        _onNodeSelected(
          NeuralNodeInfo(
            id: 'h2_$k',
            layerName: 'Capa Oculta 2 (Hidden 2)',
            nodeName: 'Neurona H2-$k',
            activationFunction: 'ReLU max(0, z)',
            bias: 0.01,
            activationValue: h2[k],
            description: 'Extractor de nivel de criticidad y probabilidad criminal.',
          ),
        );
        return;
      }
    }

    // Check layer 3
    final l3Y = _getLayerY(outputs.length, size.height);
    for (int m = 0; m < outputs.length; m++) {
      if ((tapPos - Offset(layerX[3], l3Y[m])).distance <= 18) {
        _onNodeSelected(
          NeuralNodeInfo(
            id: 'out_$m',
            layerName: 'Capa de Salida (Output Layer)',
            nodeName: outputNames[m],
            activationFunction: m == 4 ? 'Softmax Classifier' : 'Sigmoide Calibrada',
            bias: -2.10,
            activationValue: outputs[m],
            description: m == 4
                ? 'Tipo detectado: ${widget.primaryThreat}'
                : 'Scoring distrital: ${widget.riskScore}% (${widget.riskLevel})',
          ),
        );
        return;
      }
    }
  }

  static List<double> _getLayerY(int count, double totalHeight) {
    final step = totalHeight / (count + 1);
    return List.generate(count, (idx) => (idx + 1) * step);
  }
}

class _NeuralNetworkPainter extends CustomPainter {
  const _NeuralNetworkPainter({
    required this.pulseProgress,
    required this.inputs,
    required this.h1,
    required this.h2,
    required this.outputs,
    required this.weights01,
    required this.weights12,
    required this.weights23,
    required this.isDark,
    this.selectedNodeId,
  });

  final double pulseProgress;
  final List<double> inputs;
  final List<double> h1;
  final List<double> h2;
  final List<double> outputs;
  final List<List<double>> weights01;
  final List<List<double>> weights12;
  final List<List<double>> weights23;
  final bool isDark;
  final String? selectedNodeId;

  @override
  void paint(Canvas canvas, Size size) {
    final layerX = [
      size.width * 0.10,
      size.width * 0.38,
      size.width * 0.64,
      size.width * 0.90,
    ];

    final l0Y = _getLayerY(inputs.length, size.height);
    final l1Y = _getLayerY(h1.length, size.height);
    final l2Y = _getLayerY(h2.length, size.height);
    final l3Y = _getLayerY(outputs.length, size.height);

    // 1. DIBUJAR CONEXIONES SINÁPTICAS (Layer 0 -> 1)
    _drawConnections(
      canvas: canvas,
      x1: layerX[0],
      y1List: l0Y,
      x2: layerX[1],
      y2List: l1Y,
      weights: weights01,
      activations1: inputs,
      pulsePhase: pulseProgress,
    );

    // 2. DIBUJAR CONEXIONES SINÁPTICAS (Layer 1 -> 2)
    _drawConnections(
      canvas: canvas,
      x1: layerX[1],
      y1List: l1Y,
      x2: layerX[2],
      y2List: l2Y,
      weights: weights12,
      activations1: h1,
      pulsePhase: (pulseProgress + 0.33) % 1.0,
    );

    // 3. DIBUJAR CONEXIONES SINÁPTICAS (Layer 2 -> 3)
    _drawConnections(
      canvas: canvas,
      x1: layerX[2],
      y1List: l2Y,
      x2: layerX[3],
      y2List: l3Y,
      weights: weights23,
      activations1: h2,
      pulsePhase: (pulseProgress + 0.66) % 1.0,
    );

    // 4. DIBUJAR CABECERAS DE CAPA
    _drawLayerHeaders(canvas, layerX);

    // 5. DIBUJAR NODOS NEURONALES
    _drawNodes(canvas, layerX[0], l0Y, inputs, 'in', const Color(0xFF0072FF));
    _drawNodes(canvas, layerX[1], l1Y, h1, 'h1', const Color(0xFF00C6FF));
    _drawNodes(canvas, layerX[2], l2Y, h2, 'h2', const Color(0xFF8B5CF6));
    _drawOutputNodes(canvas, layerX[3], l3Y, outputs);
  }

  void _drawConnections({
    required Canvas canvas,
    required double x1,
    required List<double> y1List,
    required double x2,
    required List<double> y2List,
    required List<List<double>> weights,
    required List<double> activations1,
    required double pulsePhase,
  }) {
    for (int i = 0; i < y1List.length; i++) {
      final p1 = Offset(x1, y1List[i]);
      final act1 = activations1[i];
      for (int j = 0; j < y2List.length; j++) {
        final p2 = Offset(x2, y2List[j]);
        final w = (i < weights.length && j < weights[i].length)
            ? weights[i][j]
            : 0.2;
        final isExcitatory = w >= 0;
        final baseColor = isExcitatory
            ? const Color(0xFF00C6FF)
            : const Color(0xFFEC4899);

        final strokeWidth = (w.abs() * 3.5).clamp(0.6, 3.2);
        final alpha = (w.abs() * 0.7 + act1 * 0.3).clamp(0.12, 0.75);

        final linePaint = Paint()
          ..color = baseColor.withValues(alpha: alpha)
          ..strokeWidth = strokeWidth
          ..style = PaintingStyle.stroke;

        canvas.drawLine(p1, p2, linePaint);

        // Fotón de pulso feedforward activo
        if (act1 > 0.15) {
          final t = (pulsePhase + (i * 0.1 + j * 0.05)) % 1.0;
          final pulsePos = Offset.lerp(p1, p2, t)!;
          final particlePaint = Paint()
            ..color = const Color(0xFF10B981).withValues(alpha: 0.9)
            ..style = PaintingStyle.fill;
          canvas.drawCircle(pulsePos, 2.0 + strokeWidth * 0.5, particlePaint);
        }
      }
    }
  }

  void _drawLayerHeaders(Canvas canvas, List<double> layerX) {
    const titles = ['ENTRADA', 'OCULTA 1', 'OCULTA 2', 'SALIDA'];
    for (int i = 0; i < layerX.length; i++) {
      final textSpan = TextSpan(
        text: titles[i],
        style: TextStyle(
          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(
        canvas,
        Offset(layerX[i] - textPainter.width / 2, 8),
      );
    }
  }

  void _drawNodes(
    Canvas canvas,
    double x,
    List<double> yList,
    List<double> activations,
    String prefix,
    Color baseColor,
  ) {
    for (int i = 0; i < yList.length; i++) {
      final center = Offset(x, yList[i]);
      final act = activations[i].clamp(0.0, 1.0);
      final isSelected = selectedNodeId == '${prefix}_$i';

      // Halo exterior
      final haloPaint = Paint()
        ..color = baseColor.withValues(alpha: isSelected ? 0.6 : (0.2 + act * 0.3))
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, isSelected ? 8 : 4);
      canvas.drawCircle(center, isSelected ? 16 : (10 + act * 3), haloPaint);

      // Cuerpo de la neurona
      final nodePaint = Paint()
        ..color = isDark ? const Color(0xFF0F172A) : Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, isSelected ? 12 : 9, nodePaint);

      // Núcleo activo
      final corePaint = Paint()
        ..color = baseColor.withValues(alpha: 0.4 + act * 0.6)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, isSelected ? 8 : (4 + act * 3), corePaint);

      // Borde
      final borderPaint = Paint()
        ..color = isSelected ? Colors.white : baseColor
        ..strokeWidth = isSelected ? 2.5 : 1.5
        ..style = PaintingStyle.stroke;
      canvas.drawCircle(center, isSelected ? 12 : 9, borderPaint);
    }
  }

  void _drawOutputNodes(
    Canvas canvas,
    double x,
    List<double> yList,
    List<double> outputs,
  ) {
    const outputColors = [
      Color(0xFF10B981), // Bajo
      Color(0xFFF59E0B), // Moderado
      Color(0xFFF97316), // Alto
      Color(0xFFEF4444), // Crítico
      Color(0xFF8B5CF6), // Tipo de amenaza
    ];

    for (int i = 0; i < yList.length; i++) {
      final center = Offset(x, yList[i]);
      final val = outputs[i].clamp(0.0, 1.0);
      final isSelected = selectedNodeId == 'out_$i';
      final color = outputColors[i];

      // Halo
      final haloPaint = Paint()
        ..color = color.withValues(alpha: isSelected ? 0.7 : (0.25 + val * 0.45))
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, isSelected ? 10 : 5);
      canvas.drawCircle(center, isSelected ? 17 : (11 + val * 4), haloPaint);

      // Fondo
      final nodePaint = Paint()
        ..color = isDark ? const Color(0xFF0F172A) : Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, isSelected ? 13 : 10, nodePaint);

      // Núcleo
      final corePaint = Paint()
        ..color = color.withValues(alpha: 0.5 + val * 0.5)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, isSelected ? 9 : (5 + val * 4), corePaint);

      // Borde
      final borderPaint = Paint()
        ..color = isSelected ? Colors.white : color
        ..strokeWidth = isSelected ? 2.5 : 1.8
        ..style = PaintingStyle.stroke;
      canvas.drawCircle(center, isSelected ? 13 : 10, borderPaint);
    }
  }

  static List<double> _getLayerY(int count, double totalHeight) {
    final step = (totalHeight - 32) / (count + 1);
    return List.generate(count, (idx) => 24 + (idx + 1) * step);
  }

  @override
  bool shouldRepaint(covariant _NeuralNetworkPainter oldDelegate) {
    return oldDelegate.pulseProgress != pulseProgress ||
        oldDelegate.selectedNodeId != selectedNodeId ||
        oldDelegate.inputs != inputs ||
        oldDelegate.h1 != h1 ||
        oldDelegate.h2 != h2 ||
        oldDelegate.outputs != outputs;
  }
}
