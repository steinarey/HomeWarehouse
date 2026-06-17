import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/domain/providers/user_provider.dart';
import 'package:mobile/l10n/app_localizations.dart';

class ConnectorsScreen extends ConsumerWidget {
  const ConnectorsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final currentUserAsync = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.get('connectors'))),
      body: currentUserAsync.when(
        data: (user) {
          if (user.role != 'admin') {
            return Center(child: Text(l10n.get('adminOnly')));
          }
          return ListView(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  l10n.get('connectorsSubtitle'),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              ListTile(
                leading: const Icon(Icons.checklist),
                title: Text(l10n.get('microsoftTodo')),
                subtitle: Text(l10n.get('microsoftTodoDescription')),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/settings/connectors/microsoft-todo'),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
