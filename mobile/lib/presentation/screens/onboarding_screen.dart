import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/config/app_constants.dart';
import 'package:mobile/domain/providers/core_providers.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _urlController = TextEditingController(
    text: AppConstants.defaultBaseUrl,
  );

  @override
  void initState() {
    super.initState();
    _loadSavedUrl();
  }

  Future<void> _loadSavedUrl() async {
    final prefs = ref.read(sharedPreferencesProvider);
    var savedUrl = prefs.getString('base_url');
    if (savedUrl != null) {
      if (savedUrl.contains('0.0.0.0')) {
        savedUrl = savedUrl.replaceAll('0.0.0.0', '10.0.2.2');
      }
      _urlController.text = savedUrl;
    }
  }

  Future<void> _saveAndContinue() async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString('base_url', _urlController.text);
    ref.invalidate(dioProvider);
    ref.invalidate(apiClientProvider);
    ref.invalidate(userRepositoryProvider);
    if (mounted) {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
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
            const Text(
              'Point this app at your Home Warehouse backend, then sign in.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'Backend URL',
                border: OutlineInputBorder(),
                hintText: 'http://10.0.2.2:8000',
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _saveAndContinue,
              child: const Text('Continue'),
            ),
          ],
        ),
      ),
    );
  }
}
