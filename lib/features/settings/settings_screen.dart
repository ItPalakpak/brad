import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/theme_notifier.dart';
import '../../core/services/geofence_manager.dart';
import '../../shared/widgets/connectivity_banner.dart';
import '../../shared/widgets/offset_shadow_card.dart';
import '../../shared/widgets/offset_shadow_button.dart';
import '../../shared/widgets/section_header.dart';
import '../../shared/widgets/brand_logo.dart';
import '../packages/packages_provider.dart';
import 'theme_picker.dart';
import 'offline_map_settings.dart';
import '../timer/timer_overlay.dart';
import 'badges_provider.dart';

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
    var savedName = prefs.getString('rider_name');
    
    // CHANGED: Auto-restore rider_name from public storage across app uninstalls if SharedPreferences was wiped
    if ((savedName == null || savedName == 'Rider') && Platform.isAndroid) {
      try {
        final profileFile = File('/storage/emulated/0/Download/BRAD_rider_profile.json');
        if (profileFile.existsSync()) {
          final data = jsonDecode(profileFile.readAsStringSync());
          if (data is Map && data['rider_name'] != null && data['rider_name'].toString().isNotEmpty) {
            savedName = data['rider_name'].toString();
            prefs.setString('rider_name', savedName);
          }
        }
      } catch (_) {}
    }

    _nameController = TextEditingController(
      text: savedName ?? 'Rider',
    );
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

    // CHANGED: Save persistent copy of rider_name to public storage to survive uninstalls
    try {
      if (Platform.isAndroid) {
        final file = File('/storage/emulated/0/Download/BRAD_rider_profile.json');
        await file.writeAsString(jsonEncode({'rider_name': name}));
      }
    } catch (_) {}
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
          content: Text(
            active
                ? 'Shift Started — Location monitoring active.'
                : 'Shift Ended — Location monitoring paused to save battery.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    // Watch database-driven badges & historical stats
    final badgesAsync = ref.watch(badgesNotifierProvider);
    final riderStats = badgesAsync.valueOrNull?.stats;

    final totalCount = riderStats?.totalPackages ?? 0;
    final successCount = riderStats?.successPackages ?? 0;
    final totalTips = riderStats?.totalTips ?? 0.0;

    // Calculate rating score
    double successRate = totalCount == 0 ? 0.0 : (successCount / totalCount) * 100.0;
    
    // Performance Score formula: Success rate with small tip multiplier
    double scoreRaw = successRate;
    if (totalTips > 0) {
      scoreRaw += (totalTips / 100.0).clamp(0.0, 5.0); // max +5 points for tips
    }
    final performanceScore = scoreRaw.clamp(0.0, 100.0).round();

    // Determine tier rank
    String rank = 'Bronze Runner';
    Color rankColor = const Color(0xFFCD7F32); // Bronze
    if (performanceScore >= 90 && successCount >= 10) {
      rank = 'Platinum Elite';
      rankColor = const Color(0xFFE5E4E2); // Platinum
    } else if (performanceScore >= 80 && successCount >= 5) {
      rank = 'Gold Speedster';
      rankColor = const Color(0xFFFFD700); // Gold
    } else if (performanceScore >= 60 && successCount >= 2) {
      rank = 'Silver Courier';
      rankColor = const Color(0xFFC0C0C0); // Silver
    }

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
                fontFamily: 'Syne',
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
                      const SectionHeader(
                        title: 'RIDER PROFILE',
                        icon: Icons.person_outline_rounded,
                      ),
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

                // Rider Gamification Performance Card
                OffsetShadowCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SectionHeader(
                        title: 'PERFORMANCE PROFILE',
                        icon: Icons.emoji_events_outlined,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          // CHANGED: Made rank chip interactive to open Rank details modal with rank history, current rank highlight, progress, and requirements
                          GestureDetector(
                            onTap: () {
                              _recordRankAchievementDate(rank);
                              _showRankDetailsModal(context, rank, performanceScore, successCount, tokens);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: rankColor.withValues(alpha: 0.15),
                                border: Border.all(color: rankColor, width: 2.0),
                                borderRadius: BorderRadius.zero,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    rank.toUpperCase(),
                                    style: TextStyle(
                                      color: tokens.text,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 11,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Icon(Icons.info_outline_rounded, size: 14, color: rankColor),
                                ],
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '$performanceScore PTS',
                            style: const TextStyle(
                              fontFamily: 'JetBrains Mono',
                              fontWeight: FontWeight.w900,
                              fontSize: 20,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Stat details
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildStatItem('Success Rate', '${successRate.toStringAsFixed(0)}%', tokens),
                          _buildStatItem('Deliveries', '$successCount', tokens),
                          _buildStatItem('Total Tips', '₱${totalTips.toStringAsFixed(0)}', tokens),
                        ],
                      ),
                      const Divider(height: 24),
                      
                      // Badges Unlocked Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'UNLOCKED BADGES',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: tokens.textSubtle,
                              letterSpacing: 0.5,
                            ),
                          ),
                          badgesAsync.maybeWhen(
                            data: (state) {
                              final totalUnlocked = state.badges.where((b) => b.unlocked).length;
                              return Text(
                                '$totalUnlocked / ${state.badges.length} UNLOCKED',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: tokens.accent,
                                  fontFamily: 'JetBrains Mono',
                                ),
                              );
                            },
                            orElse: () => const SizedBox.shrink(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      badgesAsync.when(
                        data: (state) {
                          final unlocked = state.badges.where((b) => b.unlocked).toList();
                          if (unlocked.isEmpty) {
                            return Container(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: tokens.surfaceAlt,
                                border: Border.all(color: tokens.border.withValues(alpha: 0.4)),
                              ),
                              child: Text(
                                'No badges unlocked yet. Start delivering to earn badges!',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: tokens.textSubtle,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          }
                          
                          // Show only 3 recent badges achieved by rider
                          final recent3 = unlocked.length > 3 ? unlocked.sublist(unlocked.length - 3) : unlocked;

                          return Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: recent3.map((badge) {
                              return _buildDynamicBadgeIcon(badge, tokens);
                            }).toList(),
                          );
                        },
                        loading: () => const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                        error: (err, stack) => Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            'Failed to load badges: $err',
                            style: const TextStyle(color: AppStatusColors.error, fontSize: 12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      OffsetShadowButton.outlined(
                        fullWidth: true,
                        foregroundColor: tokens.accent,
                        borderColor: tokens.border,
                        onPressed: () {
                          if (badgesAsync.hasValue) {
                            _showAllBadgesBottomSheet(context, badgesAsync.value!.badges);
                          }
                        },
                        child: const Text('VIEW ALL BADGES & PROGRESS'),
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
                      const SectionHeader(
                        title: 'SHIFT CONTROL',
                        icon: Icons.alarm_rounded,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isShiftActive ? 'ACTIVE SHIFT' : 'SHIFT OFF',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _isShiftActive
                                    ? 'GPS alerts running'
                                    : 'GPS paused to save battery',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: tokens.textSubtle,
                                ),
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
                      OffsetShadowButton.elevated(
                        backgroundColor: _isShiftActive
                            ? AppStatusColors.error
                            : AppStatusColors.success,
                        foregroundColor: Colors.white,
                        fullWidth: true,
                        onPressed: () => _toggleShift(!_isShiftActive),
                        child: Text(
                          _isShiftActive ? 'END SHIFT' : 'START SHIFT',
                        ),
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
                      const SectionHeader(
                        title: 'APPEARANCE',
                        icon: Icons.palette_outlined,
                      ),
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
                      const SectionHeader(
                        title: 'PROXIMITY ALARMS',
                        icon: Icons.notification_important_outlined,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Alert Radius',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            '${_proximityRadius.toInt()} meters',
                            style: const TextStyle(
                              fontFamily: 'JetBrains Mono',
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
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
                      const SectionHeader(
                        title: 'TIMER WIDGET',
                        icon: Icons.timer_outlined,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Full-Screen Shift Timers',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          OffsetShadowButton.elevated(
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
                      const SectionHeader(
                        title: 'DATA MANAGEMENT',
                        icon: Icons.backup_outlined,
                      ),
                      const SizedBox(height: 16),
                      OffsetShadowButton.icon(
                        fullWidth: true,
                        onPressed: () async {
                          try {
                            await ref
                                .read(packagesNotifierProvider.notifier)
                                .shareXlsx();
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

                      // CHANGED: Added 'RESTORE FROM SQL BACKUP' button to allow riders to restore historical/cleared data from locally saved SQL files
                      OffsetShadowButton.icon(
                        variant: OffsetButtonVariant.outlined,
                        fullWidth: true,
                        foregroundColor: tokens.accent,
                        borderColor: tokens.border,
                        onPressed: () => _showRestoreBackupDialog(context),
                        icon: const Icon(Icons.settings_backup_restore_rounded),
                        label: const Text('RESTORE FROM SQL BACKUP'),
                      ),
                      const SizedBox(height: 12),
                      OffsetShadowButton.icon(
                        variant: OffsetButtonVariant.outlined,
                        fullWidth: true,
                        foregroundColor: AppStatusColors.error,
                        borderColor: tokens.border,
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
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    const Text(
                                      'Clear Package Data?',
                                      style: TextStyle(
                                        fontFamily: 'Syne',
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    const Text(
                                      'This will automatically back up all shift data to an Excel file and then delete all packages with a status of "delivered", "failed", "returned", or "rejected" from the database.',
                                      style: TextStyle(fontSize: 13),
                                    ),
                                    const SizedBox(height: 20),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, false),
                                          style: TextButton.styleFrom(foregroundColor: AppStatusColors.error),
                                          child: const Text('CANCEL', textAlign: TextAlign.center),
                                        ),
                                        const SizedBox(width: 8),
                                        OffsetShadowButton.elevated(
                                          backgroundColor:
                                              AppStatusColors.error,
                                          foregroundColor: Colors.white,
                                          onPressed: () =>
                                              Navigator.pop(context, true),
                                          child: const Text(
                                            'CLEAR PACKAGES',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );

                          if (confirmed == true) {
                            await ref
                                .read(packagesNotifierProvider.notifier)
                                .clearDelivered();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Delivered and failed packages backed up and cleared.',
                                  ),
                                ),
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.delete_sweep_outlined),
                        label: const Text('CLEAR PACKAGE DATA'),
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

  // CHANGED: Added _showRestoreBackupDialog method to display list of available SQL backups and prompt for restoration
  void _showRestoreBackupDialog(BuildContext context) async {
    final notifier = ref.read(packagesNotifierProvider.notifier);
    final backups = await notifier.listSqlBackups();

    if (!context.mounted) return;
    final tokens = context.tokens;

    showDialog(
      context: context,
      builder: (outerContext) {
        return Dialog(
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
                  'Restore from SQL Backup',
                  style: TextStyle(
                    fontFamily: 'Syne',
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                if (backups.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24.0),
                    child: Text(
                      'No SQL backups found.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13),
                    ),
                  )
                else
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(outerContext).size.height * 0.4,
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: backups.length,
                      itemBuilder: (listContext, index) {
                        final file = backups[index];
                        final filename = file.path
                            .split('/')
                            .last
                            .split('\\')
                            .last;
                        String displayDate = filename;
                        try {
                          final datePart = filename
                              .replaceAll('BRAD_backup_autosave_', '')
                              .replaceAll('BRAD_backup_', '')
                              .replaceAll('.sql', '');
                          final year = int.parse(datePart.substring(0, 4));
                          final month = int.parse(datePart.substring(4, 6));
                          final day = int.parse(datePart.substring(6, 8));
                          final hour = int.parse(datePart.substring(9, 11));
                          final minute = int.parse(datePart.substring(11, 13));
                          final dt = DateTime(year, month, day, hour, minute);
                          final isAutosave = filename.contains('autosave');
                          displayDate = '${DateFormat('MMMM dd, yyyy - hh:mm a').format(dt)}${isAutosave ? ' (Autosave)' : ''}';
                        } catch (_) {
                          try {
                            displayDate = DateFormat('MMMM dd, yyyy - hh:mm a').format(file.lastModifiedSync());
                          } catch (_) {}
                        }

                        final isDownloadDir = file.path.toLowerCase().contains('download');
                        final locLabel = isDownloadDir ? '📍 Downloads Folder' : '📱 Internal Storage';

                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            displayDate,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            '$locLabel • $filename',
                            style: TextStyle(
                              fontSize: 11,
                              color: tokens.textSubtle,
                            ),
                          ),
                          trailing: Icon(
                            Icons.restore_rounded,
                            color: tokens.accent,
                          ),
                          onTap: () async {
                            final confirm = await showDialog<bool>(
                              context: outerContext,
                              builder: (dialogContext) => Dialog(
                                backgroundColor: Colors.transparent,
                                elevation: 0,
                                child: OffsetShadowCard(
                                  backgroundColor: tokens.surface,
                                  shadowColor: tokens.border,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      const Text(
                                        'Confirm Restore?',
                                        style: TextStyle(
                                          fontFamily: 'Syne',
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      const Text(
                                        'Are you sure you want to restore all data from this backup? Existing records with matching IDs will be updated.',
                                        style: TextStyle(fontSize: 13),
                                      ),
                                      const SizedBox(height: 20),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(
                                              dialogContext,
                                              false,
                                            ),
                                            style: TextButton.styleFrom(foregroundColor: AppStatusColors.error),
                                            child: const Text('CANCEL', textAlign: TextAlign.center),
                                          ),
                                          const SizedBox(width: 8),
                                          OffsetShadowButton.elevated(
                                            backgroundColor: tokens.accent,
                                            onPressed: () => Navigator.pop(
                                              dialogContext,
                                              true,
                                            ),
                                            child: const Text(
                                              'RESTORE',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );

                            if (confirm == true) {
                              if (!outerContext.mounted) return;
                              Navigator.pop(outerContext);
                              await notifier.restoreFromSqlBackup(file);
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Backup restored successfully!',
                                  ),
                                ),
                              );
                            }
                          },
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(outerContext),
                      child: Text(
                        'Close',
                        style: TextStyle(color: tokens.textSubtle),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value, AppColorTokens tokens) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: tokens.textSubtle, fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      ],
    );
  }

  Widget _buildDynamicBadgeIcon(RiderBadge badge, AppColorTokens tokens) {
    return GestureDetector(
      onTap: () => _showBadgeDetailDialog(context, badge, tokens),
      child: Tooltip(
        message: '${badge.title}\n${badge.description}',
        child: Container(
          width: 78,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: tokens.accentSoft,
            border: Border.all(
              color: tokens.accent,
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                badge.icon,
                size: 20,
                color: tokens.accent,
              ),
              const SizedBox(height: 4),
              Text(
                badge.title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: tokens.text,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAllBadgesBottomSheet(BuildContext context, List<RiderBadge> badges) {
    final tokens = context.tokens;
    String selectedCategory = 'All';
    String selectedStatus = 'All';
    
    final categories = ['All', 'Volume', 'Tips', 'Collections', 'Barangay', 'City', 'Rides', 'Consistency', 'Quality'];
    final statuses = ['All', 'Unlocked', 'Locked'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            // Filter badges
            final filteredBadges = badges.where((b) {
              final matchesCategory = selectedCategory == 'All' || b.category == selectedCategory;
              final matchesStatus = selectedStatus == 'All' ||
                  (selectedStatus == 'Unlocked' && b.unlocked) ||
                  (selectedStatus == 'Locked' && !b.unlocked);
              return matchesCategory && matchesStatus;
            }).toList();

            // Group filtered badges
            final Map<String, List<RiderBadge>> grouped = {};
            for (final b in filteredBadges) {
              grouped.putIfAbsent(b.category, () => []).add(b);
            }

            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: BoxDecoration(
                color: tokens.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                border: Border(
                  top: BorderSide(color: tokens.border, width: 2),
                  left: BorderSide(color: tokens.border, width: 2),
                  right: BorderSide(color: tokens.border, width: 2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Drag Handle
                  Center(
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: tokens.textSubtle.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  
                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'PERFORMANCE BADGES',
                          style: TextStyle(
                            fontFamily: 'Syne',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: tokens.text,
                          ),
                        ),
                        Text(
                          '${badges.where((b) => b.unlocked).length} / ${badges.length} UNLOCKED',
                          style: TextStyle(
                            fontFamily: 'JetBrains Mono',
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: tokens.accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 16),
                  
                  // Filters Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'GROUP FILTER',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: tokens.textSubtle,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        SizedBox(
                          height: 32,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: categories.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 8),
                            itemBuilder: (context, index) {
                              final cat = categories[index];
                              return _buildFilterChip(
                                label: cat,
                                selected: selectedCategory == cat,
                                onTap: () {
                                  setModalState(() {
                                    selectedCategory = cat;
                                  });
                                },
                                tokens: tokens,
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'STATUS FILTER',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: tokens.textSubtle,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: statuses.map((status) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: _buildFilterChip(
                                label: status,
                                selected: selectedStatus == status,
                                onTap: () {
                                  setModalState(() {
                                    selectedStatus = status;
                                  });
                                },
                                tokens: tokens,
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 16),
                  
                  // Badges List / Grid
                  Expanded(
                    child: filteredBadges.isEmpty
                        ? Center(
                            child: Text(
                              'No badges match the selected filters.',
                              style: TextStyle(
                                fontSize: 13,
                                color: tokens.textSubtle,
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            itemCount: grouped.keys.length,
                            itemBuilder: (context, index) {
                              final categoryName = grouped.keys.elementAt(index);
                              final categoryBadges = grouped[categoryName]!;
                              final unlockedCount = categoryBadges.where((b) => b.unlocked).length;
                              
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          categoryName.toUpperCase(),
                                          style: TextStyle(
                                            fontFamily: 'Syne',
                                            fontSize: 13,
                                            fontWeight: FontWeight.w800,
                                            color: tokens.text,
                                          ),
                                        ),
                                        Text(
                                          '$unlockedCount / ${categoryBadges.length} Unlocked',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: tokens.textSubtle,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  GridView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 4,
                                      mainAxisSpacing: 8,
                                      crossAxisSpacing: 8,
                                      childAspectRatio: 0.8,
                                    ),
                                    itemCount: categoryBadges.length,
                                    itemBuilder: (context, idx) {
                                      final b = categoryBadges[idx];
                                      return _buildBadgeDetailItem(context, b, tokens);
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                ],
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    required AppColorTokens tokens,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? tokens.accent : tokens.surfaceAlt,
          border: Border.all(color: tokens.border, width: 1.5),
        ),
        child: Text(
          label.toUpperCase(),
          style: TextStyle(
            color: selected ? Colors.white : tokens.text,
            fontWeight: FontWeight.bold,
            fontSize: 10,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildBadgeDetailItem(BuildContext context, RiderBadge badge, AppColorTokens tokens) {
    return GestureDetector(
      onTap: () => _showBadgeDetailDialog(context, badge, tokens),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: badge.unlocked ? tokens.accentSoft : tokens.surfaceAlt,
          border: Border.all(
            color: badge.unlocked ? tokens.accent : tokens.border.withValues(alpha: 0.4),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              badge.icon,
              size: 24,
              color: badge.unlocked ? tokens.accent : tokens.textSubtle.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 6),
            Text(
              badge.title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: badge.unlocked ? tokens.text : tokens.textSubtle.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBadgeDetailDialog(BuildContext context, RiderBadge badge, AppColorTokens tokens) {
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: OffsetShadowCard(
          backgroundColor: tokens.surface,
          shadowColor: tokens.border,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: badge.unlocked ? tokens.accentSoft : tokens.surfaceAlt,
                      border: Border.all(
                        color: badge.unlocked ? tokens.accent : tokens.border.withValues(alpha: 0.4),
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      badge.icon,
                      color: badge.unlocked ? tokens.accent : tokens.textSubtle.withValues(alpha: 0.4),
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          badge.title,
                          style: TextStyle(
                            fontFamily: 'Syne',
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: tokens.text,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: tokens.accentSoft,
                                border: Border.all(color: tokens.accent, width: 1),
                              ),
                              child: Text(
                                badge.category.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: tokens.accent,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppStatusColors.success.withValues(alpha: 0.15),
                                border: Border.all(color: AppStatusColors.success, width: 1),
                              ),
                              child: Text(
                                '+${badge.points} PTS',
                                style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: AppStatusColors.success,
                                  fontFamily: 'JetBrains Mono',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                badge.description,
                style: TextStyle(
                  fontSize: 13,
                  color: tokens.text,
                ),
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Status:',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: tokens.textSubtle,
                    ),
                  ),
                  Text(
                    badge.unlocked ? 'UNLOCKED' : 'LOCKED',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: badge.unlocked ? AppStatusColors.success : AppStatusColors.error,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Achieved On:',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: tokens.textSubtle,
                    ),
                  ),
                  Text(
                    badge.unlocked
                        ? (badge.unlockedAt != null
                            ? DateFormat('MMM dd, yyyy · hh:mm a').format(badge.unlockedAt!)
                            : 'Unlocked')
                        : 'In Progress',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: badge.unlocked ? tokens.text : tokens.textSubtle,
                      fontFamily: 'JetBrains Mono',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Requirement:',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: tokens.textSubtle,
                    ),
                  ),
                  Flexible(
                    child: Text(
                      badge.requirement,
                      textAlign: TextAlign.end,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: tokens.text,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Progress:',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: tokens.textSubtle,
                    ),
                  ),
                  Text(
                    '${badge.currentValue.toStringAsFixed(0)} / ${badge.targetValue.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: badge.unlocked ? tokens.accent : tokens.textSubtle,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: badge.progress,
                backgroundColor: tokens.surfaceAlt,
                valueColor: AlwaysStoppedAnimation<Color>(badge.unlocked ? tokens.accent : tokens.textSubtle.withValues(alpha: 0.5)),
              ),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerRight,
                child: OffsetShadowButton.elevated(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('CLOSE'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // CHANGED: Persists rank unlock timestamp in SharedPreferences when achieved
  Future<void> _recordRankAchievementDate(String rank) async {
    final prefs = ref.read(sharedPreferencesProvider);
    final ranksOrder = ['Bronze Runner', 'Silver Courier', 'Gold Speedster', 'Platinum Elite'];
    final currentIndex = ranksOrder.indexOf(rank);
    final nowStr = DateTime.now().toIso8601String();

    for (int i = 0; i <= currentIndex; i++) {
      if (i < 0) continue;
      final rName = ranksOrder[i];
      final key = 'rank_achieved_$rName';
      if (!prefs.containsKey(key)) {
        await prefs.setString(key, nowStr);
      }
    }
  }

  // CHANGED: Displays interactive modal showing all ranks, requirements, current rank highlight, progress to next rank, and achieved timestamps
  void _showRankDetailsModal(
    BuildContext context,
    String currentRank,
    int performanceScore,
    int successCount,
    AppColorTokens tokens,
  ) {
    final prefs = ref.read(sharedPreferencesProvider);

    final ranks = [
      _RankDetailSpec('Bronze Runner', const Color(0xFFCD7F32), 'Default starting tier (< 60 PTS)', 0, 0, 'Initial tier for all active delivery riders.'),
      _RankDetailSpec('Silver Courier', const Color(0xFFC0C0C0), 'Score ≥ 60 PTS & ≥ 2 deliveries', 60, 2, 'Earned by completing early deliveries reliably.'),
      _RankDetailSpec('Gold Speedster', const Color(0xFFFFD700), 'Score ≥ 80 PTS & ≥ 5 deliveries', 80, 5, 'High performance and consistent delivery speed.'),
      _RankDetailSpec('Platinum Elite', const Color(0xFFE5E4E2), 'Score ≥ 90 PTS & ≥ 10 deliveries', 90, 10, 'Top-tier master courier with outstanding service.'),
    ];

    final ranksOrder = ranks.map((r) => r.name).toList();
    final currentIndex = ranksOrder.indexOf(currentRank);
    final nextRank = currentIndex < ranks.length - 1 ? ranks[currentIndex + 1] : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: BoxDecoration(
            color: tokens.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            border: Border(
              top: BorderSide(color: tokens.border, width: 2),
              left: BorderSide(color: tokens.border, width: 2),
              right: BorderSide(color: tokens.border, width: 2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: tokens.textSubtle.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'RIDER RANK & PROGRESS',
                      style: TextStyle(
                        fontFamily: 'Syne',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: tokens.text,
                      ),
                    ),
                    Text(
                      '$performanceScore PTS',
                      style: TextStyle(
                        fontFamily: 'JetBrains Mono',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: tokens.accent,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 16),
              
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Next Rank Progress Section
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: tokens.surfaceAlt,
                        border: Border.all(color: tokens.border, width: 1.5),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'PROGRESS TO NEXT RANK',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: tokens.textSubtle,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          if (nextRank != null) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Next: ${nextRank.name}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: nextRank.color,
                                  ),
                                ),
                                Text(
                                  '${(nextRank.minScore - performanceScore).clamp(0, 100)} PTS needed',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: tokens.textSubtle,
                                    fontFamily: 'JetBrains Mono',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            LinearProgressIndicator(
                              value: (performanceScore / nextRank.minScore).clamp(0.0, 1.0),
                              backgroundColor: tokens.border.withValues(alpha: 0.2),
                              valueColor: AlwaysStoppedAnimation<Color>(nextRank.color),
                            ),
                          ] else ...[
                            Text(
                              '👑 MAXIMUM RANK ACHIEVED! Top courier tier unlocked.',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: tokens.accent,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    Text(
                      'ALL AVAILABLE RANKS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: tokens.textSubtle,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 10),

                    ...ranks.map((rSpec) {
                      final isCurrent = rSpec.name == currentRank;
                      final rIndex = ranksOrder.indexOf(rSpec.name);
                      final isAchieved = rIndex <= currentIndex;
                      final dateStr = prefs.getString('rank_achieved_${rSpec.name}');
                      DateTime? achievedDt;
                      if (dateStr != null) {
                        achievedDt = DateTime.tryParse(dateStr);
                      }

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? rSpec.color.withValues(alpha: 0.15)
                              : (isAchieved ? tokens.surfaceAlt : tokens.bg),
                          border: Border.all(
                            color: isCurrent ? rSpec.color : tokens.border,
                            width: isCurrent ? 2.5 : 1.5,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: rSpec.color,
                                    borderRadius: BorderRadius.zero,
                                  ),
                                  child: Text(
                                    rSpec.name.toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (isCurrent)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: tokens.accent,
                                      borderRadius: BorderRadius.zero,
                                    ),
                                    child: const Text(
                                      'CURRENT RANK',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 9,
                                      ),
                                    ),
                                  ),
                                const Spacer(),
                                Icon(
                                  isAchieved ? Icons.check_circle : Icons.lock_outline,
                                  size: 18,
                                  color: isAchieved ? rSpec.color : tokens.textSubtle,
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              rSpec.desc,
                              style: TextStyle(fontSize: 12, color: tokens.text),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Requirements:',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: tokens.textSubtle,
                                  ),
                                ),
                                Flexible(
                                  child: Text(
                                    rSpec.req,
                                    textAlign: TextAlign.end,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: tokens.text,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Achieved On:',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: tokens.textSubtle,
                                  ),
                                ),
                                Text(
                                  isAchieved
                                      ? (achievedDt != null
                                          ? DateFormat('MMM dd, yyyy · hh:mm a').format(achievedDt)
                                          : 'Achieved')
                                      : 'Locked',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isAchieved ? rSpec.color : tokens.textSubtle,
                                    fontFamily: 'JetBrains Mono',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RankDetailSpec {
  final String name;
  final Color color;
  final String req;
  final int minScore;
  final int minDeliveries;
  final String desc;

  _RankDetailSpec(this.name, this.color, this.req, this.minScore, this.minDeliveries, this.desc);
}
