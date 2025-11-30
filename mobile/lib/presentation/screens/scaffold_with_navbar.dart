import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/domain/providers/dashboard_provider.dart';
import 'package:mobile/domain/providers/core_providers.dart';
import 'package:mobile/l10n/app_localizations.dart';

class ScaffoldWithNavbar extends ConsumerWidget {
  const ScaffoldWithNavbar({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) {
          // Update the provider
          ref.read(bottomNavIndexProvider.notifier).state = index;

          // Refresh data when switching tabs
          if (index == 0) {
            ref.invalidate(dashboardProvider);
          } else if (index == 2) {
            ref.invalidate(lowStockProvider); // Assuming this provider exists
          } else if (index == 3) {
            // Refresh activity log if provider exists, or just let it auto-refresh
            // ref.invalidate(activityLogProvider);
          }

          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.dashboard_outlined),
            selectedIcon: const Icon(Icons.dashboard),
            label: AppLocalizations.of(context).get('home'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.qr_code_scanner),
            label: AppLocalizations.of(context).get('useRestock'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.shopping_cart_outlined),
            selectedIcon: const Icon(Icons.shopping_cart),
            label: AppLocalizations.of(context).get('lowStock'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.history),
            label: AppLocalizations.of(context).get('activity'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            label: AppLocalizations.of(context).get('settings'),
          ),
        ],
      ),
    );
  }
}
