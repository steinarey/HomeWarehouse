import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/config/app_constants.dart';
// import 'package:mobile/data/models/user.dart';
import 'package:mobile/domain/providers/core_providers.dart';
import 'package:mobile/domain/providers/user_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _urlController = TextEditingController(
    text: AppConstants.defaultBaseUrl,
  );
  bool _isUrlSaved = false;

  @override
  void initState() {
    super.initState();
    _loadSavedUrl();
  }

  Future<void> _loadSavedUrl() async {
    final prefs = ref.read(sharedPreferencesProvider);
    var savedUrl = prefs.getString('base_url');
    if (savedUrl != null) {
      // Auto-correct 0.0.0.0 to 10.0.2.2 for Android emulator
      if (savedUrl.contains('0.0.0.0')) {
        savedUrl = savedUrl.replaceAll('0.0.0.0', '10.0.2.2');
      }
      _urlController.text = savedUrl!;
      setState(() {
        _isUrlSaved = true;
      });
    }
  }

  Future<void> _saveUrl() async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString('base_url', _urlController.text);
    // Invalidate dio to pick up new URL
    ref.invalidate(dioProvider);
    ref.invalidate(apiClientProvider);
    ref.invalidate(userRepositoryProvider);
    setState(() {
      _isUrlSaved = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(usersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Welcome')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Setup Home Warehouse',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'Backend URL',
                border: OutlineInputBorder(),
                hintText: 'http://10.0.2.2:8000',
              ),
              onChanged: (_) => setState(() => _isUrlSaved = false),
            ),
            const SizedBox(height: 8),
            ElevatedButton(onPressed: _saveUrl, child: const Text('Connect')),
            const SizedBox(height: 32),
            if (_isUrlSaved) ...[
              const Text(
                'Select Active User',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: usersAsync.when(
                  data: (users) => ListView.builder(
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final user = users[index];
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(child: Text(user.name[0])),
                          title: Text(user.name),
                          subtitle: Text(user.role),
                          onTap: () async {
                            await ref
                                .read(activeUserProvider.notifier)
                                .setUser(user);
                            if (mounted) {
                              context.go('/');
                            }
                          },
                        ),
                      );
                    },
                  ),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Error: $err',
                          style: const TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () => ref.refresh(usersProvider),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
