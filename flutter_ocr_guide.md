# Flutter OCR Guide: Scan Text from Camera & Photos
### Using Google ML Kit Text Recognition

---

## Is It Free?

**Yes — 100% free.** Here's the breakdown:

| Component | Cost |
|---|---|
| `google_mlkit_text_recognition` package | Free (open-source) |
| `image_picker` package | Free (open-source) |
| ML processing | Free (runs **on-device**, no API calls) |
| Internet connection required? | ❌ No |
| Google account / billing required? | ❌ No |

> ✅ Everything runs locally on the user's phone. No cloud fees, no usage limits, no sign-in required.

---

## Prerequisites

Before starting, make sure you have:

- Flutter SDK **v3.0+** installed
- Android Studio or Xcode set up
- A physical device or emulator (Android API 21+ / iOS 15.5+)
- Basic knowledge of Dart/Flutter

---

## Step 1 — Create a New Flutter Project

```bash
flutter create ocr_app
cd ocr_app
```

---

## Step 2 — Add Dependencies

Open `pubspec.yaml` and add the following under `dependencies`:

```yaml
dependencies:
  flutter:
    sdk: flutter

  # For picking images from camera or gallery
  image_picker: ^1.1.2

  # Google ML Kit OCR (on-device, free)
  google_mlkit_text_recognition: ^0.15.0
```

Then run:

```bash
flutter pub get
```

---

## Step 3 — Android Setup

### 3a. Set Minimum SDK Version

Open `android/app/build.gradle` and make sure `minSdkVersion` is at least **21**:

```gradle
android {
    defaultConfig {
        minSdkVersion 21   // ← must be 21 or higher
        targetSdkVersion 34
    }
}
```

### 3b. Add Camera & Storage Permissions

Open `android/app/src/main/AndroidManifest.xml` and add inside `<manifest>`:

```xml
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
<!-- For Android 13+ -->
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/>
```

---

## Step 4 — iOS Setup

### 4a. Set Minimum iOS Version

Open `ios/Podfile` and set the platform version:

```ruby
platform :ios, '15.5'
```

### 4b. Add Permission Descriptions

Open `ios/Runner/Info.plist` and add these keys inside `<dict>`:

```xml
<key>NSCameraUsageDescription</key>
<string>We need camera access to scan text from photos.</string>

<key>NSPhotoLibraryUsageDescription</key>
<string>We need photo library access to pick images for text scanning.</string>
```

### 4c. Exclude Unsupported Architectures (iOS only)

Still in `ios/Podfile`, add this block to avoid build errors on simulators:

```ruby
post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    target.build_configurations.each do |config|
      config.build_settings['EXCLUDED_ARCHS[sdk=iphonesimulator*]'] = 'arm64'
    end
  end
end
```

---

## Step 5 — Write the OCR Code

Replace the contents of `lib/main.dart` with the following:

```dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'dart:io';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OCR Scanner',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const OcrHomePage(),
    );
  }
}

class OcrHomePage extends StatefulWidget {
  const OcrHomePage({super.key});

  @override
  State<OcrHomePage> createState() => _OcrHomePageState();
}

class _OcrHomePageState extends State<OcrHomePage> {
  // Holds the picked image file
  File? _imageFile;

  // Holds the extracted text result
  String _extractedText = 'No text scanned yet.';

  // Whether OCR is currently processing
  bool _isLoading = false;

  final ImagePicker _picker = ImagePicker();

  // Runs OCR on the given image file path
  Future<void> _performOcr(String imagePath) async {
    setState(() {
      _isLoading = true;
      _extractedText = 'Processing...';
    });

    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final textRecognizer = TextRecognizer(
        script: TextRecognitionScript.latin,
      );

      final RecognizedText recognizedText =
          await textRecognizer.processImage(inputImage);

      textRecognizer.close(); // Always close to free resources

      setState(() {
        _extractedText = recognizedText.text.isNotEmpty
            ? recognizedText.text
            : 'No text found in this image.';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _extractedText = 'Error during OCR: $e';
        _isLoading = false;
      });
    }
  }

  // Pick image from CAMERA
  Future<void> _pickFromCamera() async {
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (photo != null) {
      setState(() => _imageFile = File(photo.path));
      await _performOcr(photo.path);
    }
  }

  // Pick image from GALLERY
  Future<void> _pickFromGallery() async {
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (photo != null) {
      setState(() => _imageFile = File(photo.path));
      await _performOcr(photo.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OCR Scanner'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            // --- Buttons Row ---
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _pickFromCamera,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Camera'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _pickFromGallery,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Gallery'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // --- Image Preview ---
            if (_imageFile != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  _imageFile!,
                  height: 220,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),

            const SizedBox(height: 16),

            // --- Loading Indicator ---
            if (_isLoading)
              const Center(child: CircularProgressIndicator()),

            // --- Result Box ---
            if (!_isLoading)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Extracted Text:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SelectableText(
                      _extractedText,
                      style: const TextStyle(fontSize: 15),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
```

---

## Step 6 — Run the App

```bash
flutter run
```

For a specific device:

```bash
flutter run -d <device_id>
```

List available devices with:

```bash
flutter devices
```

---

## How It Works (Summary)

```
User taps "Camera" or "Gallery"
        ↓
image_picker opens camera / file browser
        ↓
User takes or selects a photo
        ↓
InputImage wraps the file path for ML Kit
        ↓
TextRecognizer.processImage() runs on-device OCR
        ↓
RecognizedText.text returns the full scanned string
        ↓
Text is displayed in the UI
```

---

## Supported Scripts

By changing `TextRecognitionScript`, you can detect other languages:

| Script Constant | Languages |
|---|---|
| `TextRecognitionScript.latin` | English, Filipino, Spanish, French, etc. |
| `TextRecognitionScript.chinese` | Chinese (Simplified & Traditional) |
| `TextRecognitionScript.japanese` | Japanese |
| `TextRecognitionScript.korean` | Korean |
| `TextRecognitionScript.devanagari` | Hindi, Sanskrit, Marathi, etc. |

---

## Tips for Better Accuracy

- **Good lighting** — well-lit images produce much better results
- **Keep text in focus** — blurry photos reduce accuracy significantly
- **High contrast** — dark text on light background works best
- **Straight angle** — avoid extreme tilts when scanning documents
- **Higher resolution** — set `imageQuality: 90` or higher for clearer images

---

## Common Errors & Fixes

| Error | Fix |
|---|---|
| `minSdkVersion` too low | Set it to `21` in `build.gradle` |
| Camera permission denied | Add permissions to `AndroidManifest.xml` |
| iOS build fails on simulator | Add `EXCLUDED_ARCHS` in `Podfile` |
| `No text found` on clear image | Try increasing `imageQuality` when picking |
| `MissingPluginException` | Run `flutter clean && flutter pub get` |

---

## What You Can Build With This

- 📄 Document scanner
- 📇 Business card reader
- 🧾 Receipt / invoice extractor
- 📚 Book page digitizer
- 🌐 On-the-fly text translator (combine with `google_mlkit_translation`)
- 🔢 License plate / ID number reader

---

*Packages used: `image_picker`, `google_mlkit_text_recognition` — both free and open-source.*
