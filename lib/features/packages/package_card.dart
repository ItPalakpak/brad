import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/database/db_helper.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../shared/widgets/offset_shadow_card.dart';
import '../../shared/widgets/status_badge.dart';
import '../../shared/widgets/payment_chip.dart';
import '../../shared/widgets/offset_shadow_button.dart';
import '../../shared/utils/currency_formatter.dart';
import '../../shared/utils/date_formatter.dart';
import 'delivery_confirmation_modal.dart';
import 'packages_provider.dart';

class PackageCard extends ConsumerWidget {
  final Package package;
  final bool showDragHandle;
  final int? index;

  const PackageCard({
    super.key,
    required this.package,
    this.showDragHandle = false,
    this.index,
  });

  Future<void> _quickDeliverPrepaid(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(packagesNotifierProvider.notifier);
    final originalPackage = package;
    await notifier.markDelivered(package.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppStatusColors.success,
          content: Text('Prepaid package #${package.trackingNumber} marked as Delivered!'),
          action: SnackBarAction(
            label: 'UNDO',
            textColor: Colors.white,
            onPressed: () async {
              await notifier.undoStatus(originalPackage);
            },
          ),
        ),
      );
    }
  }

  Future<void> _showQuickFailureSheet(BuildContext context, WidgetRef ref) async {
    final tokens = context.tokens;
    final notifier = ref.read(packagesNotifierProvider.notifier);
    final originalPackage = package;

    final result = await showModalBottomSheet<Map<String, String>>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: tokens.surface,
            borderRadius: BorderRadius.zero,
            border: Border(
              top: BorderSide(color: tokens.border, width: 2.0),
              left: BorderSide(color: tokens.border, width: 2.0),
              right: BorderSide(color: tokens.border, width: 2.0),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'LOG DELIVERY FAILURE',
                style: TextStyle(
                  fontFamily: 'Syne',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: tokens.text,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Recipient Not Around / No Answer'),
                leading: Icon(Icons.person_off_rounded, color: tokens.accent),
                onTap: () => Navigator.pop(context, {'status': 'failed', 'reason': 'Recipient not around/no answer'}),
              ),
              ListTile(
                title: const Text('Refused / Rejected by Consignee'),
                leading: Icon(Icons.cancel_presentation_rounded, color: AppStatusColors.error),
                onTap: () => Navigator.pop(context, {'status': 'failed', 'reason': 'Refused by consignee'}),
              ),
              ListTile(
                title: const Text('Incomplete Address / Cannot Locate'),
                leading: Icon(Icons.wrong_location_rounded, color: AppStatusColors.warning),
                onTap: () => Navigator.pop(context, {'status': 'failed', 'reason': 'Cannot locate address'}),
              ),
              const SizedBox(height: 12),
              OffsetShadowButton.outlined(
                onPressed: () => Navigator.pop(context),
                child: const Text('CANCEL'),
              ),
            ],
          ),
        );
      },
    );

    if (result != null) {
      final status = result['status']!;
      final reason = result['reason']!;
      await notifier.markFailed(package.id, status, reason);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppStatusColors.error,
            content: Text('Logged attempt: $reason'),
            action: SnackBarAction(
              label: 'UNDO',
              textColor: Colors.white,
              onPressed: () async {
                await notifier.undoStatus(originalPackage);
              },
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;

    // Check if max attempts are reached (3 attempts)
    final isMaxAttempts = package.attemptCount >= 3 && package.status != 'delivered';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Slidable(
        key: ValueKey(package.id),
        // FEATURE-02: Swipe right (reveals startActionPane on the left) -> FAILED
        startActionPane: package.status == 'pending'
            ? ActionPane(
                motion: const ScrollMotion(),
                extentRatio: 0.3,
                children: [
                  SlidableAction(
                    onPressed: (slidableContext) async {
                      await _showQuickFailureSheet(context, ref);
                    },
                    backgroundColor: AppStatusColors.error,
                    foregroundColor: Colors.white,
                    icon: Icons.cancel_outlined,
                    label: 'Failed',
                    borderRadius: BorderRadius.zero,
                  ),
                ],
              )
            : null,
        // FEATURE-02: Swipe left (reveals endActionPane on the right) -> DELIVER or EDIT
        endActionPane: ActionPane(
          motion: const ScrollMotion(),
          extentRatio: 0.5,
          children: [
            if (package.status == 'pending')
              SlidableAction(
                onPressed: (slidableContext) async {
                  if (package.paymentType == 'prepaid') {
                    await _quickDeliverPrepaid(context, ref);
                  } else {
                    // COD opens delivery confirmation modal
                    final confirmed = await showDeliveryConfirmationModal(
                      context: context,
                      package: package,
                      ref: ref,
                    );
                    if (confirmed && slidableContext.mounted) {
                      ScaffoldMessenger.of(slidableContext).showSnackBar(
                        SnackBar(
                          backgroundColor: AppStatusColors.success,
                          content: Text('Package #${package.trackingNumber} marked as Delivered!'),
                        ),
                      );
                    }
                  }
                },
                backgroundColor: AppStatusColors.success,
                foregroundColor: Colors.white,
                icon: Icons.check_circle_outline_rounded,
                label: 'Deliver',
                borderRadius: BorderRadius.zero,
              ),
            SlidableAction(
              onPressed: (context) {
                context.push('/packages/${package.id}');
              },
              backgroundColor: tokens.accent,
              foregroundColor: tokens.textInvert,
              icon: Icons.edit_outlined,
              label: 'Edit',
              borderRadius: BorderRadius.zero,
            ),
          ],
        ),
        child: OffsetShadowCard(
          padding: EdgeInsets.zero,
          onTap: () {
            context.push('/packages/${package.id}');
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Return notification banner if max attempts reached
              if (isMaxAttempts)
                Container(
                  color: AppStatusColors.errorSoft,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, size: 14, color: AppStatusColors.error),
                      const SizedBox(width: 6),
                      Text(
                        'RETURN TO SENDER: Max attempts reached (${package.attemptCount}/3)',
                        style: const TextStyle(
                          color: AppStatusColors.error,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top row: barcode # + status
                    Row(
                      children: [
                        if (showDragHandle) ...[
                          if (index != null)
                            ReorderableDragStartListener(
                              index: index!,
                              child: Icon(Icons.drag_handle_rounded, color: tokens.textSubtle),
                            )
                          else
                            Icon(Icons.drag_handle_rounded, color: tokens.textSubtle),
                          const SizedBox(width: 8),
                        ],
                        const Icon(Icons.inventory_2_outlined, size: 16),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            package.trackingNumber,
                            style: const TextStyle(
                              fontFamily: 'JetBrains Mono',
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        StatusBadge(status: package.status),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // Receiver name
                    Text(
                      package.receiverName ?? 'Unnamed Receiver',
                      style: TextStyle(
                        color: tokens.text,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Delivery location Address
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined, size: 14, color: tokens.textSubtle),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            [
                              package.street,
                              package.zone,
                              package.barangay,
                              package.city
                            ].where((s) => s != null && s.isNotEmpty).join(', '),
                            style: TextStyle(
                              color: tokens.textMuted,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24, thickness: 1.0),

                    // Bottom Row: Payments, Attempt, Date
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        PaymentChip(type: package.paymentType),
                        Row(
                          children: [
                            // COD indicator
                            if (package.paymentType != 'prepaid') ...[
                              Text(
                                CurrencyFormatter.format(package.totalCod),
                                style: TextStyle(
                                  color: tokens.text,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 12),
                            ],
                            // Attempt count
                            Icon(Icons.replay_rounded, size: 14, color: tokens.textSubtle),
                            const SizedBox(width: 2),
                            Text(
                              '${package.attemptCount}',
                              style: TextStyle(
                                color: tokens.textMuted,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Date
                            Icon(Icons.calendar_today_rounded, size: 12, color: tokens.textSubtle),
                            const SizedBox(width: 4),
                            Text(
                              DateFormatter.formatShort(package.createdAt),
                              style: TextStyle(
                                color: tokens.textMuted,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
