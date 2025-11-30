import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:mobile/data/models/product.dart';
import 'package:mobile/domain/providers/core_providers.dart';

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
    // Pause camera while processing
    await _controller.stop();

    try {
      final product = await ref
          .read(productRepositoryProvider)
          .getProductByBarcode(barcode);

      if (mounted) {
        if (product != null) {
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
        // Resume camera if needed (usually handled by parent after action)
      }
    }
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
              label: const Text('Scan'),
            ),
          ),
        ),
      ],
    );
  }
}
