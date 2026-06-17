import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile/data/models/inventory_action.dart';
import 'package:mobile/domain/providers/core_providers.dart';
import 'package:mobile/l10n/app_localizations.dart';

class ActivityLogScreen extends ConsumerStatefulWidget {
  const ActivityLogScreen({super.key});

  @override
  ConsumerState<ActivityLogScreen> createState() => _ActivityLogScreenState();
}

class _ActivityLogScreenState extends ConsumerState<ActivityLogScreen> {
  static const _pageSize = 30;

  final ScrollController _scrollController = ScrollController();
  final List<InventoryAction> _actions = [];

  bool _isLoadingInitial = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadInitial();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Trigger next page when within 300px of the bottom and not already loading.
    if (!_isLoadingMore &&
        _hasMore &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 300) {
      _loadMore();
    }
  }

  Future<void> _loadInitial() async {
    setState(() {
      _isLoadingInitial = true;
      _error = null;
      _actions.clear();
      _hasMore = true;
    });
    try {
      final page = await ref
          .read(inventoryRepositoryProvider)
          .getActions(skip: 0, limit: _pageSize);
      if (!mounted) return;
      setState(() {
        _actions.addAll(page);
        _hasMore = page.length == _pageSize;
        _isLoadingInitial = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoadingInitial = false;
      });
    }
  }

  Future<void> _loadMore() async {
    setState(() => _isLoadingMore = true);
    try {
      final page = await ref
          .read(inventoryRepositoryProvider)
          .getActions(skip: _actions.length, limit: _pageSize);
      if (!mounted) return;
      setState(() {
        _actions.addAll(page);
        _hasMore = page.length == _pageSize;
        _isLoadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingMore = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
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
      await ref.read(inventoryRepositoryProvider).undoAction(action.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).get('actionUndone'))),
      );
      _loadInitial(); // Refresh — easier than splicing the new state in.
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).get('errorUndoingAction')),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.get('activityLog')),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadInitial),
        ],
      ),
      body: _isLoadingInitial
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(l10n.get('errorLoadingActions')))
              : _actions.isEmpty
                  ? RefreshIndicator(
                      onRefresh: () async => _loadInitial(),
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          const SizedBox(height: 120),
                          Icon(
                            Icons.history,
                            size: 80,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Center(
                            child: Text(
                              l10n.get('noActivityYet'),
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () async => _loadInitial(),
                      child: ListView.builder(
                        controller: _scrollController,
                        // +1 for the footer (spinner or "no more" message).
                        itemCount: _actions.length + 1,
                        itemBuilder: (context, index) {
                          if (index == _actions.length) {
                            return _footer(l10n);
                          }
                          final action = _actions[index];
                          final delta = action.quantityDelta;
                          final color = delta < 0 ? Colors.orange : Colors.green;
                          final sign = delta >= 0 ? '+' : '';

                          return ListTile(
                            title: Text(
                              action.productName ??
                                  action.categoryName ??
                                  'Unknown Item',
                            ),
                            subtitle: Text(
                              '${DateFormat.yMMMd().add_jm().format(action.createdAt)} • ${action.userName ?? 'Unknown User'}',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '$sign$delta',
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
                    ),
    );
  }

  Widget _footer(AppLocalizations l10n) {
    if (_isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (!_hasMore) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Text(
            l10n.get('noMoreResults'),
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ),
      );
    }
    // Should rarely be visible — scroll listener triggers loadMore early.
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: OutlinedButton(
          onPressed: _loadMore,
          child: Text(l10n.get('loadMore')),
        ),
      ),
    );
  }
}
