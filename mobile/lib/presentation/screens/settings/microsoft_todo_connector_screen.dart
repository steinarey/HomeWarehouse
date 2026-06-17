import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile/data/models/connector.dart';
import 'package:mobile/domain/providers/connector_provider.dart';
import 'package:mobile/domain/providers/core_providers.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

class MicrosoftTodoConnectorScreen extends ConsumerStatefulWidget {
  const MicrosoftTodoConnectorScreen({super.key});

  @override
  ConsumerState<MicrosoftTodoConnectorScreen> createState() =>
      _MicrosoftTodoConnectorScreenState();
}

class _MicrosoftTodoConnectorScreenState
    extends ConsumerState<MicrosoftTodoConnectorScreen>
    with WidgetsBindingObserver {
  bool _connecting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // When the user returns from the system browser after the OAuth dance,
    // re-fetch the connector status so the UI reflects the newly stored tokens.
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(microsoftConnectorProvider);
    }
  }

  Future<void> _connect() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _connecting = true);
    try {
      final urlPayload = await ref
          .read(connectorRepositoryProvider)
          .getMicrosoftAuthUrl();
      final uri = Uri.parse(urlPayload.authUrl);
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.get('failedToOpenBrowser'))),
        );
      }
    } on DioException catch (e) {
      if (!mounted) return;
      final detail = e.response?.statusCode == 503
          ? l10n.get('connectorNotConfiguredServer')
          : (e.response?.data?.toString() ?? e.message ?? 'Error');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(detail)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _connecting = false);
    }
  }

  Future<void> _disconnect() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.get('disconnect')),
        content: Text(l10n.get('confirmDelete')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.get('cancel')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              l10n.get('disconnect'),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref
          .read(connectorRepositoryProvider)
          .disconnectMicrosoftConnector();
      if (!mounted) return;
      ref.invalidate(microsoftConnectorProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.get('microsoftDisconnected'))),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _pickList() async {
    final l10n = AppLocalizations.of(context);
    final lists = await showDialog<MicrosoftList>(
      context: context,
      builder: (context) => _ListPickerDialog(),
    );
    if (lists == null) return;
    try {
      await ref
          .read(connectorRepositoryProvider)
          .updateMicrosoftConnector(
            listId: lists.id,
            listName: lists.displayName,
          );
      if (!mounted) return;
      ref.invalidate(microsoftConnectorProvider);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.get('listUpdated'))));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final connectorAsync = ref.watch(microsoftConnectorProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.get('microsoftTodo'))),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(microsoftConnectorProvider.future),
        child: connectorAsync.when(
          data: (connector) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: _bodyForConnector(connector, l10n),
          ),
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

  List<Widget> _bodyForConnector(Connector? connector, AppLocalizations l10n) {
    final isConnected = connector != null && connector.status == 'connected';
    final isError = connector != null && connector.status == 'error';

    final children = <Widget>[
      Text(
        l10n.get('microsoftTodoDescription'),
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      const SizedBox(height: 24),
      _statusTile(connector, l10n),
      const SizedBox(height: 16),
    ];

    if (!isConnected) {
      children.add(
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _connecting ? null : _connect,
            icon: const Icon(Icons.login),
            label: Text(
              _connecting
                  ? l10n.get('connectingMessage')
                  : l10n.get('connectMicrosoftAccount'),
            ),
          ),
        ),
      );
      if (isError && connector.lastError != null) {
        children.add(const SizedBox(height: 12));
        children.add(
          Text(
            connector.lastError!,
            style: TextStyle(color: Colors.red.shade700),
          ),
        );
      }
      return children;
    }

    children.add(
      ListTile(
        leading: const Icon(Icons.list_alt),
        title: Text(
          connector.selectedListName ?? l10n.get('noListSelected'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(l10n.get('selectList')),
        trailing: TextButton(
          onPressed: _pickList,
          child: Text(
            connector.selectedListId == null
                ? l10n.get('selectList')
                : l10n.get('changeList'),
          ),
        ),
      ),
    );
    children.add(const Divider(height: 32));
    children.add(
      _kv(l10n.get('lastSynced'), _formatDate(connector.lastSyncedAt, l10n)),
    );
    children.add(const SizedBox(height: 24));
    children.add(
      SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: _disconnect,
          icon: const Icon(Icons.logout, color: Colors.red),
          label: Text(
            l10n.get('disconnect'),
            style: const TextStyle(color: Colors.red),
          ),
        ),
      ),
    );

    return children;
  }

  Widget _statusTile(Connector? connector, AppLocalizations l10n) {
    Color color = Colors.grey.shade200;
    Color fg = Colors.grey.shade900;
    String text = l10n.get('notConnected');
    IconData icon = Icons.link_off;

    if (connector?.status == 'connected') {
      color = Colors.green.shade100;
      fg = Colors.green.shade900;
      text = l10n.get('connected');
      icon = Icons.link;
      if (connector?.msUserEmail != null) {
        text = '$text · ${connector!.msUserEmail}';
      }
    } else if (connector?.status == 'error') {
      color = Colors.red.shade100;
      fg = Colors.red.shade900;
      text = l10n.get('connectionError');
      icon = Icons.error_outline;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: fg),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: fg, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text('$k: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(v)),
        ],
      ),
    );
  }

  String _formatDate(DateTime? d, AppLocalizations l10n) {
    if (d == null) return l10n.get('never');
    return DateFormat.yMd().add_jm().format(d.toLocal());
  }
}

class _ListPickerDialog extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final listsAsync = ref.watch(microsoftListsProvider);

    return AlertDialog(
      title: Text(l10n.get('selectList')),
      content: SizedBox(
        width: 400,
        child: listsAsync.when(
          data: (lists) => ListView.separated(
            shrinkWrap: true,
            itemCount: lists.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final l = lists[i];
              return ListTile(
                title: Text(l.displayName),
                subtitle: l.wellKnownListName != null
                    ? Text(l.wellKnownListName!)
                    : null,
                onTap: () => Navigator.pop(context, l),
              );
            },
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('Error: $e'),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.get('cancel')),
        ),
      ],
    );
  }
}
