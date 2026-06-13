import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class OffsetShadowCard extends StatelessWidget {
  final Widget child;
  final Color? backgroundColor;
  final Color? shadowColor;
  final Offset shadowOffset;
  final double borderWidth;
  final BorderRadius borderRadius;
  final EdgeInsets padding;
  final VoidCallback? onTap;

  const OffsetShadowCard({
    super.key,
    required this.child,
    this.backgroundColor,
    this.shadowColor,
    this.shadowOffset = const Offset(3, 3),
    this.borderWidth = 1.5,
    this.borderRadius = BorderRadius.zero,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final shadow = shadowColor ?? tokens.shadowColor;
    final bg = backgroundColor ?? tokens.surface;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: borderRadius,
          border: Border.all(color: tokens.border, width: borderWidth),
          boxShadow: [
            BoxShadow(
              color: shadow,
              offset: shadowOffset,
              blurRadius: 0,
            )
          ],
        ),
        padding: padding,
        child: child,
      ),
    );
  }
}
