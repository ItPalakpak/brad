import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/scan/scan_screen.dart';
import '../features/packages/packages_screen.dart';
import '../features/packages/package_detail_screen.dart';
import '../features/map/map_screen.dart';
import '../features/settings/settings_screen.dart';
import '../core/theme/app_theme.dart';
import '../shared/widgets/offset_shadow_card.dart';

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
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/scan',
              builder: (context, state) => const ScanScreen(),
            ),
          ],
        ),
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
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/map',
              builder: (context, state) => const MapScreen(),
            ),
          ],
        ),
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

class MainNavigationShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainNavigationShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: tokens.surface,
          border: Border(
            top: BorderSide(color: tokens.border, width: 1.5),
          ),
        ),
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 8,
          bottom: MediaQuery.of(context).padding.bottom + 8,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(context, 0, Icons.qr_code_scanner_rounded, 'Scan'),
            _buildNavItem(context, 1, Icons.inventory_2_outlined, 'Packages'),
            _buildNavItem(context, 2, Icons.map_outlined, 'Map'),
            _buildNavItem(context, 3, Icons.settings_outlined, 'Settings'),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, int index, IconData icon, String label) {
    final tokens = context.tokens;
    final isSelected = navigationShell.currentIndex == index;

    if (isSelected) {
      return OffsetShadowCard(
        shadowOffset: const Offset(1.5, 1.5),
        borderWidth: 1.5,
        borderRadius: BorderRadius.zero,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        backgroundColor: tokens.accent,
        shadowColor: tokens.border,
        onTap: () => navigationShell.goBranch(index),
        child: Row(
          children: [
            Icon(icon, size: 20, color: tokens.textInvert),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: tokens.textInvert,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    } else {
      return InkWell(
        onTap: () => navigationShell.goBranch(index),
        borderRadius: BorderRadius.zero,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: tokens.textSubtle),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: tokens.textSubtle,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }
  }
}
