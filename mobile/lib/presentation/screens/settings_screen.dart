import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/config/app_constants.dart';
import 'package:mobile/domain/providers/core_providers.dart';
import 'package:mobile/domain/providers/user_provider.dart';
import 'package:mobile/domain/providers/auth_provider.dart';
import 'package:mobile/domain/providers/theme_provider.dart';
import 'package:mobile/domain/providers/locale_provider.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/presentation/screens/user_management_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _urlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUrl();
  }

  void _loadUrl() {
    final prefs = ref.read(sharedPreferencesProvider);
    _urlController.text =
        prefs.getString('base_url') ?? AppConstants.defaultBaseUrl;
  }

  Future<void> _saveUrl() async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString('base_url', _urlController.text);
    ref.invalidate(dioProvider);
    ref.invalidate(apiClientProvider);
    ref.invalidate(userRepositoryProvider);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).get('backendUrlSaved')),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeUserAsync = ref.watch(activeUserProvider);
    final usersAsync = ref.watch(usersProvider);

    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context).get('settings'))),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Text(
            AppLocalizations.of(context).get('connection'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _urlController,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context).get('backendUrl'),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _saveUrl,
            child: Text(AppLocalizations.of(context).get('saveUrl')),
          ),
          const Divider(height: 32),
          Text(
            AppLocalizations.of(context).get('activeUser'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          activeUserAsync.when(
            data: (activeUser) => usersAsync.when(
              data: (users) => DropdownButtonFormField<int>(
                initialValue: activeUser?.id,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context).get('currentUser'),
                  border: const OutlineInputBorder(),
                ),
                items: users
                    .map(
                      (u) => DropdownMenuItem(value: u.id, child: Text(u.name)),
                    )
                    .toList(),
                onChanged: (val) async {
                  if (val != null) {
                    final user = users.firstWhere((u) => u.id == val);
                    await ref.read(activeUserProvider.notifier).setUser(user);
                  }
                },
              ),
              loading: () => const CircularProgressIndicator(),
              error: (e, s) => Text('Error loading users: $e'),
            ),
            loading: () => const CircularProgressIndicator(),
            error: (e, s) => Text('Error: $e'),
          ),
          const Divider(height: 32),
          Text(
            AppLocalizations.of(context).get('settings'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ListTile(
            title: Text(AppLocalizations.of(context).get('darkMode')),
            trailing: DropdownButton<ThemeMode>(
              value: ref.watch(themeProvider),
              onChanged: (ThemeMode? newValue) {
                if (newValue != null) {
                  ref.read(themeProvider.notifier).setTheme(newValue);
                }
              },
              items: [
                DropdownMenuItem(
                  value: ThemeMode.system,
                  child: Text(AppLocalizations.of(context).get('system')),
                ),
                DropdownMenuItem(
                  value: ThemeMode.light,
                  child: Text(AppLocalizations.of(context).get('light')),
                ),
                DropdownMenuItem(
                  value: ThemeMode.dark,
                  child: Text(AppLocalizations.of(context).get('dark')),
                ),
              ],
            ),
          ),
          ListTile(
            title: Text(AppLocalizations.of(context).get('language')),
            trailing: DropdownButton<Locale>(
              value: ref.watch(localeProvider),
              onChanged: (Locale? newValue) {
                if (newValue != null) {
                  ref.read(localeProvider.notifier).setLocale(newValue);
                }
              },
              items: [
                DropdownMenuItem(
                  value: const Locale('en'),
                  child: Text(AppLocalizations.of(context).get('english')),
                ),
                DropdownMenuItem(
                  value: const Locale('is'),
                  child: Text(AppLocalizations.of(context).get('icelandic')),
                ),
              ],
            ),
          ),
          const Divider(height: 32),

          Text(
            AppLocalizations.of(context).get('userManagement'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.group),
            title: Text(AppLocalizations.of(context).get('manageUsers')),
            subtitle: Text(
              AppLocalizations.of(context).get('inviteUsersAndRoles'),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const UserManagementScreen(),
                ),
              );
            },
          ),
          const Divider(height: 32),
          Text(
            AppLocalizations.of(context).get('appInfo'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ListTile(
            title: Text(AppLocalizations.of(context).get('version')),
            subtitle: const Text('1.0.0'),
          ),
          const Divider(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                await ref.read(authProvider.notifier).logout();
                // Router will redirect to login automatically
              },
              icon: const Icon(Icons.logout),
              label: Text(AppLocalizations.of(context).get('logout')),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
