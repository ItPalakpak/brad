import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';

import '../../core/database/db_helper.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/services/map_cache_service.dart';
import '../../shared/widgets/connectivity_banner.dart';
import '../../shared/widgets/offset_shadow_card.dart';
import '../../shared/widgets/status_badge.dart';
import '../../shared/widgets/payment_chip.dart';
import '../../shared/utils/currency_formatter.dart';
import '../../shared/utils/date_formatter.dart';
import '../map/pin_picker_sheet.dart';
import 'packages_provider.dart';
import 'package:brad/features/packages/package_form.dart';

class PackageDetailScreen extends ConsumerStatefulWidget {
  final String packageId;
  final String? initialTrackingNumber;

  const PackageDetailScreen({
    super.key,
    required this.packageId,
    this.initialTrackingNumber,
  });

  @override
  ConsumerState<PackageDetailScreen> createState() => _PackageDetailScreenState();
}

class _PackageDetailScreenState extends ConsumerState<PackageDetailScreen> {
  Package? _package;
  List<DeliveryAttempt> _attempts = [];
  bool _isLoading = true;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.packageId == 'new';
    _loadPackageDetails();
  }

  Future<void> _loadPackageDetails() async {
    if (widget.packageId == 'new') {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final pkg = await DbHelper.instance.getPackageById(widget.packageId);
    final list = await DbHelper.instance.getAttemptsForPackage(widget.packageId);

    if (mounted) {
      setState(() {
        _package = pkg;
        _attempts = list;
        _isLoading = false;
      });
    }
  }

  void _onSaved() {
    setState(() {
      _isEditing = false;
    });
    _loadPackageDetails();
    ref.read(packagesNotifierProvider.notifier).refresh();
  }

  Future<void> _logAttempt() async {
    String status = 'no_answer';
    final notesController = TextEditingController();
    final tokens = context.tokens;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: OffsetShadowCard(
                backgroundColor: tokens.surface,
                shadowColor: tokens.border,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Log Delivery Attempt',
                      style: TextStyle(fontFamily: 'Geist', fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    const Text('Select attempt status:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: tokens.inputBg,
                        borderRadius: BorderRadius.zero,
                        border: Border.all(color: tokens.inputBorder, width: 1.5),
                        boxShadow: [AppShadows.offsetSm(tokens.shadowColor)],
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: status,
                          isExpanded: true,
                          dropdownColor: tokens.surface,
                          style: TextStyle(
                            color: tokens.text,
                            fontFamily: 'DM Sans',
                            fontSize: 14,
                          ),
                          onChanged: (val) {
                            if (val != null) {
                              setDialogState(() {
                                status = val;
                              });
                            }
                          },
                          items: const [
                            DropdownMenuItem(value: 'no_answer', child: Text('No Answer / Unreachable')),
                            DropdownMenuItem(value: 'refused', child: Text('Customer Refused Delivery')),
                            DropdownMenuItem(value: 'failed', child: Text('Address Unresolved / Other')),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.zero,
                        boxShadow: [AppShadows.offsetSm(tokens.shadowColor)],
                      ),
                      child: TextField(
                        controller: notesController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Attempt Notes',
                          hintText: 'e.g. Gate was locked, called twice',
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('CANCEL'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () async {
                            Navigator.pop(context);
                            if (_package != null) {
                              await ref.read(packagesNotifierProvider.notifier).markFailed(
                                    _package!.id,
                                    status,
                                    notesController.text.trim(),
                                  );
                              _loadPackageDetails();
                            }
                          },
                          child: const Text('LOG ATTEMPT'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _pickLocationOnMap() async {
    if (_package == null) return;
    
    final initialPos = _package!.lat != null && _package!.lng != null
        ? LatLng(_package!.lat!, _package!.lng!)
        : const LatLng(8.4542, 124.6319); // Default CDO coords

    final LatLng? pickedLocation = await showModalBottomSheet<LatLng>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return PinPickerSheet(initialLocation: initialPos);
      },
    );

    if (pickedLocation != null) {
      final updated = _package!.copyWith(
        lat: pickedLocation.latitude,
        lng: pickedLocation.longitude,
      );
      await ref.read(packagesNotifierProvider.notifier).updatePackage(updated);
      _loadPackageDetails();
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Loading details...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_isEditing) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.packageId == 'new' ? 'NEW PACKAGE' : 'EDIT PACKAGE'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () {
              if (widget.packageId == 'new') {
                context.pop();
              } else {
                setState(() {
                  _isEditing = false;
                });
              }
            },
          ),
        ),
        body: Column(
          children: [
            const ConnectivityBanner(),
            Expanded(
              child: PackageForm(
                package: _package,
                initialTrackingNumber: widget.initialTrackingNumber,
                onSaved: _onSaved,
              ),
            ),
          ],
        ),
      );
    }

    if (_package == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Package Details')),
        body: const Center(child: Text('Package not found.')),
      );
    }

    final p = _package!;
    final isMaxAttempts = _attempts.length >= 3 && p.status != 'delivered';

    return Scaffold(
      appBar: AppBar(
        title: const Text('PACKAGE DETAILS'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Package',
            onPressed: () {
              setState(() {
                _isEditing = true;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            tooltip: 'Delete Package',
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      body: Column(
        children: [
          const ConnectivityBanner(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                // Top status card
                OffsetShadowCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            p.trackingNumber,
                            style: const TextStyle(
                              fontFamily: 'JetBrains Mono',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          StatusBadge(status: p.status),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        p.receiverName ?? 'Unnamed Receiver',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      if (p.receiverPhone != null && p.receiverPhone!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.phone_outlined, size: 14, color: tokens.textSubtle),
                            const SizedBox(width: 6),
                            Text(
                              p.receiverPhone!,
                              style: TextStyle(color: tokens.textMuted, fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ],
                      if (p.notes != null && p.notes!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: tokens.bg,
                            borderRadius: BorderRadius.zero,
                            border: Border.all(color: tokens.border, width: 1.0),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.notes_rounded, size: 14, color: tokens.accent),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  p.notes!,
                                  style: TextStyle(color: tokens.text, fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Location details + mini map
                Text(
                  'DELIVERY LOCATION',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: tokens.textSubtle, letterSpacing: 0.5),
                ),
                const SizedBox(height: 8),
                OffsetShadowCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.location_on_outlined, color: tokens.accent),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                [p.street, p.zone, p.barangay, p.city].where((s) => s != null && s.isNotEmpty).join(', '),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Map Thumbnail Section
                      SizedBox(
                        height: 150,
                        child: p.lat != null && p.lng != null
                            ? Stack(
                                children: [
                                  // Mini non-interactive map
                                  FlutterMap(
                                    options: MapOptions(
                                      initialCenter: LatLng(p.lat!, p.lng!),
                                      initialZoom: 14.5,
                                    ),
                                    children: [
                                      TileLayer(
                                        urlTemplate: 'https://mt1.google.com/vt/lyrs=m&x={x}&y={y}&z={z}',
                                        tileProvider: ref.read(mapCacheServiceProvider).offlineTileProvider,
                                        userAgentPackageName: 'com.brad.brad',
                                      ),
                                      MarkerLayer(
                                        markers: [
                                          Marker(
                                            point: LatLng(p.lat!, p.lng!),
                                            width: 32,
                                            height: 32,
                                            child: Icon(Icons.location_pin, color: tokens.accent, size: 32),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  // Click mask to prevent touch conflicts and enable click
                                  Positioned.fill(
                                    child: GestureDetector(
                                      onTap: _pickLocationOnMap,
                                      child: Container(
                                        color: Colors.transparent,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 8,
                                    right: 8,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.zero,
                                        boxShadow: [AppShadows.offsetSm(tokens.shadowColor)],
                                      ),
                                      child: FloatingActionButton.small(
                                        heroTag: 'map-thumbnail-fab',
                                        onPressed: _pickLocationOnMap,
                                        backgroundColor: tokens.surface,
                                        foregroundColor: tokens.accent,
                                        child: const Icon(Icons.edit_location_alt_rounded),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : Container(
                                color: tokens.bg,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.map_outlined, size: 32, color: tokens.textSubtle),
                                    const SizedBox(height: 8),
                                    const Text('No location coordinates pinned', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 8),
                                    OutlinedButton.icon(
                                      onPressed: _pickLocationOnMap,
                                      icon: const Icon(Icons.pin_drop_rounded, size: 16),
                                      label: const Text('PIN ON MAP', style: TextStyle(fontSize: 11)),
                                    ),
                                  ],
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Financial details
                Text(
                  'FINANCIAL DETAILS',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: tokens.textSubtle, letterSpacing: 0.5),
                ),
                const SizedBox(height: 8),
                OffsetShadowCard(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Payment Type', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                          PaymentChip(type: p.paymentType),
                        ],
                      ),
                      const Divider(height: 20),
                      if (p.paymentType != 'prepaid') ...[
                        _buildPriceRow('COD Amount', p.totalCod),
                        _buildPriceRow('  - Cash portion', p.codCash),
                        _buildPriceRow('  - Digital portion', p.codDigital),
                        const Divider(height: 20),
                      ],
                      _buildPriceRow('Tips Received', p.tips),
                      if (p.extraAmount > 0) ...[
                        _buildPriceRow(p.extraLabel ?? 'Extra Amount', p.extraAmount),
                      ],
                      const Divider(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('TOTAL COLLECTED', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                          Text(
                            CurrencyFormatter.format(p.grandTotal),
                            style: TextStyle(fontSize: 16, color: tokens.text, fontWeight: FontWeight.w900, fontFamily: 'JetBrains Mono'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Attempts List
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'DELIVERY ATTEMPTS (${_attempts.length})',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: tokens.textSubtle, letterSpacing: 0.5),
                    ),
                    if (p.status == 'pending' && !isMaxAttempts)
                      TextButton.icon(
                        onPressed: _logAttempt,
                        icon: const Icon(Icons.add_circle_outline_rounded, size: 16),
                        label: const Text('LOG ATTEMPT', style: TextStyle(fontSize: 12)),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                if (isMaxAttempts) ...[
                  OffsetShadowCard(
                    backgroundColor: AppStatusColors.errorSoft,
                    shadowColor: tokens.border,
                    child: const Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: AppStatusColors.error),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Return package to sender. Max failed attempts (3/3) reached.',
                            style: TextStyle(color: AppStatusColors.error, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                if (_attempts.isEmpty)
                  OffsetShadowCard(
                    child: Center(
                      child: Text(
                        'No delivery attempts recorded yet.',
                        style: TextStyle(color: tokens.textSubtle, fontSize: 12),
                      ),
                    ),
                  )
                else
                  ..._attempts.map((attempt) => Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: OffsetShadowCard(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          child: Row(
                            children: [
                              Icon(
                                attempt.status == 'success'
                                    ? Icons.check_circle_outline_rounded
                                    : Icons.cancel_outlined,
                                color: attempt.status == 'success' ? AppStatusColors.success : AppStatusColors.error,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      attempt.status == 'success'
                                          ? 'Delivered'
                                          : (attempt.status == 'no_answer'
                                              ? 'Unreachable / No Answer'
                                              : (attempt.status == 'refused' ? 'Customer Refused' : 'Failed')),
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                    if (attempt.notes != null && attempt.notes!.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        attempt.notes!,
                                        style: TextStyle(color: tokens.textMuted, fontSize: 12),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              Text(
                                DateFormatter.formatShort(attempt.attemptedAt),
                                style: TextStyle(color: tokens.textSubtle, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      )),

                const SizedBox(height: 32),

                // Deliver Button (if pending)
                if (p.status == 'pending') ...[
                  OffsetShadowCard(
                    backgroundColor: AppStatusColors.success,
                    shadowColor: tokens.border,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    onTap: () async {
                      await ref.read(packagesNotifierProvider.notifier).markDelivered(p.id);
                      _loadPackageDetails();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: AppStatusColors.success,
                            content: Text('Package #${p.trackingNumber} marked as Delivered!'),
                          ),
                        );
                      }
                    },
                    child: Center(
                      child: Text(
                        'MARK AS DELIVERED',
                        style: TextStyle(
                          color: tokens.textInvert,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ],
            ),
          ),
        ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, double val) {
    final tokens = context.tokens;
    final isSub = label.startsWith('  -');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isSub ? 12 : 13,
              color: isSub ? tokens.textSubtle : tokens.text,
              fontWeight: isSub ? FontWeight.normal : FontWeight.bold,
            ),
          ),
          Text(
            CurrencyFormatter.format(val),
            style: TextStyle(
              fontSize: isSub ? 12 : 13,
              color: isSub ? tokens.textSubtle : tokens.text,
              fontFamily: 'JetBrains Mono',
              fontWeight: isSub ? FontWeight.normal : FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Package?'),
          content: Text('Are you sure you want to delete package #${_package?.trackingNumber}? This action is irreversible.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppStatusColors.error),
              onPressed: () async {
                Navigator.pop(context);
                if (_package != null) {
                  await ref.read(packagesNotifierProvider.notifier).deletePackage(_package!.id);
                  if (context.mounted) {
                    context.pop(); // Go back to list
                  }
                }
              },
              child: const Text('DELETE', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}
