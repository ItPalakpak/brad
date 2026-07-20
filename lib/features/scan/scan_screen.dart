import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../shared/widgets/connectivity_banner.dart';
import '../../shared/widgets/offset_shadow_card.dart';
import '../../shared/widgets/offset_shadow_button.dart';
import '../../shared/widgets/brand_logo.dart';
import 'scan_provider.dart';

class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key});

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen> {
  late MobileScannerController _controller;
  bool _isProcessingScan = false;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      returnImage: false,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleBarcodeScan(String code) async {
    if (_isProcessingScan) return;
    setState(() {
      _isProcessingScan = true;
    });

    final scanState = ref.read(scanStateNotifierProvider);

    // Vibrate to signal scan registered
    await HapticFeedback.mediumImpact();

    final isDuplicate = await ref.read(scanStateNotifierProvider.notifier).checkTrackingNumber(code);

    if (isDuplicate) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppStatusColors.error,
            content: Text(
              'Duplicate Package: "$code" has already been scanned.',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
        // Resume scanning after brief delay
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) {
            setState(() {
              _isProcessingScan = false;
            });
          }
        });
      }
    } else {
      if (scanState.isBatchMode) {
        // If in batch mode, check if code is already in batch queue
        if (scanState.batchQueue.contains(code)) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                backgroundColor: AppStatusColors.warning,
                content: Text(
                  'Already in batch queue.',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        } else {
          ref.read(scanStateNotifierProvider.notifier).addToQueue(code);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: AppStatusColors.success,
                content: Text(
                  'Added "$code" to batch queue.',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                ),
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 1),
              ),
            );
          }
        }
        // Resume scanning immediately in batch mode
        Future.delayed(const Duration(milliseconds: 1200), () {
          if (mounted) {
            setState(() {
              _isProcessingScan = false;
            });
          }
        });
      } else {
        if (mounted) {
          _showScanResultBottomSheet(code);
        }
      }
    }
  }

  void _showScanResultBottomSheet(String trackingNumber) {
    final tokens = context.tokens;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
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
                  Icon(Icons.inventory_2_rounded, color: tokens.accent),
                  const SizedBox(width: 8),
                  Text(
                    'Package Picked Up',
                    style: TextStyle(
                      fontFamily: 'Syne',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: tokens.text,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'TRACKING NUMBER',
                style: TextStyle(
                  color: tokens.textSubtle,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: tokens.bg,
                  borderRadius: BorderRadius.zero,
                  border: Border.all(color: tokens.border, width: 1.5),
                ),
                child: Text(
                  trackingNumber,
                  style: const TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              OffsetShadowCard(
                backgroundColor: tokens.accent,
                shadowColor: tokens.border,
                padding: const EdgeInsets.symmetric(vertical: 14),
                onTap: () {
                  Navigator.pop(context);
                  // Route to package form details screen using GoRouter
                  context.push('/packages/new?tracking=$trackingNumber');
                },
                child: Center(
                  child: Text(
                    'ADD DETAILS',
                    style: TextStyle(
                      color: tokens.textInvert,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              OffsetShadowButton.outlined(
                onPressed: () {
                  Navigator.pop(context);
                  _controller.start();
                },
                foregroundColor: AppStatusColors.error,
                child: const Text('CANCEL', textAlign: TextAlign.center),
              ),
            ],
          ),
        );
      },
    ).then((_) {
      // Sheet dismissed, reset scanner state
      setState(() {
        _isProcessingScan = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final size = MediaQuery.of(context).size;
    final maxW = size.width - 250;
    final maxH = size.height - 250 - 100; // safety margin for bottom/top appbars
    final scanState = ref.watch(scanStateNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            BrandLogo(type: BrandLogoType.icon, height: 32),
            const SizedBox(width: 8),
            Text(
              'SCAN PACKAGE',
              style: TextStyle(
                color: tokens.text,
                fontFamily: 'Syne',
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              scanState.isBatchMode ? Icons.layers_rounded : Icons.layers_clear_rounded,
              color: scanState.isBatchMode ? tokens.accent : null,
            ),
            tooltip: 'Toggle Batch Mode',
            onPressed: () {
              ref.read(scanStateNotifierProvider.notifier).toggleBatchMode();
              _controller.start();
            },
          ),
          IconButton(
            icon: ValueListenableBuilder<MobileScannerState>(
              valueListenable: _controller,
              builder: (context, state, child) {
                switch (state.torchState) {
                  case TorchState.on:
                    return const Icon(Icons.flash_on_rounded);
                  case TorchState.off:
                  default:
                    return const Icon(Icons.flash_off_rounded);
                }
              },
            ),
            onPressed: () => _controller.toggleTorch(),
          ),
          IconButton(
            icon: ValueListenableBuilder<MobileScannerState>(
              valueListenable: _controller,
              builder: (context, state, child) {
                switch (state.cameraDirection) {
                  case CameraFacing.front:
                    return const Icon(Icons.camera_front_rounded);
                  case CameraFacing.back:
                    return const Icon(Icons.camera_rear_rounded);
                }
              },
            ),
            onPressed: () => _controller.switchCamera(),
          ),
        ],
      ),
      body: Column(
        children: [
          const ConnectivityBanner(),
          if (scanState.isBatchMode)
            Container(
              color: tokens.accentSoft,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.layers_rounded, size: 16, color: tokens.accent),
                  const SizedBox(width: 8),
                  Text(
                    'Batch Mode Active — Queued: ${scanState.batchQueue.length}',
                    style: TextStyle(
                      color: tokens.accent,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      ref.read(scanStateNotifierProvider.notifier).clearQueue();
                    },
                    child: Text(
                      'CLEAR ALL',
                      style: TextStyle(
                        color: tokens.textSubtle,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: Stack(
              children: [
                // Full Screen MobileScanner
                RepaintBoundary(
                  child: MobileScanner(
                    controller: _controller,
                    onDetect: (capture) {
                      final barcode = capture.barcodes.first;
                      final code = barcode.rawValue;
                      if (code != null && code.isNotEmpty) {
                        _handleBarcodeScan(code);
                      }
                    },
                  ),
                ),

                // Dark semi-transparent mask
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.5),
                  ),
                ),

                // Transparent Cutout for Scanner View (Draggable)
                DraggableScannerCutout(
                  maxW: maxW,
                  maxH: maxH,
                ),

                // Informative Label Overlay or Batch List Overlay
                if (!scanState.isBatchMode || scanState.batchQueue.isEmpty)
                  Positioned(
                    bottom: 64,
                    left: 24,
                    right: 24,
                    child: OffsetShadowCard(
                      backgroundColor: tokens.surface,
                      shadowColor: tokens.border,
                      child: Row(
                        children: [
                          Icon(Icons.center_focus_strong_outlined, color: tokens.accent),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Align the barcode or QR code inside the brackets to register package pickup.',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                if (scanState.isBatchMode && scanState.batchQueue.isNotEmpty)
                  Positioned(
                    bottom: 24,
                    left: 16,
                    right: 16,
                    child: Container(
                      decoration: BoxDecoration(
                        color: tokens.surface,
                        border: Border.all(color: tokens.border, width: 2.0),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'BATCH QUEUE (${scanState.batchQueue.length})',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              GestureDetector(
                                onTap: () async {
                                  final messenger = ScaffoldMessenger.of(context);
                                  final navigator = GoRouter.of(context);
                                  await ref.read(scanStateNotifierProvider.notifier).commitBatch();
                                  messenger.showSnackBar(
                                    const SnackBar(
                                      content: Text('Successfully registered batch pickup!'),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                  navigator.pop();
                                },
                                child: Text(
                                  'SAVE BATCH',
                                  style: TextStyle(
                                    color: tokens.accent,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 40,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: scanState.batchQueue.length,
                              itemBuilder: (context, index) {
                                final trk = scanState.batchQueue[index];
                                return Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: tokens.bg,
                                    border: Border.all(color: tokens.border, width: 1),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        trk,
                                        style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 12, fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(width: 6),
                                      GestureDetector(
                                        onTap: () {
                                          ref.read(scanStateNotifierProvider.notifier).removeFromQueue(trk);
                                        },
                                        child: const Icon(Icons.close, size: 14, color: AppStatusColors.error),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

}

class DraggableScannerCutout extends StatefulWidget {
  final double maxW;
  final double maxH;

  const DraggableScannerCutout({
    super.key,
    required this.maxW,
    required this.maxH,
  });

  @override
  State<DraggableScannerCutout> createState() => _DraggableScannerCutoutState();
}

class _DraggableScannerCutoutState extends State<DraggableScannerCutout> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _pulseAnimation;
  double? _scannerX;
  double? _scannerY;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Widget _buildCorner(Color color, {required bool top, required bool left}) {
    const double length = 24.0;
    const double thickness = 4.0;
    return SizedBox(
      width: length,
      height: length,
      child: Stack(
        children: [
          // Horizontal line
          Positioned(
            top: top ? 0 : null,
            bottom: top ? null : 0,
            left: 0,
            right: 0,
            child: Container(
              height: thickness,
              color: color,
            ),
          ),
          // Vertical line
          Positioned(
            top: 0,
            bottom: 0,
            left: left ? 0 : null,
            right: left ? null : 0,
            child: Container(
              width: thickness,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    
    final scannerX = (_scannerX ?? widget.maxW / 2).clamp(0.0, widget.maxW);
    final scannerY = (_scannerY ?? widget.maxH / 2).clamp(0.0, widget.maxH);

    return Positioned.fill(
      child: Stack(
        children: [
          Transform.translate(
            offset: Offset(scannerX, scannerY),
            child: RepaintBoundary(
              child: SizedBox(
                width: 250,
                height: 250,
                child: GestureDetector(
                  onPanUpdate: (details) {
                    setState(() {
                      final activeX = _scannerX ?? (widget.maxW / 2);
                      final activeY = _scannerY ?? (widget.maxH / 2);
                      _scannerX = (activeX + details.delta.dx).clamp(0.0, widget.maxW);
                      _scannerY = (activeY + details.delta.dy).clamp(0.0, widget.maxH);
                    });
                  },
                  child: ScaleTransition(
                    scale: _pulseAnimation,
                    child: Container(
                      width: 250,
                      height: 250,
                      decoration: const BoxDecoration(
                        color: Colors.transparent,
                      ),
                      child: Stack(
                        children: [
                          // Reticle corner brackets
                          Positioned(
                            top: 0,
                            left: 0,
                            child: _buildCorner(tokens.accent, top: true, left: true),
                          ),
                          Positioned(
                            top: 0,
                            right: 0,
                            child: _buildCorner(tokens.accent, top: true, left: false),
                          ),
                          Positioned(
                            bottom: 0,
                            left: 0,
                            child: _buildCorner(tokens.accent, top: false, left: true),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: _buildCorner(tokens.accent, top: false, left: false),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
