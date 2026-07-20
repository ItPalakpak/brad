import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/database/db_helper.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../shared/widgets/offset_shadow_card.dart';
import '../../shared/widgets/offset_shadow_button.dart';
import 'packages_provider.dart';

/// Shows the delivery confirmation modal and returns `true` if delivery was confirmed.
Future<bool> showDeliveryConfirmationModal({
  required BuildContext context,
  required Package package,
  required WidgetRef ref,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return _DeliveryConfirmationModal(
        package: package,
        ref: ref,
      );
    },
  );
  return result ?? false;
}

class _DeliveryConfirmationModal extends StatefulWidget {
  final Package package;
  final WidgetRef ref;

  const _DeliveryConfirmationModal({
    required this.package,
    required this.ref,
  });

  @override
  State<_DeliveryConfirmationModal> createState() =>
      _DeliveryConfirmationModalState();
}

class _DeliveryConfirmationModalState
    extends State<_DeliveryConfirmationModal> {
  late TextEditingController _amountReceivedController;
  late TextEditingController _tipsController;
  late TextEditingController _extraAmountController;
  late TextEditingController _extraLabelController;

  String? _deliveryPhotoPath;
  String? _signaturePath;
  bool _isSubmitting = false;

  bool get _isCod => widget.package.paymentType != 'prepaid';
  double get _codAmount => widget.package.totalCod;

  @override
  void initState() {
    super.initState();
    _amountReceivedController = TextEditingController(
      text: _isCod ? _codAmount.toStringAsFixed(0) : '',
    );
    _tipsController = TextEditingController(text: '0');
    _extraAmountController = TextEditingController(
      text: widget.package.extraAmount.toString(),
    );
    _extraLabelController = TextEditingController(
      text: widget.package.extraLabel ?? '',
    );
  }

  @override
  void dispose() {
    _amountReceivedController.dispose();
    _tipsController.dispose();
    _extraAmountController.dispose();
    _extraLabelController.dispose();
    super.dispose();
  }

  void _recalculateTip() {
    if (!_isCod) return;
    final received = double.tryParse(_amountReceivedController.text) ?? 0.0;
    final tip = (received - _codAmount).clamp(0.0, double.infinity);
    _tipsController.text = tip.toStringAsFixed(tip == tip.roundToDouble() ? 0 : 2);
    setState(() {});
  }

  double _getGrandTotal() {
    final cod = _isCod ? _codAmount : 0.0;
    final tips = double.tryParse(_tipsController.text) ?? 0.0;
    final extra = double.tryParse(_extraAmountController.text) ?? 0.0;
    return cod + tips + extra;
  }

  Future<void> _takeDeliveryPhoto() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );
      if (image != null) {
        final appDir = await getApplicationDocumentsDirectory();
        final filename =
            'delivery_${widget.package.trackingNumber}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final savedFile =
            await File(image.path).copy('${appDir.path}/$filename');

        setState(() {
          _deliveryPhotoPath = savedFile.path;
        });
      }
    } catch (e) {
      debugPrint('Error taking delivery photo: $e');
    }
  }

  Future<void> _confirmDelivery() async {
    setState(() {
      _isSubmitting = true;
    });

    final tips = double.tryParse(_tipsController.text) ?? 0.0;
    final extraAmount = double.tryParse(_extraAmountController.text) ?? 0.0;
    final extraLabel = _extraLabelController.text.trim();

    await widget.ref.read(packagesNotifierProvider.notifier).markDelivered(
          widget.package.id,
          tips: tips,
          extraAmount: extraAmount,
          extraLabel: extraLabel.isEmpty ? null : extraLabel,
          deliveryPhotoPath: _deliveryPhotoPath,
          signaturePath: _signaturePath,
        );

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: OffsetShadowCard(
        backgroundColor: tokens.surface,
        shadowColor: tokens.border,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Icon(Icons.check_circle_outline_rounded,
                      color: AppStatusColors.success, size: 22),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Confirm Delivery',
                      style: TextStyle(
                          fontFamily: 'Syne',
                          fontWeight: FontWeight.bold,
                          fontSize: 16),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '#${widget.package.trackingNumber}',
                style: TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 12,
                  color: tokens.textSubtle,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // COD Amount display (for reference)
              if (_isCod) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: tokens.surfaceAlt,
                    border: Border.all(color: tokens.border, width: 1.5),
                    borderRadius: BorderRadius.zero,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'COD AMOUNT',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      Text(
                        '₱${_codAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          fontFamily: 'JetBrains Mono',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Amount Received input
                Text(
                  'AMOUNT RECEIVED',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: tokens.textSubtle,
                      letterSpacing: 0.5),
                ),
                const SizedBox(height: 6),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.zero,
                    boxShadow: [AppShadows.offsetSm(tokens.shadowColor)],
                  ),
                  child: TextField(
                    controller: _amountReceivedController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      hintText: 'e.g. 1500',
                      prefixText: '₱ ',
                    ),
                    style: const TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                    onChanged: (_) => _recalculateTip(),
                  ),
                ),
                const SizedBox(height: 12),

                // Auto-calculated Tip (read-only)
                Text(
                  'TIP (AUTO-CALCULATED)',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: tokens.textSubtle,
                      letterSpacing: 0.5),
                ),
                const SizedBox(height: 6),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.zero,
                    boxShadow: [AppShadows.offsetSm(tokens.shadowColor)],
                  ),
                  child: TextField(
                    controller: _tipsController,
                    readOnly: true,
                    decoration: const InputDecoration(
                      prefixText: '₱ ',
                    ),
                    style: TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppStatusColors.success,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Prepaid: manual tip input
              if (!_isCod) ...[
                Text(
                  'TIPS RECEIVED',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: tokens.textSubtle,
                      letterSpacing: 0.5),
                ),
                const SizedBox(height: 6),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.zero,
                    boxShadow: [AppShadows.offsetSm(tokens.shadowColor)],
                  ),
                  child: TextField(
                    controller: _tipsController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      hintText: '0',
                      prefixText: '₱ ',
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Extra Amount + Label
              Text(
                'EXTRA FEES',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: tokens.textSubtle,
                    letterSpacing: 0.5),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.zero,
                        boxShadow: [AppShadows.offsetSm(tokens.shadowColor)],
                      ),
                      child: TextField(
                        controller: _extraAmountController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Amount (₱)',
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 4,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.zero,
                        boxShadow: [AppShadows.offsetSm(tokens.shadowColor)],
                      ),
                      child: TextField(
                        controller: _extraLabelController,
                        decoration: const InputDecoration(
                          labelText: 'Label',
                          hintText: 'e.g. Parking fee',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Delivery Evidence Photo
              Text(
                'DELIVERY EVIDENCE PHOTO',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: tokens.textSubtle,
                    letterSpacing: 0.5),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: tokens.surfaceAlt,
                  border: Border.all(color: tokens.border, width: 1.5),
                  borderRadius: BorderRadius.zero,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        border: Border.all(color: tokens.border, width: 1.5),
                        color: tokens.surface,
                      ),
                      child: _deliveryPhotoPath != null &&
                              File(_deliveryPhotoPath!).existsSync()
                          ? Image.file(
                              File(_deliveryPhotoPath!),
                              fit: BoxFit.cover,
                            )
                          : Icon(Icons.receipt_long_outlined,
                              color: tokens.textSubtle, size: 22),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _deliveryPhotoPath != null
                                ? 'Evidence Captured'
                                : 'No Photo Yet',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _deliveryPhotoPath != null
                                ? 'Saved locally'
                                : 'Photo of amount received',
                            style: TextStyle(
                                fontSize: 10, color: tokens.textSubtle),
                          ),
                        ],
                      ),
                    ),
                    OffsetShadowButton.icon(
                      variant: OffsetButtonVariant.outlined,
                      onPressed: _takeDeliveryPhoto,
                      icon: Icon(
                        _deliveryPhotoPath != null
                            ? Icons.cached_rounded
                            : Icons.camera_alt_rounded,
                        size: 16,
                      ),
                      label: Text(
                        _deliveryPhotoPath != null ? 'RETAKE' : 'TAKE',
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Signature Capture Widget
              SignatureCaptureWidget(
                onSignatureSaved: (path) {
                  setState(() {
                    _signaturePath = path;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Grand Total
              Container(
                decoration: BoxDecoration(
                  color: tokens.surfaceAlt,
                  border: Border.all(color: tokens.border, width: 1.5),
                  borderRadius: BorderRadius.zero,
                ),
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'TOTAL COLLECTED',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    Text(
                      '₱${_getGrandTotal().toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        fontFamily: 'JetBrains Mono',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed:
                        _isSubmitting ? null : () => Navigator.pop(context),
                    style: TextButton.styleFrom(foregroundColor: AppStatusColors.error),
                    child: const Text('CANCEL', textAlign: TextAlign.center),
                  ),
                  const SizedBox(width: 8),
                  OffsetShadowButton.elevated(
                    backgroundColor: AppStatusColors.success,
                    foregroundColor: Colors.white,
                    onPressed: _isSubmitting ? null : _confirmDelivery,
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('CONFIRM DELIVERY'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SignatureCaptureWidget extends StatefulWidget {
  final Function(String?) onSignatureSaved;

  const SignatureCaptureWidget({super.key, required this.onSignatureSaved});

  @override
  State<SignatureCaptureWidget> createState() => _SignatureCaptureWidgetState();
}

class _SignatureCaptureWidgetState extends State<SignatureCaptureWidget> {
  final GlobalKey _boundaryKey = GlobalKey();
  final List<Offset?> _points = [];

  void _clear() {
    setState(() {
      _points.clear();
    });
    widget.onSignatureSaved(null);
  }

  Future<void> _exportSignature() async {
    if (_points.isEmpty) return;
    try {
      final boundary = _boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final bytes = byteData.buffer.asUint8List();
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/sig_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(bytes);
      widget.onSignatureSaved(file.path);
    } catch (e) {
      debugPrint('Error exporting signature: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'CUSTOMER SIGNATURE',
              style: TextStyle(
                color: tokens.textSubtle,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
            GestureDetector(
              onTap: _clear,
              child: Text(
                'CLEAR',
                style: TextStyle(
                  color: AppStatusColors.error,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onPanUpdate: (details) {
            final RenderBox referenceBox = context.findRenderObject() as RenderBox;
            final localPosition = referenceBox.globalToLocal(details.globalPosition);
            setState(() {
              _points.add(localPosition);
            });
          },
          onPanEnd: (details) {
            _points.add(null);
            _exportSignature();
          },
          child: RepaintBoundary(
            key: _boundaryKey,
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                color: tokens.bg,
                border: Border.all(color: tokens.border, width: 2.0),
              ),
              child: ClipRect(
                child: CustomPaint(
                  painter: _SignaturePainter(_points, tokens.text),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SignaturePainter extends CustomPainter {
  final List<Offset?> points;
  final Color strokeColor;

  _SignaturePainter(this.points, this.strokeColor);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = strokeColor
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        final p1 = Offset(points[i]!.dx.clamp(0.0, size.width), points[i]!.dy.clamp(0.0, size.height));
        final p2 = Offset(points[i+1]!.dx.clamp(0.0, size.width), points[i+1]!.dy.clamp(0.0, size.height));
        paint.strokeWidth = 3.0;
        canvas.drawLine(p1, p2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) => true;
}
