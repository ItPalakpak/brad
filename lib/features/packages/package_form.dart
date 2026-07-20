import 'dart:io';
import 'dart:math';
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
import '../../core/services/location_service.dart';
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
  ConsumerState<PackageForm> createState() => PackageFormState();
}

class PackageFormState extends ConsumerState<PackageForm> {
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

  late FocusNode _nameFocusNode;
  late FocusNode _phoneFocusNode;

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
    _cityController = TextEditingController(text: p?.city ?? '');

    _codCashController = TextEditingController(text: p?.codCash.toString() ?? '0');
    _codDigitalController = TextEditingController(text: p?.codDigital.toString() ?? '0');

    _paymentType = p?.paymentType ?? 'cod_cash';
    _lat = p?.lat;
    _lng = p?.lng;
    _photoPath = p?.photoPath;

    _nameFocusNode = FocusNode();
    _phoneFocusNode = FocusNode();

    _nameFocusNode.addListener(() {
      if (!_nameFocusNode.hasFocus) {
        _checkAndFillFromArchive();
      }
    });

    _phoneFocusNode.addListener(() {
      if (!_phoneFocusNode.hasFocus) {
        _checkAndFillFromArchive();
      }
    });

    _phoneController.addListener(() {
      final text = _phoneController.text.trim();
      if (text.length == 11) {
        _checkAndFillFromArchive();
      }
    });
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
    _nameFocusNode.dispose();
    _phoneFocusNode.dispose();
    super.dispose();
  }

  Future<void> _pickLocationOnMap() async {
    // BUG-03 FIX: Use rider's current GPS location instead of hardcoded coordinates
    LatLng initialPos;
    if (_lat != null && _lng != null) {
      initialPos = LatLng(_lat!, _lng!);
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

  // CHANGED: Removed the automatic call to _runOcrOnPhoto so that capturing a parcel photo doesn't trigger OCR auto-population.
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
      }
    } catch (e) {
      debugPrint('Error taking photo: $e');
    }
  }

  // CHANGED: Public method to trigger OCR scan from external sources (Camera or Gallery)
  // Supports capturing/uploading multiple photos sequentially.
  Future<void> scanAndPopulateFields({required ImageSource source}) async {
    final ImagePicker picker = ImagePicker();
    final List<String> paths = [];
    try {
      if (source == ImageSource.gallery) {
        // CHANGED: Use pickMultiImage to allow uploading multiple photos from the gallery
        final List<XFile> images = await picker.pickMultiImage(
          imageQuality: 80,
        );
        if (images.isNotEmpty) {
          paths.addAll(images.map((img) => img.path));
        }
      } else {
        // Camera source: allow the rider to capture multiple photos sequentially
        bool captureMore = true;
        while (captureMore) {
          final XFile? image = await picker.pickImage(
            source: ImageSource.camera,
            imageQuality: 80,
          );
          if (image == null) break;
          paths.add(image.path);

          // Ask the rider if they want to capture another photo to aggregate details
          if (mounted) {
            final bool? another = await showDialog<bool>(
              context: context,
              builder: (context) => Dialog(
                backgroundColor: Colors.transparent,
                elevation: 0,
                child: OffsetShadowCard(
                  backgroundColor: context.tokens.surface,
                  shadowColor: context.tokens.border,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Capture Another Photo?',
                        style: TextStyle(
                          fontFamily: 'Syne',
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'You have captured ${paths.length} photo(s). Would you like to capture another photo to scan more details?',
                        style: TextStyle(fontSize: 13, color: context.tokens.textSubtle),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            style: TextButton.styleFrom(foregroundColor: AppStatusColors.error),
                            child: const Text('NO, SCAN NOW', textAlign: TextAlign.center),
                          ),
                          const SizedBox(width: 8),
                          OffsetShadowButton.elevated(
                            backgroundColor: context.tokens.accent,
                            foregroundColor: Colors.white,
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('YES, CAPTURE MORE'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
            captureMore = another == true;
          } else {
            captureMore = false;
          }
        }
      }

      if (paths.isNotEmpty) {
        await _runOcrOnPhotos(paths);
      }
    } catch (e) {
      debugPrint('Error during scan picker: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image for scan: $e'),
            backgroundColor: AppStatusColors.error,
          ),
        );
      }
    }
  }

  // CHANGED: Process multiple photos with ML Kit Text Recognition to extract and aggregate details
  Future<void> _runOcrOnPhotos(List<String> imagePaths) async {
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
      String? parsedName;
      String? parsedPhone;
      double? parsedCodAmount;
      String? parsedStreet;
      String? parsedZone;
      String? parsedBarangay;
      String? parsedCity;

      for (final path in imagePaths) {
        final inputImage = InputImage.fromFilePath(path);
        final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
        final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
        await textRecognizer.close();

        final List<TextLine> rawLines = [];
        for (final block in recognizedText.blocks) {
          rawLines.addAll(block.lines);
        }

        // Filter out diagonal lines (e.g. watermarked texts or rotated lines)
        final List<TextLine> horizontalLines = rawLines.where((line) {
          if (line.cornerPoints.length < 2) return true;
          final p1 = line.cornerPoints[0];
          final p2 = line.cornerPoints[1];
          final dx = p2.x - p1.x;
          final dy = p2.y - p1.y;
          final angleDeg = (atan2(dy.toDouble(), dx.toDouble()) * 180 / pi).abs();
          // If rotation angle is between 15 and 165 degrees, it's diagonal/vertical, so we filter it out
          return !(angleDeg > 15 && angleDeg < 165);
        }).toList();

        // Sort lines vertically from top to bottom
        horizontalLines.sort((a, b) => a.boundingBox.top.compareTo(b.boundingBox.top));

        // Find the first line containing 'sender' (case insensitive)
        int senderIndex = -1;
        for (int i = 0; i < horizontalLines.length; i++) {
          if (horizontalLines[i].text.toLowerCase().contains('sender')) {
            senderIndex = i;
            break;
          }
        }

        // Exclude the sender line and any lines below/after it
        final List<TextLine> filteredLines = senderIndex != -1
            ? horizontalLines.sublist(0, senderIndex)
            : horizontalLines;

        final String text = filteredLines.map((l) => l.text).join('\n');
        if (text.isEmpty) continue;

        // 1. Phone parsing: match (09|\+63|63)\d{9} or \d{4}[- ]\d{3}[- ]\d{4}
        if (parsedPhone == null || parsedPhone.isEmpty) {
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
        }

        // 2. COD amount parsing:
        // CHANGED: Multi-tiered COD amount parsing utilizing spatial bounding box vertical alignment coordinates
        // to associate the 'COD' label with its matching value column, avoiding 'COD Fee' or 'COD Transfer Fee' matches.
        double? extractedCod;
        final List<TextLine> allLines = filteredLines;

        // Find the main "COD" label line (contains "cod", but excludes "fee" or "transfer")
        TextLine? codLine;
        for (final line in allLines) {
          final txt = line.text.toLowerCase();
          if (txt.contains('cod') && !txt.contains('fee') && !txt.contains('transfer')) {
            codLine = line;
            break;
          }
        }

        if (codLine != null) {
          // Tier 1: Check if the COD line itself contains the value (e.g. "COD 2,590.00")
          final codSameLineRegex = RegExp(
            r'\bcod\b(?!\s*fee)(?!\s*transfer)\s*[:=-]?\s*(?:php|₱)?\s*([0-9,]+\.[0-9]{2})\b',
            caseSensitive: false,
          );
          final match = codSameLineRegex.firstMatch(codLine.text);
          if (match != null) {
            final amtStr = match.group(1)?.replaceAll(',', '');
            if (amtStr != null) {
              final parsed = double.tryParse(amtStr);
              if (parsed != null) {
                extractedCod = parsed;
              }
            }
          }

          // Tier 2: Check for a matching decimal value line on the same visual row (Y-axis alignment)
          if (extractedCod == null) {
            final codRect = codLine.boundingBox;
            final codCenterY = codRect.center.dy;
            final codHeight = codRect.height;
            double? bestMatchValue;
            double bestDistance = double.infinity;

            for (final line in allLines) {
              if (line == codLine) continue;
              final lineRect = line.boundingBox;
              final centerY = lineRect.center.dy;
              final verticalDist = (centerY - codCenterY).abs();

              // Check if Y center is within 70% of the COD label height
              if (verticalDist < codHeight * 0.7) {
                final cleanedText = line.text.trim();
                final priceRegex = RegExp(
                  r'^\s*(?:php|₱)?\s*([0-9,]+\.[0-9]{1,2})\s*$',
                  caseSensitive: false,
                );
                final match = priceRegex.firstMatch(cleanedText);
                if (match != null) {
                  final amtStr = match.group(1)?.replaceAll(',', '');
                  if (amtStr != null) {
                    final parsed = double.tryParse(amtStr);
                    if (parsed != null) {
                      if (verticalDist < bestDistance) {
                        bestDistance = verticalDist;
                        bestMatchValue = parsed;
                      }
                    }
                  }
                }
              }
            }
            if (bestMatchValue != null) {
              extractedCod = bestMatchValue;
            }
          }
        }

        // Tier 3: Fallback general keyword search on the entire text string
        if (extractedCod == null) {
          final codGeneralRegex = RegExp(
            r'\b(?:cod|collect|collectable)\b\s*[:=-]?\s*(?:php|₱)?\s*([0-9,]+(?:\.[0-9]{1,2})?)',
            caseSensitive: false,
          );
          final codMatches = codGeneralRegex.allMatches(text);
          for (final match in codMatches) {
            final amtStr = match.group(1)?.replaceAll(',', '');
            if (amtStr != null) {
              final parsed = double.tryParse(amtStr);
              if (parsed != null) {
                extractedCod = parsed;
                break;
              }
            }
          }
        }

        if (extractedCod != null) {
          parsedCodAmount = extractedCod;
        }

        // 3. Name parsing: lines starting with or containing "To:", "Consignee:", "Receiver:", "Name:"
        // CHANGED: Strip phone/contact numbers from the receiver name candidate to ensure only the name is auto-populated.
        if (parsedName == null || parsedName.isEmpty) {
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
                var cleanedName = candidate;
                final phoneStripRegex = RegExp(
                  r'\b(?:09|\+639|639)\d{9}\b|\b\d{4}[- ]?\d{3}[- ]?\d{4}\b|\b\d{9,12}\b',
                  caseSensitive: false,
                );
                cleanedName = cleanedName.replaceAll(phoneStripRegex, '').trim();
                cleanedName = cleanedName.replaceAll(RegExp(r'^[,\s\-]+|[,\s\-]+$'), '').trim();
                if (cleanedName.isNotEmpty) {
                  parsedName = cleanedName;
                  break;
                }
              }
            }
          }
        }

        // 4. Address parsing:
        // CHANGED: Standardize every zone/purok spelling to "Zone <Value>" and format sub-letters (e.g. 1-a -> 1A)
        if (parsedZone == null || parsedZone.isEmpty) {
          final zoneRegex = RegExp(r'\b(?:zone|purok|puk|pk)\s*([0-9a-zA-Z]+(?:\s*[-]?\s*[0-9a-zA-Z]+)*)', caseSensitive: false);
          final zoneMatch = zoneRegex.firstMatch(text);
          if (zoneMatch != null) {
            final rawValue = zoneMatch.group(1)?.trim() ?? '';
            final cleanedValue = rawValue.replaceAllMapped(
              RegExp(r'(\d+)\s*[-]?\s*([a-zA-Z])\b'),
              (match) => '${match.group(1)}${match.group(2)!.toUpperCase()}',
            ).replaceAll(RegExp(r'\s*[-]\s*'), '').toUpperCase();
            final tempZone = 'Zone $cleanedValue';
            if (RegExp(r'^Zone \d+[A-Z]?$', caseSensitive: false).hasMatch(tempZone)) {
              parsedZone = tempZone;
            }
          }
        }

        // Barangay search: try to match against database or local Claveria barangays list
        if (parsedBarangay == null || parsedBarangay.isEmpty) {
          final packagesState = ref.read(packagesNotifierProvider);
          final dbBarangays = packagesState.uniqueBarangays;
          const defaultBarangays = [
            'Ani-e', 'Cabacungan', 'Gumaod', 'Hinaplanan', 'Kalawihon', 'Lanise',
            'Libertad', 'Madaguing', 'Malagana', 'Minsacopa', 'Patrocinio', 'Plaridel',
            'Poblacion', 'Punong', 'Rizal', 'Santa Cruz', 'Tamboboan', 'Tipolohon'
          ];
          final barangaysToSearch = dbBarangays.isNotEmpty ? dbBarangays : defaultBarangays;
          for (final b in barangaysToSearch) {
            final escB = RegExp.escape(b);
            final brgyRegex = RegExp('\\b$escB\\b', caseSensitive: false);
            if (brgyRegex.hasMatch(text)) {
              parsedBarangay = b;
              break;
            }
          }
        }

        // City search
        if (parsedCity == null || parsedCity.isEmpty) {
          final packagesState = ref.read(packagesNotifierProvider);
          final dbCities = packagesState.uniqueCities;
          final citiesToSearch = dbCities.isNotEmpty ? dbCities : ['Claveria', 'Gingoog', 'Cagayan de Oro'];
          for (final c in citiesToSearch) {
            if (c.isNotEmpty && text.toLowerCase().contains(c.toLowerCase())) {
              parsedCity = c;
              break;
            }
          }
        }

        // Street Address parsing
        if (parsedStreet == null || parsedStreet.isEmpty) {
          final streetRegex = RegExp(
            r'.*?\b(?:st\.?|street|rd\.?|road|ave\.?|avenue|blvd\.?|boulevard|highway|h-way)\b.*',
            caseSensitive: false,
          );
          final streetMatch = streetRegex.firstMatch(text);
          if (streetMatch != null) {
            parsedStreet = streetMatch.group(0)?.trim();
          }

          if (parsedStreet == null || parsedStreet.isEmpty) {
            final lines = text.split('\n');
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

        await _checkAndFillFromArchive();
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

  Future<void> _checkAndFillFromArchive() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    if (name.isEmpty && phone.isEmpty) return;

    try {
      final archiveMap = await DbHelper.instance.lookupReceiverArchive(
        name.isNotEmpty ? name : null,
        phone.isNotEmpty ? phone : null,
      );

      if (archiveMap != null && mounted) {
        final archiveName = archiveMap['name'] as String;
        final archiveStreet = archiveMap['street'] as String?;
        final archiveBarangay = archiveMap['barangay'] as String?;
        final archiveCity = archiveMap['city'] as String?;
        final archiveLat = archiveMap['lat'] as double?;
        final archiveLng = archiveMap['lng'] as double?;

        setState(() {
          if (_lat == null && _lng == null) {
            _lat = archiveLat;
            _lng = archiveLng;
          }
          if (_streetController.text.trim().isEmpty && archiveStreet != null) {
            _streetController.text = archiveStreet;
          }
          if (_barangayController.text.trim().isEmpty && archiveBarangay != null) {
            _barangayController.text = archiveBarangay;
          }
          if ((_cityController.text.trim().isEmpty || _cityController.text.trim() == 'Claveria') && archiveCity != null) {
            _cityController.text = archiveCity;
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Auto-pinned location and address from archive for $archiveName.'),
            duration: const Duration(seconds: 2),
          ),
        );
      } else if (mounted) {
        // CHANGED: If no exact receiver archive found, look for nearby zone & barangay match as default pinning coordinates
        final zone = _zoneController.text.trim();
        final barangay = _barangayController.text.trim();
        if (barangay.isNotEmpty) {
          final nearMatches = await DbHelper.instance.findArchivesByZoneAndBarangay(
            zone.isNotEmpty ? zone : null,
            barangay,
          );
          if (nearMatches.isNotEmpty && mounted) {
            final bestMatch = nearMatches.first;
            setState(() {
              if (_lat == null && _lng == null) {
                _lat = (bestMatch['lat'] as num).toDouble();
                _lng = (bestMatch['lng'] as num).toDouble();
              }
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('No exact archive found. Pinned near matching ${zone.isNotEmpty ? "$zone, " : ""}$barangay.'),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error looking up receiver archive: $e');
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
                maxLength: 50,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Tracking number is required';
                  if (val.trim().length > 50) return 'Tracking number is too long';
                  return null;
                },
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(borderRadius: BorderRadius.zero, boxShadow: [AppShadows.offsetSm(tokens.shadowColor)]),
              child: TextFormField(
                controller: _nameController,
                focusNode: _nameFocusNode,
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
                focusNode: _phoneFocusNode,
                keyboardType: TextInputType.phone,
                maxLength: 13,
                decoration: const InputDecoration(
                  labelText: 'Receiver Phone',
                  hintText: 'e.g. 09171234567',
                ),
                validator: (val) {
                  if (val != null && val.trim().isNotEmpty) {
                    final cleaned = val.trim().replaceAll(RegExp(r'[\s-]'), '');
                    if (!RegExp(r'^(09|\+639|639)\d{9}$').hasMatch(cleaned)) {
                      return 'Enter a valid PH phone number (e.g. 09171234567)';
                    }
                  }
                  return null;
                },
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
