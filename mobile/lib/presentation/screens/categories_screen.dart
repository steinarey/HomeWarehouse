import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/data/models/category.dart';
import 'package:mobile/domain/providers/core_providers.dart';
import 'package:mobile/l10n/app_localizations.dart';

class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen> {
  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref
        .watch(categoryRepositoryProvider)
        .getCategories(includeStock: true);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).get('categories')),
      ),
      body: FutureBuilder<List<Category>>(
        future: categoriesAsync,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                AppLocalizations.of(context).get('noCategoriesFound'),
              ),
            );
          }

          final categories = snapshot.data!;
          return ListView.builder(
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return ListTile(
                title: Text(category.name),
                subtitle: Text(
                  'Current: ${category.currentStock ?? 0} | Min: ${category.minStock}',
                ),
                trailing: const Icon(Icons.edit),
                onTap: () => _showEditDialog(category),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _showEditDialog(Category category) async {
    final nameController = TextEditingController(text: category.name);
    final minStockController = TextEditingController(
      text: category.minStock.toString(),
    );

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).get('editCategory')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: minStockController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Minimum Stock'),
            ),
            const SizedBox(height: 16),
            Text('Current Stock: ${category.currentStock ?? 0} (Read-only)'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context).get('cancel')),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => _showDeleteConfirmation(category),
            child: Text(AppLocalizations.of(context).get('delete')),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await ref
                    .read(categoryRepositoryProvider)
                    .updateCategory(category.id, {
                      'name': nameController.text,
                      'min_stock': int.tryParse(minStockController.text) ?? 0,
                    });
                if (mounted) {
                  Navigator.pop(context);
                  setState(() {}); // Refresh list
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error updating category: $e')),
                  );
                }
              }
            },
            child: Text(AppLocalizations.of(context).get('save')),
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteConfirmation(Category category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category?'),
        content: Text(
          'Are you sure you want to delete "${category.name}"? This will also delete ALL products in this category. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context).get('cancel')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              AppLocalizations.of(context).get('delete'),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(categoryRepositoryProvider).deleteCategory(category.id);
        if (mounted) {
          // Close the Edit Dialog (which is currently open)
          Navigator.of(context).pop();
          // Refresh the categories list
          setState(() {});
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context).get('errorDeletingCategory'),
              ),
            ),
          );
        }
      }
    }
  }
}
