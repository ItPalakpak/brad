import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/database/db_helper.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../shared/widgets/offset_shadow_card.dart';
import 'packages_provider.dart';

class PackageForm extends ConsumerStatefulWidget {
  final Package? package;
  final String? initialTrackingNumber;
  final VoidCallback onSaved;

  const PackageForm({
    super.key,
    this.package,
    this.initialTrackingNumber,
    required this.onSaved,
  });

  @override
  ConsumerState<PackageForm> createState() => _PackageFormState();
}

class _PackageFormState extends ConsumerState<PackageForm> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _trackingController;
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _notesController;
  late TextEditingController _streetController;
  late TextEditingController _zoneController;
  late TextEditingController _barangayController;
  late TextEditingController _cityController;

  late TextEditingController _codCashController;
  late TextEditingController _codDigitalController;
  late TextEditingController _tipsController;
  late TextEditingController _extraAmountController;
  late TextEditingController _extraLabelController;

  String _paymentType = 'cod_cash';
  double? _lat;
  double? _lng;

  @override
  void initState() {
    super.initState();
    final p = widget.package;

    _trackingController = TextEditingController(text: p?.trackingNumber ?? widget.initialTrackingNumber ?? '');
    _nameController = TextEditingController(text: p?.receiverName ?? '');
    _phoneController = TextEditingController(text: p?.receiverPhone ?? '');
    _notesController = TextEditingController(text: p?.notes ?? '');
    
    _streetController = TextEditingController(text: p?.street ?? '');
    _zoneController = TextEditingController(text: p?.zone ?? '');
    _barangayController = TextEditingController(text: p?.barangay ?? '');
    _cityController = TextEditingController(text: p?.city ?? 'Cagayan de Oro'); // Default PH City

    _codCashController = TextEditingController(text: p?.codCash.toString() ?? '0');
    _codDigitalController = TextEditingController(text: p?.codDigital.toString() ?? '0');
    _tipsController = TextEditingController(text: p?.tips.toString() ?? '0');
    _extraAmountController = TextEditingController(text: p?.extraAmount.toString() ?? '0');
    _extraLabelController = TextEditingController(text: p?.extraLabel ?? '');

    _paymentType = p?.paymentType ?? 'cod_cash';
    _lat = p?.lat;
    _lng = p?.lng;
  }

  @override
  void dispose() {
    _trackingController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    _streetController.dispose();
    _zoneController.dispose();
    _barangayController.dispose();
    _cityController.dispose();
    _codCashController.dispose();
    _codDigitalController.dispose();
    _tipsController.dispose();
    _extraAmountController.dispose();
    _extraLabelController.dispose();
    super.dispose();
  }

  double _getGrandTotal() {
    final cash = double.tryParse(_codCashController.text) ?? 0.0;
    final digital = double.tryParse(_codDigitalController.text) ?? 0.0;
    final tips = double.tryParse(_tipsController.text) ?? 0.0;
    final extra = double.tryParse(_extraAmountController.text) ?? 0.0;
    return cash + digital + tips + extra;
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final tracking = _trackingController.text.trim();
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final notes = _notesController.text.trim();
    final street = _streetController.text.trim();
    final zone = _zoneController.text.trim();
    final barangay = _barangayController.text.trim();
    final city = _cityController.text.trim();

    final codCash = double.tryParse(_codCashController.text) ?? 0.0;
    final codDigital = double.tryParse(_codDigitalController.text) ?? 0.0;
    final tips = double.tryParse(_tipsController.text) ?? 0.0;
    final extraAmount = double.tryParse(_extraAmountController.text) ?? 0.0;
    final extraLabel = _extraLabelController.text.trim();

    final p = widget.package;
    final notifier = ref.read(packagesNotifierProvider.notifier);

    if (p == null) {
      // Create new package
      final newPkg = Package(
        id: const Uuid().v4(),
        trackingNumber: tracking,
        receiverName: name.isEmpty ? null : name,
        receiverPhone: phone.isEmpty ? null : phone,
        notes: notes.isEmpty ? null : notes,
        lat: _lat,
        lng: _lng,
        street: street.isEmpty ? null : street,
        zone: zone.isEmpty ? null : zone,
        barangay: barangay.isEmpty ? null : barangay,
        city: city.isEmpty ? null : city,
        paymentType: _paymentType,
        codCash: _paymentType == 'prepaid' ? 0.0 : codCash,
        codDigital: _paymentType == 'prepaid' ? 0.0 : codDigital,
        tips: tips,
        extraAmount: extraAmount,
        extraLabel: extraLabel.isEmpty ? null : extraLabel,
        status: 'pending',
        sortOrder: 0, // Auto computed in DB helper
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      notifier.addPackage(newPkg);
    } else {
      // Update existing
      final updatedPkg = p.copyWith(
        trackingNumber: tracking,
        receiverName: name.isEmpty ? null : name,
        receiverPhone: phone.isEmpty ? null : phone,
        notes: notes.isEmpty ? null : notes,
        lat: _lat,
        lng: _lng,
        street: street.isEmpty ? null : street,
        zone: zone.isEmpty ? null : zone,
        barangay: barangay.isEmpty ? null : barangay,
        city: city.isEmpty ? null : city,
        paymentType: _paymentType,
        codCash: _paymentType == 'prepaid' ? 0.0 : codCash,
        codDigital: _paymentType == 'prepaid' ? 0.0 : codDigital,
        tips: tips,
        extraAmount: extraAmount,
        extraLabel: extraLabel.isEmpty ? null : extraLabel,
        updatedAt: DateTime.now(),
      );
      notifier.updatePackage(updatedPkg);
    }

    widget.onSaved();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Package Basic Info Section
            Text(
              'PACKAGE DETAILS',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: tokens.textSubtle, letterSpacing: 0.5),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(borderRadius: BorderRadius.zero, boxShadow: [AppShadows.offsetSm(tokens.shadowColor)]),
              child: TextFormField(
                controller: _trackingController,
                readOnly: widget.package != null, // Tracking number is immutable after registration
                decoration: const InputDecoration(
                  labelText: 'Tracking Number *',
                  hintText: 'e.g. TRK-123456',
                ),
                style: const TextStyle(fontFamily: 'JetBrains Mono', fontWeight: FontWeight.bold),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Tracking number is required';
                  return null;
                },
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(borderRadius: BorderRadius.zero, boxShadow: [AppShadows.offsetSm(tokens.shadowColor)]),
              child: TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Receiver Name',
                  hintText: 'e.g. John Doe',
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(borderRadius: BorderRadius.zero, boxShadow: [AppShadows.offsetSm(tokens.shadowColor)]),
              child: TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Receiver Phone',
                  hintText: 'e.g. 09171234567',
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(borderRadius: BorderRadius.zero, boxShadow: [AppShadows.offsetSm(tokens.shadowColor)]),
              child: TextFormField(
                controller: _notesController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Delivery Notes / Landmark',
                  hintText: 'e.g. Leave with security guard',
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Location Section
            Text(
              'DELIVERY LOCATION',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: tokens.textSubtle, letterSpacing: 0.5),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(borderRadius: BorderRadius.zero, boxShadow: [AppShadows.offsetSm(tokens.shadowColor)]),
              child: TextFormField(
                controller: _streetController,
                decoration: const InputDecoration(
                  labelText: 'Street Address',
                  hintText: 'e.g. House 12, St. Jude Street',
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(borderRadius: BorderRadius.zero, boxShadow: [AppShadows.offsetSm(tokens.shadowColor)]),
              child: TextFormField(
                controller: _zoneController,
                decoration: const InputDecoration(
                  labelText: 'Zone / Purok',
                  hintText: 'e.g. Zone 4',
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(borderRadius: BorderRadius.zero, boxShadow: [AppShadows.offsetSm(tokens.shadowColor)]),
                    child: TextFormField(
                      controller: _barangayController,
                      decoration: const InputDecoration(
                        labelText: 'Barangay',
                        hintText: 'e.g. Kauswagan',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(borderRadius: BorderRadius.zero, boxShadow: [AppShadows.offsetSm(tokens.shadowColor)]),
                    child: TextFormField(
                      controller: _cityController,
                      decoration: const InputDecoration(
                        labelText: 'City *',
                        hintText: 'e.g. Cagayan de Oro',
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'City is required';
                        return null;
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Payment Section
            Text(
              'PAYMENT METHOD & FINANCIALS',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: tokens.textSubtle, letterSpacing: 0.5),
            ),
            const SizedBox(height: 8),
            // Segmented payment buttons
            Row(
              children: [
                _buildPaymentSelectButton('cod_cash', 'COD Cash'),
                const SizedBox(width: 8),
                _buildPaymentSelectButton('cod_digital', 'COD Digital'),
                const SizedBox(width: 8),
                _buildPaymentSelectButton('prepaid', 'Prepaid'),
              ],
            ),
            const SizedBox(height: 16),

            if (_paymentType != 'prepaid') ...[
              Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(borderRadius: BorderRadius.zero, boxShadow: [AppShadows.offsetSm(tokens.shadowColor)]),
                      child: TextFormField(
                        controller: _paymentType == 'cod_cash' ? _codCashController : _codDigitalController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: _paymentType == 'cod_cash' ? 'COD Cash Amount (₱) *' : 'COD Digital Amount (₱) *',
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],

            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(borderRadius: BorderRadius.zero, boxShadow: [AppShadows.offsetSm(tokens.shadowColor)]),
                    child: TextFormField(
                      controller: _tipsController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Tips Received (₱)',
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Container(
                    decoration: BoxDecoration(borderRadius: BorderRadius.zero, boxShadow: [AppShadows.offsetSm(tokens.shadowColor)]),
                    child: TextFormField(
                      controller: _extraAmountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Extra Amount (₱)',
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 4,
                  child: Container(
                    decoration: BoxDecoration(borderRadius: BorderRadius.zero, boxShadow: [AppShadows.offsetSm(tokens.shadowColor)]),
                    child: TextFormField(
                      controller: _extraLabelController,
                      decoration: const InputDecoration(
                        labelText: 'Extra Label',
                        hintText: 'e.g. Parking fee',
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),
            // Live Recomputed Grand Total
            Container(
              decoration: BoxDecoration(
                color: tokens.surfaceAlt,
                border: Border.all(color: tokens.border, width: 1.5),
                borderRadius: BorderRadius.zero,
              ),
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'TOTAL COLLECTED AMOUNT',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  Text(
                    '₱${_getGrandTotal().toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, fontFamily: 'JetBrains Mono'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
            OffsetShadowCard(
              backgroundColor: tokens.accent,
              shadowColor: tokens.border,
              padding: const EdgeInsets.symmetric(vertical: 14),
              onTap: _save,
              child: Center(
                child: Text(
                  widget.package == null ? 'CREATE PACKAGE' : 'SAVE CHANGES',
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
        ),
      ),
    );
  }

  Widget _buildPaymentSelectButton(String value, String label) {
    final tokens = context.tokens;
    final isSelected = _paymentType == value;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _paymentType = value;
          });
        },
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? tokens.accentSoft : tokens.surface,
            border: Border.all(color: tokens.border, width: 1.5),
            borderRadius: BorderRadius.zero,
            boxShadow: [
              BoxShadow(
                color: tokens.shadowColor,
                offset: const Offset(1.5, 1.5),
                blurRadius: 0,
              )
            ],
          ),
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: tokens.text,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
