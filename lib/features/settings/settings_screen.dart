import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/theme_notifier.dart';
import '../../core/services/geofence_manager.dart';
import '../../shared/widgets/connectivity_banner.dart';
import '../../shared/widgets/offset_shadow_card.dart';
import '../../shared/widgets/section_header.dart';
import '../../shared/widgets/brand_logo.dart';
import '../packages/packages_provider.dart';
import 'theme_picker.dart';
import 'offline_map_settings.dart';
import '../timer/timer_overlay.dart';


class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late TextEditingController _nameController;
  double _proximityRadius = 500.0;
  bool _isShiftActive = true;

  @override
  void initState() {
    super.initState();
    final prefs = ref.read(sharedPreferencesProvider);
    _nameController = TextEditingController(text: prefs.getString('rider_name') ?? 'Rider');
    _proximityRadius = prefs.getDouble('proximity_radius') ?? 500.0;
    _isShiftActive = prefs.getBool('is_shift_active') ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveRiderName(String name) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString('rider_name', name);
  }

  Future<void> _updateProximityRadius(double val) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setDouble('proximity_radius', val);
    setState(() {
      _proximityRadius = val;
    });
    // Sync radius inside geofence manager
    ref.read(geofenceManagerProvider).setAlertRadius(val);
  }



  Future<void> _toggleShift(bool active) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool('is_shift_active', active);
    setState(() {
      _isShiftActive = active;
    });
    // Sync geofences state
    ref.read(geofenceManagerProvider).setShiftActive(active);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(active ? 'Shift Started — Location monitoring active.' : 'Shift Ended — Location monitoring paused to save battery.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            BrandLogo(type: BrandLogoType.icon, height: 32),
            const SizedBox(width: 8),
            Text(
              'SETTINGS',
              style: TextStyle(
                color: tokens.text,
                fontFamily: 'Geist',
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          const ConnectivityBanner(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                // Brand Header Banner
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24.0),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        BrandLogo(type: BrandLogoType.mark, height: 80),
                        const SizedBox(height: 12),
                        Text(
                          'Last-Mile Delivery Rider App',
                          style: TextStyle(
                            fontSize: 12,
                            color: tokens.textSubtle,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Profile Section
                OffsetShadowCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SectionHeader(title: 'RIDER PROFILE', icon: Icons.person_outline_rounded),
                      const SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.zero,
                          boxShadow: [AppShadows.offsetSm(tokens.shadowColor)],
                        ),
                        child: TextField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Rider Name',
                          ),
                          onChanged: _saveRiderName,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Shift Toggle Section (Battery Saver)
                OffsetShadowCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SectionHeader(title: 'SHIFT CONTROL', icon: Icons.alarm_rounded),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isShiftActive ? 'ACTIVE SHIFT' : 'SHIFT OFF',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _isShiftActive ? 'GPS alerts running' : 'GPS paused to save battery',
                                style: TextStyle(fontSize: 11, color: tokens.textSubtle),
                              ),
                            ],
                          ),
                          Switch(
                            value: _isShiftActive,
                            onChanged: _toggleShift,
                            activeThumbColor: tokens.accent,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isShiftActive ? AppStatusColors.error : AppStatusColors.success,
                        ),
                        onPressed: () => _toggleShift(!_isShiftActive),
                        child: Text(_isShiftActive ? 'END SHIFT' : 'START SHIFT'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Theme section
                OffsetShadowCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SectionHeader(title: 'APPEARANCE', icon: Icons.palette_outlined),
                      const SizedBox(height: 16),
                      const ThemePicker(),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Proximity Alarm Settings
                OffsetShadowCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SectionHeader(title: 'PROXIMITY ALARMS', icon: Icons.notification_important_outlined),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Alert Radius', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          Text(
                            '${_proximityRadius.toInt()} meters',
                            style: const TextStyle(fontFamily: 'JetBrains Mono', fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ],
                      ),
                      Slider(
                        value: _proximityRadius,
                        min: 200,
                        max: 2000,
                        divisions: 18,
                        activeColor: tokens.accent,
                        inactiveColor: tokens.surfaceAlt,
                        onChanged: _updateProximityRadius,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Offline Map caching
                const OfflineMapSettingsSection(),
                const SizedBox(height: 16),

                // Timer widget launcher
                OffsetShadowCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SectionHeader(title: 'TIMER WIDGET', icon: Icons.timer_outlined),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Full-Screen Shift Timers', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          ElevatedButton(
                            onPressed: () {
                              TimerOverlayManager.instance.show(context, ref);
                            },
                            child: const Text('OPEN TIMERS'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Data management settings
                OffsetShadowCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SectionHeader(title: 'DATA MANAGEMENT', icon: Icons.backup_outlined),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () async {
                          try {
                            await ref.read(packagesNotifierProvider.notifier).shareXlsx();
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Export failed: $e')),
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.share_rounded),
                        label: const Text('EXPORT SHIFT DATA (XLSX)'),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (context) => Dialog(
                              backgroundColor: Colors.transparent,
                              elevation: 0,
                              child: OffsetShadowCard(
                                backgroundColor: tokens.surface,
                                shadowColor: tokens.border,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    const Text(
                                      'Clear Delivered Packages?',
                                      style: TextStyle(fontFamily: 'Geist', fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    const SizedBox(height: 12),
                                    const Text(
                                      'This will delete all packages with a status of "delivered" from SQLite database to free up space.',
                                      style: TextStyle(fontSize: 13),
                                    ),
                                    const SizedBox(height: 20),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context, false),
                                          child: const Text('CANCEL'),
                                        ),
                                        const SizedBox(width: 8),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(backgroundColor: AppStatusColors.error),
                                          onPressed: () => Navigator.pop(context, true),
                                          child: const Text('CLEAR DELIVERED', style: TextStyle(color: Colors.white)),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );

                          if (confirmed == true) {
                            await ref.read(packagesNotifierProvider.notifier).clearDelivered();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Delivered packages cleared.')),
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.delete_sweep_outlined, color: AppStatusColors.error),
                        label: const Text('CLEAR DELIVERED PACKAGES', style: TextStyle(color: AppStatusColors.error)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
