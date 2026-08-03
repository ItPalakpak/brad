import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../../core/database/db_helper.dart';
import '../../core/theme/app_theme.dart';

/// Modal bottom sheet allowing riders to upload sample parcel label photos,
/// configure keyword anchors, and train the ML OCR engine with new data formats.
class TrainOcrModal extends StatefulWidget {
  const TrainOcrModal({super.key});

  // CHANGED: Added optional useRootNavigator parameter to support launching modal from root shell navigation context
  static Future<void> show(BuildContext context, {bool useRootNavigator = false}) {
    return showModalBottomSheet(
      context: context,
      useRootNavigator: useRootNavigator,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const TrainOcrModal(),
    );
  }

  @override
  State<TrainOcrModal> createState() => _TrainOcrModalState();
}

class _TrainOcrModalState extends State<TrainOcrModal> {
  final _picker = ImagePicker();
  File? _sampleImage;
  bool _isProcessing = false;
  String _extractedRawText = '';
  List<LearnedOcrFormat> _existingFormats = [];

  final _formatNameController = TextEditingController();
  final _trackingAnchorController = TextEditingController();
  final _nameAnchorController = TextEditingController();
  final _phoneAnchorController = TextEditingController();
  final _streetAnchorController = TextEditingController();
  final _codAnchorController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadExistingFormats();
  }

  Future<void> _loadExistingFormats() async {
    try {
      final formats = await DbHelper.instance.getLearnedOcrFormats();
      if (mounted) {
        setState(() {
          _existingFormats = formats;
        });
      }
    } catch (e) {
      debugPrint('Error loading learned formats: $e');
    }
  }

  Future<void> _pickAndAnalyzeImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(source: source);
      if (picked == null) return;

      setState(() {
        _sampleImage = File(picked.path);
        _isProcessing = true;
        _extractedRawText = '';
      });

      final inputImage = InputImage.fromFilePath(picked.path);
      final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
      await textRecognizer.close();

      if (mounted) {
        setState(() {
          _extractedRawText = recognizedText.text;
          _isProcessing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error analyzing sample label: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    // CHANGED: Properly dispose all controllers when modal is closed
    _formatNameController.dispose();
    _trackingAnchorController.dispose();
    _nameAnchorController.dispose();
    _phoneAnchorController.dispose();
    _streetAnchorController.dispose();
    _codAnchorController.dispose();
    super.dispose();
  }

  Future<void> _saveTrainedFormat() async {
    final formatName = _formatNameController.text.trim();
    if (formatName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a name for this label format template.')),
      );
      return;
    }

    final trackingAnchor = _trackingAnchorController.text.trim();
    final nameAnchor = _nameAnchorController.text.trim();
    final phoneAnchor = _phoneAnchorController.text.trim();
    final streetAnchor = _streetAnchorController.text.trim();
    final codAnchor = _codAnchorController.text.trim();

    // CHANGED: Validation to ensure at least one field anchor keyword is configured before saving
    if (trackingAnchor.isEmpty &&
        nameAnchor.isEmpty &&
        phoneAnchor.isEmpty &&
        streetAnchor.isEmpty &&
        codAnchor.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please configure at least one keyword anchor (e.g. Tracking, Name, Phone, or Address).')),
      );
      return;
    }

    final patternMap = {
      'tracking_anchor': trackingAnchor,
      'name_anchor': nameAnchor,
      'phone_anchor': phoneAnchor,
      'street_anchor': streetAnchor,
      'cod_anchor': codAnchor,
    };

    final newFormat = LearnedOcrFormat(
      id: const Uuid().v4(),
      name: formatName,
      formatPattern: jsonEncode(patternMap),
      createdAt: DateTime.now(),
    );

    try {
      await DbHelper.instance.insertLearnedOcrFormat(newFormat);
      await _loadExistingFormats();

      _formatNameController.clear();
      _trackingAnchorController.clear();
      _nameAnchorController.clear();
      _phoneAnchorController.clear();
      _streetAnchorController.clear();
      _codAnchorController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Saved & trained new OCR format template "$formatName"!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving format: $e')),
        );
      }
    }
  }

  // CHANGED: Added delete confirmation dialog before deleting trained OCR template from SQLite
  Future<void> _deleteFormat(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Format Template?'),
        content: const Text('Are you sure you want to delete this custom trained OCR format template?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('DELETE', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await DbHelper.instance.deleteLearnedOcrFormat(id);
      await _loadExistingFormats();
    } catch (e) {
      debugPrint('Error deleting format: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(color: tokens.border, width: 2),
      ),
      child: Column(
        children: [
          // Header Drag Handle
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: tokens.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),

          // Modal Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Icon(Icons.model_training_outlined, color: tokens.accent, size: 24),
                const SizedBox(width: 10),
                Text(
                  'TRAIN OCR MODEL FORMAT',
                  style: TextStyle(
                    color: tokens.text,
                    fontFamily: 'Syne',
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.close_rounded, color: tokens.text),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Upload a sample parcel label image to extract field anchor keywords and train custom layout recognition rules.',
                    style: TextStyle(color: tokens.textMuted, fontSize: 13),
                  ),
                  const SizedBox(height: 16),

                  // Image Upload Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _pickAndAnalyzeImage(ImageSource.camera),
                          icon: const Icon(Icons.camera_alt_outlined, size: 18),
                          label: const Text('CAMERA SAMPLE'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: tokens.surfaceAlt,
                            foregroundColor: tokens.text,
                            side: BorderSide(color: tokens.border),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _pickAndAnalyzeImage(ImageSource.gallery),
                          icon: const Icon(Icons.photo_library_outlined, size: 18),
                          label: const Text('GALLERY SAMPLE'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: tokens.surfaceAlt,
                            foregroundColor: tokens.text,
                            side: BorderSide(color: tokens.border),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (_isProcessing)
                    const Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Center(child: CircularProgressIndicator()),
                    ),

                  if (_sampleImage != null && !_isProcessing) ...[
                    Container(
                      height: 150,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border.all(color: tokens.border),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(_sampleImage!, fit: BoxFit.cover),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  if (_extractedRawText.isNotEmpty) ...[
                    Text(
                      'DETECTED OCR TEXT PREVIEW',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: tokens.textMuted,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 100,
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: tokens.bg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: tokens.border.withValues(alpha: 0.5)),
                      ),
                      child: SingleChildScrollView(
                        child: Text(
                          _extractedRawText,
                          style: TextStyle(fontSize: 11, color: tokens.text, fontFamily: 'monospace'),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Form Input for Format Anchors
                  Text(
                    'CONFIGURE FIELD ANCHORS',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: tokens.accent,
                    ),
                  ),
                  const SizedBox(height: 10),

                  TextField(
                    controller: _formatNameController,
                    decoration: const InputDecoration(
                      labelText: 'Format Template Name (e.g. J&T Custom Waybill)',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 10),

                  TextField(
                    controller: _trackingAnchorController,
                    decoration: const InputDecoration(
                      labelText: 'Tracking # Anchor Keyword (e.g. TRACKING NO:)',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 10),

                  TextField(
                    controller: _nameAnchorController,
                    decoration: const InputDecoration(
                      labelText: 'Recipient Name Anchor Keyword (e.g. CONSIGNEE:)',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 10),

                  TextField(
                    controller: _phoneAnchorController,
                    decoration: const InputDecoration(
                      labelText: 'Phone Anchor Keyword (e.g. TEL:)',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 10),

                  TextField(
                    controller: _streetAnchorController,
                    decoration: const InputDecoration(
                      labelText: 'Address Anchor Keyword (e.g. DELIVER TO:)',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 10),

                  TextField(
                    controller: _codAnchorController,
                    decoration: const InputDecoration(
                      labelText: 'COD Amount Anchor Keyword (e.g. AMOUNT TO COLLECT:)',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _saveTrainedFormat,
                      icon: const Icon(Icons.save_rounded),
                      label: const Text('SAVE & TRAIN MODEL FORMAT'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: tokens.accent,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Trained Formats List
                  Text(
                    'TRAINED FORMAT TEMPLATES (${_existingFormats.length})',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: tokens.text,
                    ),
                  ),
                  const SizedBox(height: 10),

                  if (_existingFormats.isEmpty)
                    Text(
                      'No custom trained format templates yet.',
                      style: TextStyle(color: tokens.textMuted, fontSize: 12),
                    )
                  else
                    ..._existingFormats.map((f) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: tokens.surfaceAlt,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: tokens.border),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.style_outlined, size: 18, color: tokens.accent),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                f.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: tokens.text,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                              onPressed: () => _deleteFormat(f.id),
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
