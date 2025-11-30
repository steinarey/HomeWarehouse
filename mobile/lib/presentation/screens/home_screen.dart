import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/domain/providers/dashboard_provider.dart';
import 'package:mobile/presentation/common/summary_card.dart';
import 'package:mobile/presentation/common/recent_activity_list.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(dashboardProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard'), actions: const []),
      body: dashboardAsync.when(
        data: (dashboard) => RefreshIndicator(
          onRefresh: () => ref.refresh(dashboardProvider.future),
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
                        title: 'Total Categories',
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
                        title: 'Low Stock',
                        value: dashboard.lowStockCategories.toString(),
                        color: Colors.orange.shade100,
                        textColor: Colors.orange.shade900,
                        onTap: () => context.go('/low-stock'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SummaryCard(
                        title: 'Critical',
                        value: dashboard.lowStockCriticalCategories.toString(),
                        color: Colors.red.shade100,
                        textColor: Colors.red.shade900,
                        onTap: () => context.go('/low-stock'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'Recent Activity',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
              Text('Error loading dashboard: $err'),
              ElevatedButton(
                onPressed: () => ref.refresh(dashboardProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
