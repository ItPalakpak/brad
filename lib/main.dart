import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:permission_handler/permission_handler.dart';

import 'app/router.dart';
import 'core/theme/theme_notifier.dart';
import 'core/theme/themes/all_themes.dart';
import 'core/theme/app_theme.dart';
import 'core/services/notification_service.dart';
import 'core/services/map_cache_service.dart';
import 'core/services/geofence_manager.dart';
import 'core/services/fcm_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase (fail silently if offline or not configured)
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase initialization skipped: $e');
  }

  // Initialize SharedPreferences
  final prefs = await SharedPreferences.getInstance();

  // Initialize Services
  final notificationService = NotificationService();
  await notificationService.init();

  final mapCacheService = MapCacheService();
  await mapCacheService.init();

  // Initialize FCM Push Notifications
  final fcmService = FcmService(notificationService);
  await fcmService.init();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        notificationServiceProvider.overrideWithValue(notificationService),
        mapCacheServiceProvider.overrideWithValue(mapCacheService),
      ],
      child: const BradApp(),
    ),
  );
}

class BradApp extends ConsumerStatefulWidget {
  const BradApp({super.key});

  @override
  ConsumerState<BradApp> createState() => _BradAppState();
}

class _BradAppState extends ConsumerState<BradApp> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Request notification and location permissions on startup
    await [
      Permission.notification,
      Permission.location,
      Permission.locationAlways,
    ].request();

    // Initialize geofencing after permissions are requested
    final geofenceMgr = ref.read(geofenceManagerProvider);
    await geofenceMgr.initialize();
    await geofenceMgr.syncGeofences();
  }

  @override
  Widget build(BuildContext context) {
    final themeState = ref.watch(themeNotifierProvider);
    final tokens = AppThemes.getTokens(themeState.themeId, themeState.isDark);
    final themeData = AppTheme.generateThemeData(tokens, themeState.isDark);

    return AppThemeScope(
      themeId: themeState.themeId,
      tokens: tokens,
      isDark: themeState.isDark,
      child: MaterialApp.router(
        title: 'BRAD',
        theme: themeData,
        routerConfig: appRouter,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
