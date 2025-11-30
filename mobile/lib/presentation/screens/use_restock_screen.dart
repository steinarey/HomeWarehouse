import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/data/models/product.dart';
import 'package:mobile/domain/providers/core_providers.dart';
import 'package:mobile/domain/providers/user_provider.dart';
import 'package:mobile/presentation/screens/use_restock/search_tab.dart';
import 'package:mobile/presentation/screens/use_restock/camera_tab.dart';
import 'package:mobile/presentation/screens/use_restock/nfc_tab.dart';
import 'package:mobile/data/models/category.dart';
// import 'package:mobile/domain/providers/core_providers.dart'; // Duplicate

class UseRestockScreen extends ConsumerStatefulWidget {
  const UseRestockScreen({super.key});

  @override
  ConsumerState<UseRestockScreen> createState() => _UseRestockScreenState();
}

class _UseRestockScreenState extends ConsumerState<UseRestockScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isRestockMode = false; // Default to Use mode

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

  void _toggleMode() {
    setState(() {
      _isRestockMode = !_isRestockMode;
    });
  }

  void _onProductSelected(Product product) {
    _showActionBottomSheet(product);
  }

  Future<void> _showActionBottomSheet(Product product) async {
    // Clear previous undo state when starting a new action
    setState(() {
      _lastActionId = null;
    });

    final quantityController = TextEditingController(text: '1');
    final isRestock = _isRestockMode;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
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
              isRestock ? 'Restock ${product.name}' : 'Use ${product.name}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Package size: ${product.packageSize}'),
            const SizedBox(height: 16),
            TextField(
              controller: quantityController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: isRestock
                    ? 'Quantity (Packages)'
                    : 'Quantity (Units)',
                border: const OutlineInputBorder(),
                helperText: isRestock
                    ? 'Adding ${product.packageSize} units per package'
                    : 'Removing individual units',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isRestock ? Colors.green : Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () async {
                      final qty = int.tryParse(quantityController.text);
                      if (qty == null || qty <= 0) return;

                      Navigator.pop(context);
                      await _performAction(product, qty);
                    },
                    child: Text(isRestock ? 'Restock' : 'Use'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _performAction(Product product, int quantity) async {
    try {
      final user = await ref.read(activeUserProvider.future);
      if (user == null) throw Exception('No active user');

      final repo = ref.read(inventoryRepositoryProvider);
      int? actionId;

      if (_isRestockMode) {
        final action = await repo.restock(
          productId: product.id,
          quantityPackages: quantity,
          userId: user.id,
          source: 'manual', // Update source based on tab
        );
        actionId = action.id;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Restocked ${quantity * product.packageSize} units of ${product.name}',
              ),
            ),
          );
        }
      } else {
        final action = await repo.consume(
          productId: product.id,
          quantityUnits: quantity, // Assuming input is units for consume
          userId: user.id,
          source: 'manual',
        );
        actionId = action.id;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Used $quantity units of ${product.name}')),
          );
        }
      }

      setState(() {
        _lastActionId = actionId;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
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
              const Text(
                'New Product',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('Barcode: $barcode'),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Product Name',
                  border: OutlineInputBorder(),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<Category>(
                      value: selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
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
                    tooltip: 'Create Category',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: pkgSizeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Package Size',
                  border: OutlineInputBorder(),
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
                      SnackBar(content: Text('Error creating product: $e')),
                    );
                  }
                },
                child: const Text('Create & Continue'),
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

    return showDialog<Category>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
              autofocus: true,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: descController,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: minStockController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Minimum Stock'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
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
                    });
                if (context.mounted) {
                  Navigator.pop(context, newCategory);
                }
              } catch (e) {
                // Handle error
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  int? _lastActionId; // Track the last action for undo

  @override
  Widget build(BuildContext context) {
    // Listen to tab changes to reset state when leaving this screen
    ref.listen(bottomNavIndexProvider, (previous, next) {
      if (next != 1) {
        setState(() {
          _lastActionId = null;
          // Optionally reset to default mode if desired, but user said "reset... default state"
          // which might mean just clearing the undo button and temporary stuff.
          // _isRestockMode = false;
        });
      }
    });

    // final colorScheme = Theme.of(context).colorScheme;
    final modeColor = _isRestockMode ? Colors.green : Colors.orange;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isRestockMode ? 'Restock Mode' : 'Use Mode'),
        backgroundColor: modeColor,
        foregroundColor: Colors.white,
        actions: [
          Switch(
            value: _isRestockMode,
            onChanged: (val) => _toggleMode(),
            activeThumbColor: Colors.white,
            activeTrackColor: Colors.green.shade700,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: Colors.orange.shade700,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.qr_code), text: 'Scan'),
            Tab(icon: Icon(Icons.nfc), text: 'NFC'),
            Tab(icon: Icon(Icons.search), text: 'Search'),
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
                  const SnackBar(
                    content: Text(
                      'Product not found. Switch to Restock mode to add it.',
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
              label: const Text('Undo Last Action'),
              icon: const Icon(Icons.undo),
              backgroundColor: Colors.grey[800],
              foregroundColor: Colors.white,
            )
          : null,
    );
  }

  Future<void> _undoLastAction() async {
    if (_lastActionId == null) return;

    try {
      final user = await ref.read(activeUserProvider.future);
      if (user == null) return;

      final repo = ref.read(inventoryRepositoryProvider);
      await repo.undoAction(_lastActionId!, user.id);

      setState(() {
        _lastActionId = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Action undone successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error undoing action: $e')));
      }
    }
  }

  Future<void> _showCategoryProductSheet(Category category) async {
    // Fetch products for category
    // Since I don't have getProductsByCategory in repo yet (only search), I'll use search with empty query and filter locally or add endpoint support.
    // Actually ApiClient has getProducts({query}), but backend supports filtering?
    // Backend `GET /products` doesn't seem to support category_id filter in the code I saw earlier.
    // `backend/app/api/endpoints/products.py` -> `read_products` only has skip/limit.
    // So I might need to fetch all and filter, or just rely on search.
    // For now, I'll just show a message or redirect to search.

    _tabController.animateTo(2); // Switch to search
    // Ideally pre-fill search with category name?
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Category: ${category.name}. Please search for product.'),
      ),
    );
  }
}
