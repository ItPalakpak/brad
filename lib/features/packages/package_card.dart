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
import '../../shared/utils/currency_formatter.dart';
import '../../shared/utils/date_formatter.dart';
import 'delivery_confirmation_modal.dart';

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;

    // Check if max attempts are reached (3 attempts)
    final isMaxAttempts = package.attemptCount >= 3 && package.status != 'delivered';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Slidable(
        key: ValueKey(package.id),
        // Swipe right (reveals startActionPane on the left) -> Delivered
        startActionPane: package.status == 'pending'
            ? ActionPane(
                motion: const ScrollMotion(),
                extentRatio: 0.3,
                children: [
                  SlidableAction(
                    onPressed: (slidableContext) async {
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
                    },
                    backgroundColor: AppStatusColors.success,
                    foregroundColor: Colors.white,
                    icon: Icons.check_circle_outline_rounded,
                    label: 'Deliver',
                    borderRadius: BorderRadius.zero,
                  ),
                ],
              )
            : null,
        // Swipe left (reveals endActionPane on the right) -> Edit
        endActionPane: ActionPane(
          motion: const ScrollMotion(),
          extentRatio: 0.3,
          children: [
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
