import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../shared/widgets/connectivity_banner.dart';
import '../../shared/widgets/offset_shadow_card.dart';
import '../../shared/widgets/brand_logo.dart';
import '../../shared/utils/currency_formatter.dart';
import '../../core/database/db_helper.dart';
import '../packages/package_card.dart';
import 'history_provider.dart';
import 'date_range_picker.dart';
import '../../app/router.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  int _currentTab = 0; // 0 = Deliveries List, 1 = Analytics / Earnings

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      ref.read(historyNotifierProvider.notifier).setSearchQuery(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(historyNotifierProvider);
    final notifier = ref.read(historyNotifierProvider.notifier);
    final tokens = context.tokens;
    final showNavBar = ref.watch(showNavBarProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.read(historyNotifierProvider.notifier).clearFilters();
          await ref.read(historyNotifierProvider.notifier).refresh();
        },
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                floating: true,
                snap: true,
                pinned: false,
                title: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    BrandLogo(type: BrandLogoType.icon, height: 32),
                    const SizedBox(width: 8),
                    Text(
                      'HISTORY',
                      style: TextStyle(
                        color: tokens.text,
                        fontFamily: 'Syne',
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.map_rounded),
                    tooltip: 'Ride Tracking Map',
                    onPressed: () => context.push('/history/map'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded),
                    tooltip: 'Refresh',
                    onPressed: () => notifier.refresh(),
                  ),
                ],
              ),
            ];
          },
          body: NotificationListener<ScrollNotification>(
            onNotification: (ScrollNotification notification) {
              if (notification is ScrollUpdateNotification) {
                final scrollDelta = notification.scrollDelta ?? 0;
                final pixels = notification.metrics.pixels;
                if (pixels <= 10) {
                  ref.read(showNavBarProvider.notifier).state = true;
                } else if (scrollDelta > 2.0) {
                  ref.read(showNavBarProvider.notifier).state = false;
                } else if (scrollDelta < -2.0) {
                  ref.read(showNavBarProvider.notifier).state = true;
                }
              }
              return false;
            },
            child: Column(
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
                        hintText: 'Search history tracking #, name...',
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

                // Horizontal Filter Bar
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  clipBehavior: Clip.none,
                  child: Row(
                    children: [
                      // Date Range Filter Chip
                      _buildFilterChip(
                        label: '${DateFormat('MM/dd').format(state.startDate)} - ${DateFormat('MM/dd').format(state.endDate)}',
                        isActive: true,
                        onTap: () => _showDateRangePickerDialog(context, state.startDate, state.endDate, notifier),
                      ),
                      const SizedBox(width: 8),

                      // Status Filter Chip
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

                      // Barangay Filter Chip
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

                      // Payment Type Filter Chip
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
                      if (state.statusFilters.isNotEmpty || state.barangayFilters.isNotEmpty || state.paymentTypeFilters.isNotEmpty || state.searchQuery.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        TextButton.icon(
                          onPressed: () {
                            _searchController.clear();
                            notifier.clearFilters();
                          },
                          icon: const Icon(Icons.clear_all_rounded, size: 16),
                          label: const Text('Clear', style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ],
                  ),
                ),
                // Custom Tab Switcher
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                              color: _currentTab == 0 ? tokens.accent : Colors.transparent,
                              child: Text(
                                'DELIVERIES',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: _currentTab == 0 ? tokens.textInvert : tokens.text,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Container(
                          width: 2,
                          height: 40,
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
                              color: _currentTab == 1 ? tokens.accent : Colors.transparent,
                              child: Text(
                                'ANALYTICS',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: _currentTab == 1 ? tokens.textInvert : tokens.text,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Conditional Views
                Expanded(
                  child: state.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _currentTab == 0
                          ? (state.packages.isEmpty
                              ? _buildEmptyState(tokens)
                              : ListView.builder(
                                  padding: const EdgeInsets.all(16),
                                  itemCount: state.packages.length,
                                  itemBuilder: (context, index) {
                                    final pkg = state.packages[index];
                                    return PackageCard(
                                      key: ValueKey(pkg.id),
                                      package: pkg,
                                      showDragHandle: false,
                                    );
                                  },
                                ))
                          : _buildAnalyticsTab(state, tokens),
                ),

                // Sticky Bottom Summary Bar (only for deliveries list tab)
                if (_currentTab == 0)
                  _buildSummaryBar(tokens, state.summary, showNavBar),
              ],
            ),
          ),
        ),
      ),
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_toggle_off_rounded, size: 64, color: tokens.textSubtle),
          const SizedBox(height: 16),
          Text(
            'No packages found in this range',
            style: TextStyle(fontSize: 16, color: tokens.text, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Try selecting a different date range or adjusting filters',
            style: TextStyle(fontSize: 13, color: tokens.textSubtle),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryBar(AppColorTokens tokens, PaymentSummary summary, bool showNavBar) {
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: tokens.surface,
        border: Border(top: BorderSide(color: tokens.border, width: 1.5)),
      ),
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: (showNavBar ? 0.0 : bottomPadding) + 12.0,
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

  void _showDateRangePickerDialog(
    BuildContext context,
    DateTime currentStart,
    DateTime currentEnd,
    HistoryNotifier notifier,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return DateRangePicker(
          initialStartDate: currentStart,
          initialEndDate: currentEnd,
          onSaved: (start, end) {
            notifier.setDateRange(start, end);
          },
        );
      },
    );
  }

  void _showStatusFilterDialog(
    BuildContext context,
    List<String> currentFilters,
    List<String> uniqueStatuses,
    HistoryNotifier notifier,
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
                      style: TextStyle(fontFamily: 'Syne', fontWeight: FontWeight.bold, fontSize: 16),
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
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            'Cancel',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppStatusColors.error),
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () {
                            for (final status in uniqueStatuses) {
                              if (tempSelected.contains(status)) {
                                notifier.toggleStatusFilter(status);
                              } else if (currentFilters.contains(status)) {
                                notifier.toggleStatusFilter(status);
                              }
                            }
                            Navigator.pop(context);
                          },
                          child: Text('Apply', style: TextStyle(color: tokens.accent, fontWeight: FontWeight.bold)),
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
    HistoryNotifier notifier,
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
                      style: TextStyle(fontFamily: 'Syne', fontWeight: FontWeight.bold, fontSize: 16),
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
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            'Cancel',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppStatusColors.error),
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () {
                            for (final brgy in uniqueBarangays) {
                              if (tempSelected.contains(brgy)) {
                                if (!currentFilters.contains(brgy)) {
                                  notifier.toggleBarangayFilter(brgy);
                                }
                              } else {
                                if (currentFilters.contains(brgy)) {
                                  notifier.toggleBarangayFilter(brgy);
                                }
                              }
                            }
                            Navigator.pop(context);
                          },
                          child: Text('Apply', style: TextStyle(color: tokens.accent, fontWeight: FontWeight.bold)),
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
    HistoryNotifier notifier,
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
                      style: TextStyle(fontFamily: 'Syne', fontWeight: FontWeight.bold, fontSize: 16),
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
                                    final displayLabel = type == 'cod_cash'
                                        ? 'COD Cash'
                                        : (type == 'cod_digital' ? 'COD Digital' : 'Prepaid');
                                    return CheckboxListTile(
                                      title: Text(displayLabel),
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
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            'Cancel',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppStatusColors.error),
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () {
                            for (final type in uniquePaymentTypes) {
                              if (tempSelected.contains(type)) {
                                if (!currentFilters.contains(type)) {
                                  notifier.togglePaymentTypeFilter(type);
                                }
                              } else {
                                if (currentFilters.contains(type)) {
                                  notifier.togglePaymentTypeFilter(type);
                                }
                              }
                            }
                            Navigator.pop(context);
                          },
                          child: Text('Apply', style: TextStyle(color: tokens.accent, fontWeight: FontWeight.bold)),
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

  Widget _buildAnalyticsTab(HistoryState state, AppColorTokens tokens) {
    // 1. Group by date for Daily Earnings Chart
    final Map<String, double> dailyData = {};
    int successCount = 0;
    int failedCount = 0;
    int rescheduledCount = 0;

    for (final p in state.packages) {
      if (p.status == 'delivered') {
        successCount++;
        final dateKey = DateFormat('MM/dd').format(p.deliveredAt ?? p.createdAt);
        final totalEarned = p.codCash + p.codDigital + p.tips + p.extraAmount;
        dailyData[dateKey] = (dailyData[dateKey] ?? 0.0) + totalEarned;
      } else if (p.status == 'failed' || p.status == 'returned') {
        failedCount++;
      } else if (p.status == 'rescheduled') {
        rescheduledCount++;
      }
    }

    // Sort daily data by date key (just simple alphabetical string sort is enough for MM/dd)
    final sortedKeys = dailyData.keys.toList()..sort();
    final Map<String, double> sortedDailyData = {
      for (final k in sortedKeys) k: dailyData[k]!
    };

    final double totalRevenue = state.summary.codCash + state.summary.codDigital + state.summary.tips + state.summary.extraAmount;
    final double avgCod = successCount == 0 ? 0.0 : (state.summary.codCash + state.summary.codDigital) / successCount;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Revenue Metrics
          Row(
            children: [
              Expanded(
                child: OffsetShadowCard(
                  padding: const EdgeInsets.all(14),
                  backgroundColor: tokens.accentSoft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('TOTAL COLLECTION', style: TextStyle(color: tokens.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(
                        CurrencyFormatter.formatNoDecimal(totalRevenue),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OffsetShadowCard(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('TIPS EARNED', style: TextStyle(color: tokens.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(
                        CurrencyFormatter.formatNoDecimal(state.summary.tips),
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppStatusColors.success),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Additional Metrics Grid
          Row(
            children: [
              Expanded(
                child: OffsetShadowCard(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('AVG COD/PARCEL', style: TextStyle(color: tokens.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(
                        CurrencyFormatter.formatNoDecimal(avgCod),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OffsetShadowCard(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('EXTRA CHARGES', style: TextStyle(color: tokens.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(
                        CurrencyFormatter.formatNoDecimal(state.summary.extraAmount),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Daily Collection Trend Chart
          Text(
            'DAILY COLLECTION TREND (PHP)',
            style: TextStyle(
              fontFamily: 'Syne',
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: tokens.textSubtle,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          OffsetShadowCard(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: sortedDailyData.isEmpty
                ? const SizedBox(
                    height: 200,
                    child: Center(
                      child: Text(
                        'No delivered package data for this date range.',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ),
                  )
                : EarningsBarChart(
                    data: sortedDailyData,
                    barColor: tokens.accent,
                    labelColor: tokens.text,
                    gridColor: tokens.border,
                  ),
          ),
          const SizedBox(height: 20),

          // Delivery Breakdown (Status Distribution)
          Text(
            'PARCEL BREAKDOWN',
            style: TextStyle(
              fontFamily: 'Syne',
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: tokens.textSubtle,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          OffsetShadowCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildBreakdownRow('Delivered Successfully', successCount, AppStatusColors.success, tokens),
                const Divider(height: 16),
                _buildBreakdownRow('Failed / Returned', failedCount, AppStatusColors.error, tokens),
                const Divider(height: 16),
                _buildBreakdownRow('Rescheduled', rescheduledCount, AppStatusColors.warning, tokens),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownRow(String title, int count, Color color, AppColorTokens tokens) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                border: Border.all(color: tokens.border, width: 1),
              ),
            ),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
        Text(
          count.toString(),
          style: const TextStyle(fontFamily: 'JetBrains Mono', fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ],
    );
  }
}

class EarningsBarChart extends StatelessWidget {
  final Map<String, double> data;
  final Color barColor;
  final Color labelColor;
  final Color gridColor;

  const EarningsBarChart({
    super.key,
    required this.data,
    required this.barColor,
    required this.labelColor,
    required this.gridColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: CustomPaint(
        size: Size.infinite,
        painter: _BarChartPainter(
          data: data,
          barColor: barColor,
          labelColor: labelColor,
          gridColor: gridColor,
        ),
      ),
    );
  }
}

class _BarChartPainter extends CustomPainter {
  final Map<String, double> data;
  final Color barColor;
  final Color labelColor;
  final Color gridColor;

  _BarChartPainter({
    required this.data,
    required this.barColor,
    required this.labelColor,
    required this.gridColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final maxVal = data.values.fold(0.0, (max, val) => val > max ? val : max);
    final limitVal = maxVal == 0 ? 100.0 : maxVal * 1.2;

    final axisPaint = Paint()
      ..color = labelColor.withValues(alpha: 0.3)
      ..strokeWidth = 1.5;

    final gridPaint = Paint()
      ..color = gridColor.withValues(alpha: 0.1)
      ..strokeWidth = 1;

    final barPaint = Paint()
      ..color = barColor
      ..style = PaintingStyle.fill;

    // Draw horizontal grid lines
    const int gridLines = 4;
    for (int i = 0; i <= gridLines; i++) {
      final y = size.height - (i * (size.height - 20) / gridLines) - 20;
      canvas.drawLine(Offset(30, y), Offset(size.width, y), gridPaint);
      
      // Y-axis label
      final val = (limitVal * i / gridLines).round();
      final textSpan = TextSpan(
        text: val.toString(),
        style: TextStyle(color: labelColor.withValues(alpha: 0.6), fontSize: 9, fontWeight: FontWeight.bold),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: ui.TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas, Offset(0, y - 6));
    }

    // Draw Axis lines
    canvas.drawLine(Offset(30, 0), Offset(30, size.height - 20), axisPaint);
    canvas.drawLine(Offset(30, size.height - 20), Offset(size.width, size.height - 20), axisPaint);

    // Draw Bars
    final keys = data.keys.toList();
    final double chartWidth = size.width - 30;
    final double barSpacing = chartWidth / keys.length;
    final double barWidth = (barSpacing * 0.6).clamp(10.0, 40.0);

    for (int i = 0; i < keys.length; i++) {
      final key = keys[i];
      final val = data[key]!;
      final double x = 30 + (i * barSpacing) + (barSpacing - barWidth) / 2;
      final double barHeight = (size.height - 20) * (val / limitVal);
      final double y = size.height - 20 - barHeight;

      // Draw bar rect
      canvas.drawRect(Rect.fromLTWH(x, y, barWidth, barHeight), barPaint);

      // Draw bar border
      final borderPaint = Paint()
        ..color = labelColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawRect(Rect.fromLTWH(x, y, barWidth, barHeight), borderPaint);

      // Draw X-axis label
      final textSpan = TextSpan(
        text: key,
        style: TextStyle(color: labelColor, fontSize: 9, fontWeight: FontWeight.bold),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: ui.TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas, Offset(x + (barWidth - textPainter.width) / 2, size.height - 15));
    }
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter oldDelegate) {
    return oldDelegate.data != data || oldDelegate.barColor != barColor;
  }
}
