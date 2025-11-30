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
    required int userId,
    String source = 'manual',
  }) {
    return _apiClient.restock(
      productId: productId,
      quantityPackages: quantityPackages,
      userId: userId,
      source: source,
    );
  }

  Future<InventoryAction> consume({
    required int productId,
    required int quantityUnits,
    required int userId,
    String source = 'manual',
  }) {
    return _apiClient.consume(
      productId: productId,
      quantityUnits: quantityUnits,
      userId: userId,
      source: source,
    );
  }

  Future<InventoryAction> undoAction(int actionId, int userId) {
    return _apiClient.undoAction(actionId, userId);
  }

  Future<List<InventoryAction>> getActions({int skip = 0, int limit = 50}) {
    return _apiClient.getActions(skip: skip, limit: limit);
  }
}
