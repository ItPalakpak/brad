import 'package:flutter/material.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/app_theme.dart';

class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    Color bgColor;
    Color textColor;
    String label;

    switch (status) {
      case 'delivered':
        bgColor = AppStatusColors.successSoft;
        textColor = AppStatusColors.success;
        label = 'Delivered';
        break;
      case 'failed':
        bgColor = AppStatusColors.errorSoft;
        textColor = AppStatusColors.error;
        label = 'Failed';
        break;
      case 'returned':
        bgColor = AppStatusColors.infoSoft;
        textColor = AppStatusColors.info;
        label = 'Returned';
        break;
      case 'pending':
      default:
        bgColor = AppStatusColors.warningSoft;
        textColor = AppStatusColors.warning;
        label = 'Pending';
        break;
    }

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.zero,
        border: Border.all(color: tokens.border, width: 1.0),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
