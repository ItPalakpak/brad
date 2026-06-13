import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../shared/widgets/connectivity_banner.dart';
import '../../shared/widgets/offset_shadow_card.dart';
import '../../shared/widgets/brand_logo.dart';
import '../../shared/utils/currency_formatter.dart';
import '../../core/database/db_helper.dart';
import 'packages_provider.dart';
import 'package:brad/features/packages/package_card.dart';

class PackagesScreen extends ConsumerStatefulWidget {
  const PackagesScreen({super.key});

  @override
  ConsumerState<PackagesScreen> createState() => _PackagesScreenState();
}

class _PackagesScreenState extends ConsumerState<PackagesScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isReorderMode = false;
  double? _fabX;
  double? _fabY;

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
            icon: Icon(_isReorderMode ? Icons.check_rounded : Icons.sort_rounded),
            tooltip: _isReorderMode ? 'Save Order' : 'Reorder Mode',
            onPressed: () {
              setState(() {
                _isReorderMode = !_isReorderMode;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () => notifier.refresh(),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final maxW = constraints.maxWidth;
          final maxH = constraints.maxHeight;

          // Default FAB position at bottom right (FAB is 56x56, plus shadow offset/padding)
          final defaultX = maxW - 72.0;
          final defaultY = maxH - 72.0;

          final fabX = _fabX ?? defaultX;
          final fabY = _fabY ?? defaultY;

          return Stack(
            children: [
              Column(
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

                  // Packages List
                  Expanded(
                    child: state.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : state.packages.isEmpty
                            ? _buildEmptyState(tokens)
                            : _buildPackageList(state.packages),
                  ),

                  // Sticky Bottom Summary Bar
                  _buildSummaryBar(tokens, state.summary),
                ],
              ),
              Positioned(
                left: fabX,
                top: fabY,
                child: GestureDetector(
                  onPanUpdate: (details) {
                    setState(() {
                      _fabX = (fabX + details.delta.dx).clamp(16.0, maxW - 72.0);
                      _fabY = (fabY + details.delta.dy).clamp(16.0, maxH - 72.0);
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.zero,
                      boxShadow: [AppShadows.offsetSm(tokens.shadowColor)],
                    ),
                    child: FloatingActionButton(
                      onPressed: () {
                        // Open Scan tab or navigate to new package form
                        context.push('/scan');
                      },
                      child: const Icon(Icons.qr_code_scanner_rounded),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
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

  Widget _buildPackageList(List<Package> packages) {
    if (_isReorderMode) {
      return ReorderableListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: packages.length,
        onReorder: (oldIndex, newIndex) {
          ref.read(packagesNotifierProvider.notifier).reorder(oldIndex, newIndex);
        },
        itemBuilder: (context, index) {
          final pkg = packages[index];
          return PackageCard(
            key: ValueKey(pkg.id),
            package: pkg,
            showDragHandle: true,
          );
        },
        proxyDecorator: (child, index, animation) {
          return ScaleTransition(
            scale: animation.drive(Tween(begin: 1.0, end: 1.03)),
            child: Material(
              color: Colors.transparent,
              elevation: 0,
              child: child,
            ),
          );
        },
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: packages.length,
      itemBuilder: (context, index) {
        final pkg = packages[index];
        return PackageCard(
          key: ValueKey(pkg.id),
          package: pkg,
        );
      },
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
                            });
                          },
                          child: const Text('RESET'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            notifier.setStatusFilters(tempSelected);
                            Navigator.pop(context);
                          },
                          child: const Text('APPLY'),
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
                            });
                          },
                          child: const Text('RESET'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            notifier.setBarangayFilters(tempSelected);
                            Navigator.pop(context);
                          },
                          child: const Text('APPLY'),
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
                            });
                          },
                          child: const Text('RESET'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            notifier.setPaymentTypeFilters(tempSelected);
                            Navigator.pop(context);
                          },
                          child: const Text('APPLY'),
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
