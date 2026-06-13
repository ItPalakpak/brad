import 'package:flutter/material.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/app_theme.dart';

class PaymentChip extends StatelessWidget {
  final String type;

  const PaymentChip({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    Color bgColor;
    Color textColor;
    String label;
    IconData icon;

    switch (type) {
      case 'cod_digital':
        bgColor = AppStatusColors.infoSoft;
        textColor = AppStatusColors.info;
        label = 'Digital';
        icon = Icons.qr_code_scanner_rounded;
        break;
      case 'prepaid':
        bgColor = AppStatusColors.successSoft;
        textColor = AppStatusColors.success;
        label = 'Prepaid';
        icon = Icons.check_circle_outline_rounded;
        break;
      case 'cod_cash':
      default:
        bgColor = tokens.accentSoft;
        textColor = tokens.accent;
        label = 'COD Cash';
        icon = Icons.payments_outlined;
        break;
    }

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.zero,
        border: Border.all(color: tokens.border, width: 1.0),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
