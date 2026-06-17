import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/data/models/pending_restock.dart';
import 'package:mobile/domain/providers/categories_provider.dart';
import 'package:mobile/domain/providers/core_providers.dart';
import 'package:mobile/domain/providers/dashboard_provider.dart';
import 'package:mobile/domain/providers/pending_restock_provider.dart';
import 'package:mobile/l10n/app_localizations.dart';

class PendingRestockBlock extends ConsumerWidget {
  const PendingRestockBlock({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final pendingAsync = ref.watch(pendingRestocksProvider);

    return pendingAsync.when(
      data: (items) {
        if (items.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.get('pendingRestockTitle'),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.get('pendingRestockSubtitle'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            ...items.map((p) => _PendingRestockTile(item: p)),
            const SizedBox(height: 24),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _PendingRestockTile extends ConsumerWidget {
  final PendingRestock item;
  const _PendingRestockTile({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Card(
      color: Colors.amber.shade50,
      child: ListTile(
        leading: const Icon(Icons.shopping_basket, color: Colors.amber),
        title: Text(item.categoryName),
        subtitle: Text(
          '${l10n.get('currentStock')}: ${item.currentStock} · ${l10n.get('minStock')}: ${item.minStock}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: l10n.get('dismiss'),
              onPressed: () => _dismiss(context, ref),
            ),
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.green),
              tooltip: l10n.get('adjustAction'),
              onPressed: () => _showAdjustDialog(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _dismiss(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(pendingRestockRepositoryProvider).dismiss(item.id);
      if (context.mounted) ref.invalidate(pendingRestocksProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _showAdjustDialog(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController(text: item.currentStock.toString());
    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('${l10n.get('adjustAction')}: ${item.categoryName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('${l10n.get('currentStock')}: ${item.currentStock}'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                labelText: l10n.get('newTotalQuantity'),
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.get('cancel')),
          ),
          ElevatedButton(
            onPressed: () async {
              final qty = int.tryParse(controller.text);
              if (qty == null || qty < 0) return;
              try {
                await ref
                    .read(categoryRepositoryProvider)
                    .adjustCategoryStock(
                      categoryId: item.categoryId,
                      newTotalQuantity: qty,
                    );
                if (dialogContext.mounted) Navigator.pop(dialogContext);
                if (context.mounted) {
                  ref.invalidate(pendingRestocksProvider);
                  ref.invalidate(categoriesProvider);
                  ref.invalidate(dashboardProvider);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${l10n.get('adjustedMessage')} ${item.categoryName} → $qty',
                      ),
                    ),
                  );
                }
              } on DioException catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        e.response?.data?.toString() ?? e.message ?? 'Error',
                      ),
                    ),
                  );
                }
              }
            },
            child: Text(l10n.get('save')),
          ),
        ],
      ),
    );
  }
}
