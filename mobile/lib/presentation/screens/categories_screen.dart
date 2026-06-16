import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/data/models/category.dart';
import 'package:mobile/domain/providers/categories_provider.dart';
import 'package:mobile/domain/providers/core_providers.dart';
import 'package:mobile/l10n/app_localizations.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.get('categories'))),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateDialog(context, ref),
        icon: const Icon(Icons.add),
        label: Text(l10n.get('addCategory')),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(categoriesProvider.future),
        child: categoriesAsync.when(
          data: (categories) {
            if (categories.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 120),
                  Icon(
                    Icons.category_outlined,
                    size: 80,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Center(child: Text(l10n.get('noCategoriesFound'))),
                ],
              );
            }
            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                return ListTile(
                  title: Text(category.name),
                  subtitle: Text(
                    '${l10n.get('minStock')}: ${category.minStock}'
                    '${category.consumptionRate != null ? ' • ${category.consumptionRate} ${l10n.get('days')}' : ''}',
                  ),
                  trailing: const Icon(Icons.edit),
                  onTap: () => _showEditDialog(context, ref, category),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              const SizedBox(height: 120),
              Center(child: Text('Error: $err')),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showCreateDialog(BuildContext context, WidgetRef ref) async {
    final nameController = TextEditingController();
    final minStockController = TextEditingController(text: '0');
    final consumptionRateController = TextEditingController();
    final l10n = AppLocalizations.of(context);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.get('addCategory')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: l10n.get('name')),
              autofocus: true,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: minStockController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: l10n.get('minStock')),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: consumptionRateController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: l10n.get('consumptionRate'),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.get('cancel')),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty) return;
              try {
                await ref.read(categoryRepositoryProvider).createCategory({
                  'name': nameController.text,
                  'min_stock': int.tryParse(minStockController.text) ?? 0,
                  'consumption_rate':
                      int.tryParse(consumptionRateController.text),
                });
                if (context.mounted) {
                  Navigator.pop(context);
                  ref.invalidate(categoriesProvider);
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: Text(l10n.get('create')),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditDialog(
    BuildContext context,
    WidgetRef ref,
    Category category,
  ) async {
    final nameController = TextEditingController(text: category.name);
    final minStockController = TextEditingController(
      text: category.minStock.toString(),
    );
    final consumptionRateController = TextEditingController(
      text: category.consumptionRate?.toString() ?? '',
    );
    final isCriticalController = ValueNotifier<bool>(category.isCritical);
    final isOneOffController = ValueNotifier<bool>(category.isOneOff);
    final l10n = AppLocalizations.of(context);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.get('editCategory')),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: l10n.get('name')),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: minStockController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: l10n.get('minStock')),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: consumptionRateController,
                decoration: InputDecoration(
                  labelText: l10n.get('consumptionRate'),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              ValueListenableBuilder<bool>(
                valueListenable: isCriticalController,
                builder: (context, isCritical, _) => Row(
                  children: [
                    Switch(
                      value: isCritical,
                      onChanged: (v) => isCriticalController.value = v,
                    ),
                    Text(l10n.get('isCritical')),
                  ],
                ),
              ),
              ValueListenableBuilder<bool>(
                valueListenable: isOneOffController,
                builder: (context, isOneOff, _) => Row(
                  children: [
                    Switch(
                      value: isOneOff,
                      onChanged: (v) => isOneOffController.value = v,
                    ),
                    Text(l10n.get('isOneOff')),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '${l10n.get('currentStock')}: ${category.currentStock ?? 0}',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.get('cancel')),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () =>
                _confirmDelete(context, ref, category),
            child: Text(l10n.get('delete')),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await ref.read(categoryRepositoryProvider).updateCategory(
                      category.id,
                      {
                        'name': nameController.text,
                        'min_stock':
                            int.tryParse(minStockController.text) ?? 0,
                        'consumption_rate': int.tryParse(
                          consumptionRateController.text,
                        ),
                        'is_critical': isCriticalController.value,
                        'is_one_off': isOneOffController.value,
                      },
                    );
                if (context.mounted) {
                  Navigator.pop(context);
                  ref.invalidate(categoriesProvider);
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error updating category: $e')),
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

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Category category,
  ) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.get('deleteCategory')),
        content: Text(
          l10n
              .get('confirmDeleteCategory')
              .replaceFirst('{name}', category.name),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.get('cancel')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              l10n.get('delete'),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(categoryRepositoryProvider).deleteCategory(category.id);
        if (context.mounted) {
          Navigator.of(context).pop(); // close edit dialog
          ref.invalidate(categoriesProvider);
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.get('errorDeletingCategory')),
            ),
          );
        }
      }
    }
  }
}
