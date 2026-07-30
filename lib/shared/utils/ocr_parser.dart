import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrParsedResult {
  final String? trackingNumber;
  final String? name;
  final String? phone;
  final double? codAmount;
  final String paymentType; // 'cod_cash' or 'prepaid'
  final String? street;
  final String? zone;
  final String? barangay;
  final String? city;

  OcrParsedResult({
    this.trackingNumber,
    this.name,
    this.phone,
    this.codAmount,
    this.paymentType = 'cod_cash',
    this.street,
    this.zone,
    this.barangay,
    this.city,
  });

  bool get isEmpty =>
      (trackingNumber == null || trackingNumber!.isEmpty) &&
      (name == null || name!.isEmpty) &&
      (phone == null || phone!.isEmpty) &&
      (codAmount == null || codAmount == 0.0) &&
      (street == null || street!.isEmpty) &&
      (zone == null || zone!.isEmpty) &&
      (barangay == null || barangay!.isEmpty) &&
      (city == null || city!.isEmpty);

  OcrParsedResult merge(OcrParsedResult other) {
    return OcrParsedResult(
      trackingNumber: (other.trackingNumber != null && other.trackingNumber!.isNotEmpty)
          ? other.trackingNumber
          : trackingNumber,
      name: (other.name != null && other.name!.isNotEmpty) ? other.name : name,
      phone: (other.phone != null && other.phone!.isNotEmpty) ? other.phone : phone,
      codAmount: (other.codAmount != null && other.codAmount! > 0) ? other.codAmount : codAmount,
      paymentType: (other.codAmount != null && other.codAmount! > 0) ? 'cod_cash' : (codAmount != null && codAmount! > 0 ? 'cod_cash' : paymentType),
      street: (other.street != null && other.street!.isNotEmpty) ? other.street : street,
      zone: (other.zone != null && other.zone!.isNotEmpty) ? other.zone : zone,
      barangay: (other.barangay != null && other.barangay!.isNotEmpty) ? other.barangay : barangay,
      city: (other.city != null && other.city!.isNotEmpty) ? other.city : city,
    );
  }
}

class OcrParser {
  /// Extract fields from multiple label images using Google ML Kit Text Recognition.
  static Future<OcrParsedResult> parseFromImages(
    List<String> imagePaths, {
    List<String> knownBarangays = const [],
    List<String> knownCities = const [],
    List<String> candidateTrackingNumbers = const [],
  }) async {
    OcrParsedResult combinedResult = OcrParsedResult();

    for (final path in imagePaths) {
      try {
        final inputImage = InputImage.fromFilePath(path);
        final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
        final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
        await textRecognizer.close();

        final singleResult = parseRecognizedText(
          recognizedText,
          knownBarangays: knownBarangays,
          knownCities: knownCities,
          candidateTrackingNumbers: candidateTrackingNumbers,
        );

        combinedResult = combinedResult.merge(singleResult);
      } catch (e) {
        debugPrint('Error parsing OCR from $path: $e');
      }
    }

    return combinedResult;
  }

