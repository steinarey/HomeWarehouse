import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile/data/models/location.dart';
import 'package:mobile/data/models/product.dart';
import 'package:mobile/domain/providers/core_providers.dart';
import 'package:mobile/presentation/screens/use_restock/search_tab.dart';
import 'package:mobile/presentation/screens/use_restock/camera_tab.dart';
import 'package:mobile/presentation/screens/use_restock/nfc_tab.dart';
import 'package:mobile/data/models/category.dart';
import 'package:mobile/l10n/app_localizations.dart';

enum _ActionMode { use, restock, adjust }

class UseRestockScreen extends ConsumerStatefulWidget {
  const UseRestockScreen({super.key});

  @override
  ConsumerState<UseRestockScreen> createState() => _UseRestockScreenState();
}

class _UseRestockScreenState extends ConsumerState<UseRestockScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  _ActionMode _mode = _ActionMode.use;

  bool get _isRestockMode => _mode == _ActionMode.restock;
  bool get _isAdjustMode => _mode == _ActionMode.adjust;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _setMode(_ActionMode m) => setState(() => _mode = m);

  void _onProductSelected(Product product) {
    _showActionBottomSheet(product);
  }

  Future<void> _showActionBottomSheet(Product product) async {
    setState(() {
      _lastActionId = null;
    });

    final isRestock = _isRestockMode;
    final isAdjust = _isAdjustMode;
    final quantityController = TextEditingController(text: isAdjust ? '0' : '1');

    // Restock-only fields. Loaded lazily once the sheet is shown.
    Location? selectedLocation;
    DateTime? expiryDate;
    List<Location> locations = const [];
    if (isRestock) {
      try {
        locations = await ref.read(apiClientProvider).getLocations();
      } catch (_) {
        locations = const [];
      }
    }
    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      isAdjust
                          ? '${AppLocalizations.of(context).get('adjustAction')} ${product.name}'
                          : isRestock
                              ? '${AppLocalizations.of(context).get('restockAction')} ${product.name}'
                              : '${AppLocalizations.of(context).get('useAction')} ${product.name}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.inventory_2_outlined),
                    tooltip: AppLocalizations.of(context).get('viewLocations'),
                    onPressed: () => _showStockBatchesSheet(product),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${AppLocalizations.of(context).get('packageSize')}: ${product.packageSize}',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: quantityController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: isAdjust
                      ? AppLocalizations.of(context).get('newTotalQuantity')
                      : isRestock
                          ? AppLocalizations.of(context).get('quantityPackages')
                          : AppLocalizations.of(context).get('quantityUnits'),
                  border: const OutlineInputBorder(),
                  helperText: isAdjust
                      ? AppLocalizations.of(context).get('adjustHint')
                      : isRestock
                          ? '${AppLocalizations.of(context).get('addingUnitsHint').replaceFirst('{size}', product.packageSize.toString())} ${product.packageSize} ${AppLocalizations.of(context).get('unitsOf')}'
                          : AppLocalizations.of(context).get('removingUnitsHint'),
                ),
                autofocus: true,
              ),
              if (isRestock) ...[
                const SizedBox(height: 16),
                DropdownButtonFormField<Location?>(
                  initialValue: selectedLocation,
                  decoration: const InputDecoration(
                    labelText: 'Location (optional)',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<Location?>(
                      value: null,
                      child: Text('Unspecified'),
                    ),
                    ...locations.map(
                      (l) => DropdownMenuItem(value: l, child: Text(l.label)),
                    ),
                  ],
                  onChanged: (val) =>
                      setSheetState(() => selectedLocation = val),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: expiryDate ?? DateTime.now().add(
                        const Duration(days: 30),
                      ),
                      firstDate: DateTime.now().subtract(
                        const Duration(days: 1),
                      ),
                      lastDate: DateTime.now().add(
                        const Duration(days: 365 * 5),
                      ),
                    );
                    if (picked != null) {
                      setSheetState(() => expiryDate = picked);
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Expiry date (optional)',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      expiryDate == null
                          ? 'None'
                          : DateFormat.yMMMd().format(expiryDate!),
                    ),
                  ),
                ),
                if (expiryDate != null)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () =>
                          setSheetState(() => expiryDate = null),
                      child: const Text('Clear expiry'),
                    ),
                  ),
              ],
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(AppLocalizations.of(context).get('cancel')),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isAdjust
                            ? Colors.blueGrey
                            : isRestock
                                ? Colors.green
                                : Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () async {
                        final qty = int.tryParse(quantityController.text);
                        if (qty == null) return;
                        if (!isAdjust && qty <= 0) return;
                        if (isAdjust && qty < 0) return;

                        Navigator.pop(context);
                        await _performAction(
                          product,
                          qty,
                          locationId: selectedLocation?.id,
                          expiryDate: expiryDate,
                        );
                      },
                      child: Text(
                        isAdjust
                            ? AppLocalizations.of(context).get('adjustAction')
                            : isRestock
                                ? AppLocalizations.of(context).get('restockAction')
                                : AppLocalizations.of(context).get('useAction'),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _performAction(
    Product product,
    int quantity, {
    int? locationId,
    DateTime? expiryDate,
  }) async {
    try {
      final repo = ref.read(inventoryRepositoryProvider);
      int? actionId;

      if (_isAdjustMode) {
        final action = await repo.adjust(
          productId: product.id,
          newTotalQuantity: quantity,
        );
        actionId = action.id;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${AppLocalizations.of(context).get('adjustedMessage')} ${product.name} → $quantity',
              ),
            ),
          );
        }
      } else if (_isRestockMode) {
        final action = await repo.restock(
          productId: product.id,
          quantityPackages: quantity,
          locationId: locationId,
          expiryDate: expiryDate,
          source: 'manual',
        );
        actionId = action.id;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${AppLocalizations.of(context).get('restockedMessage')} ${quantity * product.packageSize} ${AppLocalizations.of(context).get('unitsOf')} ${product.name}',
              ),
            ),
          );
        }
      } else {
        final action = await repo.consume(
          productId: product.id,
          quantityUnits: quantity,
          source: 'manual',
        );
        actionId = action.id;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${AppLocalizations.of(context).get('usedMessage')} $quantity ${AppLocalizations.of(context).get('unitsOf')} ${product.name}',
              ),
            ),
          );
        }
      }

      setState(() {
        _lastActionId = actionId;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppLocalizations.of(context).get('errorMessage')}: $e',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showCreateProductSheet(String barcode) async {
    final nameController = TextEditingController();
    final pkgSizeController = TextEditingController(text: '1');
    Category? selectedCategory;

    // Fetch categories for dropdown
    final categories = await ref
        .read(categoryRepositoryProvider)
        .getCategories();

    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                AppLocalizations.of(context).get('newProduct'),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text('${AppLocalizations.of(context).get('barcode')}: $barcode'),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context).get('productName'),
                  border: const OutlineInputBorder(),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<Category>(
                      initialValue: selectedCategory,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context).get('category'),
                        border: const OutlineInputBorder(),
                      ),
                      items: categories
                          .map(
                            (c) =>
                                DropdownMenuItem(value: c, child: Text(c.name)),
                          )
                          .toList(),
                      onChanged: (val) =>
                          setSheetState(() => selectedCategory = val),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () async {
                      final newCategory = await _showCreateCategoryDialog();
                      if (newCategory != null) {
                        // Refresh categories and select the new one
                        final updatedCategories = await ref
                            .read(categoryRepositoryProvider)
                            .getCategories();
                        setSheetState(() {
                          categories.clear();
                          categories.addAll(updatedCategories);
                          selectedCategory = updatedCategories.firstWhere(
                            (c) => c.id == newCategory.id,
                            orElse: () => updatedCategories.first,
                          );
                        });
                      }
                    },
                    icon: const Icon(Icons.add_circle_outline),
                    tooltip: AppLocalizations.of(context).get('createCategory'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: pkgSizeController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context).get('packageSize'),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  if (nameController.text.isEmpty || selectedCategory == null) {
                    return;
                  }

                  try {
                    final newProduct = await ref
                        .read(productRepositoryProvider)
                        .createProduct({
                          'name': nameController.text,
                          'category_id': selectedCategory!.id,
                          'barcode': barcode,
                          'package_size':
                              int.tryParse(pkgSizeController.text) ?? 1,
                        });

                    if (mounted) {
                      Navigator.pop(context);
                      _showActionBottomSheet(newProduct);
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '${AppLocalizations.of(context).get('errorCreatingProduct')}: $e',
                        ),
                      ),
                    );
                  }
                },
                child: Text(
                  AppLocalizations.of(context).get('createAndContinue'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<Category?> _showCreateCategoryDialog() async {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final minStockController = TextEditingController(text: '0');
    final consumptionRateController = TextEditingController();

    return showDialog<Category>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).get('newCategory')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context).get('name'),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: descController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context).get('description'),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: minStockController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context).get('minStock'),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: consumptionRateController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context).get('consumptionRate'),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context).get('cancel')),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty) return;
              try {
                final newCategory = await ref
                    .read(categoryRepositoryProvider)
                    .createCategory({
                      'name': nameController.text,
                      'description': descController.text,
                      'min_stock': int.tryParse(minStockController.text) ?? 0,
                      'consumption_rate': int.tryParse(
                        consumptionRateController.text,
                      ),
                    });
                if (context.mounted) {
                  Navigator.pop(context, newCategory);
                }
              } catch (e) {
                // Handle error
              }
            },
            child: Text(AppLocalizations.of(context).get('create')),
          ),
        ],
      ),
    );
  }

  int? _lastActionId; // Track the last action for undo

  @override
  Widget build(BuildContext context) {
    final modeColor = _isAdjustMode
        ? Colors.blueGrey
        : _isRestockMode
            ? Colors.green
            : Colors.orange;

    return Scaffold(
      appBar: AppBar(
        title: SegmentedButton<_ActionMode>(
          showSelectedIcon: false,
          style: SegmentedButton.styleFrom(
            backgroundColor: Colors.white.withValues(alpha: 0.15),
            selectedBackgroundColor: Colors.white,
            selectedForegroundColor: modeColor,
            foregroundColor: Colors.white,
          ),
          segments: [
            ButtonSegment(
              value: _ActionMode.use,
              icon: const Icon(Icons.remove_circle_outline),
              label: Text(AppLocalizations.of(context).get('useMode')),
            ),
            ButtonSegment(
              value: _ActionMode.restock,
              icon: const Icon(Icons.add_circle_outline),
              label: Text(AppLocalizations.of(context).get('restockMode')),
            ),
            ButtonSegment(
              value: _ActionMode.adjust,
              icon: const Icon(Icons.tune),
              label: Text(AppLocalizations.of(context).get('adjustMode')),
            ),
          ],
          selected: {_mode},
          onSelectionChanged: (set) {
            if (set.first != _mode) _setMode(set.first);
          },
        ),
        centerTitle: true,
        backgroundColor: modeColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: [
            Tab(
              icon: const Icon(Icons.qr_code),
              text: AppLocalizations.of(context).get('scan'),
            ),
            Tab(
              icon: const Icon(Icons.nfc),
              text: AppLocalizations.of(context).get('nfc'),
            ),
            Tab(
              icon: const Icon(Icons.search),
              text: AppLocalizations.of(context).get('search'),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          CameraTab(
            isRestockMode: _isRestockMode,
            onProductFound: (product) {
              _showActionBottomSheet(product).then((_) {
                // Resume scanning if needed
              });
            },
            onUnknownBarcode: (barcode) {
              if (_isRestockMode) {
                _showCreateProductSheet(barcode);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      AppLocalizations.of(
                        context,
                      ).get('productNotFoundRestockHint'),
                    ),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            },
          ),
          NFCTab(
            isRestockMode: _isRestockMode,
            onCategoryFound: (category) {
              _showCategoryProductSheet(category);
            },
          ),
          SearchTab(
            isRestockMode: _isRestockMode,
            onProductSelected: _onProductSelected,
          ),
        ],
      ),
      floatingActionButton: _lastActionId != null
          ? FloatingActionButton.extended(
              onPressed: _undoLastAction,
              label: Text(AppLocalizations.of(context).get('undoLastAction')),
              icon: const Icon(Icons.undo),
              backgroundColor: Colors.grey[800],
              foregroundColor: Colors.white,
            )
          : null,
    );
  }

  Future<void> _showStockBatchesSheet(Product product) async {
    final l10n = AppLocalizations.of(context);
    List<Map<String, dynamic>>? batches;
    try {
      batches = await ref
          .read(apiClientProvider)
          .getProductStockBatches(product.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
      return;
    }
    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '${l10n.get('stockLocationsFor')} ${product.name}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              if (batches!.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Center(child: Text(l10n.get('noStockOnHand'))),
                )
              else
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.5,
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: batches.length,
                    itemBuilder: (context, index) {
                      final b = batches![index];
                      final loc = b['location_label'] as String?;
                      final exp = b['expiry_date'] as String?;
                      return ListTile(
                        leading: CircleAvatar(child: Text('${b['quantity']}')),
                        title: Text(loc ?? l10n.get('unspecifiedLocation')),
                        subtitle: exp == null
                            ? null
                            : Text('${l10n.get('expiresAt')} $exp'),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _undoLastAction() async {
    if (_lastActionId == null) return;

    try {
      final repo = ref.read(inventoryRepositoryProvider);
      await repo.undoAction(_lastActionId!);

      setState(() {
        _lastActionId = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).get('actionUndone')),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).get('errorUndoingAction'),
            ),
          ),
        );
      }
    }
  }

  Future<void> _showCategoryProductSheet(Category category) async {
    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.5,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              '${category.name} ${AppLocalizations.of(context).get('products')}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: FutureBuilder<List<Product>>(
                future: ref.read(productRepositoryProvider).getProducts(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        '${AppLocalizations.of(context).get('errorMessage')}: ${snapshot.error}',
                      ),
                    );
                  }

                  final products = snapshot.data ?? [];
                  final categoryProducts = products
                      .where((p) => p.categoryId == category.id)
                      .toList();

                  if (categoryProducts.isEmpty) {
                    return Center(
                      child: Text(
                        AppLocalizations.of(context).get('noProductsFound'),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: categoryProducts.length,
                    itemBuilder: (context, index) {
                      final product = categoryProducts[index];
                      return ListTile(
                        title: Text(product.name),
                        subtitle: Text(
                          '${AppLocalizations.of(context).get('packageSize')}: ${product.packageSize}',
                        ),
                        onTap: () {
                          Navigator.pop(context); // Close list sheet
                          _showActionBottomSheet(product);
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
