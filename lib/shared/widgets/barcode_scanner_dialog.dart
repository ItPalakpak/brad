import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/theme/app_theme.dart';
import 'offset_shadow_card.dart';

class BarcodeScannerDialog extends StatefulWidget {
  const BarcodeScannerDialog({super.key});

  static Future<String?> scan(BuildContext context) {
    return Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (context) => const BarcodeScannerDialog(),
        fullscreenDialog: true,
      ),
    );
  }

  @override
  State<BarcodeScannerDialog> createState() => _BarcodeScannerDialogState();
}

class _BarcodeScannerDialogState extends State<BarcodeScannerDialog> with SingleTickerProviderStateMixin {
  late MobileScannerController _controller;
  late AnimationController _animController;
  late Animation<double> _pulseAnimation;
  bool _isFinished = false;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      returnImage: false,
    );

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
    _controller.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_isFinished) return;
    final code = capture.barcodes.first.rawValue;
    if (code != null && code.isNotEmpty) {
      _isFinished = true;
      await HapticFeedback.mediumImpact();
      if (mounted) {
        Navigator.of(context).pop(code);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('SCAN TRACKING CODE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: ValueListenableBuilder<MobileScannerState>(
              valueListenable: _controller,
              builder: (context, state, child) {
                switch (state.torchState) {
                  case TorchState.on:
                    return const Icon(Icons.flash_on_rounded, color: Colors.white);
                  case TorchState.off:
                  default:
                    return const Icon(Icons.flash_off_rounded, color: Colors.white70);
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
                    return const Icon(Icons.camera_front_rounded, color: Colors.white);
                  case CameraFacing.back:
                    return const Icon(Icons.camera_rear_rounded, color: Colors.white70);
                }
              },
            ),
            onPressed: () => _controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.5),
            ),
          ),
          Align(
            alignment: Alignment.center,
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
                    Positioned(top: 0, left: 0, child: _buildCorner(tokens.accent, top: true, left: true)),
                    Positioned(top: 0, right: 0, child: _buildCorner(tokens.accent, top: true, left: false)),
                    Positioned(bottom: 0, left: 0, child: _buildCorner(tokens.accent, top: false, left: true)),
                    Positioned(bottom: 0, right: 0, child: _buildCorner(tokens.accent, top: false, left: false)),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 48,
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
                      'Position the barcode or QR code inside the markers to scan.',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCorner(Color color, {required bool top, required bool left}) {
    const double length = 24.0;
    const double thickness = 4.0;
    return SizedBox(
      width: length,
      height: length,
      child: Stack(
        children: [
          Positioned(
            top: top ? 0 : null,
            bottom: top ? null : 0,
            left: 0,
            right: 0,
            child: Container(height: thickness, color: color),
          ),
          Positioned(
            top: 0,
            bottom: 0,
            left: left ? 0 : null,
            right: left ? null : 0,
            child: Container(width: thickness, color: color),
          ),
        ],
      ),
    );
  }
}
