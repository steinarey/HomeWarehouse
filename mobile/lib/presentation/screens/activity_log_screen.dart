import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile/data/models/inventory_action.dart';
import 'package:mobile/domain/providers/core_providers.dart';
import 'package:mobile/domain/providers/user_provider.dart';
import 'package:mobile/l10n/app_localizations.dart';

class ActivityLogScreen extends ConsumerStatefulWidget {
  const ActivityLogScreen({super.key});

  @override
  ConsumerState<ActivityLogScreen> createState() => _ActivityLogScreenState();
}

class _ActivityLogScreenState extends ConsumerState<ActivityLogScreen> {
  List<InventoryAction> _actions = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadActions();
  }

  Future<void> _loadActions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final actions = await ref
          .read(inventoryRepositoryProvider)
          .getActions(limit: 50);
      if (mounted) {
        setState(() {
          _actions = actions;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _undoAction(InventoryAction action) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).get('undoAction')),
        content: Text(
          'Are you sure you want to undo this action?\n\n${action.actionType} ${action.quantityDelta}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context).get('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppLocalizations.of(context).get('undo')),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final user = await ref.read(activeUserProvider.future);
      if (user == null) throw Exception('No active user');

      await ref
          .read(inventoryRepositoryProvider)
          .undoAction(action.id, user.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).get('actionUndone')),
          ),
        );
        _loadActions(); // Refresh list
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).get('activityLog')),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadActions),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Text(
                AppLocalizations.of(context).get('errorLoadingActions'),
              ),
            )
          : ListView.builder(
              itemCount: _actions.length,
              itemBuilder: (context, index) {
                final action = _actions[index];
                final isConsume = action.actionType == 'consume';
                final color = isConsume ? Colors.orange : Colors.green;

                return ListTile(
                  title: Text(
                    action.productName ?? action.categoryName ?? 'Unknown Item',
                  ),
                  subtitle: Text(
                    '${DateFormat.yMMMd().add_jm().format(action.createdAt)} • ${action.userName ?? 'Unknown User'}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${isConsume ? '-' : '+'}${action.quantityDelta}',
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (!action.undone)
                        IconButton(
                          icon: const Icon(Icons.undo),
                          onPressed: () => _undoAction(action),
                        ),
                      if (action.undone)
                        const Padding(
                          padding: EdgeInsets.only(left: 8.0),
                          child: Text(
                            '(Undone)',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
