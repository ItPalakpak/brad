import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/scan/scan_screen.dart';
import '../features/packages/packages_screen.dart';
import '../features/packages/package_detail_screen.dart';
import '../features/map/map_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/history/history_screen.dart';
import '../core/theme/app_theme.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();
final shellNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/packages', // default to package list for easier startup
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return MainNavigationShell(navigationShell: navigationShell);
      },
      branches: [
        // Index 0: Packages
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/packages',
              builder: (context, state) => const PackagesScreen(),
              routes: [
                GoRoute(
                  path: ':id',
                  parentNavigatorKey: rootNavigatorKey,
                  builder: (context, state) {
                    final id = state.pathParameters['id']!;
                    final tracking = state.uri.queryParameters['tracking'];
                    return PackageDetailScreen(
                      packageId: id,
                      initialTrackingNumber: tracking,
                    );
                  },
                ),
              ],
            ),
          ],
        ),
        // Index 1: Map
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/map',
              builder: (context, state) => const MapScreen(),
            ),
          ],
        ),
        // Index 2: Scan (Center)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/scan',
              builder: (context, state) => const ScanScreen(),
            ),
          ],
        ),
        // Index 3: History
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/history',
              builder: (context, state) => const HistoryScreen(),
            ),
          ],
        ),
        // Index 4: Settings
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/settings',
              builder: (context, state) => const SettingsScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);

// CHANGED: Added showNavBarProvider to coordinate hiding/showing the bottom navigation bar based on scrolling actions
final showNavBarProvider = StateProvider<bool>((ref) => true);

class MainNavigationShell extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const MainNavigationShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final showNavBar = ref.watch(showNavBarProvider);

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        height: showNavBar ? (60.0 + bottomPadding) : 0.0,
        child: OverflowBox(
          minHeight: 0.0,
          maxHeight: 60.0 + bottomPadding,
          alignment: Alignment.topCenter,
          child: AnimatedSlide(
            offset: showNavBar ? Offset.zero : const Offset(0, 1.0),
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.topCenter,
              children: [
                // Background Bar
                Container(
                  height: 60 + bottomPadding,
                  decoration: BoxDecoration(
                    color: tokens.surface,
                    border: Border(
                      top: BorderSide(color: tokens.border, width: 1.5),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -3),
                      ),
                    ],
                  ),
                  padding: EdgeInsets.only(
                    bottom: bottomPadding,
                  ),
                  child: Row(
                    children: [
                      // Left Tabs: Packages & Map
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Expanded(
                              child: _buildNavItem(
                                context,
                                ref,
                                0,
                                Icons.inventory_2_outlined,
                                'Packages',
                              ),
                            ),
                            Expanded(
                              child: _buildNavItem(
                                context,
                                ref,
                                1,
                                Icons.map_outlined,
                                'Map',
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Gap for Center Button
                      const SizedBox(width: 72),
                      // Right Tabs: History & Settings
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Expanded(
                              child: _buildNavItem(
                                context,
                                ref,
                                3,
                                Icons.history_outlined,
                                'History',
                              ),
                            ),
                            Expanded(
                              child: _buildNavItem(
                                context,
                                ref,
                                4,
                                Icons.settings_outlined,
                                'Settings',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Floating Center Scan Button (In-line)
                Positioned(
                  top: -10, // Positioned in the middle of the 60px active bar height
                  child: GestureDetector(
                    onTap: () {
                      ref.read(showNavBarProvider.notifier).state = true;
                      navigationShell.goBranch(2);
                    },
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: navigationShell.currentIndex == 2
                            ? tokens.accent
                            : tokens.surface,
                        border: Border.all(
                          color: navigationShell.currentIndex == 2
                              ? tokens.accent
                              : tokens.border,
                          width: 2.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (navigationShell.currentIndex == 2
                                    ? tokens.accent
                                    : Colors.black)
                                .withValues(alpha: 0.15),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.qr_code_scanner_rounded,
                        size: 30,
                        color: navigationShell.currentIndex == 2
                            ? Colors.white
                            : tokens.text,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, WidgetRef ref, int index, IconData icon, String label) {
    final tokens = context.tokens;
    final isSelected = navigationShell.currentIndex == index;

    return InkWell(
      onTap: () {
        ref.read(showNavBarProvider.notifier).state = true;
        navigationShell.goBranch(index);
      },
      borderRadius: BorderRadius.zero,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 20,
            color: isSelected ? tokens.accent : tokens.textSubtle,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? tokens.text : tokens.textSubtle,
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
