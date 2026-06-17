import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
// CHANGED: Import Google ML Kit Text Recognition for OCR scanning
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../../core/database/db_helper.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../shared/widgets/offset_shadow_card.dart';
import '../../shared/widgets/offset_shadow_button.dart';
import '../map/pin_picker_sheet.dart';
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

  String _paymentType = 'cod_cash';
  double? _lat;
  double? _lng;
  String? _photoPath;

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
    _cityController = TextEditingController(text: p?.city ?? 'Claveria'); // Default PH City

    _codCashController = TextEditingController(text: p?.codCash.toString() ?? '0');
    _codDigitalController = TextEditingController(text: p?.codDigital.toString() ?? '0');

    _paymentType = p?.paymentType ?? 'cod_cash';
    _lat = p?.lat;
    _lng = p?.lng;
    _photoPath = p?.photoPath;
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
    super.dispose();
  }

  Future<void> _pickLocationOnMap() async {
    final initialPos = _lat != null && _lng != null
        ? LatLng(_lat!, _lng!)
        : const LatLng(8.6074, 124.8957); // Default Claveria coords

    final LatLng? pickedLocation = await showModalBottomSheet<LatLng>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return PinPickerSheet(initialLocation: initialPos);
      },
    );

    if (pickedLocation != null) {
      setState(() {
        _lat = pickedLocation.latitude;
        _lng = pickedLocation.longitude;
      });

      try {
        final placemarks = await geo.placemarkFromCoordinates(
          pickedLocation.latitude,
          pickedLocation.longitude,
        );
        if (placemarks.isNotEmpty && mounted) {
          final place = placemarks.first;
          final finalBarangay = place.subLocality ?? '';
          final finalCity = place.locality ?? '';
          String finalStreet = place.street ?? '';
          if (finalStreet == finalBarangay || finalStreet == finalCity) {
            finalStreet = place.thoroughfare ?? '';
          }

          bool autoFilled = false;
          if (_streetController.text.trim().isEmpty && finalStreet.isNotEmpty) {
            _streetController.text = finalStreet;
            autoFilled = true;
          }
          if (_barangayController.text.trim().isEmpty && finalBarangay.isNotEmpty) {
            _barangayController.text = finalBarangay;
            autoFilled = true;
          }
          if ((_cityController.text.trim().isEmpty || _cityController.text.trim() == 'Claveria') && finalCity.isNotEmpty) {
            _cityController.text = finalCity;
            autoFilled = true;
          }

          if (autoFilled && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Address details auto-filled from pinned location.'),
                duration: Duration(seconds: 2),
              ),
            );
          }
        }
      } catch (e) {
        debugPrint('Geocoding error: $e');
      }
    }
  }

  Future<void> _takePhoto() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );
      if (image != null) {
        final appDir = await getApplicationDocumentsDirectory();
        final trackingNum = _trackingController.text.trim();
        final filename = 'parcel_${trackingNum.isEmpty ? const Uuid().v4() : trackingNum}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final savedFile = await File(image.path).copy('${appDir.path}/$filename');
        
        setState(() {
          _photoPath = savedFile.path;
        });

        // CHANGED: Automatically run OCR on the captured parcel photo to auto-populate fields
        await _runOcrOnPhoto(savedFile.path);
      }
    } catch (e) {
      debugPrint('Error taking photo: $e');
    }
  }

  // CHANGED: Process the photo with ML Kit Text Recognition to extract details
  Future<void> _runOcrOnPhoto(String imagePath) async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ),
            SizedBox(width: 12),
            Text('Processing label OCR...'),
          ],
        ),
        duration: Duration(seconds: 2),
      ),
    );

    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
      await textRecognizer.close();

      final text = recognizedText.text;
      if (text.isEmpty) return;

      String? parsedName;
      String? parsedPhone;
      double? parsedCodAmount;
      String? parsedStreet;
      String? parsedZone;
      String? parsedBarangay;
      String? parsedCity;

      // 1. Phone parsing: match (09|\+63|63)\d{9} or \d{4}[- ]\d{3}[- ]\d{4}
      final phoneRegex = RegExp(r'\b(?:09|\+639|639)\d{9}\b|\b\d{4}[- ]?\d{3}[- ]?\d{4}\b');
      final phoneMatch = phoneRegex.firstMatch(text);
      if (phoneMatch != null) {
        parsedPhone = phoneMatch.group(0)?.replaceAll(RegExp(r'[- ]'), '');
        // Normalize starting with 639 or +639 to 09
        if (parsedPhone != null) {
          if (parsedPhone.startsWith('+639')) {
            parsedPhone = '09${parsedPhone.substring(4)}';
          } else if (parsedPhone.startsWith('639')) {
            parsedPhone = '09${parsedPhone.substring(3)}';
          }
        }
      }

      // 2. COD amount parsing:
      // Search for keywords COD, Cash on Delivery, Collect, PHP, ₱ followed by numbers
      final codRegex = RegExp(
        r'\b(?:cod|collect|collectable|amount|php|₱)\b\s*[:=-]?\s*(?:php|₱)?\s*([0-9,]+(?:\.[0-9]{1,2})?)',
        caseSensitive: false,
      );
      final codMatches = codRegex.allMatches(text);
      for (final match in codMatches) {
        final amtStr = match.group(1)?.replaceAll(',', '');
        if (amtStr != null) {
          final parsed = double.tryParse(amtStr);
          if (parsed != null && parsed > 0) {
            parsedCodAmount = parsed;
            break;
          }
        }
      }

      // 3. Name parsing: lines starting with or containing "To:", "Consignee:", "Receiver:", "Name:"
      final lines = text.split('\n');
      final namePrefixRegex = RegExp(
        r'^\s*(?:to|name|consignee|receiver|recipient)\s*[:=-]\s*(.*)$',
        caseSensitive: false,
      );
      for (final line in lines) {
        final match = namePrefixRegex.firstMatch(line);
        if (match != null) {
          final candidate = match.group(1)?.trim();
          if (candidate != null && candidate.isNotEmpty && candidate.length > 2) {
            parsedName = candidate;
            break;
          }
        }
      }

      // 4. Address parsing:
      // Zone / Purok
      final zoneRegex = RegExp(r'\b(?:zone|purok|puk|pk)\s*([0-9a-zA-Z\-]+)', caseSensitive: false);
      final zoneMatch = zoneRegex.firstMatch(text);
      if (zoneMatch != null) {
        parsedZone = zoneMatch.group(0)?.trim();
      }

      // Barangay search: try to match against database or local Claveria barangays list
      final packagesState = ref.read(packagesNotifierProvider);
      final dbBarangays = packagesState.uniqueBarangays;
      const defaultBarangays = [
        'Ani-e', 'Cabacungan', 'Gumaod', 'Hinaplanan', 'Kalawihon', 'Lanise',
        'Libertad', 'Madaguing', 'Malagana', 'Minsacopa', 'Patrocinio', 'Plaridel',
        'Poblacion', 'Punong', 'Rizal', 'Santa Cruz', 'Tamboboan', 'Tipolohon'
      ];
      final barangaysToSearch = dbBarangays.isNotEmpty ? dbBarangays : defaultBarangays;
      for (final b in barangaysToSearch) {
        if (b.isNotEmpty && text.toLowerCase().contains(b.toLowerCase())) {
          parsedBarangay = b;
          break;
        }
      }

      // City search
      final dbCities = packagesState.uniqueCities;
      final citiesToSearch = dbCities.isNotEmpty ? dbCities : ['Claveria', 'Gingoog', 'Cagayan de Oro'];
      for (final c in citiesToSearch) {
        if (c.isNotEmpty && text.toLowerCase().contains(c.toLowerCase())) {
          parsedCity = c;
          break;
        }
      }

      // Street Address parsing
      final streetRegex = RegExp(
        r'.*?\b(?:st\.?|street|rd\.?|road|ave\.?|avenue|blvd\.?|boulevard|highway|h-way)\b.*',
        caseSensitive: false,
      );
      final streetMatch = streetRegex.firstMatch(text);
      if (streetMatch != null) {
        parsedStreet = streetMatch.group(0)?.trim();
      }

      if (parsedStreet == null || parsedStreet.isEmpty) {
        for (final line in lines) {
          final lower = line.toLowerCase();
          if (lower.contains('address') || lower.contains('ship to') || lower.contains('deliver to')) {
            parsedStreet = line.replaceAll(
              RegExp(r'^\s*(?:address|ship to|deliver to)\s*[:=-]\s*', caseSensitive: false),
              '',
            ).trim();
            break;
          }
        }
      }

      // Apply the parsed values to controllers
      if (mounted) {
        setState(() {
          if (parsedName != null && parsedName.isNotEmpty) {
            _nameController.text = parsedName;
          }
          if (parsedPhone != null && parsedPhone.isNotEmpty) {
            _phoneController.text = parsedPhone;
          }
          if (parsedCodAmount != null && parsedCodAmount > 0) {
            _paymentType = 'cod_cash';
            _codCashController.text = parsedCodAmount.toStringAsFixed(2);
            _codDigitalController.text = '0';
          } else {
            _paymentType = 'prepaid';
            _codCashController.text = '0';
            _codDigitalController.text = '0';
          }
          if (parsedStreet != null && parsedStreet.isNotEmpty) {
            var cleanStreet = parsedStreet;
            if (parsedBarangay != null && parsedBarangay.isNotEmpty) {
              cleanStreet = cleanStreet.replaceAll(RegExp(parsedBarangay, caseSensitive: false), '');
            }
            if (parsedCity != null && parsedCity.isNotEmpty) {
              cleanStreet = cleanStreet.replaceAll(RegExp(parsedCity, caseSensitive: false), '');
            }
            cleanStreet = cleanStreet.replaceAll(RegExp(r'^[,\s\-]+|[,\s\-]+$'), '').trim();
            if (cleanStreet.isNotEmpty) {
              _streetController.text = cleanStreet;
            }
          }
          if (parsedZone != null && parsedZone.isNotEmpty) {
            _zoneController.text = parsedZone;
          }
          if (parsedBarangay != null && parsedBarangay.isNotEmpty) {
            _barangayController.text = parsedBarangay;
          }
          if (parsedCity != null && parsedCity.isNotEmpty) {
            _cityController.text = parsedCity;
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Form auto-populated from scanned label details.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error during OCR processing: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to process label OCR: $e'),
            backgroundColor: AppStatusColors.error,
          ),
        );
      }
    }
  }

  double _getGrandTotal() {
    final cash = double.tryParse(_codCashController.text) ?? 0.0;
    final digital = double.tryParse(_codDigitalController.text) ?? 0.0;
    return cash + digital;
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
        tips: 0,
        extraAmount: 0,
        extraLabel: null,
        status: 'pending',
        sortOrder: 0, // Auto computed in DB helper
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        photoPath: _photoPath,
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
        tips: p.tips,
        extraAmount: p.extraAmount,
        extraLabel: p.extraLabel,
        updatedAt: DateTime.now(),
        photoPath: _photoPath,
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
            // CHANGED: Moved Parcel Photo section to the top of the form layout
            // Parcel Photo Section
            Text(
              'PARCEL PHOTO',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: tokens.textSubtle, letterSpacing: 0.5),
            ),
            const SizedBox(height: 8),
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
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      border: Border.all(color: tokens.border, width: 1.5),
                      color: tokens.surface,
                    ),
                    child: _photoPath != null && File(_photoPath!).existsSync()
                        ? Image.file(
                            File(_photoPath!),
                            fit: BoxFit.cover,
                          )
                        : Icon(Icons.camera_alt_outlined, color: tokens.textSubtle),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _photoPath != null ? 'Parcel Photo Captured' : 'No Photo Captured',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _photoPath != null ? 'Saved locally' : 'Take a photo of the parcel',
                          style: TextStyle(fontSize: 11, color: tokens.textSubtle),
                        ),
                      ],
                    ),
                  ),
                  OffsetShadowButton.icon(
                    variant: OffsetButtonVariant.outlined,
                    onPressed: _takePhoto,
                    icon: Icon(_photoPath != null ? Icons.cached_rounded : Icons.camera_alt_rounded),
                    label: Text(_photoPath != null ? 'RETAKE' : 'TAKE PHOTO'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

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
            LayoutBuilder(
              builder: (context, constraints) {
                return Autocomplete<String>(
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text.isEmpty) {
                      return const Iterable<String>.empty();
                    }
                    final suggestions = ref.read(packagesNotifierProvider).uniqueStreets;
                    return suggestions.where((option) =>
                        option.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                  },
                  onSelected: (String selection) {
                    _streetController.text = selection;
                  },
                  optionsViewBuilder: (context, onSelected, options) {
                    return Align(
                      alignment: Alignment.topLeft,
                      child: Material(
                        elevation: 0,
                        color: Colors.transparent,
                        child: Container(
                          width: constraints.maxWidth,
                          constraints: const BoxConstraints(maxHeight: 200),
                          margin: const EdgeInsets.only(top: 4),
                          decoration: BoxDecoration(
                            color: tokens.surface,
                            border: Border.all(color: tokens.border, width: 2.0),
                            boxShadow: [
                              BoxShadow(
                                color: tokens.shadowColor,
                                offset: const Offset(3, 3),
                                blurRadius: 0,
                              ),
                            ],
                          ),
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            itemCount: options.length,
                            itemBuilder: (BuildContext context, int index) {
                              final String option = options.elementAt(index);
                              return InkWell(
                                onTap: () => onSelected(option),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        color: index == options.length - 1 ? Colors.transparent : tokens.border,
                                        width: 1.0,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    option,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: tokens.text,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                  fieldViewBuilder: (context, fieldController, focusNode, onFieldSubmitted) {
                    if (fieldController.text != _streetController.text) {
                      fieldController.text = _streetController.text;
                    }
                    return Container(
                      decoration: BoxDecoration(borderRadius: BorderRadius.zero, boxShadow: [AppShadows.offsetSm(tokens.shadowColor)]),
                      child: TextFormField(
                        controller: fieldController,
                        focusNode: focusNode,
                        onFieldSubmitted: (_) => onFieldSubmitted(),
                        onChanged: (val) {
                          _streetController.text = val;
                        },
                        decoration: const InputDecoration(
                          labelText: 'Street Address',
                          hintText: 'e.g. House 12, St. Jude Street',
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                return Autocomplete<String>(
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text.isEmpty) {
                      return const Iterable<String>.empty();
                    }
                    final suggestions = ref.read(packagesNotifierProvider).uniqueZones;
                    return suggestions.where((option) =>
                        option.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                  },
                  onSelected: (String selection) {
                    _zoneController.text = selection;
                  },
                  optionsViewBuilder: (context, onSelected, options) {
                    return Align(
                      alignment: Alignment.topLeft,
                      child: Material(
                        elevation: 0,
                        color: Colors.transparent,
                        child: Container(
                          width: constraints.maxWidth,
                          constraints: const BoxConstraints(maxHeight: 200),
                          margin: const EdgeInsets.only(top: 4),
                          decoration: BoxDecoration(
                            color: tokens.surface,
                            border: Border.all(color: tokens.border, width: 2.0),
                            boxShadow: [
                              BoxShadow(
                                color: tokens.shadowColor,
                                offset: const Offset(3, 3),
                                blurRadius: 0,
                              ),
                            ],
                          ),
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            itemCount: options.length,
                            itemBuilder: (BuildContext context, int index) {
                              final String option = options.elementAt(index);
                              return InkWell(
                                onTap: () => onSelected(option),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        color: index == options.length - 1 ? Colors.transparent : tokens.border,
                                        width: 1.0,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    option,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: tokens.text,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                  fieldViewBuilder: (context, fieldController, focusNode, onFieldSubmitted) {
                    if (fieldController.text != _zoneController.text) {
                      fieldController.text = _zoneController.text;
                    }
                    return Container(
                      decoration: BoxDecoration(borderRadius: BorderRadius.zero, boxShadow: [AppShadows.offsetSm(tokens.shadowColor)]),
                      child: TextFormField(
                        controller: fieldController,
                        focusNode: focusNode,
                        onFieldSubmitted: (_) => onFieldSubmitted(),
                        onChanged: (val) {
                          _zoneController.text = val;
                        },
                        decoration: const InputDecoration(
                          labelText: 'Zone / Purok',
                          hintText: 'e.g. Zone 4',
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Autocomplete<String>(
                        optionsBuilder: (TextEditingValue textEditingValue) {
                          if (textEditingValue.text.isEmpty) {
                            return const Iterable<String>.empty();
                          }
                          final suggestions = ref.read(packagesNotifierProvider).uniqueBarangays;
                          return suggestions.where((option) =>
                              option.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                        },
                        onSelected: (String selection) {
                          _barangayController.text = selection;
                        },
                        optionsViewBuilder: (context, onSelected, options) {
                          return Align(
                            alignment: Alignment.topLeft,
                            child: Material(
                              elevation: 0,
                              color: Colors.transparent,
                              child: Container(
                                width: constraints.maxWidth,
                                constraints: const BoxConstraints(maxHeight: 200),
                                margin: const EdgeInsets.only(top: 4),
                                decoration: BoxDecoration(
                                  color: tokens.surface,
                                  border: Border.all(color: tokens.border, width: 2.0),
                                  boxShadow: [
                                    BoxShadow(
                                      color: tokens.shadowColor,
                                      offset: const Offset(3, 3),
                                      blurRadius: 0,
                                    ),
                                  ],
                                ),
                                child: ListView.builder(
                                  padding: EdgeInsets.zero,
                                  shrinkWrap: true,
                                  itemCount: options.length,
                                  itemBuilder: (BuildContext context, int index) {
                                    final String option = options.elementAt(index);
                                    return InkWell(
                                      onTap: () => onSelected(option),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                        decoration: BoxDecoration(
                                          border: Border(
                                            bottom: BorderSide(
                                              color: index == options.length - 1 ? Colors.transparent : tokens.border,
                                              width: 1.0,
                                            ),
                                          ),
                                        ),
                                        child: Text(
                                          option,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: tokens.text,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                        fieldViewBuilder: (context, fieldController, focusNode, onFieldSubmitted) {
                          if (fieldController.text != _barangayController.text) {
                            fieldController.text = _barangayController.text;
                          }
                          return Container(
                            decoration: BoxDecoration(borderRadius: BorderRadius.zero, boxShadow: [AppShadows.offsetSm(tokens.shadowColor)]),
                            child: TextFormField(
                              controller: fieldController,
                              focusNode: focusNode,
                              onFieldSubmitted: (_) => onFieldSubmitted(),
                              onChanged: (val) {
                                _barangayController.text = val;
                              },
                              decoration: const InputDecoration(
                                labelText: 'Barangay',
                                hintText: 'e.g. Kauswagan',
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Autocomplete<String>(
                        optionsBuilder: (TextEditingValue textEditingValue) {
                          if (textEditingValue.text.isEmpty) {
                            return const Iterable<String>.empty();
                          }
                          final suggestions = ref.read(packagesNotifierProvider).uniqueCities;
                          return suggestions.where((option) =>
                              option.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                        },
                        onSelected: (String selection) {
                          _cityController.text = selection;
                        },
                        optionsViewBuilder: (context, onSelected, options) {
                          return Align(
                            alignment: Alignment.topLeft,
                            child: Material(
                              elevation: 0,
                              color: Colors.transparent,
                              child: Container(
                                width: constraints.maxWidth,
                                constraints: const BoxConstraints(maxHeight: 200),
                                margin: const EdgeInsets.only(top: 4),
                                decoration: BoxDecoration(
                                  color: tokens.surface,
                                  border: Border.all(color: tokens.border, width: 2.0),
                                  boxShadow: [
                                    BoxShadow(
                                      color: tokens.shadowColor,
                                      offset: const Offset(3, 3),
                                      blurRadius: 0,
                                    ),
                                  ],
                                ),
                                child: ListView.builder(
                                  padding: EdgeInsets.zero,
                                  shrinkWrap: true,
                                  itemCount: options.length,
                                  itemBuilder: (BuildContext context, int index) {
                                    final String option = options.elementAt(index);
                                    return InkWell(
                                      onTap: () => onSelected(option),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                        decoration: BoxDecoration(
                                          border: Border(
                                            bottom: BorderSide(
                                              color: index == options.length - 1 ? Colors.transparent : tokens.border,
                                              width: 1.0,
                                            ),
                                          ),
                                        ),
                                        child: Text(
                                          option,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: tokens.text,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                        fieldViewBuilder: (context, fieldController, focusNode, onFieldSubmitted) {
                          if (fieldController.text != _cityController.text) {
                            fieldController.text = _cityController.text;
                          }
                          return Container(
                            decoration: BoxDecoration(borderRadius: BorderRadius.zero, boxShadow: [AppShadows.offsetSm(tokens.shadowColor)]),
                            child: TextFormField(
                              controller: fieldController,
                              focusNode: focusNode,
                              onFieldSubmitted: (_) => onFieldSubmitted(),
                              onChanged: (val) {
                                _cityController.text = val;
                              },
                              decoration: const InputDecoration(
                                labelText: 'City *',
                                hintText: 'e.g. Claveria',
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) return 'City is required';
                                return null;
                              },
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: tokens.surfaceAlt,
                border: Border.all(color: tokens.border, width: 1.5),
                borderRadius: BorderRadius.zero,
              ),
              child: Row(
                children: [
                  Icon(
                    _lat != null && _lng != null ? Icons.location_on_rounded : Icons.location_off_rounded,
                    color: _lat != null && _lng != null ? tokens.accent : tokens.textSubtle,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _lat != null && _lng != null ? 'Location Coordinates Pinned' : 'No Location Pinned',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        if (_lat != null && _lng != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            '${_lat!.toStringAsFixed(6)}, ${_lng!.toStringAsFixed(6)}',
                            style: TextStyle(fontFamily: 'JetBrains Mono', fontSize: 11, color: tokens.textSubtle),
                          ),
                        ],
                      ],
                    ),
                  ),
                  OffsetShadowButton.icon(
                    variant: OffsetButtonVariant.outlined,
                    onPressed: _pickLocationOnMap,
                    icon: Icon(_lat != null && _lng != null ? Icons.edit_location_alt_rounded : Icons.pin_drop_rounded),
                    label: Text(_lat != null && _lng != null ? 'CHANGE PIN' : 'PIN ON MAP'),
                  ),
                ],
              ),
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
                    'COD AMOUNT',
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
