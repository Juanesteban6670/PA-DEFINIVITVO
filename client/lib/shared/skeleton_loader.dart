import 'package:flutter/material.dart';

import 'theme.dart';

/// Efecto Shimmer / Skeleton Loader para estados de carga elegantes.
class SkeletonLoader extends StatefulWidget {
  const SkeletonLoader({
    this.width,
    this.height = 16,
    this.borderRadius = 8,
    super.key,
  });

  final double? width;
  final double height;
  final double borderRadius;

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark
        ? AppColors.darkCardHover
        : const Color(0xFFE2E8F0);
    final highlightColor = isDark
        ? AppColors.darkBorderSubtle
        : const Color(0xFFF1F5F9);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(-2.0 + (_controller.value * 4), 0),
              end: Alignment(-1.0 + (_controller.value * 4), 0),
              colors: [baseColor, highlightColor, baseColor],
            ),
          ),
        );
      },
    );
  }
}

/// Tarjeta pre-ensamblada tipo esqueleto para listas de incidentes.
class SkeletonIncidentCard extends StatelessWidget {
  const SkeletonIncidentCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            const SkeletonLoader(width: 40, height: 40, borderRadius: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  SkeletonLoader(width: 140, height: 14),
                  SizedBox(height: 6),
                  SkeletonLoader(width: 220, height: 12),
                  SizedBox(height: 6),
                  SkeletonLoader(width: 80, height: 10),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const SkeletonLoader(width: 60, height: 22, borderRadius: 12),
          ],
        ),
      ),
    );
  }
}
