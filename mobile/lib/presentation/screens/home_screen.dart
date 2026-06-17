import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/domain/providers/dashboard_provider.dart';
import 'package:mobile/domain/providers/pending_restock_provider.dart';
import 'package:mobile/presentation/common/pending_restock_block.dart';
import 'package:mobile/presentation/common/summary_card.dart';
import 'package:mobile/presentation/common/recent_activity_list.dart';

import '../../l10n/app_localizations.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(dashboardProvider);

    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context).get('dashboard')), actions: const []),
      body: dashboardAsync.when(
        data: (dashboard) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(pendingRestocksProvider);
            await ref.refresh(dashboardProvider.future);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: SummaryCard(
                        title: AppLocalizations.of(context).get('totalCategories'),
                        value: dashboard.totalCategories.toString(),
                        onTap: () async {
                          await context.push('/categories');
                          ref.invalidate(dashboardProvider);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SummaryCard(
                        title: AppLocalizations.of(context).get('lowStock'),
                        value: dashboard.lowStockCategories.toString(),
                        color: dashboard.lowStockCategories > 0
                            ? Colors.orange.shade100
                            : null,
                        textColor: dashboard.lowStockCategories > 0
                            ? Colors.orange.shade900
                            : null,
                        onTap: () => context.go('/low-stock'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SummaryCard(
                        title: AppLocalizations.of(context).get('critical'),
                        value:
                            dashboard.lowStockCriticalCategories.toString(),
                        color: dashboard.lowStockCriticalCategories > 0
                            ? Colors.red.shade100
                            : null,
                        textColor: dashboard.lowStockCriticalCategories > 0
                            ? Colors.red.shade900
                            : null,
                        onTap: () => context.go('/low-stock'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const PendingRestockBlock(),
                Text(
                  AppLocalizations.of(context).get('recentActivity'),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                RecentActivityList(actions: dashboard.recentActions),
              ],
            ),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${AppLocalizations.of(context).get('errorLoadingDashboard')}: $err',
              ),
              ElevatedButton(
                onPressed: () => ref.refresh(dashboardProvider),
                child: Text(AppLocalizations.of(context).get('retry')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
