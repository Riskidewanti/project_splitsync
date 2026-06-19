import 'dart:math' as math;

import 'package:flutter/material.dart';

class Responsive {
  const Responsive._(this.size);

  final Size size;

  factory Responsive.of(BuildContext context) {
    return Responsive._(MediaQuery.sizeOf(context));
  }

  bool get isCompactHeight => size.height < 740;
  bool get isVeryCompactHeight => size.height < 640;
  bool get isNarrow => size.width < 380;
  bool get isWide => size.width >= 700;

  double get scale {
    final widthScale = size.width / 393;
    final heightScale = size.height / 852;
    return math.min(widthScale, heightScale).clamp(0.82, 1.08);
  }

  double space(double value) => value * scale;

  double font(double value) {
    final factor = isNarrow ? 0.9 : scale;
    return (value * factor).clamp(value * 0.82, value * 1.08);
  }

  EdgeInsets horizontal(double value) {
    return EdgeInsets.symmetric(horizontal: value * (isNarrow ? 0.72 : scale));
  }

  double clamp(double value, double min, double max) {
    return space(value).clamp(min, max);
  }
}

class ResponsivePage extends StatelessWidget {
  const ResponsivePage({
    super.key,
    required this.child,
    this.maxWidth = 430,
    this.padding = EdgeInsets.zero,
    this.scrollable = false,
    this.alignment = Alignment.topCenter,
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsets padding;
  final bool scrollable;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    final content = Center(
      child: Align(
        alignment: alignment,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );

    if (!scrollable) return content;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: content,
          ),
        );
      },
    );
  }
}
