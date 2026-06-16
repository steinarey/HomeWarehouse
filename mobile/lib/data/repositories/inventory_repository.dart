import 'package:mobile/data/api/api_client.dart';
import 'package:mobile/data/models/dashboard_summary.dart';
import 'package:mobile/data/models/inventory_action.dart';
import 'package:mobile/data/models/low_stock_item.dart';

class InventoryRepository {
  final ApiClient _apiClient;

  InventoryRepository(this._apiClient);

  Future<DashboardSummary> getDashboard() => _apiClient.getDashboard();

  Future<List<LowStockItem>> getLowStock() => _apiClient.getLowStock();

  Future<InventoryAction> restock({
    required int productId,
    required int quantityPackages,
    int? locationId,
    DateTime? expiryDate,
    String source = 'manual',
  }) {
    return _apiClient.restock(
      productId: productId,
      quantityPackages: quantityPackages,
      locationId: locationId,
      expiryDate: expiryDate,
      source: source,
    );
  }

  Future<InventoryAction> consume({
    required int productId,
    required int quantityUnits,
    String source = 'manual',
  }) {
    return _apiClient.consume(
      productId: productId,
      quantityUnits: quantityUnits,
      source: source,
    );
  }

  Future<InventoryAction> adjust({
    required int productId,
    required int newTotalQuantity,
    String reason = 'manual_correction',
  }) {
    return _apiClient.adjust(
      productId: productId,
      newTotalQuantity: newTotalQuantity,
      reason: reason,
    );
  }

  Future<InventoryAction> undoAction(int actionId) {
    return _apiClient.undoAction(actionId);
  }

  Future<List<InventoryAction>> getActions({int skip = 0, int limit = 50}) {
    return _apiClient.getActions(skip: skip, limit: limit);
  }
}
