import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../shared/widgets/connectivity_banner.dart';
import '../../shared/widgets/offset_shadow_card.dart';
import '../../shared/widgets/offset_shadow_button.dart';
import '../../shared/widgets/brand_logo.dart';
import '../../shared/utils/currency_formatter.dart';
import '../../core/database/db_helper.dart';
import '../../shared/widgets/status_badge.dart';
import 'packages_provider.dart';
import 'package:brad/features/packages/package_card.dart';

class PackagesScreen extends ConsumerStatefulWidget {
  const PackagesScreen({super.key});

  @override
  ConsumerState<PackagesScreen> createState() => _PackagesScreenState();
}

class _PackagesScreenState extends ConsumerState<PackagesScreen> {
  final TextEditingController _searchController = TextEditingController();
  int _currentTab = 0; // 0 = Packages List, 1 = Totals & Stats

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      ref.read(packagesNotifierProvider.notifier).setSearchQuery(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(packagesNotifierProvider);
    final notifier = ref.read(packagesNotifierProvider.notifier);
    final tokens = context.tokens;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            BrandLogo(type: BrandLogoType.icon, height: 32),
            const SizedBox(width: 8),
            Text(
              'PACKAGES',
              style: TextStyle(
                color: tokens.text,
                fontFamily: 'Geist',
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () => notifier.refresh(),
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                const ConnectivityBanner(),

                // Search Bar
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.zero,
                      boxShadow: [AppShadows.offsetMd(tokens.shadowColor)],
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search tracking #, name, barangay...',
                        prefixIcon: Icon(Icons.search_rounded, color: tokens.textSubtle),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded),
                                onPressed: () {
                                  _searchController.clear();
                                },
                              )
                            : null,
                      ),
                    ),
                  ),
                ),

                // Stackable Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  clipBehavior: Clip.none,
                  child: Row(
                    children: [
                      // Status Filter
                      _buildFilterChip(
                        label: state.statusFilters.isEmpty
                            ? 'All Statuses'
                            : (state.statusFilters.length == 1
                                ? state.statusFilters.first.toUpperCase()
                                : 'Statuses (${state.statusFilters.length})'),
                        isActive: state.statusFilters.isNotEmpty,
                        onTap: () => _showStatusFilterDialog(context, state.statusFilters, state.uniqueStatuses, notifier),
                      ),
                      const SizedBox(width: 8),

                      // Location Barangay Filter
                      _buildFilterChip(
                        label: state.barangayFilters.isEmpty
                            ? 'All Barangays'
                            : (state.barangayFilters.length == 1
                                ? state.barangayFilters.first
                                : 'Barangays (${state.barangayFilters.length})'),
                        isActive: state.barangayFilters.isNotEmpty,
                        onTap: () => _showBarangayFilterDialog(context, state.barangayFilters, state.uniqueBarangays, notifier),
                      ),
                      const SizedBox(width: 8),

                      // Payment Type Filter
                      _buildFilterChip(
                        label: state.paymentTypeFilters.isEmpty
                            ? 'All Payments'
                            : (state.paymentTypeFilters.length == 1
                                ? (state.paymentTypeFilters.first == 'cod_cash'
                                    ? 'COD Cash'
                                    : (state.paymentTypeFilters.first == 'cod_digital' ? 'COD Digital' : 'Prepaid'))
                                : 'Payments (${state.paymentTypeFilters.length})'),
                        isActive: state.paymentTypeFilters.isNotEmpty,
                        onTap: () => _showPaymentFilterDialog(context, state.paymentTypeFilters, state.uniquePaymentTypes, notifier),
                      ),

                      // Clear Filters Button
                      if (state.statusFilters.isNotEmpty || state.barangayFilters.isNotEmpty || state.paymentTypeFilters.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        TextButton.icon(
                          onPressed: () => notifier.clearFilters(),
                          icon: const Icon(Icons.clear_all_rounded, size: 16),
                          label: const Text('Clear', style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Custom Tab Switcher
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: tokens.border, width: 2.0),
                      boxShadow: [AppShadows.offsetSm(tokens.shadowColor)],
                      color: tokens.surface,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _currentTab = 0;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              color: _currentTab == 0 ? tokens.accent : tokens.surface,
                              alignment: Alignment.center,
                              child: Text(
                                'PACKAGES LIST',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: _currentTab == 0 ? Colors.white : tokens.text,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Container(
                          width: 2.0,
                          height: 38,
                          color: tokens.border,
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _currentTab = 1;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              color: _currentTab == 1 ? tokens.accent : tokens.surface,
                              alignment: Alignment.center,
                              child: Text(
                                "TODAY'S TOTALS",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: _currentTab == 1 ? Colors.white : tokens.text,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Tab Content View
                if (_currentTab == 0) ...[
                  // Grouped Packages List
                  Expanded(
                    child: state.packages.isEmpty && state.activeRide == null
                        ? _buildEmptyState(tokens)
                        : _buildGroupedPackages(tokens, state.packages, state.activeRide, state.todayRides, notifier),
                  ),
                  // Sticky Bottom Summary Bar
                  _buildSummaryBar(tokens, state.summary),
                ] else ...[
                  Expanded(
                    child: _buildTotalsAndStatsTab(tokens, state.packages, state.activeRide, state.todayRides),
                  ),
                ],
              ],
            ),
    );
  }

  Widget _buildGroupedPackages(
    AppColorTokens tokens,
    List<Package> packages,
    Ride? activeRide,
    List<Ride> todayRides,
    PackagesNotifier notifier,
  ) {
    final Map<String?, List<Package>> grouped = {};
    for (final p in packages) {
      grouped.putIfAbsent(p.rideId, () => []).add(p);
    }

    final List<Widget> children = [];

    children.add(_buildRideBannerCard(tokens, activeRide, notifier));
    children.add(const SizedBox(height: 12));

    if (activeRide != null) {
      final ridePkgs = grouped[activeRide.id] ?? [];
      children.add(_buildRideGroupHeader(
        tokens,
        title: 'RIDE #${activeRide.rideNumber} (ACTIVE)',
        timeStr: 'Started at ${DateFormat('hh:mm a').format(activeRide.startedAt)}',
        packages: ridePkgs,
      ));
      if (ridePkgs.isEmpty) {
        children.add(_buildNoPackagesInGroup(tokens, 'No packages added to this ride yet. Scan packages or add them to assign.'));
      } else {
        children.add(_buildPackagesListView(ridePkgs));
      }
      children.add(const SizedBox(height: 16));
    }

    final completedRides = todayRides.where((r) => r.endedAt != null).toList();
    for (final ride in completedRides) {
      final ridePkgs = grouped[ride.id] ?? [];
      final startStr = DateFormat('hh:mm a').format(ride.startedAt);
      final endStr = DateFormat('hh:mm a').format(ride.endedAt!);
      children.add(_buildRideGroupHeader(
        tokens,
        title: 'RIDE #${ride.rideNumber} (COMPLETED)',
        timeStr: '$startStr - $endStr',
        packages: ridePkgs,
      ));
      if (ridePkgs.isEmpty) {
        children.add(_buildNoPackagesInGroup(tokens, 'No packages were handled in this ride.'));
      } else {
        children.add(_buildPackagesListView(ridePkgs));
      }
      children.add(const SizedBox(height: 16));
    }

    final unassignedPkgs = grouped[null] ?? [];
    if (unassignedPkgs.isNotEmpty || (activeRide == null && completedRides.isEmpty)) {
      children.add(_buildRideGroupHeader(
        tokens,
        title: 'UNASSIGNED PACKAGES',
        timeStr: 'Not assigned to any ride',
        packages: unassignedPkgs,
      ));
      if (unassignedPkgs.isEmpty) {
        children.add(_buildNoPackagesInGroup(tokens, 'All packages have been assigned to rides.'));
      } else {
        children.add(_buildPackagesListView(unassignedPkgs));
      }
      children.add(const SizedBox(height: 16));
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: children,
    );
  }

  Widget _buildRideBannerCard(
    AppColorTokens tokens,
    Ride? activeRide,
    PackagesNotifier notifier,
  ) {
    if (activeRide == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: tokens.surface,
          border: Border.all(color: tokens.border, width: 1.5),
          boxShadow: [AppShadows.offsetSm(tokens.shadowColor)],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'No Active Ride',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: tokens.text),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Start a ride to automatically group scanned packages.',
                    style: TextStyle(fontSize: 12, color: tokens.textSubtle),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            OffsetShadowButton.elevated(
              onPressed: () => notifier.startRide(),
              backgroundColor: tokens.accent,
              child: const Text(
                'START RIDE',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: tokens.surface,
          border: Border.all(color: tokens.border, width: 1.5),
          boxShadow: [AppShadows.offsetSm(tokens.shadowColor)],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'RIDE #${activeRide.rideNumber} IS ACTIVE',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: tokens.accent),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'All newly scanned packages will be added here.',
                    style: TextStyle(fontSize: 12, color: tokens.textSubtle),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            OffsetShadowButton.elevated(
              onPressed: () => _confirmEndRide(context, notifier),
              backgroundColor: AppStatusColors.error,
              child: const Text(
                'END RIDE',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ],
        ),
      );
    }
  }

  void _confirmEndRide(BuildContext context, PackagesNotifier notifier) {
    final tokens = context.tokens;
    showDialog(
      context: context,
      builder: (context) {
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
                  'End Current Ride?',
                  style: TextStyle(fontFamily: 'Geist', fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 12),
                Text(
                  'Are you sure you want to end this ride? Any packages not yet delivered will be moved back to unassigned.',
                  style: TextStyle(fontSize: 13, color: tokens.textSubtle),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Cancel', style: TextStyle(color: tokens.textSubtle)),
                    ),
                    const SizedBox(width: 8),
                    OffsetShadowButton.elevated(
                      onPressed: () {
                        notifier.endRide();
                        Navigator.pop(context);
                      },
                      backgroundColor: AppStatusColors.error,
                      child: const Text('END RIDE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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

  Widget _buildRideGroupHeader(
    AppColorTokens tokens, {
    required String title,
    required String timeStr,
    required List<Package> packages,
  }) {
    double totalCod = 0;
    for (final p in packages) {
      totalCod += p.codCash + p.codDigital;
    }

    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: tokens.text,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                timeStr,
                style: TextStyle(fontSize: 10, color: tokens.textSubtle),
              ),
            ],
          ),
          Text(
            'COD: ${CurrencyFormatter.formatNoDecimal(totalCod)}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: tokens.accent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoPackagesInGroup(AppColorTokens tokens, String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: tokens.surface,
        border: Border.all(color: tokens.border.withValues(alpha: 0.5), width: 1.0),
      ),
      child: Text(
        message,
        style: TextStyle(fontSize: 11, color: tokens.textSubtle, fontStyle: FontStyle.italic),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildPackagesListView(List<Package> packages) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: packages.length,
      itemBuilder: (context, index) {
        final pkg = packages[index];
        return PackageCard(
          key: ValueKey(pkg.id),
          package: pkg,
          showDragHandle: false,
        );
      },
    );
  }

  Widget _buildFilterChip({required String label, required bool isActive, required VoidCallback onTap}) {
    final tokens = context.tokens;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isActive ? tokens.accentSoft : tokens.surface,
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: tokens.text,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down_rounded,
              size: 16,
              color: tokens.textSubtle,
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildEmptyState(AppColorTokens tokens) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: OffsetShadowCard(
          shadowColor: tokens.border,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              BrandLogo(type: BrandLogoType.mark, height: 72),
              const SizedBox(height: 16),
              const Text(
                'No Packages Found',
                style: TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Add package details by scanning barcodes or click the scan button.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryBar(AppColorTokens tokens, PaymentSummary summary) {
    return Container(
      decoration: BoxDecoration(
        color: tokens.surface,
        border: Border(
          top: BorderSide(color: tokens.border, width: 2.0),
        ),
      ),
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TOTAL COD CASH',
                style: TextStyle(fontSize: 10, color: tokens.textSubtle, fontWeight: FontWeight.bold),
              ),
              Text(
                CurrencyFormatter.formatNoDecimal(summary.codCash),
                style: TextStyle(fontSize: 14, color: tokens.text, fontWeight: FontWeight.w900),
              ),
            ],
          ),
          Container(height: 24, width: 1.5, color: tokens.border),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'COD DIGITAL',
                style: TextStyle(fontSize: 10, color: tokens.textSubtle, fontWeight: FontWeight.bold),
              ),
              Text(
                CurrencyFormatter.formatNoDecimal(summary.codDigital),
                style: TextStyle(fontSize: 14, color: tokens.text, fontWeight: FontWeight.w900),
              ),
            ],
          ),
          Container(height: 24, width: 1.5, color: tokens.border),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TIPS COLLECTED',
                style: TextStyle(fontSize: 10, color: tokens.textSubtle, fontWeight: FontWeight.bold),
              ),
              Text(
                CurrencyFormatter.formatNoDecimal(summary.tips),
                style: TextStyle(fontSize: 14, color: AppStatusColors.success, fontWeight: FontWeight.w900),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showStatusFilterDialog(
    BuildContext context,
    List<String> currentFilters,
    List<String> uniqueStatuses,
    PackagesNotifier notifier,
  ) {
    final tokens = context.tokens;
    List<String> tempSelected = [...currentFilters];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
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
                      'Filter by Status',
                      style: TextStyle(fontFamily: 'Geist', fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 12),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.45,
                      ),
                      child: uniqueStatuses.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.symmetric(vertical: 24.0),
                              child: Text('No status data available.', textAlign: TextAlign.center),
                            )
                          : Scrollbar(
                              child: SingleChildScrollView(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: uniqueStatuses.map((status) {
                                    final isChecked = tempSelected.contains(status);
                                    return CheckboxListTile(
                                      title: Text(status.toUpperCase()),
                                      value: isChecked,
                                      controlAffinity: ListTileControlAffinity.leading,
                                      activeColor: tokens.accent,
                                      onChanged: (val) {
                                        setState(() {
                                          if (val == true) {
                                            tempSelected.add(status);
                                          } else {
                                            tempSelected.remove(status);
                                          }
                                          notifier.setStatusFilters(tempSelected);
                                        });
                                      },
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            setState(() {
                              tempSelected.clear();
                              notifier.setStatusFilters(tempSelected);
                            });
                          },
                          child: const Text('RESET'),
                        ),
                        const SizedBox(width: 8),
                        OffsetShadowButton.elevated(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text('DONE'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showBarangayFilterDialog(
    BuildContext context,
    List<String> currentFilters,
    List<String> uniqueBarangays,
    PackagesNotifier notifier,
  ) {
    final tokens = context.tokens;
    List<String> tempSelected = [...currentFilters];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
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
                      'Filter by Barangay',
                      style: TextStyle(fontFamily: 'Geist', fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 12),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.45,
                      ),
                      child: uniqueBarangays.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.symmetric(vertical: 24.0),
                              child: Text('No barangay data available.', textAlign: TextAlign.center),
                            )
                          : Scrollbar(
                              child: SingleChildScrollView(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: uniqueBarangays.map((brgy) {
                                    final isChecked = tempSelected.contains(brgy);
                                    return CheckboxListTile(
                                      title: Text(brgy),
                                      value: isChecked,
                                      controlAffinity: ListTileControlAffinity.leading,
                                      activeColor: tokens.accent,
                                      onChanged: (val) {
                                        setState(() {
                                          if (val == true) {
                                            tempSelected.add(brgy);
                                          } else {
                                            tempSelected.remove(brgy);
                                          }
                                          notifier.setBarangayFilters(tempSelected);
                                        });
                                      },
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            setState(() {
                              tempSelected.clear();
                              notifier.setBarangayFilters(tempSelected);
                            });
                          },
                          child: const Text('RESET'),
                        ),
                        const SizedBox(width: 8),
                        OffsetShadowButton.elevated(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text('DONE'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showPaymentFilterDialog(
    BuildContext context,
    List<String> currentFilters,
    List<String> uniquePaymentTypes,
    PackagesNotifier notifier,
  ) {
    final tokens = context.tokens;
    List<String> tempSelected = [...currentFilters];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
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
                      'Filter by Payment Type',
                      style: TextStyle(fontFamily: 'Geist', fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 12),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.45,
                      ),
                      child: uniquePaymentTypes.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.symmetric(vertical: 24.0),
                              child: Text('No payment type data available.', textAlign: TextAlign.center),
                            )
                          : Scrollbar(
                              child: SingleChildScrollView(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: uniquePaymentTypes.map((type) {
                                    final isChecked = tempSelected.contains(type);
                                    final label = type == 'cod_cash'
                                        ? 'COD Cash'
                                        : (type == 'cod_digital' ? 'COD Digital' : (type == 'prepaid' ? 'Prepaid' : type.toUpperCase()));
                                    return CheckboxListTile(
                                      title: Text(label),
                                      value: isChecked,
                                      controlAffinity: ListTileControlAffinity.leading,
                                      activeColor: tokens.accent,
                                      onChanged: (val) {
                                        setState(() {
                                          if (val == true) {
                                            tempSelected.add(type);
                                          } else {
                                            tempSelected.remove(type);
                                          }
                                          notifier.setPaymentTypeFilters(tempSelected);
                                        });
                                      },
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            setState(() {
                              tempSelected.clear();
                              notifier.setPaymentTypeFilters(tempSelected);
                            });
                          },
                          child: const Text('RESET'),
                        ),
                        const SizedBox(width: 8),
                        OffsetShadowButton.elevated(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text('DONE'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Map<String, dynamic> _computeStats(List<Package> pkgs) {
    int total = pkgs.length;
    final statusCounts = <String, int>{};
    final barangayCounts = <String, int>{};

    for (final p in pkgs) {
      statusCounts[p.status] = (statusCounts[p.status] ?? 0) + 1;
      final brgy = p.barangay ?? 'Unknown';
      barangayCounts[brgy] = (barangayCounts[brgy] ?? 0) + 1;
    }

    return {
      'total': total,
      'status': statusCounts,
      'barangay': barangayCounts,
    };
  }

  Widget _buildTotalsAndStatsTab(
    AppColorTokens tokens,
    List<Package> packages,
    Ride? activeRide,
    List<Ride> todayRides,
  ) {
    final overall = _computeStats(packages);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Section: Overall Summary Header
          Text(
            'OVERALL SUMMARY',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: tokens.textSubtle, letterSpacing: 0.5),
          ),
          const SizedBox(height: 8),
          _buildStatsCard(
            tokens: tokens,
            title: "TODAY'S OVERALL STATS",
            color: tokens.accentSoft,
            borderColor: tokens.accent,
            stats: overall,
          ),
          const SizedBox(height: 24),

          // Section: Ride-by-Ride Statistics Header
          Text(
            'PER-RIDE BREAKDOWN',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: tokens.textSubtle, letterSpacing: 0.5),
          ),
          const SizedBox(height: 8),

          // Active Ride (if present)
          if (activeRide != null) ...[
            _buildRideStatsCard(
              tokens: tokens,
              rideTitle: 'RIDE #${activeRide.rideNumber} (ACTIVE)',
              color: tokens.surface,
              borderColor: tokens.border,
              ridePkgs: packages.where((p) => p.rideId == activeRide.id).toList(),
            ),
            const SizedBox(height: 16),
          ],

          // Today's Completed Rides
          ...todayRides.where((r) => r.endedAt != null).map((ride) {
            return Column(
              children: [
                _buildRideStatsCard(
                  tokens: tokens,
                  rideTitle: 'RIDE #${ride.rideNumber} (COMPLETED)',
                  color: tokens.surface,
                  borderColor: tokens.border,
                  ridePkgs: packages.where((p) => p.rideId == ride.id).toList(),
                ),
                const SizedBox(height: 16),
              ],
            );
          }),

          // Unassigned Packages
          _buildRideStatsCard(
            tokens: tokens,
            rideTitle: 'UNASSIGNED PACKAGES',
            color: tokens.surface,
            borderColor: tokens.border,
            ridePkgs: packages.where((p) => p.rideId == null).toList(),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildRideStatsCard({
    required AppColorTokens tokens,
    required String rideTitle,
    required Color color,
    required Color borderColor,
    required List<Package> ridePkgs,
  }) {
    final stats = _computeStats(ridePkgs);
    return _buildStatsCard(
      tokens: tokens,
      title: rideTitle,
      color: color,
      borderColor: borderColor,
      stats: stats,
    );
  }

  Widget _buildStatsCard({
    required AppColorTokens tokens,
    required String title,
    required Color color,
    required Color borderColor,
    required Map<String, dynamic> stats,
  }) {
    final total = stats['total'] as int;
    final statusCounts = stats['status'] as Map<String, int>;
    final barangayCounts = stats['barangay'] as Map<String, int>;

    return OffsetShadowCard(
      backgroundColor: color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: tokens.surface,
                  border: Border.all(color: tokens.border, width: 1.5),
                ),
                child: Text(
                  '$total PKGS',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, fontFamily: 'JetBrains Mono'),
                ),
              ),
            ],
          ),
          const Divider(height: 24, thickness: 1.5),

          if (total == 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No packages match the active filters.',
                style: TextStyle(color: tokens.textSubtle, fontSize: 12, fontStyle: FontStyle.italic),
                textAlign: TextAlign.center,
              ),
            )
          else ...[
            // Statuses Grid/Wrap
            const Text(
              'BY STATUS',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: statusCounts.entries.map((entry) {
                final status = entry.key;
                final count = entry.value;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: tokens.surface,
                    border: Border.all(color: tokens.border, width: 1.0),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      StatusBadge(status: status),
                      const SizedBox(width: 8),
                      Text(
                        '$count',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, fontFamily: 'JetBrains Mono'),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 16),

            // Barangays Grid/Wrap
            const Text(
              'BY BARANGAY / LOCATION',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: barangayCounts.entries.map((entry) {
                final brgy = entry.key;
                final count = entry.value;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: tokens.surface,
                    border: Border.all(color: tokens.border, width: 1.0),
                  ),
                  child: Text(
                    '${brgy.toUpperCase()}: $count',
                    style: TextStyle(
                      color: tokens.text,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      fontFamily: 'JetBrains Mono',
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
