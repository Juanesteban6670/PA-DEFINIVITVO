import 'package:flutter/material.dart';

enum TooltipPosition { auto, top, bottom }

class TourStep {
  const TourStep({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    this.targetKey,
    this.targetTabIndex,
    this.preferredPosition = TooltipPosition.auto,
    this.padding = 8.0,
    this.borderRadius = 16.0,
  });

  final String id;
  final String title;
  final String description;
  final IconData icon;
  final GlobalKey? targetKey;
  final int? targetTabIndex;
  final TooltipPosition preferredPosition;
  final double padding;
  final double borderRadius;
}
