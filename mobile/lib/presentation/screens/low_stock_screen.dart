import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/domain/providers/dashboard_provider.dart';
import 'package:mobile/presentation/screens/low_stock/low_stock_list_item.dart';

class LowStockScreen extends ConsumerWidget {
  const LowStockScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lowStockAsync = ref.watch(lowStockProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping List'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.refresh(lowStockProvider),
          ),
        ],
      ),
      body: lowStockAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('Everything is well stocked!'));
          }

          final criticalItems = items.where((i) => i.isCritical).toList();
          final otherItems = items.where((i) => !i.isCritical).toList();

          return RefreshIndicator(
            onRefresh: () => ref.refresh(lowStockProvider.future),
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                if (criticalItems.isNotEmpty) ...[
                  const Text(
                    'Critical Items',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...criticalItems.map((item) => LowStockListItem(item: item)),
                  const SizedBox(height: 24),
                ],
                if (otherItems.isNotEmpty) ...[
                  const Text(
                    'Low Stock',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...otherItems.map((item) => LowStockListItem(item: item)),
                ],
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
