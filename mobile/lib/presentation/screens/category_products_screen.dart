import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/data/models/category.dart';
import 'package:mobile/data/models/location.dart';
import 'package:mobile/data/models/product.dart';
import 'package:mobile/domain/providers/categories_provider.dart';
import 'package:mobile/domain/providers/core_providers.dart';
import 'package:mobile/domain/providers/locations_provider.dart';
import 'package:mobile/l10n/app_localizations.dart';

class CategoryProductsScreen extends ConsumerStatefulWidget {
  final int categoryId;
  const CategoryProductsScreen({required this.categoryId, super.key});

  @override
  ConsumerState<CategoryProductsScreen> createState() =>
      _CategoryProductsScreenState();
}

class _CategoryProductsScreenState
    extends ConsumerState<CategoryProductsScreen> {
  Future<List<Product>>? _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Product>> _load() {
    return ref
        .read(productRepositoryProvider)
        .getProducts(categoryId: widget.categoryId);
  }

  Future<void> _refresh() async {
    final fut = _load();
    setState(() => _future = fut);
    await fut;
  }

  Category? _category() {
    final cats = ref.read(categoriesProvider).asData?.value ?? const [];
    try {
      return cats.firstWhere((c) => c.id == widget.categoryId);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final category = _category();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          category != null
              ? '${l10n.get('products')} · ${category.name}'
              : l10n.get('products'),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<Product>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 120),
                  Center(child: Text('Error: ${snapshot.error}')),
                ],
              );
            }
            final products = snapshot.data ?? const [];
            if (products.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 120),
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 80,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Center(child: Text(l10n.get('noProductsInCategory'))),
                ],
              );
            }
            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: products.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final p = products[i];
                return ListTile(
                  leading: const Icon(Icons.inventory_2),
                  title: Text(p.name),
                  subtitle: _LocationSubtitle(locationId: p.locationId),
                  trailing: const Icon(Icons.edit),
                  onTap: () => _showEditDialog(p),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Future<void> _showEditDialog(Product product) async {
    final l10n = AppLocalizations.of(context);
    final nameCtrl = TextEditingController(text: product.name);
    final locationId = ValueNotifier<int?>(product.locationId);

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.get('editProduct')),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(labelText: l10n.get('name')),
                autofocus: true,
              ),
              const SizedBox(height: 12),
              _ProductLocationDropdown(selected: locationId),
            ],
          ),
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => _confirmDelete(dialogContext, product),
            child: Text(l10n.get('delete')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.get('cancel')),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await ref.read(productRepositoryProvider).updateProduct(
                  product.id,
                  {
                    'name': nameCtrl.text,
                    'location_id': locationId.value,
                  },
                );
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                  _refresh();
                }
              } on DioException catch (e) {
                if (dialogContext.mounted) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
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

  Future<void> _confirmDelete(
    BuildContext dialogContext,
    Product product,
  ) async {
    final l10n = AppLocalizations.of(dialogContext);
    final confirmed = await showDialog<bool>(
      context: dialogContext,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.get('deleteProduct')),
        content: Text(
          l10n
              .get('confirmDeleteProduct')
              .replaceFirst('{name}', product.name),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.get('cancel')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              l10n.get('delete'),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(productRepositoryProvider).deleteProduct(product.id);
      if (dialogContext.mounted) {
        Navigator.pop(dialogContext);
        _refresh();
      }
    } on DioException catch (e) {
      if (dialogContext.mounted) {
        ScaffoldMessenger.of(dialogContext).showSnackBar(
          SnackBar(
            content: Text(
              e.response?.data?.toString() ?? e.message ?? 'Error',
            ),
          ),
        );
      }
    }
  }
}

class _LocationSubtitle extends ConsumerWidget {
  final int? locationId;
  const _LocationSubtitle({required this.locationId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    if (locationId == null) {
      return Text(l10n.get('unspecifiedLocation'));
    }
    final locationsAsync = ref.watch(locationsListProvider);
    return locationsAsync.maybeWhen(
      data: (locs) {
        final match = locs.where((l) => l.id == locationId).cast<Location?>();
        final loc = match.isEmpty ? null : match.first;
        return Text(
          loc?.label.isNotEmpty == true ? loc!.label : l10n.get('unspecifiedLocation'),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

class _ProductLocationDropdown extends ConsumerWidget {
  final ValueNotifier<int?> selected;
  const _ProductLocationDropdown({required this.selected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locationsAsync = ref.watch(locationsListProvider);
    return locationsAsync.when(
      data: (locations) => ValueListenableBuilder<int?>(
        valueListenable: selected,
        builder: (context, value, _) {
          final ids = locations.map((l) => l.id).toSet();
          final safeValue = ids.contains(value) ? value : null;
          return DropdownButtonFormField<int?>(
            value: safeValue,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: l10n.get('location'),
              border: const OutlineInputBorder(),
            ),
            items: <DropdownMenuItem<int?>>[
              DropdownMenuItem<int?>(
                value: null,
                child: Text(l10n.get('unspecifiedLocation')),
              ),
              ...locations.map(
                (Location l) => DropdownMenuItem<int?>(
                  value: l.id,
                  child: Text(l.label.isEmpty ? '(unnamed)' : l.label),
                ),
              ),
            ],
            onChanged: (v) => selected.value = v,
          );
        },
      ),
      loading: () => const Padding(
        padding: EdgeInsets.all(8),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Text('Error: $e'),
    );
  }
}