  /// Parses ML Kit RecognizedText into OcrParsedResult.
  static OcrParsedResult parseRecognizedText(
    RecognizedText recognizedText, {
    List<String> knownBarangays = const [],
    List<String> knownCities = const [],
    List<String> candidateTrackingNumbers = const [],
  }) {
    final List<TextLine> rawLines = [];
    for (final block in recognizedText.blocks) {
      rawLines.addAll(block.lines);
    }

    // Filter out diagonal lines (watermarks, angled stamps)
    final List<TextLine> horizontalLines = rawLines.where((line) {
      if (line.cornerPoints.length < 2) return true;
      final p1 = line.cornerPoints[0];
      final p2 = line.cornerPoints[1];
      final dx = p2.x - p1.x;
      final dy = p2.y - p1.y;
      final angleDeg = (atan2(dy.toDouble(), dx.toDouble()) * 180 / pi).abs();
      return !(angleDeg > 15 && angleDeg < 165);
    }).toList();

    // Sort lines vertically from top to bottom
    horizontalLines.sort((a, b) => a.boundingBox.top.compareTo(b.boundingBox.top));

    // Exclude sender section if present
    int senderIndex = -1;
    for (int i = 0; i < horizontalLines.length; i++) {
      if (horizontalLines[i].text.toLowerCase().contains('sender')) {
        senderIndex = i;
        break;
      }
    }

    final List<TextLine> filteredLines = senderIndex != -1
        ? horizontalLines.sublist(0, senderIndex)
        : horizontalLines;

    final String text = filteredLines.map((l) => l.text).join('\n');
    if (text.isEmpty) return OcrParsedResult();

    // Pre-detection: Task Details screenshot format (delivery app)
    // Detected by presence of "Waybill number" + "client:" + "COD:" markers
    final lowerText = text.toLowerCase();
    final isTaskDetailsFormat = lowerText.contains('waybill') &&
        lowerText.contains('client') &&
        lowerText.contains('cod');

    if (isTaskDetailsFormat) {
      return _parseTaskDetailsFormat(
        text,
        knownBarangays: knownBarangays,
        knownCities: knownCities,
        candidateTrackingNumbers: candidateTrackingNumbers,
      );
    }

    String? parsedTrackingNumber;
    String? parsedName;
    String? parsedPhone;
    double? parsedCodAmount;
    String? parsedStreet;
    String? parsedZone;
    String? parsedBarangay;
    String? parsedCity;

    // 0. Tracking Number Matching
    if (candidateTrackingNumbers.isNotEmpty) {
      final textCleaned = text.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
      for (final trk in candidateTrackingNumbers) {
        final trkCleaned = trk.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
        if (trkCleaned.isNotEmpty && textCleaned.contains(trkCleaned)) {
          parsedTrackingNumber = trk;
          break;
        }
      }
    }

    // 1. Phone parsing
    final phoneRegex = RegExp(r'\b(?:09|\+639|639)\d{9}\b|\b\d{4}[- ]?\d{3}[- ]?\d{4}\b');
    final phoneMatch = phoneRegex.firstMatch(text);
    if (phoneMatch != null) {
      var phoneStr = phoneMatch.group(0)?.replaceAll(RegExp(r'[- ]'), '');
      if (phoneStr != null) {
        if (phoneStr.startsWith('+639')) {
          phoneStr = '09${phoneStr.substring(4)}';
        } else if (phoneStr.startsWith('639')) {
          phoneStr = '09${phoneStr.substring(3)}';
        }
        parsedPhone = phoneStr;
      }
    }

    // 2. COD amount parsing
    double? extractedCod;
    TextLine? codLine;
    for (final line in filteredLines) {
      final txt = line.text.toLowerCase();
      if (txt.contains('cod') && !txt.contains('fee') && !txt.contains('transfer')) {
        codLine = line;
        break;
      }
    }

    if (codLine != null) {
      final codSameLineRegex = RegExp(
        r'\bcod\b(?!\s*fee)(?!\s*transfer)\s*[:=-]?\s*(?:php|₱)?\s*([0-9,]+\.[0-9]{2})\b',
        caseSensitive: false,
      );
      final match = codSameLineRegex.firstMatch(codLine.text);
      if (match != null) {
        final amtStr = match.group(1)?.replaceAll(',', '');
        if (amtStr != null) {
          extractedCod = double.tryParse(amtStr);
        }
      }

      if (extractedCod == null) {
        final codRect = codLine.boundingBox;
        final codCenterY = codRect.center.dy;
        final codHeight = codRect.height;
        double? bestMatchValue;
        double bestDistance = double.infinity;

        for (final line in filteredLines) {
          if (line == codLine) continue;
          final lineRect = line.boundingBox;
          final centerY = lineRect.center.dy;
          final verticalDist = (centerY - codCenterY).abs();

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
                if (parsed != null && verticalDist < bestDistance) {
                  bestDistance = verticalDist;
                  bestMatchValue = parsed;
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

    // 3. Receiver Name parsing
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

    // 4. Zone parsing
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

    // 5. Barangay search
    const defaultBarangays = [
      'Ani-e', 'Cabacungan', 'Gumaod', 'Hinaplanan', 'Kalawihon', 'Lanise',
      'Libertad', 'Madaguing', 'Malagana', 'Minsacopa', 'Patrocinio', 'Plaridel',
      'Poblacion', 'Punong', 'Rizal', 'Santa Cruz', 'Tamboboan', 'Tipolohon'
    ];
    final barangaysToSearch = knownBarangays.isNotEmpty ? knownBarangays : defaultBarangays;
    for (final b in barangaysToSearch) {
      final escB = RegExp.escape(b);
      final brgyRegex = RegExp('\\b$escB\\b', caseSensitive: false);
      if (brgyRegex.hasMatch(text)) {
        parsedBarangay = b;
        break;
      }
    }

    // 6. City search
    final citiesToSearch = knownCities.isNotEmpty ? knownCities : ['Claveria', 'Gingoog', 'Cagayan de Oro'];
    for (final c in citiesToSearch) {
      if (c.isNotEmpty && text.toLowerCase().contains(c.toLowerCase())) {
        parsedCity = c;
        break;
      }
    }

    // 7. Street Address parsing
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

    if (parsedStreet != null && parsedStreet.isNotEmpty) {
      var cleanStreet = parsedStreet;
      if (parsedBarangay != null && parsedBarangay.isNotEmpty) {
        cleanStreet = cleanStreet.replaceAll(RegExp(RegExp.escape(parsedBarangay), caseSensitive: false), '');
      }
      if (parsedCity != null && parsedCity.isNotEmpty) {
        cleanStreet = cleanStreet.replaceAll(RegExp(RegExp.escape(parsedCity), caseSensitive: false), '');
      }
      cleanStreet = cleanStreet.replaceAll(RegExp(r'^[,\s\-]+|[,\s\-]+$'), '').trim();
      if (cleanStreet.isNotEmpty) {
        parsedStreet = cleanStreet;
      }
    }

    return OcrParsedResult(
      trackingNumber: parsedTrackingNumber,
      name: parsedName,
      phone: parsedPhone,
      codAmount: parsedCodAmount,
      paymentType: (parsedCodAmount != null && parsedCodAmount > 0) ? 'cod_cash' : 'prepaid',
      street: parsedStreet,
      zone: parsedZone,
      barangay: parsedBarangay,
      city: parsedCity,
    );
  }

  /// Parses delivery app "Task details" screenshot format.
  /// Expected structure:
  ///   To    `full address`
  ///   Waybill number    `tracking number`
  ///   client:    `client name`
  ///   COD:    `amount`
  static OcrParsedResult _parseTaskDetailsFormat(
    String text, {
    List<String> knownBarangays = const [],
    List<String> knownCities = const [],
    List<String> candidateTrackingNumbers = const [],
  }) {
    final lines = text.split('\n');
    String? parsedTrackingNumber;
    String? parsedName;
    double? parsedCodAmount;
    String? parsedStreet;
    String? parsedZone;
    String? parsedBarangay;
    String? parsedCity;
    String? toAddressText;

    for (final line in lines) {
      final trimmed = line.trim();
      final lower = trimmed.toLowerCase();

      // Parse "Waybill number" → trackingNumber
      if (lower.startsWith('waybill')) {
        final waybillRegex = RegExp(
          r'waybill\s*(?:number|no\.?|#)?\s*[:=]?\s*(.+)',
          caseSensitive: false,
        );
        final match = waybillRegex.firstMatch(trimmed);
        if (match != null) {
          parsedTrackingNumber = match.group(1)?.trim();
        }
      }

      // Parse "client:" → name (strip trailing non-alphanumeric junk like ;-&)
      else if (lower.startsWith('client')) {
        final clientRegex = RegExp(
          r'client\s*[:=]\s*(.+)',
          caseSensitive: false,
        );
        final match = clientRegex.firstMatch(trimmed);
        if (match != null) {
          var rawName = match.group(1)?.trim() ?? '';
          // Strip trailing non-alphanumeric/space junk (e.g. ";-&")
          rawName = rawName.replaceAll(RegExp(r'[^a-zA-Z0-9\s.]+$'), '').trim();
          if (rawName.isNotEmpty) {
            parsedName = rawName;
          }
        }
      }

      // Parse "COD:" → codAmount (0 = prepaid, >0 = cod_cash)
      else if (lower.startsWith('cod')) {
        final codRegex = RegExp(
          r'cod\s*[:=]\s*([0-9,]+(?:\.[0-9]{1,2})?)',
          caseSensitive: false,
        );
        final match = codRegex.firstMatch(trimmed);
        if (match != null) {
          final amtStr = match.group(1)?.replaceAll(',', '');
          if (amtStr != null) {
            parsedCodAmount = double.tryParse(amtStr);
          }
        }
      }

      // Parse "To" → full address text for subsequent address parsing
      else if (lower.startsWith('to') && toAddressText == null) {
        // Strip "To" prefix (may be "To:", "To ", etc.)
        final toRegex = RegExp(r'^to\s*[:=]?\s*', caseSensitive: false);
        final addressContent = trimmed.replaceFirst(toRegex, '').trim();
        if (addressContent.isNotEmpty) {
          toAddressText = addressContent;
        }
      }
    }

    // If candidate tracking numbers provided, try matching against them
    if (candidateTrackingNumbers.isNotEmpty && parsedTrackingNumber != null) {
      final trkCleaned = parsedTrackingNumber.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
      bool matched = false;
      for (final candidate in candidateTrackingNumbers) {
        final candidateCleaned = candidate.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
        if (candidateCleaned.isNotEmpty && trkCleaned.contains(candidateCleaned)) {
          parsedTrackingNumber = candidate;
          matched = true;
          break;
        }
      }
      if (!matched) {
        // Keep the raw waybill number as-is if no candidate matched
      }
    }

    // Parse address components from "To" line using existing logic
    if (toAddressText != null && toAddressText.isNotEmpty) {
      // Zone parsing
      final zoneRegex = RegExp(r'\b(?:zone|purok|puk|pk)\s*([0-9a-zA-Z]+(?:\s*[-]?\s*[0-9a-zA-Z]+)*)', caseSensitive: false);
      final zoneMatch = zoneRegex.firstMatch(toAddressText);
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

      // Barangay search
      const defaultBarangays = [
        'Ani-e', 'Cabacungan', 'Gumaod', 'Hinaplanan', 'Kalawihon', 'Lanise',
        'Libertad', 'Madaguing', 'Malagana', 'Minsacopa', 'Patrocinio', 'Plaridel',
        'Poblacion', 'Punong', 'Rizal', 'Santa Cruz', 'Tamboboan', 'Tipolohon'
      ];
      final barangaysToSearch = knownBarangays.isNotEmpty ? knownBarangays : defaultBarangays;
      for (final b in barangaysToSearch) {
        final escB = RegExp.escape(b);
        final brgyRegex = RegExp('\\b$escB\\b', caseSensitive: false);
        if (brgyRegex.hasMatch(toAddressText)) {
          parsedBarangay = b;
          break;
        }
      }

      // City search
      final citiesToSearch = knownCities.isNotEmpty ? knownCities : ['Claveria', 'Gingoog', 'Cagayan de Oro'];
      for (final c in citiesToSearch) {
        if (c.isNotEmpty && toAddressText.toLowerCase().contains(c.toLowerCase())) {
          parsedCity = c;
          break;
        }
      }

      // Street extraction: take the portion before zone/barangay/city markers
      var streetCandidate = toAddressText;
      // Remove zone text
      if (parsedZone != null) {
        streetCandidate = streetCandidate.replaceAll(
          RegExp(r'\b(?:zone|purok|puk|pk)\s*[0-9a-zA-Z]+', caseSensitive: false), '',
        );
      }
      // Remove barangay name
      if (parsedBarangay != null && parsedBarangay.isNotEmpty) {
        streetCandidate = streetCandidate.replaceAll(
          RegExp(RegExp.escape(parsedBarangay), caseSensitive: false), '',
        );
      }
      // Remove city name
      if (parsedCity != null && parsedCity.isNotEmpty) {
        streetCandidate = streetCandidate.replaceAll(
          RegExp(RegExp.escape(parsedCity), caseSensitive: false), '',
        );
      }
      // Remove province-like trailing text (e.g. "Misamis Oriental")
      streetCandidate = streetCandidate.replaceAll(
        RegExp(r'\b(?:Misamis\s+Oriental|Misamis\s+Occidental|Bukidnon|Lanao\s+del\s+Norte|Lanao\s+del\s+Sur)\b', caseSensitive: false), '',
      );
      // Clean up separators and whitespace
      streetCandidate = streetCandidate.replaceAll(RegExp(r'[,\s\-]+$|^[,\s\-]+'), '').trim();
      streetCandidate = streetCandidate.replaceAll(RegExp(r',\s*,'), ',').trim();
      streetCandidate = streetCandidate.replaceAll(RegExp(r'^[,\s]+|[,\s]+$'), '').trim();
      if (streetCandidate.isNotEmpty) {
        parsedStreet = streetCandidate;
      }
    }

    // COD = 0 means prepaid
    final bool isPrepaid = parsedCodAmount == null || parsedCodAmount == 0.0;

    return OcrParsedResult(
      trackingNumber: parsedTrackingNumber,
      name: parsedName,
      codAmount: isPrepaid ? null : parsedCodAmount,
      paymentType: isPrepaid ? 'prepaid' : 'cod_cash',
      street: parsedStreet,
      zone: parsedZone,
      barangay: parsedBarangay,
      city: parsedCity,
    );
  }
}
