import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

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

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  final TextEditingController _searchController = TextEditingController();

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

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            BrandLogo(type: BrandLogoType.icon, height: 32),
            const SizedBox(width: 8),
            Text(
              'HISTORY',
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
      body: Column(
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
          const SizedBox(height: 12),

          // Packages List
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : state.packages.isEmpty
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
                      ),
          ),

          // Sticky Bottom Summary Bar
          _buildSummaryBar(tokens, state.summary),
        ],
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

  Widget _buildSummaryBar(AppColorTokens tokens, PaymentSummary summary) {
    return Container(
      decoration: BoxDecoration(
        color: tokens.surface,
        border: Border(top: BorderSide(color: tokens.border, width: 1.5)),
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
                          child: Text('Cancel', style: TextStyle(color: tokens.textSubtle)),
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
                          child: Text('Cancel', style: TextStyle(color: tokens.textSubtle)),
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
                          child: Text('Cancel', style: TextStyle(color: tokens.textSubtle)),
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
}
