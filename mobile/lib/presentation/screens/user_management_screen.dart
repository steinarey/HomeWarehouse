import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/domain/providers/member_provider.dart';
import 'package:mobile/domain/providers/core_providers.dart';
import 'package:flutter/services.dart';
import 'package:mobile/l10n/app_localizations.dart';

class UserManagementScreen extends ConsumerWidget {
  const UserManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(membersProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).get('userManagement')),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () => _showInviteDialog(context, ref),
          ),
        ],
      ),
      body: membersAsync.when(
        data: (members) {
          return ListView.builder(
            itemCount: members.length,
            itemBuilder: (context, index) {
              final member = members[index];
              return ListTile(
                leading: CircleAvatar(
                  child: Text(member['name'][0].toUpperCase()),
                ),
                title: Text(member['name']),
                subtitle: Text(
                  '${AppLocalizations.of(context).get('role')}: ${member['role']}',
                ),
                trailing:
                    member['role'] !=
                        'admin' // Simple check, ideally check current user permissions too
                    ? IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _confirmRemove(context, ref, member),
                      )
                    : null,
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }

  void _showInviteDialog(BuildContext context, WidgetRef ref) {
    String selectedRole = 'user';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(AppLocalizations.of(context).get('inviteUser')),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(AppLocalizations.of(context).get('generateInviteCode')),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context).get('role'),
                    border: const OutlineInputBorder(),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: 'admin',
                      child: Text(AppLocalizations.of(context).get('admin')),
                    ),
                    DropdownMenuItem(
                      value: 'user',
                      child: Text(AppLocalizations.of(context).get('user')),
                    ),
                    DropdownMenuItem(
                      value: 'viewer',
                      child: Text(AppLocalizations.of(context).get('viewer')),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => selectedRole = value);
                    }
                  },
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      final api = ref.read(apiClientProvider);
                      final response = await api.createInvite(selectedRole);
                      final code = response['code'];

                      if (context.mounted) {
                        Navigator.pop(context);
                        _showCodeDialog(context, code);
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '${AppLocalizations.of(context).get('errorGeneratingInvite')}: $e',
                            ),
                          ),
                        );
                      }
                    }
                  },
                  child: Text(AppLocalizations.of(context).get('generateCode')),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showCodeDialog(BuildContext context, String code) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).get('inviteCode')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SelectableText(
              code,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(AppLocalizations.of(context).get('shareCodeMessage')),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: code));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      AppLocalizations.of(context).get('codeCopied'),
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.copy),
              label: Text(AppLocalizations.of(context).get('copyCode')),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context).get('close')),
          ),
        ],
      ),
    );
  }

  void _confirmRemove(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> member,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).get('removeUser')),
        content: Text(AppLocalizations.of(context).get('confirmRemoveUser')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context).get('cancel')),
          ),
          TextButton(
            onPressed: () async {
              try {
                final api = ref.read(apiClientProvider);
                await api.removeMember(member['id']);
                ref.invalidate(membersProvider);
                if (context.mounted) {
                  Navigator.pop(context);
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${AppLocalizations.of(context).get('errorRemovingUser')}: $e',
                      ),
                    ),
                  );
                }
              }
            },
            child: Text(
              AppLocalizations.of(context).get('remove'),
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
