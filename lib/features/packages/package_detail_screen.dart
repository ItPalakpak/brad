import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';

import '../../core/database/db_helper.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/services/map_cache_service.dart';
import '../../core/services/location_service.dart';
import '../../shared/widgets/connectivity_banner.dart';
import '../../shared/widgets/offset_shadow_card.dart';
import '../../shared/widgets/offset_shadow_button.dart';
import '../../shared/widgets/status_badge.dart';
import '../../shared/widgets/payment_chip.dart';
import '../../shared/utils/currency_formatter.dart';
import '../../shared/utils/date_formatter.dart';
import '../map/pin_picker_sheet.dart';
import 'packages_provider.dart';
import 'package:brad/features/packages/package_form.dart';
import 'package:brad/features/packages/delivery_confirmation_modal.dart';
// CHANGED: Import image_picker for ImageSource selection in bottom sheet
import 'package:image_picker/image_picker.dart';

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
  // CHANGED: GlobalKey to interact with the PackageFormState
  final GlobalKey<PackageFormState> _formKey = GlobalKey<PackageFormState>();

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  Future<void> _sendSMS(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'sms',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

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
    ref.read(packagesNotifierProvider.notifier).refresh();
    if (widget.packageId == 'new') {
      context.pop();
      return;
    }
    setState(() {
      _isEditing = false;
    });
    _loadPackageDetails();
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
                      style: TextStyle(fontFamily: 'Syne', fontWeight: FontWeight.bold, fontSize: 16),
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
                          style: TextButton.styleFrom(foregroundColor: AppStatusColors.error),
                          child: const Text('CANCEL', textAlign: TextAlign.center),
                        ),
                        const SizedBox(width: 8),
                        OffsetShadowButton.elevated(
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
    
    // BUG-03 FIX: Use rider's current GPS location instead of hardcoded coordinates
    LatLng initialPos;
    if (_package!.lat != null && _package!.lng != null) {
      initialPos = LatLng(_package!.lat!, _package!.lng!);
    } else {
      final currentPos = await ref.read(locationServiceProvider.notifier).getCurrentLocation();
      if (!mounted) return;
      initialPos = currentPos != null
          ? LatLng(currentPos.latitude, currentPos.longitude)
          : const LatLng(8.6074, 124.8957); // Fallback only
    }

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

  // CHANGED: Bottom sheet that allows rider to pick between Camera & Gallery for OCR field population
  void _showScanSourceBottomSheet() {
    final tokens = context.tokens;
    showModalBottomSheet(
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
            boxShadow: [
              BoxShadow(
                color: tokens.shadowColor,
                offset: const Offset(0, -4),
                blurRadius: 0,
              ),
            ],
          ),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: tokens.textSubtle.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.zero,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Icon(Icons.document_scanner_rounded, color: tokens.accent),
                  const SizedBox(width: 8),
                  Text(
                    'Auto-Populate Fields',
                    style: TextStyle(
                      fontFamily: 'Syne',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: tokens.text,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Scan package details from a parcel label photo or upload.',
                style: TextStyle(color: tokens.textSubtle, fontSize: 13),
              ),
              const SizedBox(height: 24),
              OffsetShadowCard(
                backgroundColor: tokens.accent,
                shadowColor: tokens.border,
                padding: const EdgeInsets.symmetric(vertical: 14),
                onTap: () {
                  Navigator.pop(context);
                  _formKey.currentState?.scanAndPopulateFields(source: ImageSource.camera);
                },
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_alt_rounded, color: tokens.textInvert, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'TAKE PHOTO (CAMERA)',
                        style: TextStyle(
                          color: tokens.textInvert,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              OffsetShadowCard(
                backgroundColor: tokens.surfaceAlt,
                shadowColor: tokens.border,
                padding: const EdgeInsets.symmetric(vertical: 14),
                onTap: () {
                  Navigator.pop(context);
                  _formKey.currentState?.scanAndPopulateFields(source: ImageSource.gallery);
                },
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.photo_library_rounded, color: tokens.text, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'UPLOAD PHOTO (GALLERY)',
                        style: TextStyle(
                          color: tokens.text,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              OffsetShadowButton.outlined(
                onPressed: () {
                  Navigator.pop(context);
                },
                foregroundColor: AppStatusColors.error,
                child: const Text('CANCEL', textAlign: TextAlign.center),
              ),
            ],
          ),
        );
      },
    );
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
          // CHANGED: Added scan icon to App Bar to trigger ML field auto-population separately
          actions: [
            IconButton(
              icon: const Icon(Icons.document_scanner_outlined),
              tooltip: 'Scan Label',
              onPressed: _showScanSourceBottomSheet,
            ),
          ],
        ),
        body: Column(
          children: [
            const ConnectivityBanner(),
            Expanded(
              child: PackageForm(
                key: _formKey,
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
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.phone_outlined, size: 14, color: tokens.textSubtle),
                            const SizedBox(width: 6),
                            Text(
                              p.receiverPhone!,
                              style: TextStyle(color: tokens.textMuted, fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                            const Spacer(),
                            // Quick Call Button
                            GestureDetector(
                              onTap: () => _makePhoneCall(p.receiverPhone!),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: tokens.surfaceAlt,
                                  border: Border.all(color: tokens.border, width: 1.5),
                                  borderRadius: BorderRadius.zero,
                                  boxShadow: [
                                    BoxShadow(
                                      color: tokens.shadowColor,
                                      offset: const Offset(1, 1),
                                      blurRadius: 0,
                                    )
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.phone_in_talk_rounded, size: 12, color: tokens.accent),
                                    const SizedBox(width: 4),
                                    const Text('CALL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Quick SMS Button
                            GestureDetector(
                              onTap: () => _sendSMS(p.receiverPhone!),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: tokens.surfaceAlt,
                                  border: Border.all(color: tokens.border, width: 1.5),
                                  borderRadius: BorderRadius.zero,
                                  boxShadow: [
                                    BoxShadow(
                                      color: tokens.shadowColor,
                                      offset: const Offset(1, 1),
                                      blurRadius: 0,
                                    )
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.sms_rounded, size: 12, color: tokens.accent),
                                    const SizedBox(width: 4),
                                    const Text('SMS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
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

                // Ride Assignment Section
                Text(
                  'RIDE ASSIGNMENT',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: tokens.textSubtle, letterSpacing: 0.5),
                ),
                const SizedBox(height: 8),
                OffsetShadowCard(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.directions_bike_rounded, color: tokens.accent),
                          const SizedBox(width: 12),
                          FutureBuilder<Ride?>(
                            future: p.rideId != null ? DbHelper.instance.getRideById(p.rideId!) : Future.value(null),
                            builder: (context, snapshot) {
                              final ride = snapshot.data;
                              if (p.rideId == null) {
                                return const Text(
                                  'Unassigned',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                );
                              }
                              if (ride == null) {
                                return const Text(
                                  'Loading...',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                );
                              }
                              final statusStr = ride.endedAt == null ? 'ACTIVE' : 'COMPLETED';
                              return Text(
                                'Ride #${ride.rideNumber} ($statusStr)',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              );
                            },
                          ),
                        ],
                      ),
                      TextButton.icon(
                        onPressed: () => _showChangeRideModal(p),
                        icon: const Icon(Icons.swap_horiz_rounded, size: 16),
                        label: const Text('CHANGE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
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
                                    OffsetShadowButton.icon(
                                      variant: OffsetButtonVariant.outlined,
                                      onPressed: _pickLocationOnMap,
                                      icon: const Icon(Icons.pin_drop_rounded),
                                      label: const Text('PIN ON MAP'),
                                    ),
                                  ],
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Parcel Photo Section
                if (p.photoPath != null && File(p.photoPath!).existsSync()) ...[
                  Text(
                    'PARCEL PHOTO',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: tokens.textSubtle, letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 8),
                  OffsetShadowCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        GestureDetector(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) => Dialog(
                                backgroundColor: Colors.transparent,
                                insetPadding: const EdgeInsets.all(12),
                                child: Stack(
                                  alignment: Alignment.topRight,
                                  children: [
                                    InteractiveViewer(
                                      child: Image.file(
                                        File(p.photoPath!),
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.close_rounded, color: Colors.white, size: 30),
                                      onPressed: () => Navigator.pop(context),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                          child: ClipRRect(
                            borderRadius: BorderRadius.zero,
                            child: SizedBox(
                              height: 200,
                              child: Image.file(
                                File(p.photoPath!),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Delivery Evidence Photo Section
                if (p.deliveryPhotoPath != null && File(p.deliveryPhotoPath!).existsSync()) ...[
                  Text(
                    'DELIVERY EVIDENCE',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: tokens.textSubtle, letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 8),
                  OffsetShadowCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        GestureDetector(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) => Dialog(
                                backgroundColor: Colors.transparent,
                                insetPadding: const EdgeInsets.all(12),
                                child: Stack(
                                  alignment: Alignment.topRight,
                                  children: [
                                    InteractiveViewer(
                                      child: Image.file(
                                        File(p.deliveryPhotoPath!),
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.close_rounded, color: Colors.white, size: 30),
                                      onPressed: () => Navigator.pop(context),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                          child: ClipRRect(
                            borderRadius: BorderRadius.zero,
                            child: SizedBox(
                              height: 200,
                              child: Image.file(
                                File(p.deliveryPhotoPath!),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

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

                if (_attempts.isEmpty && p.status == 'pending')
                  OffsetShadowCard(
                    child: Center(
                      child: Text(
                        'No delivery attempts recorded yet.',
                        style: TextStyle(color: tokens.textSubtle, fontSize: 12),
                      ),
                    ),
                  )
                else
                  _buildStatusTimeline(p, tokens),

                const SizedBox(height: 32),

                // Deliver Button (if pending)
                if (p.status == 'pending') ...[
                  OffsetShadowCard(
                    backgroundColor: AppStatusColors.success,
                    shadowColor: tokens.border,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    onTap: () async {
                      final confirmed = await showDeliveryConfirmationModal(
                        context: context,
                        package: p,
                        ref: ref,
                      );
                      if (confirmed) {
                        _loadPackageDetails();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: AppStatusColors.success,
                              content: Text('Package #${p.trackingNumber} marked as Delivered!'),
                            ),
                          );
                        }
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
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OffsetShadowCard(
                          backgroundColor: AppStatusColors.warning,
                          shadowColor: tokens.border,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          onTap: () => _showRescheduleModal(context),
                          child: Center(
                            child: Text(
                              'RESCHEDULE',
                              style: TextStyle(
                                color: tokens.textInvert,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OffsetShadowCard(
                          backgroundColor: AppStatusColors.error,
                          shadowColor: tokens.border,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          onTap: () => _showRejectModal(context),
                          child: Center(
                            child: Text(
                              'REJECT',
                              style: TextStyle(
                                color: tokens.textInvert,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
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
              style: TextButton.styleFrom(foregroundColor: AppStatusColors.error),
              child: const Text('CANCEL', textAlign: TextAlign.center),
            ),
            OffsetShadowButton.elevated(
              backgroundColor: AppStatusColors.error,
              foregroundColor: Colors.white,
              onPressed: () async {
                Navigator.pop(context);
                if (_package != null) {
                  await ref.read(packagesNotifierProvider.notifier).deletePackage(_package!.id);
                  if (context.mounted) {
                    context.pop(); // Go back to list
                  }
                }
              },
              child: const Text('DELETE'),
            ),
          ],
        );
      },
    );
  }

  void _showRescheduleModal(BuildContext context) async {
    final tokens = context.tokens;
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: tokens.accent,
              brightness: Theme.of(context).brightness,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && _package != null) {
      await ref.read(packagesNotifierProvider.notifier).markRescheduled(_package!.id, picked);
      _loadPackageDetails();
      scaffoldMessenger.showSnackBar(
        SnackBar(
          backgroundColor: AppStatusColors.warning,
          content: Text('Package rescheduled to ${DateFormat('yyyy-MM-dd').format(picked)}'),
        ),
      );
    }
  }

  void _showRejectModal(BuildContext context) {
    final tokens = context.tokens;
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    String selectedReason = 'Refused to accept';
    final customReasonController = TextEditingController();

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
                      'Select Rejection Reason',
                      style: TextStyle(fontFamily: 'Syne', fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    ...['Refused to accept', 'Wrong address', 'Cannot contact customer', 'Other'].map((reason) {
                      final isSelected = selectedReason == reason;
                      return GestureDetector(
                        onTap: () {
                          setDialogState(() {
                            selectedReason = reason;
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? tokens.accentSoft : tokens.surface,
                            border: Border.all(
                              color: isSelected ? tokens.accent : tokens.border,
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 18,
                                height: 18,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected ? tokens.accent : tokens.textSubtle,
                                    width: 1.5,
                                  ),
                                  color: isSelected ? tokens.accent : Colors.transparent,
                                ),
                                child: isSelected
                                    ? const Center(
                                        child: Icon(
                                          Icons.circle,
                                          size: 8,
                                          color: Colors.white,
                                        ),
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                reason,
                                style: TextStyle(
                                  color: tokens.text,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    if (selectedReason == 'Other') ...[
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.zero,
                          boxShadow: [AppShadows.offsetSm(tokens.shadowColor)],
                        ),
                        child: TextField(
                          controller: customReasonController,
                          decoration: const InputDecoration(
                            labelText: 'Specify Reason',
                            hintText: 'Enter reason here...',
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            'Cancel',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppStatusColors.error),
                          ),
                        ),
                        const SizedBox(width: 8),
                        OffsetShadowButton.elevated(
                          onPressed: () async {
                            final reason = selectedReason == 'Other'
                                ? customReasonController.text.trim()
                                : selectedReason;
                            if (reason.isEmpty) return;

                            Navigator.pop(context);
                            if (_package != null) {
                              await ref.read(packagesNotifierProvider.notifier).markRejected(
                                    _package!.id,
                                    reason,
                                  );
                              _loadPackageDetails();
                              scaffoldMessenger.showSnackBar(
                                SnackBar(
                                  backgroundColor: AppStatusColors.error,
                                  content: Text('Package rejected: $reason'),
                                ),
                              );
                            }
                          },
                          backgroundColor: AppStatusColors.error,
                          child: const Text('REJECT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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

  void _showChangeRideModal(Package p) async {
    final tokens = context.tokens;
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    // Fetch rides of today
    final todayRides = await DbHelper.instance.getRidesForDate(DateTime.now());

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) {
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
                  'Change Ride Assignment',
                  style: TextStyle(fontFamily: 'Syne', fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 16),
                // Unassigned Option
                GestureDetector(
                  onTap: () async {
                    Navigator.pop(context);
                    final updated = p.copyWith(rideId: null);
                    await ref.read(packagesNotifierProvider.notifier).updatePackage(updated);
                    _loadPackageDetails();
                    scaffoldMessenger.showSnackBar(
                      const SnackBar(
                        backgroundColor: AppStatusColors.warning,
                        content: Text('Package unassigned from ride.'),
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: p.rideId == null ? tokens.accentSoft : tokens.surface,
                      border: Border.all(
                        color: p.rideId == null ? tokens.accent : tokens.border,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.do_not_disturb_on_outlined,
                          color: p.rideId == null ? tokens.accent : tokens.textSubtle,
                          size: 18,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Unassigned (Remove from Ride)',
                          style: TextStyle(
                            color: tokens.text,
                            fontWeight: p.rideId == null ? FontWeight.bold : FontWeight.normal,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // List of today's rides
                if (todayRides.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      'No rides created today yet.',
                      style: TextStyle(color: tokens.textSubtle, fontSize: 12, fontStyle: FontStyle.italic),
                    ),
                  )
                else
                  ...todayRides.map((ride) {
                    final isSelected = p.rideId == ride.id;
                    final isCurrentActive = ride.endedAt == null;
                    return GestureDetector(
                      onTap: () async {
                        Navigator.pop(context);
                        final updated = p.copyWith(rideId: ride.id);
                        await ref.read(packagesNotifierProvider.notifier).updatePackage(updated);
                        _loadPackageDetails();
                        scaffoldMessenger.showSnackBar(
                          SnackBar(
                            backgroundColor: AppStatusColors.success,
                            content: Text('Package assigned to Ride #${ride.rideNumber}.'),
                          ),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? tokens.accentSoft : tokens.surface,
                          border: Border.all(
                            color: isSelected ? tokens.accent : tokens.border,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.directions_bike_rounded,
                              color: isSelected ? tokens.accent : tokens.textSubtle,
                              size: 18,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Ride #${ride.rideNumber} ${isCurrentActive ? '(Active)' : '(Completed)'}',
                              style: TextStyle(
                                color: tokens.text,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Close',
                        style: TextStyle(color: tokens.textSubtle, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusTimeline(Package p, AppColorTokens tokens) {
    // 1. Gather all timeline events
    final List<_TimelineEvent> events = [];

    // Always start with Registration
    events.add(_TimelineEvent(
      title: 'Parcel Registered',
      description: 'Package entered into system',
      timestamp: p.createdAt,
      icon: Icons.app_registration_rounded,
      color: tokens.textSubtle,
    ));

    // Add all delivery attempts
    for (final attempt in _attempts) {
      IconData icon = Icons.info_outline_rounded;
      Color color = tokens.textSubtle;
      String title = 'Attempt Logged';
      
      if (attempt.status == 'success') {
        icon = Icons.check_circle_outline_rounded;
        color = AppStatusColors.success;
        title = 'Delivered';
      } else {
        icon = Icons.cancel_outlined;
        color = AppStatusColors.error;
        if (attempt.status == 'no_answer') {
          title = 'Failed: No Answer';
        } else if (attempt.status == 'refused') {
          title = 'Failed: Refused';
        } else {
          title = 'Failed: Cannot Locate';
        }
      }

      events.add(_TimelineEvent(
        title: title,
        description: attempt.notes ?? 'No additional details',
        timestamp: attempt.attemptedAt,
        icon: icon,
        color: color,
      ));
    }

    // If final status is delivered/failed/rescheduled and it occurred after last attempt
    if (p.status == 'delivered') {
      events.add(_TimelineEvent(
        title: 'Delivered',
        description: 'Successfully received by customer',
        timestamp: p.deliveredAt ?? p.updatedAt,
        icon: Icons.check_circle_rounded,
        color: AppStatusColors.success,
      ));
    } else if (p.status == 'failed' || p.status == 'returned') {
      events.add(_TimelineEvent(
        title: 'Delivery Failed',
        description: p.rejectionReason ?? 'Final delivery failure',
        timestamp: p.updatedAt,
        icon: Icons.error_outline_rounded,
        color: AppStatusColors.error,
      ));
    } else if (p.status == 'rescheduled') {
      events.add(_TimelineEvent(
        title: 'Rescheduled',
        description: p.rescheduledDate != null
            ? 'Postponed to ${DateFormatter.formatShort(p.rescheduledDate!)}'
            : 'Postponed to future date',
        timestamp: p.updatedAt,
        icon: Icons.calendar_today_rounded,
        color: AppStatusColors.warning,
      ));
    }

    // Sort events by timestamp ascending (chronological order)
    events.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    // Remove consecutive duplicates of final state if timestamps are identical
    final Map<String, _TimelineEvent> uniqueEvents = {};
    for (final ev in events) {
      final key = '${ev.title}_${ev.timestamp.millisecondsSinceEpoch}';
      uniqueEvents[key] = ev;
    }
    final sortedUniqueEvents = uniqueEvents.values.toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sortedUniqueEvents.length,
      itemBuilder: (context, index) {
        final ev = sortedUniqueEvents[index];
        final isFirst = index == 0;
        final isLast = index == sortedUniqueEvents.length - 1;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left column: Dot and Line
            Column(
              children: [
                // Top line segment
                Container(
                  width: 2,
                  height: 16,
                  color: isFirst ? Colors.transparent : tokens.border,
                ),
                // Dot with icon
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: tokens.surface,
                    border: Border.all(color: tokens.border, width: 2.0),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(ev.icon, size: 16, color: ev.color),
                ),
                // Bottom line segment
                Container(
                  width: 2,
                  height: 32,
                  color: isLast ? Colors.transparent : tokens.border,
                ),
              ],
            ),
            const SizedBox(width: 16),
            // Right column: Content Card
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                child: OffsetShadowCard(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              ev.title,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('MM/dd HH:mm').format(ev.timestamp),
                            style: TextStyle(color: tokens.textSubtle, fontSize: 10),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        ev.description,
                        style: TextStyle(color: tokens.textMuted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TimelineEvent {
  final String title;
  final String description;
  final DateTime timestamp;
  final IconData icon;
  final Color color;

  _TimelineEvent({
    required this.title,
    required this.description,
    required this.timestamp,
    required this.icon,
    required this.color,
  });
}
