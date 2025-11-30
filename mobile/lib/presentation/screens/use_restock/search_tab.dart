import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/data/models/product.dart';
import 'package:mobile/domain/providers/core_providers.dart';

class SearchTab extends ConsumerStatefulWidget {
  final bool isRestockMode;
  final Function(Product) onProductSelected;

  const SearchTab({
    super.key,
    required this.isRestockMode,
    required this.onProductSelected,
  });

  @override
  ConsumerState<SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends ConsumerState<SearchTab> {
  final _searchController = TextEditingController();
  List<Product> _allProducts = [];
  List<Product> _filteredResults = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchAllProducts();
  }

  Future<void> _fetchAllProducts() async {
    setState(() => _isLoading = true);
    try {
      final products = await ref
          .read(productRepositoryProvider)
          .getProducts(); // Fetch all (no query)
      if (mounted) {
        setState(() {
          _allProducts = products;
          _filteredResults = products;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading products: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _filterProducts(String query) {
    if (query.isEmpty) {
      setState(() => _filteredResults = _allProducts);
      return;
    }

    final lowerQuery = query.toLowerCase();
    setState(() {
      _filteredResults = _allProducts.where((p) {
        return p.name.toLowerCase().contains(lowerQuery) ||
            (p.barcode?.contains(lowerQuery) ?? false);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Search product',
              prefixIcon: const Icon(Icons.search),
              border: const OutlineInputBorder(),
              suffixIcon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _filterProducts('');
                      },
                    ),
            ),
            onChanged: _filterProducts,
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _filteredResults.length,
            itemBuilder: (context, index) {
              final product = _filteredResults[index];
              return ListTile(
                title: Text(product.name),
                subtitle: Text(
                  'Pkg size: ${product.packageSize} • Barcode: ${product.barcode ?? "N/A"}',
                ),
                trailing: Icon(
                  widget.isRestockMode ? Icons.add_circle : Icons.remove_circle,
                  color: widget.isRestockMode ? Colors.green : Colors.orange,
                ),
                onTap: () => widget.onProductSelected(product),
              );
            },
          ),
        ),
      ],
    );
  }
}
