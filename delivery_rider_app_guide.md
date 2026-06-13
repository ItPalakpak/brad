# 📦 BRAD — Flutter Delivery Rider App
## Full Development Prompt & Implementation Guide

> **Stack:** Flutter · SQLite (sqflite) · FCM · flutter_map / OSM · mobile_scanner · geolocator

---

## Table of Contents

1. [Project Overview](#1-project-overview)
2. [Tech Stack & Dependencies](#2-tech-stack--dependencies)
3. [App Architecture](#3-app-architecture)
4. [Offline-First Strategy](#4-offline-first-strategy)
5. [Design System — Tokens, Themes & Offset Shadows](#5-design-system--tokens-themes--offset-shadows)
6. [Screen-by-Screen Specification](#6-screen-by-screen-specification)
7. [Core Features — Detailed Spec](#7-core-features--detailed-spec)
8. [Database Schema (SQLite)](#8-database-schema-sqlite)
9. [Notifications & Geofencing (FCM + Background Location)](#9-notifications--geofencing-fcm--background-location)
10. [Floating Timer Widget](#10-floating-timer-widget)
11. [Package Card Drag & Reorder](#11-package-card-drag--reorder)
12. [AI Prompt to Bootstrap the Project](#12-ai-prompt-to-bootstrap-the-project)

---

## 1. Project Overview

**BRAD** is a mobile-first Flutter app built for last-mile delivery riders. It is designed **offline-first** — every core rider workflow functions without any internet connection, and online features gracefully degrade when the network is unavailable.

Core capabilities:
- Scan package barcodes / QR codes on pickup (100% offline)
- Pin delivery locations on a map with custom labels (offline with cached tiles)
- Manage package details: receiver name, COD amounts, payment type, tips, extras (100% offline)
- Reorder packages by priority via drag-and-drop (100% offline)
- Search and filter packages by location, date, and payment type (100% offline)
- Track delivery attempts per package stored in local SQLite (100% offline)
- Get proximity notifications when near a delivery pin via GPS geofencing (offline-capable)
- Use a floating timer overlay that persists across screens (100% offline)
- FCM notifications from a dispatcher and live map tiles require a connection, but the app handles their absence cleanly

---

## 2. Tech Stack & Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter

  # State management
  flutter_riverpod: ^2.5.1
  riverpod_annotation: ^2.3.5

  # Local database — the source of truth
  sqflite: ^2.3.3
  path: ^1.9.0

  # Barcode / QR scanning
  mobile_scanner: ^5.2.3

  # Maps (OSM — free, no API key)
  flutter_map: ^6.2.1
  latlong2: ^0.9.1

  # Offline map tile caching — REQUIRED for offline map support
  flutter_map_tile_caching: ^9.1.0

  # Location & geofencing (GPS-only, works offline)
  geolocator: ^12.0.0
  geofence_service: ^4.0.2
  permission_handler: ^11.3.1

  # Push notifications (online only — graceful fallback)
  firebase_core: ^3.6.0
  firebase_messaging: ^15.1.3
  flutter_local_notifications: ^17.2.3   # used both online and offline

  # Floating overlay (timer widget)
  system_alert_window: ^0.4.1            # Android system overlay

  # UI helpers
  flutter_slidable: ^3.1.1
  intl: ^0.19.0
  uuid: ^4.4.2
  shared_preferences: ^2.3.2

  # Connectivity awareness
  connectivity_plus: ^6.0.5

  # CSV export (offline)
  csv: ^6.0.0

dev_dependencies:
  riverpod_generator: ^2.4.3
  build_runner: ^2.4.9
```

---

## 3. App Architecture

```
lib/
├── main.dart
├── app/
│   ├── app.dart                        # MaterialApp + theme provider
│   ├── router.dart                     # go_router routes
│   └── providers.dart                  # Root Riverpod providers
├── core/
│   ├── theme/
│   │   ├── app_theme.dart
│   │   ├── tokens.dart
│   │   ├── theme_notifier.dart
│   │   └── themes/
│   │       ├── pure_bold.dart
│   │       ├── techy.dart
│   │       ├── friendly.dart
│   │       ├── corporate.dart
│   │       ├── playful.dart
│   │       ├── trailblazer.dart
│   │       ├── monochrome.dart
│   │       └── rider_green.dart        # Added theme
│   ├── database/
│   │   ├── db_helper.dart              # SQLite singleton
│   │   └── migrations/
│   │       └── v1_initial.dart
│   └── services/
│       ├── connectivity_service.dart   # Watches network state
│       ├── location_service.dart       # GPS stream
│       ├── geofence_manager.dart       # GPS-based geofencing (offline)
│       ├── notification_service.dart   # Local notifications (offline)
│       ├── map_cache_service.dart      # Tile pre-caching
│       └── fcm_service.dart            # FCM (online only, optional)
├── features/
│   ├── scan/
│   │   ├── scan_screen.dart
│   │   └── scan_provider.dart
│   ├── packages/
│   │   ├── packages_screen.dart
│   │   ├── package_card.dart
│   │   ├── package_detail_screen.dart
│   │   ├── package_form.dart
│   │   └── packages_provider.dart
│   ├── map/
│   │   ├── map_screen.dart
│   │   ├── pin_picker_sheet.dart
│   │   ├── offline_tile_manager.dart   # Tile cache management UI
│   │   └── map_provider.dart
│   ├── timer/
│   │   ├── timer_widget.dart
│   │   ├── timer_notifier.dart
│   │   └── timer_overlay.dart
│   └── settings/
│       ├── settings_screen.dart
│       ├── theme_picker.dart
│       └── offline_map_settings.dart   # Download/manage tile regions
└── shared/
    ├── widgets/
    │   ├── offset_shadow_card.dart
    │   ├── connectivity_banner.dart    # Shown when offline
    │   ├── status_badge.dart
    │   ├── payment_chip.dart
    │   └── section_header.dart
    └── utils/
        ├── currency_formatter.dart
        └── date_formatter.dart
```

---

## 4. Offline-First Strategy

This is the most critical architectural section. Every feature is categorized by its offline behavior. The rule is: **never block the rider from doing their job because of a missing network connection.**

---

### 4.1 Feature Offline Matrix

| Feature                          | Offline Support | Notes                                              |
|----------------------------------|-----------------|----------------------------------------------------|
| Barcode / QR scanning            | ✅ Full          | Camera + SQLite only, no network needed            |
| View package list                | ✅ Full          | Reads from SQLite                                  |
| Add / edit package details       | ✅ Full          | Writes to SQLite                                   |
| Search & filter packages         | ✅ Full          | SQL queries on local DB                            |
| Drag-and-drop reorder            | ✅ Full          | Updates sort_order in SQLite                       |
| Log delivery attempt             | ✅ Full          | Writes to SQLite                                   |
| Mark as delivered / failed       | ✅ Full          | Updates SQLite record                              |
| Floating timer                   | ✅ Full          | Pure Dart timer, no network                        |
| Map: view pinned locations       | ✅ Full          | Markers from SQLite; tiles from cache              |
| Map: pin a delivery location     | ✅ Full          | Coordinates saved locally; no geocoding needed     |
| Map: current location (GPS)      | ✅ Full          | GPS works without internet                         |
| Proximity alerts (geofencing)    | ✅ Full          | GPS + local notifications only                     |
| Map tiles (background layer)     | ⚠️ Partial      | Cached regions show; uncached areas = gray tiles   |
| CSV export                       | ✅ Full          | Reads SQLite, writes to device storage             |
| Theme / settings changes         | ✅ Full          | SharedPreferences, no network                      |
| FCM push from dispatcher         | ❌ Online only   | Graceful: shown as banner when back online         |
| Pre-download map tiles           | ❌ Online only   | Done in advance via Settings; works offline after  |

---

### 4.2 Connectivity Service

This service drives the entire offline-awareness layer. Every part of the app that behaves differently online/offline reads from this single provider.

```dart
// core/services/connectivity_service.dart

@riverpod
Stream<bool> connectivityStream(ConnectivityStreamRef ref) async* {
  final connectivity = Connectivity();
  yield* connectivity.onConnectivityChanged.map(
    (result) => result != ConnectivityResult.none,
  );
}

@riverpod
class ConnectivityNotifier extends _$ConnectivityNotifier {
  @override
  bool build() {
    // Initialize synchronously, then update via stream
    ref.listen(connectivityStreamProvider, (_, next) {
      next.whenData((isOnline) => state = isOnline);
    });
    return true; // optimistic default
  }
}
```

---

### 4.3 Connectivity Banner

A slim banner shown at the top of every screen when offline. It must not be intrusive — it only appears when offline and dismisses automatically when connection is restored.

```dart
// shared/widgets/connectivity_banner.dart

class ConnectivityBanner extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(connectivityNotifierProvider);
    final tokens = context.tokens;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: isOnline
          ? const SizedBox.shrink()
          : Container(
              key: const ValueKey('offline-banner'),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: tokens.warning.withOpacity(0.15),
              child: Row(
                children: [
                  Icon(Icons.wifi_off_rounded, size: 16, color: tokens.warning),
                  const SizedBox(width: 8),
                  Text(
                    'Offline — all changes saved locally',
                    style: TextStyle(
                      color: tokens.warning,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
```

Wrap every screen's `Scaffold` body in a `Column` with `ConnectivityBanner()` at the top:

```dart
// In each screen's Scaffold:
body: Column(
  children: [
    const ConnectivityBanner(),
    Expanded(child: /* main content */),
  ],
),
```

---

### 4.4 Offline Map Tiles

The map must show something useful even without a connection. This uses `flutter_map_tile_caching` to pre-download tile regions while online, then serve them from disk offline.

#### Tile Store Setup

```dart
// core/services/map_cache_service.dart

class MapCacheService {
  static const _storeName = 'BRAD_tiles';

  Future<void> init() async {
    await FlutterMapTileCaching.initialise();
    await FMTC.instance(_storeName).manage.createAsync();
  }

  // Called from map screen TileLayer:
  TileProvider get offlineTileProvider {
    return FMTC.instance(_storeName).getTileProvider(
      FMTCTileProviderSettings(
        behavior: CacheBehavior.cacheFirst, // serve cache, fallback to network
        fallbackToNetwork: true,
        cachedValidDuration: const Duration(days: 30),
      ),
    );
  }

  // Download a region around a LatLng point (e.g. the rider's city)
  Future<void> downloadRegion({
    required LatLng center,
    required double radiusKm,
    int minZoom = 12,
    int maxZoom = 17,
    void Function(DownloadProgress)? onProgress,
  }) async {
    final region = CircleRegion(center, radiusKm);
    await FMTC.instance(_storeName).download.startForeground(
      region: region.toDownloadable(minZoom, maxZoom, TileLayer()),
      parallelThreads: 2,
      maxBufferLength: 100,
      skipExistingTiles: true,
      onProgress: onProgress,
    );
  }

  Future<int> get cachedTileCount =>
      FMTC.instance(_storeName).stats.cachedLengthAsync;

  Future<double> get cacheStorageMB =>
      FMTC.instance(_storeName).stats.storeSizeAsync;

  Future<void> clearCache() =>
      FMTC.instance(_storeName).manage.resetAsync();
}
```

#### Map Screen TileLayer

```dart
// features/map/map_screen.dart

TileLayer(
  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
  tileProvider: ref.read(mapCacheServiceProvider).offlineTileProvider,
  errorTileCallback: (tile, error, stackTrace) {
    // Tile failed to load and wasn't cached — show gray tile silently
    // Do NOT crash or show error dialogs for missing tiles
  },
  userAgentPackageName: 'com.yourapp.BRAD',
)
```

#### Offline Map Settings Screen

```dart
// features/settings/offline_map_settings.dart

// A dedicated section in Settings where the rider can:
// 1. See how much map cache is stored (e.g., "48 MB — ~2,400 tiles cached")
// 2. Download a new region (enter a city name or use current GPS location)
// 3. Clear the cache

class OfflineMapSettingsSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(connectivityNotifierProvider);
    final cacheInfo = ref.watch(cacheInfoProvider); // tile count + MB

    return OffsetShadowCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Offline Map', icon: Icons.map_outlined),
          const SizedBox(height: 12),
          Text('Cached: ${cacheInfo.tiles} tiles (${cacheInfo.mb} MB)'),
          const SizedBox(height: 12),
          if (isOnline) ...[
            ElevatedButton.icon(
              onPressed: _downloadCurrentArea,
              icon: const Icon(Icons.download_rounded),
              label: const Text('Download area around me'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _clearCache,
              child: const Text('Clear tile cache',
                  style: TextStyle(color: Colors.red)),
            ),
          ] else
            Text(
              'Go online to download map tiles for offline use.',
              style: TextStyle(color: context.tokens.textMuted),
            ),
        ],
      ),
    );
  }
}
```

#### First-Run Prompt

On first launch (or when no tiles are cached), show a one-time prompt:

```dart
// After splash screen, check cache count:
if (cachedTileCount == 0 && isOnline) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Download offline map?'),
      content: const Text(
        'Download your delivery area map now so you can use the map '
        'even without mobile data. You can do this later in Settings.',
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Later')),
        ElevatedButton(onPressed: _downloadAndClose, child: const Text('Download now')),
      ],
    ),
  );
}
```

---

### 4.5 Offline Geofencing

GPS-based proximity detection works entirely without the internet. The `geofence_service` package uses the device GPS to monitor circular zones.

**Key principle:** Geofences are registered from SQLite data, not from any server. When packages are added or updated, geofences are re-registered immediately from local data.

```dart
// core/services/geofence_manager.dart

class GeofenceManager {
  final GeofenceService _service = GeofenceService.instance;
  final NotificationService _notifications;
  final DbHelper _db;

  // Called on app start AND every time packages change
  Future<void> syncGeofences() async {
    final packages = await _db.getPendingPackagesWithLocation();

    final geofences = packages.map((p) => Geofence(
      id: p.id,
      latitude: p.lat!,
      longitude: p.lng!,
      radius: [
        GeofenceRadius(id: 'alert_radius', length: _alertRadiusMeters),
      ],
    )).toList();

    await _service.stop();
    if (geofences.isNotEmpty) {
      await _service.start(geofences);
    }
  }

  void _onGeofenceStatusChanged(
    Geofence geofence,
    GeofenceRadius radius,
    GeofenceStatus status,
    Position position,
  ) {
    if (status == GeofenceStatus.enter) {
      _db.getPackageById(geofence.id).then((pkg) {
        if (pkg != null) {
          // This local notification works 100% offline
          _notifications.showProximityAlert(
            title: '📦 Delivery nearby!',
            body: '${pkg.receiverName ?? "Package"} — ${pkg.barangay}, ${pkg.city}',
            packageId: pkg.id,
          );
        }
      });
    }
  }
}
```

**Re-sync triggers** — call `geofenceManager.syncGeofences()` after:
- App startup
- A package is added
- A package location is changed
- A package is marked as delivered or failed (removes it from monitoring)
- The alert radius setting is changed

---

### 4.6 Offline-Safe Local Notifications

`flutter_local_notifications` works entirely offline. It is used for both proximity alerts (geofence enter) and timer completion. FCM is never used as the sole notification channel for things the rider needs during their shift.

```dart
// core/services/notification_service.dart

class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestSoundPermission: true,
      requestBadgePermission: true,
    );
    await _plugin.initialize(
      const InitializationSettings(
          android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: _onNotificationTap,
    );
  }

  // Proximity alert — fired by geofence, works offline
  Future<void> showProximityAlert({
    required String title,
    required String body,
    required String packageId,
  }) async {
    await _plugin.show(
      packageId.hashCode,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'proximity_alerts',
          'Proximity Alerts',
          channelDescription: 'Alerts when near a delivery location',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
      ),
      payload: packageId,
    );
  }

  // Timer done — works offline
  Future<void> showTimerDone() async {
    await _plugin.show(
      9999,
      '⏱ Timer done!',
      'Your delivery timer has ended.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'timer_alerts',
          'Timer Alerts',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }
}
```

---

### 4.7 Offline CSV Export

The export feature reads purely from SQLite and writes to device storage — no network required.

```dart
// In packages_provider.dart

Future<String> exportToCsv(List<Package> packages) async {
  final rows = [
    // Header
    ['Tracking #', 'Receiver', 'Barangay', 'City', 'Status',
     'COD Cash', 'COD Digital', 'Tips', 'Extras', 'Attempts', 'Date'],
    // Data
    ...packages.map((p) => [
      p.trackingNumber,
      p.receiverName ?? '',
      p.barangay ?? '',
      p.city ?? '',
      p.status,
      p.codCash.toStringAsFixed(2),
      p.codDigital.toStringAsFixed(2),
      p.tips.toStringAsFixed(2),
      p.extraAmount.toStringAsFixed(2),
      p.attemptCount.toString(),
      DateFormat('yyyy-MM-dd').format(p.createdAt),
    ]),
  ];

  final csvString = const ListToCsvConverter().convert(rows);
  final dir = await getApplicationDocumentsDirectory();
  final file = File(
    '${dir.path}/BRAD_export_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.csv'
  );
  await file.writeAsString(csvString);
  return file.path;
}
```

---

### 4.8 What Requires Internet (and How to Handle Absence)

| Online Feature         | Behavior When Offline                                                              |
|------------------------|------------------------------------------------------------------------------------|
| FCM push notifications | Silently skipped. Local geofence alerts still work.                                |
| Fresh map tiles        | Cached tiles serve instead. Uncached areas show gray placeholder tiles.            |
| Pre-downloading tiles  | Button is disabled with tooltip: "Connect to mobile data to download tiles."       |
| (Future) dispatcher sync | Held in a local `sync_queue` table; auto-syncs when connection is restored.     |

**No feature should crash or show an error dialog because of missing internet.** Every online-dependent operation is wrapped in a connectivity check and either silently skipped or shown as a disabled UI element.

```dart
// Pattern used everywhere for online-gated actions:
void _onDownloadTap() {
  final isOnline = ref.read(connectivityNotifierProvider);
  if (!isOnline) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('You\'re offline. Connect to download map tiles.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    return;
  }
  _startDownload();
}
```

---

## 5. Design System — Tokens, Themes & Offset Shadows

### 5.1 Themes Available

| Theme ID       | Character                                    | Default Mode |
|----------------|----------------------------------------------|--------------|
| `pure-bold`    | Clean, high-contrast, professional           | Light        |
| `techy`        | Neon-on-dark, hacker aesthetic               | Dark         |
| `friendly`     | Warm oranges, approachable                   | Light        |
| `corporate`    | Purple-toned, polished                       | Light        |
| `playful`      | Vibrant pink/purple, energetic               | Dark         |
| `trailblazer`  | Navy + golden yellow, bold                   | Dark         |
| `monochrome`   | Cool grays only, minimal                     | Dark         |
| `rider-green`  | High-visibility green, outdoor readability   | Dark         |

**`rider-green` token values:**

```dart
// core/theme/themes/rider_green.dart
static const riderGreenDark = AppColorTokens(
  bg:          Color(0xFF0A1A0F),
  surface:     Color(0xFF122A19),
  surfaceAlt:  Color(0xFF1A3D24),
  primary:     Color(0xFFF0FFF4),
  accent:      Color(0xFF22C55E),
  accentSoft:  Color(0x2622C55E),
  accentRing:  Color(0x4022C55E),
  text:        Color(0xFFF0F2F5),
  textMuted:   Color(0xFFC8CDD8),
  textSubtle:  Color(0xFF8E95A6),
  textInvert:  Color(0xFF0A1A0F),
  border:      Color(0xFF1E3A28),
  borderStrong:Color(0xFF2D5A3C),
  inputBg:     Color(0xFF122A19),
  inputBorder: Color(0xFF1E3A28),
  inputFocus:  Color(0xFF22C55E),
  hover:       Color(0x0AF0FFF4),
  active:      Color(0x1422C55E),
  shadowColor: Color(0xB3D1FAE5),
);

static const riderGreenLight = AppColorTokens(
  bg:          Color(0xFFDCEDE2),
  surface:     Color(0xFFEAF5EE),
  surfaceAlt:  Color(0xFFC8DECE),
  primary:     Color(0xFF0A1A0F),
  accent:      Color(0xFF16A34A),
  accentSoft:  Color(0x2016A34A),
  accentRing:  Color(0x3516A34A),
  text:        Color(0xFF0F1117),
  textMuted:   Color(0xFF3A3F4A),
  textSubtle:  Color(0xFF6B7385),
  textInvert:  Color(0xFFFFFFFF),
  border:      Color(0xFFAAC8B4),
  borderStrong:Color(0xFF8AAD96),
  inputBg:     Color(0xFFF2F9F4),
  inputBorder: Color(0xFFAAC8B4),
  inputFocus:  Color(0xFF16A34A),
  hover:       Color(0x0A0A1A0F),
  active:      Color(0x1416A34A),
  shadowColor: Color(0xFF0A1A0F),
);
```

### 5.2 Flutter Token Classes

```dart
// core/theme/tokens.dart

class AppColorTokens {
  final Color bg, surface, surfaceAlt;
  final Color primary, accent, accentSoft, accentRing;
  final Color text, textMuted, textSubtle, textInvert;
  final Color border, borderStrong;
  final Color inputBg, inputBorder, inputFocus;
  final Color hover, active;
  final Color shadowColor;

  const AppColorTokens({
    required this.bg, required this.surface, required this.surfaceAlt,
    required this.primary, required this.accent,
    required this.accentSoft, required this.accentRing,
    required this.text, required this.textMuted,
    required this.textSubtle, required this.textInvert,
    required this.border, required this.borderStrong,
    required this.inputBg, required this.inputBorder, required this.inputFocus,
    required this.hover, required this.active,
    required this.shadowColor,
  });
}

class AppShadows {
  // Hard offset shadow — blurRadius is ALWAYS 0
  static BoxShadow offsetXs(Color c) =>
      BoxShadow(color: c, offset: const Offset(1, 1),   blurRadius: 0);
  static BoxShadow offsetSm(Color c) =>
      BoxShadow(color: c, offset: const Offset(1.5, 1.5), blurRadius: 0);
  static BoxShadow offsetMd(Color c) =>
      BoxShadow(color: c, offset: const Offset(3, 3),   blurRadius: 0);
  static BoxShadow offsetLg(Color c) =>
      BoxShadow(color: c, offset: const Offset(5, 5),   blurRadius: 0);
  static BoxShadow offsetXl(Color c) =>
      BoxShadow(color: c, offset: const Offset(7.5, 7.5), blurRadius: 0);
}

class AppSpacing {
  static const xs  =  4.0;
  static const sm  =  8.0;
  static const md  = 16.0;
  static const lg  = 24.0;
  static const xl  = 32.0;
  static const xxl = 48.0;
}

class AppRadius {
  static const xs   = Radius.circular(4);
  static const sm   = Radius.circular(6);
  static const md   = Radius.circular(12);
  static const lg   = Radius.circular(20);
  static const full = Radius.circular(999);
}

// Semantic status colors — same across all themes
class AppStatusColors {
  static const success      = Color(0xFF10B981);
  static const successSoft  = Color(0x2010B981);
  static const warning      = Color(0xFFF59E0B);
  static const warningSoft  = Color(0x20F59E0B);
  static const error        = Color(0xFFEF4444);
  static const errorSoft    = Color(0x20EF4444);
  static const info         = Color(0xFF3B82F6);
  static const infoSoft     = Color(0x203B82F6);
}
```

### 5.3 OffsetShadowCard Widget

```dart
// shared/widgets/offset_shadow_card.dart

class OffsetShadowCard extends StatelessWidget {
  final Widget child;
  final Color? backgroundColor;
  final Color? shadowColor;
  final Offset shadowOffset;
  final double borderWidth;
  final BorderRadius borderRadius;
  final EdgeInsets padding;
  final VoidCallback? onTap;

  const OffsetShadowCard({
    super.key,
    required this.child,
    this.backgroundColor,
    this.shadowColor,
    this.shadowOffset = const Offset(3, 3),
    this.borderWidth = 1.5,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
    this.padding = const EdgeInsets.all(16),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final shadow = shadowColor ?? tokens.shadowColor;
    final bg     = backgroundColor ?? tokens.surface;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: borderRadius,
          border: Border.all(color: shadow, width: borderWidth),
          boxShadow: [BoxShadow(color: shadow, offset: shadowOffset, blurRadius: 0)],
        ),
        padding: padding,
        child: child,
      ),
    );
  }
}
```

### 5.4 Theme Notifier

```dart
// core/theme/theme_notifier.dart

@riverpod
class ThemeNotifier extends _$ThemeNotifier {
  @override
  ThemeState build() {
    final prefs = ref.read(sharedPreferencesProvider);
    return ThemeState(
      themeId: prefs.getString('theme') ?? 'pure-bold',
      isDark:  prefs.getBool('isDark')  ?? false,
    );
  }

  Future<void> setTheme(String id) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString('theme', id);
    state = state.copyWith(themeId: id);
  }

  Future<void> toggleMode() async {
    final prefs = ref.read(sharedPreferencesProvider);
    final next = !state.isDark;
    await prefs.setBool('isDark', next);
    state = state.copyWith(isDark: next);
  }
}
```

---

## 6. Screen-by-Screen Specification

### 6.1 Bottom Navigation Structure

```
[ 📷 Scan ] [ 📦 Packages ] [ 🗺️ Map ] [ ⚙️ Settings ]
```

Custom bottom nav bar with `OffsetShadowCard`-styled active indicator. 4 tabs, one-thumb reachable.

### 6.2 Scan Screen

**Offline: ✅ Full**

- Full-screen `MobileScanner` camera view
- Animated scan reticle (accent color corner brackets)
- On scan success: bottom sheet with tracking number + "Add details" CTA
- Duplicate guard: if tracking ID already in SQLite, show warning snackbar
- `HapticFeedback.mediumImpact()` on scan
- Supported formats: QR Code, Code 128, Code 39, EAN-13, DataMatrix

### 6.3 Packages Screen (Main List)

**Offline: ✅ Full**

```
┌─────────────────────────────────────┐
│ 📡 Offline — all changes saved locally │  ← ConnectivityBanner (when offline)
│ 🔍 Search bar                        │
│ [📍 Location ▾] [📅 Date ▾] [💳 Type ▾] │
├─────────────────────────────────────┤
│ ≡  [Package Card]                   │
│ ≡  [Package Card]                   │
│ ...                                 │
├─────────────────────────────────────┤
│ Total Cash: ₱4,200 | Digital: ₱1,500 | Tips: ₱350 │  ← sticky summary
└─────────────────────────────────────┘
                   ＋ FAB
```

**Package Card:**
```
┌──────────────────────────────────────┐
│ [≡] 📦 #TRK-001234      [● Pending] │
│      Maria Santos                    │
│      📍 Zone 3, Divisoria, CDO       │
│      💵 Cash: ₱850  |  🏦 GCash: ₱0 │
│      🔁 Attempt 1    |  📅 Jun 13    │
└──────────────────────────────────────┘
```

Swipe right = delivered, swipe left = edit. Filter chips stack with AND logic. Filters persist in SharedPreferences across sessions.

### 6.4 Package Detail / Edit Screen

**Offline: ✅ Full**

Scrollable form: Package Info → Delivery Location → Payment → Delivery Attempts.

Payment auto-computes grand total live as fields change. Map thumbnail shows last saved pin coordinates (rendered from cached tiles or a static coordinate display if no tiles cached).

### 6.5 Map Screen

**Offline: ⚠️ Partial (markers full, tiles cached regions only)**

- `flutter_map` with `CacheBehavior.cacheFirst` tile provider
- All package markers loaded from SQLite — always available offline
- GPS "Center on me" button — works offline (device GPS)
- Gray tiles shown for uncached areas with a one-line notice:
  `"Some map areas not cached — download in Settings"`
- Pin placement fully offline (coordinates saved to SQLite)

### 6.6 Settings Screen

**Offline: ✅ Full (except tile download)**

Sections:
- **Appearance:** Theme grid + Light/Dark toggle
- **Notifications:** Proximity radius slider (200m – 2km), toggle alerts on/off
- **Offline Map:** Cache size display, download area button (disabled offline), clear cache
- **Timer:** Default duration, float style (Bubble / Bar)
- **Data:** Export CSV (offline), Clear delivered packages
- **Shift:** "End Shift" button — stops GPS/geofence to save battery
- **About:** App version, rider name

---

## 7. Core Features — Detailed Spec

### 7.1 Barcode / QR Scan

```dart
MobileScanner(
  controller: MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    returnImage: false,
  ),
  onDetect: (capture) {
    final trackingId = capture.barcodes.first.rawValue ?? '';
    ref.read(scanProvider.notifier).onScan(trackingId);
  },
)
```

### 7.2 Location Pinning

```dart
Future<void> _onConfirmPin(LatLng position) async {
  final label = await showModalBottomSheet<LocationLabel>(
    context: context,
    builder: (_) => PinLabelForm(),
  );
  if (label != null) {
    ref.read(packagesProvider.notifier).assignLocation(
      packageId: widget.packageId,
      lat: position.latitude,
      lng: position.longitude,
      street: label.street,
      zone: label.zone,
      barangay: label.barangay,
      city: label.city,
    );
    // Re-sync geofences after location change
    ref.read(geofenceManagerProvider).syncGeofences();
  }
}
```

### 7.3 COD & Payment Computation

```dart
class PaymentSummary {
  final double codCash;
  final double codDigital;
  final double tips;
  final double extras;

  double get totalCod   => codCash + codDigital;
  double get grandTotal => totalCod + tips + extras;
}
// Live-recomputed via TextEditingController listeners — no network needed
```

### 7.4 Delivery Attempts Log

```dart
class DeliveryAttempt {
  final int id;
  final String packageId;
  final DateTime timestamp;
  final String status;  // 'success' | 'failed' | 'no_answer' | 'refused'
  final String? notes;
}
// All writes go directly to SQLite — fully offline
```

At max attempts (configurable, default 3): card shows "Return to sender" warning banner.

---

## 8. Database Schema (SQLite)

SQLite is the **single source of truth**. All reads and writes go through it, online or offline.

```sql
-- packages
CREATE TABLE packages (
  id              TEXT PRIMARY KEY,
  tracking_number TEXT NOT NULL UNIQUE,
  receiver_name   TEXT,
  receiver_phone  TEXT,
  notes           TEXT,

  lat             REAL,
  lng             REAL,
  street          TEXT,
  zone            TEXT,
  barangay        TEXT,
  city            TEXT,

  payment_type    TEXT NOT NULL DEFAULT 'cod_cash',
  cod_cash        REAL NOT NULL DEFAULT 0,
  cod_digital     REAL NOT NULL DEFAULT 0,
  tips            REAL NOT NULL DEFAULT 0,
  extra_amount    REAL NOT NULL DEFAULT 0,
  extra_label     TEXT,

  status          TEXT NOT NULL DEFAULT 'pending',
  sort_order      INTEGER NOT NULL DEFAULT 0,
  created_at      TEXT NOT NULL,
  updated_at      TEXT NOT NULL,
  delivered_at    TEXT
);

-- delivery_attempts
CREATE TABLE delivery_attempts (
  id           INTEGER PRIMARY KEY AUTOINCREMENT,
  package_id   TEXT NOT NULL REFERENCES packages(id) ON DELETE CASCADE,
  status       TEXT NOT NULL,
  notes        TEXT,
  attempted_at TEXT NOT NULL
);

-- settings key-value store (persists user preferences beyond SharedPreferences)
CREATE TABLE settings (
  key   TEXT PRIMARY KEY,
  value TEXT NOT NULL
);

-- (Future) sync_queue — for optional dispatcher integration
-- Holds mutations that happened offline to be sent when back online
CREATE TABLE sync_queue (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  entity_type TEXT NOT NULL,   -- 'package' | 'attempt'
  entity_id   TEXT NOT NULL,
  operation   TEXT NOT NULL,   -- 'create' | 'update' | 'delete'
  payload     TEXT NOT NULL,   -- JSON
  created_at  TEXT NOT NULL,
  synced      INTEGER NOT NULL DEFAULT 0
);
```

**Indexes:**
```sql
CREATE INDEX idx_packages_barangay   ON packages(barangay);
CREATE INDEX idx_packages_city       ON packages(city);
CREATE INDEX idx_packages_status     ON packages(status);
CREATE INDEX idx_packages_created_at ON packages(created_at);
CREATE INDEX idx_packages_sort_order ON packages(sort_order);
CREATE INDEX idx_sync_queue_synced   ON sync_queue(synced);
```

**Bulk reorder:**
```dart
Future<void> updateSortOrders(List<String> orderedIds) async {
  final db = await _db;
  final batch = db.batch();
  for (int i = 0; i < orderedIds.length; i++) {
    batch.update('packages', {'sort_order': i},
        where: 'id = ?', whereArgs: [orderedIds[i]]);
  }
  await batch.commit(noResult: true);
}
```

---

## 9. Notifications & Geofencing (FCM + Background Location)

### 9.1 Offline/Online Decision Matrix

| Scenario                         | Solution                                           |
|----------------------------------|----------------------------------------------------|
| App foreground, any connectivity | `geolocator` stream + distance check               |
| App background, any connectivity | `geofence_service` + `flutter_local_notifications` |
| App killed, has internet         | FCM data message → local notification on receive   |
| App killed, no internet          | `geofence_service` background isolate (Android)    |
| No GPS signal                    | Notifications paused gracefully, no crash          |

### 9.2 Geofence Setup

```dart
Future<void> registerGeofences(List<Package> packages) async {
  final geofenceList = packages
    .where((p) => p.lat != null && p.status == 'pending')
    .map((p) => Geofence(
          id: p.id,
          latitude: p.lat!,
          longitude: p.lng!,
          radius: [GeofenceRadius(id: 'r_main', length: _radiusMeters)],
        ))
    .toList();

  await GeofenceService.instance.stop();
  if (geofenceList.isNotEmpty) {
    await GeofenceService.instance.start(geofenceList);
  }
}
```

### 9.3 FCM (Optional Online Enhancement)

```dart
// Only initialized if Firebase is configured and network is available
FirebaseMessaging.onBackgroundMessage(_backgroundHandler);

@pragma('vm:entry-point')
Future<void> _backgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  NotificationService().showFromFCM(message);
}
```

FCM is a progressive enhancement only. The app never requires FCM to function.

### 9.4 Required Permissions (Android)

```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
<uses-permission android:name="android.permission.VIBRATE" />
<uses-permission android:name="android.permission.INTERNET" />   <!-- for tile download only -->
```

---

## 10. Floating Timer Widget

**Offline: ✅ Full**

### 10.1 Behavior

- Draggable overlay persisting across all 4 tabs
- Two display modes: **Bubble** (80×80 circular) or **Bar** (slim pill)
- Controls: Start/Pause, Reset, +1/+5/+10 min, set custom duration
- Vibrate + local notification on completion (both work offline)

### 10.2 Flutter Overlay Implementation (Cross-Platform)

```dart
// features/timer/timer_overlay.dart

class TimerOverlayManager {
  OverlayEntry? _entry;

  void show(BuildContext context) {
    _entry?.remove();
    _entry = OverlayEntry(
      builder: (_) => const DraggableTimerBubble(),
    );
    Navigator.of(context).overlay!.insert(_entry!);
  }

  void hide() {
    _entry?.remove();
    _entry = null;
  }
}

class DraggableTimerBubble extends ConsumerStatefulWidget {
  const DraggableTimerBubble({super.key});

  @override
  ConsumerState<DraggableTimerBubble> createState() => _DraggableTimerBubbleState();
}

class _DraggableTimerBubbleState extends ConsumerState<DraggableTimerBubble> {
  Offset _position = const Offset(16, 100);

  @override
  Widget build(BuildContext context) {
    final timer = ref.watch(timerNotifierProvider);

    return Positioned(
      left: _position.dx,
      top: _position.dy,
      child: GestureDetector(
        onPanUpdate: (d) => setState(() => _position += d.delta),
        child: Material(
          color: Colors.transparent,
          child: OffsetShadowCard(
            shadowOffset: const Offset(3, 3),
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  timer.formattedTime,
                  style: const TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(timer.isRunning ? Icons.pause : Icons.play_arrow),
                      onPressed: timer.isRunning
                          ? ref.read(timerNotifierProvider.notifier).pause
                          : ref.read(timerNotifierProvider.notifier).start,
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: ref.read(timerNotifierProvider.notifier).reset,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

### 10.3 Timer Notifier

```dart
@riverpod
class TimerNotifier extends _$TimerNotifier {
  Timer? _ticker;

  @override
  TimerState build() => TimerState(
    duration:  const Duration(minutes: 30),
    remaining: const Duration(minutes: 30),
    isRunning: false,
  );

  void start() {
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.remaining.inSeconds <= 0) {
        _ticker?.cancel();
        _onDone();
      } else {
        state = state.copyWith(remaining: state.remaining - const Duration(seconds: 1));
      }
    });
    state = state.copyWith(isRunning: true);
  }

  void pause()        { _ticker?.cancel(); state = state.copyWith(isRunning: false); }
  void reset()        { pause(); state = state.copyWith(remaining: state.duration); }
  void addMinutes(int m) =>
      state = state.copyWith(remaining: state.remaining + Duration(minutes: m));

  void _onDone() {
    HapticFeedback.vibrate();
    ref.read(notificationServiceProvider).showTimerDone();
    state = state.copyWith(isRunning: false);
  }
}
```

---

## 11. Package Card Drag & Reorder

**Offline: ✅ Full**

### 11.1 Reorder Mode Toggle

```dart
bool _reorderMode = false;

// AppBar action:
IconButton(
  icon: Icon(_reorderMode ? Icons.check : Icons.sort),
  onPressed: () => setState(() => _reorderMode = !_reorderMode),
)
```

### 11.2 ReorderableListView

```dart
Widget _buildList(List<Package> packages) {
  if (_reorderMode) {
    return ReorderableListView.builder(
      itemCount: packages.length,
      onReorder: (oldIndex, newIndex) {
        ref.read(packagesProvider.notifier).reorder(oldIndex, newIndex);
      },
      itemBuilder: (ctx, i) => PackageCard(
        key: ValueKey(packages[i].id),
        package: packages[i],
        showDragHandle: true,
      ),
      proxyDecorator: (child, index, animation) => ScaleTransition(
        scale: animation.drive(Tween(begin: 1.0, end: 1.03)),
        child: Material(elevation: 0, color: Colors.transparent, child: child),
      ),
    );
  }
  return ListView.builder(
    itemCount: packages.length,
    itemBuilder: (ctx, i) => PackageCard(package: packages[i]),
  );
}
```

### 11.3 Reorder + SQLite Persistence

```dart
void reorder(int oldIndex, int newIndex) {
  final list = [...state.packages];
  if (newIndex > oldIndex) newIndex--;
  final item = list.removeAt(oldIndex);
  list.insert(newIndex, item);
  _dbHelper.updateSortOrders(list.map((p) => p.id).toList()); // writes to SQLite
  state = state.copyWith(packages: list);
}
```

---

## 12. AI Prompt to Bootstrap the Project

Use this prompt verbatim with Claude, Cursor, or any AI coding assistant:

---

```
You are a senior Flutter developer. Build a complete, offline-first Flutter mobile app 
called "BRAD" for delivery riders.

## Core Principle
The app MUST work without internet. Every feature that can work offline MUST work offline.
Features that require internet (FCM, map tile downloads) must fail gracefully without 
blocking the rider or showing error dialogs.

## Tech Stack
- Flutter (latest stable)
- State management: flutter_riverpod v2 with @riverpod code-gen
- Local DB: sqflite (single source of truth — all reads/writes go here)
- Barcode scanning: mobile_scanner
- Maps: flutter_map + latlong2 (OpenStreetMap, free, no API key)
- Offline map tiles: flutter_map_tile_caching (CacheBehavior.cacheFirst)
- Location: geolocator + geofence_service (GPS-based, works offline)
- Local notifications: flutter_local_notifications (works offline)
- FCM: firebase_messaging (optional enhancement, only when online)
- Connectivity: connectivity_plus
- Floating timer overlay: system_alert_window (Android) + Flutter Overlay (iOS/fallback)
- Navigation: go_router
- CSV export: csv package

## Offline-First Rules
1. SQLite is always the source of truth — read from it, write to it, always.
2. Never make a feature contingent on internet unless it is physically impossible offline.
3. GPS/geofencing works without internet — use it.
4. Local notifications work without internet — use them for geofence alerts and timer.
5. Map markers load from SQLite — always available. Tiles come from cache when offline.
6. Show a slim ConnectivityBanner at the top of every screen when offline.
7. Disable (not hide) buttons for online-only actions (tile download) with a tooltip explaining why.
8. Never show a crash, dialog, or blocking spinner because of a missing network.
9. FCM is never the only notification path for anything the rider needs during a shift.

## Offline Feature Matrix
| Feature                   | Works Offline? |
|---------------------------|----------------|
| Barcode/QR scan           | YES — full     |
| View / search packages    | YES — full     |
| Add / edit packages       | YES — full     |
| Drag-and-drop reorder     | YES — full     |
| Log delivery attempt      | YES — full     |
| Mark delivered/failed     | YES — full     |
| Floating timer            | YES — full     |
| Map markers               | YES — full     |
| Map tiles                 | PARTIAL — cached regions only; gray for uncached |
| GPS / current location    | YES — full     |
| Proximity alerts          | YES — GPS geofence + local notifications |
| CSV export                | YES — full     |
| FCM push from dispatcher  | NO — online only, graceful fallback |
| Tile download             | NO — online only, button disabled when offline |

## Design Requirements

### Offset Shadow Card System
Every card/button uses a "hard offset shadow" with blurRadius ALWAYS = 0.
```dart
BoxShadow(color: shadowColor, offset: Offset(3, 3), blurRadius: 0)
```
All interactive cards also have a matching border (color = shadowColor, width = 1.5px).

### Connectivity Banner
```dart
// Shown at top of every screen when offline:
AnimatedSwitcher(
  child: isOnline ? SizedBox.shrink() : Container(
    color: warningColor.withOpacity(0.15),
    child: Row(children: [
      Icon(Icons.wifi_off_rounded, color: warningColor),
      Text('Offline — all changes saved locally'),
    ]),
  ),
)
```

### Themes (8 total)
pure-bold, techy, friendly, corporate, playful, trailblazer, monochrome, rider-green.
Each theme has light + dark mode variants. Store selection in SharedPreferences.

Token structure per theme:
- bg, surface, surfaceAlt (backgrounds)
- primary, accent, accentSoft, accentRing (brand)
- text, textMuted, textSubtle, textInvert (typography)
- border, borderStrong (borders)
- shadowColor (changes per theme — used in offset shadows)
- inputBg, inputBorder, inputFocus (forms)

rider-green dark: bg=#0A1A0F, surface=#122A19, accent=#22C55E, shadowColor=rgba(209,250,229,0.7)
rider-green light: bg=#DCEEE2, surface=#EAF5EE, accent=#16A34A, shadowColor=#0A1A0F

Semantic colors (same all themes): success=#10B981, warning=#F59E0B, error=#EF4444, info=#3B82F6

### Typography
- Font sans: DM Sans
- Font heading: Geist
- Font mono: JetBrains Mono (used for tracking numbers and timer display)

## App Structure
4-tab bottom nav: Scan | Packages | Map | Settings

### Tab 1 — Scan (offline: full)
- Full-screen MobileScanner
- Animated reticle (accent color corner brackets)
- On scan: bottom sheet with tracking number + "Add details" CTA
- Duplicate guard against SQLite
- HapticFeedback.mediumImpact() on success

### Tab 2 — Packages (offline: full)
- ConnectivityBanner at top
- Search bar with offset shadow
- Filter chips: Location (barangay/city from SQLite), Date (today/week/custom), Type
- ReorderableListView with "reorder mode" toggle in AppBar
- Package card: tracking number, status badge, receiver name, location, COD breakdown, attempt count, date
- Swipe right = delivered, swipe left = edit
- Sticky bottom: total COD Cash | COD Digital | Tips (computed from SQLite)
- FAB: add/scan package

### Tab 3 — Map (offline: partial)
- flutter_map with CacheBehavior.cacheFirst tile provider
- All markers loaded from SQLite (always available)
- Color-coded markers by status
- Tap marker: package mini-card in bottom sheet
- FAB pin mode: crosshair + confirm + label form (saved to SQLite)
- "Center on me" (device GPS)
- When tiles fail: gray tile shown silently, no dialog or crash

### Tab 4 — Settings (offline: full except tile download)
- Theme grid picker (8 swatches)
- Light/Dark toggle
- Proximity radius slider (200m–2km)
- Offline Map section: cache size display, download button (disabled offline with tooltip), clear cache
- Timer default duration + float style
- Export CSV (fully offline)
- Clear delivered packages
- End Shift button (stops GPS/geofence to save battery)
- Rider name input

## SQLite Schema
```sql
CREATE TABLE packages (
  id TEXT PRIMARY KEY, tracking_number TEXT NOT NULL UNIQUE,
  receiver_name TEXT, receiver_phone TEXT, notes TEXT,
  lat REAL, lng REAL, street TEXT, zone TEXT, barangay TEXT, city TEXT,
  payment_type TEXT NOT NULL DEFAULT 'cod_cash',
  cod_cash REAL DEFAULT 0, cod_digital REAL DEFAULT 0,
  tips REAL DEFAULT 0, extra_amount REAL DEFAULT 0, extra_label TEXT,
  status TEXT NOT NULL DEFAULT 'pending',
  sort_order INTEGER NOT NULL DEFAULT 0,
  created_at TEXT NOT NULL, updated_at TEXT NOT NULL, delivered_at TEXT
);
CREATE TABLE delivery_attempts (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  package_id TEXT NOT NULL REFERENCES packages(id) ON DELETE CASCADE,
  status TEXT NOT NULL, notes TEXT, attempted_at TEXT NOT NULL
);
CREATE TABLE settings (key TEXT PRIMARY KEY, value TEXT NOT NULL);
CREATE INDEX idx_packages_barangay ON packages(barangay);
CREATE INDEX idx_packages_status ON packages(status);
CREATE INDEX idx_packages_sort_order ON packages(sort_order);
```

## Geofencing (offline)
- Register GPS geofences for all pending packages with lat/lng
- Use geofence_service package
- On ENTER: show local notification (receiver name + address) — no FCM needed
- Re-register geofences after every package change
- Handle gracefully when GPS unavailable (no crash)

## Offline Map Tiles
- Use flutter_map_tile_caching with store name 'BRAD_tiles'
- CacheBehavior.cacheFirst — serve from cache, try network only if tile missing from cache
- On first launch (if online and no tiles cached): offer to download current area
- Settings section: show cache size in MB + tile count, download button (online-gated), clear button
- errorTileCallback in TileLayer: do nothing (show gray tile silently)

## Floating Timer (offline: full)
- Draggable Flutter Overlay widget (works on both platforms)
- Modes: Bubble (80×80 circle) and Bar (slim pill)
- Controls: Start/Pause, Reset, +1/+5/+10 min, set duration
- On end: HapticFeedback.vibrate() + flutter_local_notifications (offline)
- Android: option for system_alert_window true overlay

## CSV Export (offline: full)
- Read all packages from SQLite
- Write CSV to app documents directory
- Share via platform share sheet (no internet needed for local share)

## Code Requirements
- Riverpod code-gen (@riverpod annotation) for all providers
- Each feature: screen + provider + data files
- No hardcoded colors — all from active theme tokens
- All cards use OffsetShadowCard (border 1.5px + blurRadius 0 shadow)
- const constructors everywhere possible
- Currency formatted as Philippine Peso (₱) using intl
- ConnectivityBanner included in every screen's Scaffold body Column

Generate: pubspec.yaml, main.dart, all feature files, theme system, DB helper, connectivity service, 
offline map cache service, geofence manager, notification service, and all screens with comments 
explaining offline behavior at each key decision point.
```

---

## Quick Reference — Key Widget Patterns

### ConnectivityBanner (every screen)
```dart
Column(children: [
  const ConnectivityBanner(),   // slim, auto-hides when online
  Expanded(child: /* screen content */),
])
```

### Status Badge
```dart
StatusBadge(status: package.status)
// pending → warning, delivered → success, failed → error, returned → info
```

### Payment Chip
```dart
PaymentChip(type: package.paymentType)
// cod_cash → accent, cod_digital → info, prepaid → success
```

### Online-Gated Button
```dart
ElevatedButton(
  onPressed: isOnline ? _onDownload : null,
  child: Text(isOnline ? 'Download map area' : 'Download (offline)'),
)
// Or with tooltip:
Tooltip(
  message: isOnline ? '' : 'Connect to download tiles',
  child: ElevatedButton(onPressed: isOnline ? _onDownload : null, ...),
)
```

---

## Developer Notes

1. **Philippines context:** Default currency ₱. Common platforms: GCash, Maya, bank. City autocomplete can pre-seed Cagayan de Oro, Cebu, Davao, Manila.

2. **Battery saving:** When rider taps "End Shift" in Settings, call `GeofenceService.instance.stop()` and cancel the location stream. Restart on next app open. This is important because continuous GPS drains battery fast.

3. **Performance:** `const` widgets everywhere. Package list uses `ListView.builder`. Apply `RepaintBoundary` around `flutter_map` and the scanner view. Filter/search queries run as parameterized SQL (`WHERE barangay = ? AND status = ?`), never in Dart.

4. **Tile pre-download UX:** Recommend riders download their delivery area at the start of a shift over Wi-Fi or LTE. A typical 10km radius at zoom 12–17 is roughly 40–80 MB. Show progress bar during download.

5. **Android overlay permission:** `system_alert_window` requires the user to grant "Display over other apps" in system settings. Show a clear explanation card in Settings before redirecting to the system screen.

6. **Geofence limits:** Android caps background geofence monitoring at 100 zones. For most riders this is fine. If a rider has more than 100 pending packages, monitor only the closest ones (sort by distance from current GPS position and register the top 100).

7. **Notifications on Android 13+:** Runtime notification permission is required. Request it at first launch using `permission_handler` before registering any local notifications.

---

*Generated for BRAD v1.0 — Flutter · SQLite · OSM · Offline-First*
