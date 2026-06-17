import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/data/models/location.dart';
import 'package:mobile/domain/providers/core_providers.dart';
import 'package:mobile/domain/providers/dashboard_provider.dart';
import 'package:mobile/domain/providers/locations_provider.dart';
import 'package:mobile/l10n/app_localizations.dart';

class LocationsScreen extends ConsumerWidget {
  const LocationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationsAsync = ref.watch(locationsListProvider);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.get('locations'))),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateDialog(context, ref),
        icon: const Icon(Icons.add),
        label: Text(l10n.get('addLocation')),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(locationsListProvider.future),
        child: locationsAsync.when(
          data: (locations) {
            if (locations.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 120),
                  Icon(
                    Icons.place_outlined,
                    size: 80,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Center(child: Text(l10n.get('noLocationsYet'))),
                ],
              );
            }
            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: locations.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final loc = locations[i];
                return ListTile(
                  leading: const Icon(Icons.place),
                  title: Text(loc.label.isEmpty ? '(unnamed)' : loc.label),
                  subtitle: loc.notes != null && loc.notes!.isNotEmpty
                      ? Text(loc.notes!)
                      : null,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/locations/${loc.id}'),
                  onLongPress: () => _showEditDialog(context, ref, loc),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              const SizedBox(height: 120),
              Center(child: Text('Error: $e')),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showCreateDialog(BuildContext context, WidgetRef ref) async {
    await _showEditOrCreate(context, ref, null);
  }

  Future<void> _showEditDialog(
    BuildContext context,
    WidgetRef ref,
    Location loc,
  ) async {
    await _showEditOrCreate(context, ref, loc);
  }

  Future<void> _showEditOrCreate(
    BuildContext context,
    WidgetRef ref,
    Location? loc,
  ) async {
    final l10n = AppLocalizations.of(context);
    final roomCtrl = TextEditingController(text: loc?.room ?? '');
    final areaCtrl = TextEditingController(text: loc?.area ?? '');
    final shelfCtrl = TextEditingController(text: loc?.shelfBox ?? '');
    final notesCtrl = TextEditingController(text: loc?.notes ?? '');

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          loc == null ? l10n.get('addLocation') : l10n.get('editLocation'),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: roomCtrl,
                decoration: InputDecoration(labelText: l10n.get('room')),
                autofocus: loc == null,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: areaCtrl,
                decoration: InputDecoration(labelText: l10n.get('area')),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: shelfCtrl,
                decoration: InputDecoration(labelText: l10n.get('shelfBox')),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: notesCtrl,
                decoration: InputDecoration(labelText: l10n.get('notes')),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          if (loc != null)
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () => _confirmDelete(dialogContext, ref, loc),
              child: Text(l10n.get('delete')),
            ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.get('cancel')),
          ),
          ElevatedButton(
            onPressed: () async {
              final data = {
                'room': roomCtrl.text,
                'area': areaCtrl.text,
                'shelf_box': shelfCtrl.text,
                'notes': notesCtrl.text.isEmpty ? null : notesCtrl.text,
              };
              try {
                if (loc == null) {
                  await ref
                      .read(locationRepositoryProvider)
                      .createLocation(data);
                } else {
                  await ref
                      .read(locationRepositoryProvider)
                      .updateLocation(loc.id, data);
                }
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                  ref.invalidate(locationsListProvider);
                  ref.invalidate(dashboardProvider);
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
            child: Text(loc == null ? l10n.get('create') : l10n.get('save')),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext dialogContext,
    WidgetRef ref,
    Location loc,
  ) async {
    final l10n = AppLocalizations.of(dialogContext);
    final confirmed = await showDialog<bool>(
      context: dialogContext,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.get('deleteLocation')),
        content: Text(
          l10n
              .get('confirmDeleteLocation')
              .replaceFirst('{name}', loc.label),
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
      await ref.read(locationRepositoryProvider).deleteLocation(loc.id);
      if (dialogContext.mounted) {
        Navigator.pop(dialogContext);
        ref.invalidate(locationsListProvider);
        ref.invalidate(dashboardProvider);
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
