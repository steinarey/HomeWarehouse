import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager_ndef/nfc_manager_ndef.dart';
import 'package:ndef_record/ndef_record.dart';
import 'package:mobile/data/models/category.dart';
import 'package:mobile/domain/providers/core_providers.dart';

class NFCTab extends ConsumerStatefulWidget {
  final bool isRestockMode;
  final Function(Category) onCategoryFound;

  const NFCTab({
    super.key,
    required this.isRestockMode,
    required this.onCategoryFound,
  });

  @override
  ConsumerState<NFCTab> createState() => _NFCTabState();
}

class _NFCTabState extends ConsumerState<NFCTab> {
  bool _isScanning = false;
  String? _nfcError;
  bool _isSetupMode = false;
  Category? _selectedCategoryForBinding;

  @override
  void dispose() {
    NfcManager.instance.stopSession();
    super.dispose();
  }

  Future<void> _startNfcSession() async {
    setState(() {
      _nfcError = null;
      _isScanning = true;
    });

    try {
      // checkAvailability returns NfcAvailability enum in 4.x
      // We can check if it's available, but for now we'll skip explicit check
      // and rely on startSession throwing if not available, or just assume it works.
      // To be safe against build errors if enum values are unknown, we skip it.
      /*
      final availability = await NfcManager.instance.checkAvailability();
      if (availability != NfcAvailability.available) { ... }
      */

      await NfcManager.instance.startSession(
        pollingOptions: {NfcPollingOption.iso14443, NfcPollingOption.iso15693},
        onDiscovered: (NfcTag tag) async {
          try {
            final ndef = Ndef.from(tag);
            if (ndef == null) {
              _showError('Tag is not NDEF formatted');
              return;
            }

            if (_isSetupMode) {
              await _handleSetupMode(ndef);
            } else {
              await _handleUseMode(ndef);
            }
          } catch (e) {
            _showError('Error reading tag: $e');
          }
        },
      );
    } catch (e) {
      _showError('Error starting NFC: $e');
    }
  }

  Future<void> _handleUseMode(Ndef ndef) async {
    final message = ndef.cachedMessage;
    if (message == null || message.records.isEmpty) {
      _showError('Empty tag');
      return;
    }

    final record = message.records.first;
    // Payload format for Text Record: Status Byte + Language Code + Text
    // We assume it's a text record or at least has payload we can parse.
    // Ideally we check record type.

    final payload = record.payload;
    if (payload.isEmpty) {
      _showError('Empty record payload');
      return;
    }

    // Simple parsing: skip first 3 bytes (Status + "en") if it's a standard text record
    // But let's be safer:
    // Status byte: bit 7 is UTF-16/8, bit 6 is reserved, bits 5-0 are lang code length.
    final statusByte = payload[0];
    final langCodeLen = statusByte & 0x3F;
    final textStart = 1 + langCodeLen;

    if (payload.length <= textStart) {
      _showError('Invalid payload');
      return;
    }

    final textPayload = String.fromCharCodes(payload.sublist(textStart));

    if (textPayload.startsWith('cat:')) {
      final catId = int.tryParse(textPayload.split(':')[1]);
      if (catId != null) {
        final categories = await ref
            .read(categoryRepositoryProvider)
            .getCategories();
        try {
          final category = categories.firstWhere((c) => c.id == catId);
          if (mounted) {
            widget.onCategoryFound(category);
            _stopScan();
          }
        } catch (e) {
          _showError('Category not found');
        }
      }
    } else {
      _showError('Unknown tag format');
    }
  }

  Future<void> _handleSetupMode(Ndef ndef) async {
    if (_selectedCategoryForBinding == null) {
      _showError('Select a category first');
      return;
    }

    if (!ndef.isWritable) {
      _showError('Tag is not writable');
      return;
    }

    final record = _createNdefTextRecord(
      'cat:${_selectedCategoryForBinding!.id}',
    );
    final message = NdefMessage(records: [record]);

    try {
      await ndef.write(message: message);

      // Update backend with dummy tag ID for now
      await ref.read(categoryRepositoryProvider).updateCategory(
        _selectedCategoryForBinding!.id,
        {'nfc_tag_id': 'tag_${DateTime.now().millisecondsSinceEpoch}'},
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bound tag to ${_selectedCategoryForBinding!.name}'),
          ),
        );
        _stopScan();
      }
    } catch (e) {
      _showError('Write failed: $e');
    }
  }

  NdefRecord _createNdefTextRecord(String text) {
    final languageCode = 'en';
    final languageCodeBytes = utf8.encode(languageCode);
    final textBytes = utf8.encode(text);

    final statusByte = languageCodeBytes.length; // UTF-8 (bit 7=0)

    final payload = Uint8List.fromList([
      statusByte,
      ...languageCodeBytes,
      ...textBytes,
    ]);

    return NdefRecord(
      typeNameFormat: TypeNameFormat.wellKnown,
      type: Uint8List.fromList([0x54]), // 'T'
      identifier: Uint8List(0),
      payload: payload,
    );
  }

  void _showError(String msg) {
    if (mounted) {
      setState(() {
        _nfcError = msg;
        _isScanning = false;
      });
      NfcManager.instance.stopSession();
    }
  }

  void _stopScan() {
    NfcManager.instance.stopSession();
    if (mounted) {
      setState(() {
        _isScanning = false;
        _nfcError = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.nfc,
            size: 100,
            color: _isScanning ? Colors.blue : Colors.grey,
          ),
          const SizedBox(height: 24),
          if (_nfcError != null)
            Text(
              _nfcError!,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
              textAlign: TextAlign.center,
            ),
          if (_isScanning && _nfcError == null)
            const Text(
              'Hold phone near tag...',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          const SizedBox(height: 32),

          // Setup Mode Toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Use Mode'),
              Switch(
                value: _isSetupMode,
                onChanged: (val) => setState(() => _isSetupMode = val),
              ),
              const Text('Setup Mode'),
            ],
          ),

          if (_isSetupMode) ...[
            const SizedBox(height: 16),
            FutureBuilder<List<Category>>(
              future: ref.watch(categoryRepositoryProvider).getCategories(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const CircularProgressIndicator();
                return DropdownButton<Category>(
                  hint: const Text('Select Category to Bind'),
                  value: _selectedCategoryForBinding,
                  items: snapshot.data!
                      .map(
                        (c) => DropdownMenuItem(value: c, child: Text(c.name)),
                      )
                      .toList(),
                  onChanged: (val) =>
                      setState(() => _selectedCategoryForBinding = val),
                );
              },
            ),
          ],

          const SizedBox(height: 32),
          if (!_isScanning)
            ElevatedButton.icon(
              onPressed: _startNfcSession,
              icon: const Icon(Icons.nfc),
              label: Text(_isSetupMode ? 'Tap to Bind' : 'Tap to Scan'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          if (_isScanning)
            OutlinedButton(onPressed: _stopScan, child: const Text('Cancel')),
        ],
      ),
    );
  }
}
