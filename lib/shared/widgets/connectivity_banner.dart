import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/connectivity_service.dart';

class ConnectivityBanner extends ConsumerWidget {
  const ConnectivityBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(connectivityNotifierProvider);
    final tokens = context.tokens;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: isOnline
          ? const SizedBox.shrink()
          : Container(
              key: const ValueKey('offline-banner'),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppStatusColors.warningSoft,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: tokens.border, width: 1.5),
                ),
              ),
              child: const Row(
                children: [
                  Icon(Icons.wifi_off_rounded, size: 16, color: AppStatusColors.warning),
                  SizedBox(width: 8),
                  Text(
                    'Offline — all changes saved locally',
                    style: TextStyle(
                      color: AppStatusColors.warning,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
