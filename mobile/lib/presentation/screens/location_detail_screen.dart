import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/data/models/location_contents.dart';
import 'package:mobile/domain/providers/core_providers.dart';
import 'package:mobile/l10n/app_localizations.dart';

class LocationDetailScreen extends ConsumerStatefulWidget {
  final int locationId;
  const LocationDetailScreen({required this.locationId, super.key});

  @override
  ConsumerState<LocationDetailScreen> createState() =>
      _LocationDetailScreenState();
}

class _LocationDetailScreenState extends ConsumerState<LocationDetailScreen> {
  Future<LocationContents>? _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<LocationContents> _load() {
    return ref
        .read(locationRepositoryProvider)
        .getLocationContents(widget.locationId);
  }

  Future<void> _refresh() async {
    final fut = _load();
    setState(() => _future = fut);
    await fut;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.get('locationContents'))),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<LocationContents>(
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
            final contents = snapshot.data!;
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  contents.location.label,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (contents.location.notes != null &&
                    contents.location.notes!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      contents.location.notes!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                const SizedBox(height: 8),
                Text(
                  '${l10n.get('totalStock')}: ${contents.totalQuantity}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const Divider(height: 32),
                if (contents.categories.isEmpty)
                  Center(child: Text(l10n.get('noStockOnHand')))
                else
                  ...contents.categories.map(
                    (c) => _categorySection(context, l10n, c),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _categorySection(
    BuildContext context,
    AppLocalizations l10n,
    LocationCategory category,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  category.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                '${category.totalQuantity}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ...category.products.map((p) => _productTile(l10n, p)),
        ],
      ),
    );
  }

  Widget _productTile(AppLocalizations l10n, LocationProduct product) {
    return Card(
      child: ExpansionTile(
        title: Text(product.name),
        trailing: Text(
          '${product.totalQuantity}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        children: product.batches
            .map(
              (b) => ListTile(
                dense: true,
                title: Text('×${b.quantity}'),
                subtitle: b.expiryDate != null
                    ? Text('${l10n.get('expiresAt')} ${b.expiryDate!}')
                    : null,
              ),
            )
            .toList(),
      ),
    );
  }
}
