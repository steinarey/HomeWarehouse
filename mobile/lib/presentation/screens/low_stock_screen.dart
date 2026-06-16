import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/data/models/low_stock_item.dart';
import 'package:mobile/domain/providers/dashboard_provider.dart';
import 'package:mobile/presentation/screens/low_stock/low_stock_list_item.dart';

import 'package:mobile/l10n/app_localizations.dart';

class LowStockScreen extends ConsumerWidget {
  const LowStockScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lowStockAsync = ref.watch(lowStockProvider);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.get('shoppingList')),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy_all),
            tooltip: l10n.get('copyShoppingList'),
            onPressed: () => _copyList(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.refresh(lowStockProvider),
          ),
        ],
      ),
      body: lowStockAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const SizedBox(height: 120),
                Icon(
                  Icons.check_circle_outline,
                  size: 80,
                  color: Colors.green.shade400,
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    l10n.get('wellStocked'),
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            );
          }

          final criticalItems = items.where((i) => i.isCritical).toList();
          final otherItems = items.where((i) => !i.isCritical).toList();

          return RefreshIndicator(
            onRefresh: () => ref.refresh(lowStockProvider.future),
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                if (criticalItems.isNotEmpty) ...[
                  Text(
                    l10n.get('criticalItems'),
                    style: const TextStyle(
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
                  Text(
                    l10n.get('lowStock'),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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

  Future<void> _copyList(BuildContext context, WidgetRef ref) async {
    final items = ref.read(lowStockProvider).valueOrNull;
    final l10n = AppLocalizations.of(context);
    if (items == null || items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.get('wellStocked'))),
      );
      return;
    }

    final text = _formatList(items, l10n);
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.get('shoppingListCopied'))),
      );
    }
  }

  String _formatList(List<LowStockItem> items, AppLocalizations l10n) {
    final buf = StringBuffer('${l10n.get('shoppingList')}\n');
    for (final item in items) {
      final marker = item.isCritical ? '! ' : '- ';
      buf.writeln(
        '$marker${item.name}: ${item.recommendedBuyQuantity} '
        '(${item.currentStock}/${item.minStock})',
      );
    }
    return buf.toString().trimRight();
  }
}
