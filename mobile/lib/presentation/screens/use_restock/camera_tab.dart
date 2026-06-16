import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:mobile/data/models/product.dart';
import 'package:mobile/domain/providers/core_providers.dart';

import '../../../l10n/app_localizations.dart';

class CameraTab extends ConsumerStatefulWidget {
  final bool isRestockMode;
  final Function(Product) onProductFound;
  final Function(String) onUnknownBarcode;

  const CameraTab({
    super.key,
    required this.isRestockMode,
    required this.onProductFound,
    required this.onUnknownBarcode,
  });

  @override
  ConsumerState<CameraTab> createState() => _CameraTabState();
}

class _CameraTabState extends ConsumerState<CameraTab>
    with WidgetsBindingObserver {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  bool _isProcessing = false;
  bool _torchOn = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;
    final barcode = capture.barcodes.first.rawValue;
    if (barcode == null) return;

    setState(() => _isProcessing = true);
    await _controller.stop();
    HapticFeedback.mediumImpact();

    try {
      final product = await ref
          .read(productRepositoryProvider)
          .getProductByBarcode(barcode);

      if (mounted) {
        if (product != null) {
          HapticFeedback.heavyImpact();
          widget.onProductFound(product);
        } else {
          widget.onUnknownBarcode(barcode);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _toggleTorch() async {
    await _controller.toggleTorch();
    setState(() => _torchOn = !_torchOn);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        MobileScanner(controller: _controller, onDetect: _onDetect),
        Center(
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              border: Border.all(
                color: widget.isRestockMode ? Colors.green : Colors.orange,
                width: 3,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        if (_isProcessing) const Center(child: CircularProgressIndicator()),
        Positioned(
          top: 16,
          right: 16,
          child: Material(
            color: Colors.black54,
            shape: const CircleBorder(),
            child: IconButton(
              icon: Icon(
                _torchOn ? Icons.flash_on : Icons.flash_off,
                color: Colors.white,
              ),
              tooltip: AppLocalizations.of(context).get('torch'),
              onPressed: _toggleTorch,
            ),
          ),
        ),
        Positioned(
          bottom: 32,
          left: 0,
          right: 0,
          child: Center(
            child: ElevatedButton.icon(
              onPressed: () {
                setState(() => _isProcessing = false);
                _controller.start();
              },
              icon: const Icon(Icons.refresh),
              label: Text(AppLocalizations.of(context).get('scan')),
            ),
          ),
        ),
      ],
    );
  }
}
