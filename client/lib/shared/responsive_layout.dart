import 'package:flutter/material.dart';

/// Puntos de quiebre (Breakpoints) canónicos para Cartagena Segura
enum ScreenBreakpoint {
  mobile,
  tablet,
  desktop,
}

class Breakpoints {
  static const double mobileMax = 767.99;
  static const double tabletMin = 768.0;
  static const double tabletMax = 1023.99;
  static const double desktopMin = 1024.0;
  static const double maxContentWidth = 1440.0;
}

extension ResponsiveContext on BuildContext {
  double get screenWidth => MediaQuery.sizeOf(this).width;
  double get screenHeight => MediaQuery.sizeOf(this).height;

  bool get isMobile => screenWidth < Breakpoints.tabletMin;
  bool get isTablet =>
      screenWidth >= Breakpoints.tabletMin && screenWidth <= Breakpoints.tabletMax;
  bool get isDesktop => screenWidth >= Breakpoints.desktopMin;
  bool get isWide => screenWidth >= Breakpoints.tabletMin;

  ScreenBreakpoint get breakpoint {
    if (isDesktop) return ScreenBreakpoint.desktop;
    if (isTablet) return ScreenBreakpoint.tablet;
    return ScreenBreakpoint.mobile;
  }

  T responsiveValue<T>({
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    if (isDesktop && desktop != null) return desktop;
    if (isTablet && tablet != null) return tablet;
    return mobile;
  }
}

/// Contenedor centrado que expande el contenido fluidamente en Desktop y Tablet
/// sin restringirlo a columnas estrechas tipo teléfono móvil.
class ResponsiveContent extends StatelessWidget {
  const ResponsiveContent({
    super.key,
    required this.child,
    this.maxWidth = Breakpoints.maxContentWidth,
    this.padding,
    this.horizontalPadding,
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;
  final double? horizontalPadding;

  @override
  Widget build(BuildContext context) {
    final defaultHPad = context.responsiveValue<double>(
      mobile: 16.0,
      tablet: 24.0,
      desktop: 32.0,
    );

    final resolvedPadding = padding ??
        EdgeInsets.symmetric(
          horizontal: horizontalPadding ?? defaultHPad,
          vertical: context.responsiveValue<double>(
            mobile: 16.0,
            tablet: 20.0,
            desktop: 24.0,
          ),
        );

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: resolvedPadding,
          child: child,
        ),
      ),
    );
  }
}
