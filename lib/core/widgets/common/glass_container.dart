import 'dart:ui';
import 'package:flutter/material.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final BoxBorder? border;
  final Color? color;

  final double? width;
  final double? height;

  const GlassContainer({
    super.key,
    required this.child,
    this.blur = 15.0,
    this.opacity = 0.5,
    this.padding,
    this.margin,
    this.borderRadius,
    this.border,
    this.color,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultBorderRadius = borderRadius ?? BorderRadius.circular(24.0);

    return Container(
      margin: margin,
      padding: padding,
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color ?? (isDark ? const Color(0xCC1E2538) : Colors.white.withValues(alpha: 0.75)),
        borderRadius: defaultBorderRadius,
        border: border ?? Border.all(
          color: Colors.white.withValues(alpha: isDark ? 0.08 : 0.6), 
          width: 1.5
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(4, 4),
          )
        ],
      ),
      child: child,
    );
  }
}
