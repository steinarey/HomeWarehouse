import 'dart:async';

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
  List<Product> _results = [];
  bool _isLoading = false;
  Timer? _debounce;
  int _requestSeq = 0;

  @override
  void initState() {
    super.initState();
    _runQuery(null);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _runQuery(value.trim().isEmpty ? null : value.trim());
    });
  }

  Future<void> _runQuery(String? query) async {
    final seq = ++_requestSeq;
    setState(() => _isLoading = true);
    try {
      final products = await ref
          .read(productRepositoryProvider)
          .getProducts(query: query);
      // Drop stale results if a newer query has been issued.
      if (!mounted || seq != _requestSeq) return;
      setState(() => _results = products);
    } catch (e) {
      if (!mounted || seq != _requestSeq) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading products: $e')),
      );
    } finally {
      if (mounted && seq == _requestSeq) {
        setState(() => _isLoading = false);
      }
    }
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
                        _onChanged('');
                      },
                    ),
            ),
            onChanged: _onChanged,
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _results.length,
            itemBuilder: (context, index) {
              final product = _results[index];
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
