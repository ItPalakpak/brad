import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

enum OffsetButtonVariant {
  elevated,
  outlined,
}

class OffsetShadowButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final OffsetButtonVariant variant;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? shadowColor;
  final Color? borderColor;
  final double borderWidth;
  final Offset shadowOffset;
  final EdgeInsets padding;
  final bool fullWidth;

  const OffsetShadowButton({
    super.key,
    required this.child,
    this.onPressed,
    this.variant = OffsetButtonVariant.elevated,
    this.backgroundColor,
    this.foregroundColor,
    this.shadowColor,
    this.borderColor,
    this.borderWidth = 1.5,
    this.shadowOffset = const Offset(1.5, 1.5), // match offsetSm
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    this.fullWidth = false,
  });

  // Factory constructor for ElevatedButton style equivalence
  factory OffsetShadowButton.elevated({
    Key? key,
    required Widget child,
    VoidCallback? onPressed,
    Color? backgroundColor,
    Color? foregroundColor,
    Color? shadowColor,
    Color? borderColor,
    Offset shadowOffset = const Offset(1.5, 1.5),
    EdgeInsets padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    bool fullWidth = false,
  }) {
    return OffsetShadowButton(
      key: key,
      variant: OffsetButtonVariant.elevated,
      onPressed: onPressed,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      shadowColor: shadowColor,
      borderColor: borderColor,
      shadowOffset: shadowOffset,
      padding: padding,
      fullWidth: fullWidth,
      child: child,
    );
  }

  // Factory constructor for OutlinedButton style equivalence
  factory OffsetShadowButton.outlined({
    Key? key,
    required Widget child,
    VoidCallback? onPressed,
    Color? foregroundColor,
    Color? shadowColor,
    Color? borderColor,
    Offset shadowOffset = const Offset(1.5, 1.5),
    EdgeInsets padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    bool fullWidth = false,
  }) {
    return OffsetShadowButton(
      key: key,
      variant: OffsetButtonVariant.outlined,
      onPressed: onPressed,
      foregroundColor: foregroundColor,
      shadowColor: shadowColor,
      borderColor: borderColor,
      shadowOffset: shadowOffset,
      padding: padding,
      fullWidth: fullWidth,
      child: child,
    );
  }

  // Factory constructor for Button.icon style equivalence
  factory OffsetShadowButton.icon({
    Key? key,
    required Widget icon,
    required Widget label,
    VoidCallback? onPressed,
    OffsetButtonVariant variant = OffsetButtonVariant.elevated,
    Color? backgroundColor,
    Color? foregroundColor,
    Color? shadowColor,
    Color? borderColor,
    Offset shadowOffset = const Offset(1.5, 1.5),
    EdgeInsets padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    bool fullWidth = false,
  }) {
    return OffsetShadowButton(
      key: key,
      variant: variant,
      onPressed: onPressed,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      shadowColor: shadowColor,
      borderColor: borderColor,
      shadowOffset: shadowOffset,
      padding: padding,
      fullWidth: fullWidth,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          icon,
          const SizedBox(width: 8),
          label,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final isEnabled = onPressed != null;

    final Color bg;
    final Color fg;
    final Color borderCol;
    final Color shadowCol;

    if (variant == OffsetButtonVariant.elevated) {
      bg = isEnabled
          ? (backgroundColor ?? tokens.surface)
          : (backgroundColor ?? tokens.surface).withValues(alpha: 0.5);
      fg = foregroundColor ?? (backgroundColor != null ? tokens.textInvert : tokens.text);
      borderCol = borderColor ?? tokens.border;
    } else {
      bg = isEnabled
          ? (backgroundColor ?? tokens.surface)
          : (backgroundColor ?? tokens.surface);
      fg = foregroundColor ?? tokens.text;
      borderCol = borderColor ?? tokens.border;
    }

    shadowCol = isEnabled
        ? (shadowColor ?? tokens.shadowColor)
        : Colors.transparent;

    Widget buttonContent = DefaultTextStyle(
      style: TextStyle(
        color: fg,
        fontWeight: FontWeight.bold,
        fontSize: 15,
        fontFamily: 'DM Sans',
      ),
      child: IconTheme(
        data: IconThemeData(
          color: fg,
          size: 18,
        ),
        child: child,
      ),
    );

    if (fullWidth) {
      buttonContent = SizedBox(
        width: double.infinity,
        child: Center(
          child: buttonContent,
        ),
      );
    }

    return GestureDetector(
      onTap: onPressed,
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.zero,
          border: Border.all(color: borderCol, width: borderWidth),
          boxShadow: isEnabled
              ? [
                  BoxShadow(
                    color: shadowCol,
                    offset: shadowOffset,
                    blurRadius: 0,
                  )
                ]
              : null,
        ),
        padding: padding,
        child: buttonContent,
      ),
    );
  }
}
