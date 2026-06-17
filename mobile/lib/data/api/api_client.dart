import 'package:dio/dio.dart';
import 'package:mobile/data/models/user.dart';
import 'package:mobile/data/models/category.dart';
import 'package:mobile/data/models/location.dart';
import 'package:mobile/data/models/product.dart';
import 'package:mobile/data/models/inventory_action.dart';
import 'package:mobile/data/models/dashboard_summary.dart';
import 'package:mobile/data/models/low_stock_item.dart';
import 'package:mobile/data/models/connector.dart';
import 'package:mobile/data/models/pending_restock.dart';
import 'package:mobile/data/models/location_contents.dart';

class ApiClient {
  final Dio _dio;

  ApiClient(this._dio);

  Future<List<User>> getUsers() async {
    final response = await _dio.get('/users/');
    return (response.data as List).map((e) => User.fromJson(e)).toList();
  }

  Future<User> createUser(Map<String, dynamic> userData) async {
    final response = await _dio.post('/users/', data: userData);
    return User.fromJson(response.data);
  }

  Future<DashboardSummary> getDashboard() async {
    final response = await _dio.get('/inventory/dashboard');
    return DashboardSummary.fromJson(response.data);
  }

  Future<List<LowStockItem>> getLowStock() async {
    final response = await _dio.get('/inventory/low-stock');
    return (response.data as List)
        .map((e) => LowStockItem.fromJson(e))
        .toList();
  }

  Future<List<Category>> getCategories({bool includeStock = false}) async {
    final response = await _dio.get(
      '/categories/',
      queryParameters: {'include_stock': includeStock},
    );
    return (response.data as List).map((e) => Category.fromJson(e)).toList();
  }

  Future<List<Product>> getProducts({String? query, int? categoryId}) async {
    final response = await _dio.get(
      '/products/',
      queryParameters: {
        if (query != null) 'q': query,
        if (categoryId != null) 'category_id': categoryId,
      },
    );
    return (response.data as List).map((e) => Product.fromJson(e)).toList();
  }

  Future<Product> updateProduct(
    int productId,
    Map<String, dynamic> data,
  ) async {
    final response = await _dio.patch('/products/$productId', data: data);
    return Product.fromJson(response.data);
  }

  Future<void> deleteProduct(int productId) async {
    await _dio.delete('/products/$productId');
  }

  Future<Product?> getProductByBarcode(String barcode) async {
    final response = await _dio.post(
      '/products/by-barcode',
      data: {'barcode': barcode},
    );
    if (response.data['exists'] == false) {
      return null;
    }
    return Product.fromJson(response.data);
  }

  Future<Product> createProduct(Map<String, dynamic> productData) async {
    final response = await _dio.post('/products/', data: productData);
    return Product.fromJson(response.data);
  }

  Future<InventoryAction> restock({
    required int productId,
    required int quantityPackages,
    int? locationId,
    DateTime? expiryDate,
    String source = 'manual',
  }) async {
    final response = await _dio.post(
      '/inventory/restock',
      data: {
        'product_id': productId,
        'quantity_packages': quantityPackages,
        if (locationId != null) 'location_id': locationId,
        if (expiryDate != null)
          'expiry_date':
              '${expiryDate.year.toString().padLeft(4, '0')}-${expiryDate.month.toString().padLeft(2, '0')}-${expiryDate.day.toString().padLeft(2, '0')}',
        'source': source,
      },
    );
    return InventoryAction.fromJson(response.data);
  }

  Future<InventoryAction> adjust({
    required int productId,
    required int newTotalQuantity,
    String reason = 'manual_correction',
  }) async {
    final response = await _dio.post(
      '/inventory/adjust',
      data: {
        'product_id': productId,
        'new_total_quantity': newTotalQuantity,
        'reason': reason,
      },
    );
    return InventoryAction.fromJson(response.data);
  }

  Future<List<Map<String, dynamic>>> getProductStockBatches(
    int productId,
  ) async {
    final response = await _dio.get('/products/$productId/stock-batches');
    return List<Map<String, dynamic>>.from(response.data);
  }

  Future<InventoryAction> consume({
    required int productId,
    required int quantityUnits,
    String source = 'manual',
  }) async {
    final response = await _dio.post(
      '/inventory/consume',
      data: {
        'product_id': productId,
        'quantity_units': quantityUnits,
        'source': source,
      },
    );
    return InventoryAction.fromJson(response.data);
  }

  Future<InventoryAction> undoAction(int actionId) async {
    final response = await _dio.post('/inventory/undo/$actionId');
    return InventoryAction.fromJson(response.data);
  }

  Future<User> getCurrentUser() async {
    final response = await _dio.get('/users/me');
    return User.fromJson(response.data);
  }

  Future<List<Location>> getLocations() async {
    final response = await _dio.get('/locations/');
    return (response.data as List).map((e) => Location.fromJson(e)).toList();
  }

  Future<Location> createLocation(Map<String, dynamic> data) async {
    final response = await _dio.post('/locations/', data: data);
    return Location.fromJson(response.data);
  }

  Future<Location> updateLocation(
    int locationId,
    Map<String, dynamic> data,
  ) async {
    final response = await _dio.patch('/locations/$locationId', data: data);
    return Location.fromJson(response.data);
  }

  Future<void> deleteLocation(int locationId) async {
    await _dio.delete('/locations/$locationId');
  }

  Future<LocationContents> getLocationContents(int locationId) async {
    final response = await _dio.get('/locations/$locationId/contents');
    return LocationContents.fromJson(response.data);
  }

  Future<List<InventoryAction>> getActions({
    int skip = 0,
    int limit = 50,
  }) async {
    final response = await _dio.get(
      '/inventory/actions',
      queryParameters: {'skip': skip, 'limit': limit},
    );
    return (response.data as List)
        .map((e) => InventoryAction.fromJson(e))
        .toList();
  }

  Future<Category> createCategory(Map<String, dynamic> data) async {
    final response = await _dio.post('/categories/', data: data);
    return Category.fromJson(response.data);
  }

  Future<Category> updateCategory(
    int categoryId,
    Map<String, dynamic> data,
  ) async {
    final response = await _dio.patch('/categories/$categoryId', data: data);
    return Category.fromJson(response.data);
  }

  Future<InventoryAction> adjustCategoryStock({
    required int categoryId,
    required int newTotalQuantity,
    String reason = 'manual_correction',
  }) async {
    final response = await _dio.post(
      '/categories/$categoryId/adjust',
      data: {
        'new_total_quantity': newTotalQuantity,
        'reason': reason,
      },
    );
    return InventoryAction.fromJson(response.data);
  }

  Future<void> deleteCategory(int categoryId) async {
    await _dio.delete('/categories/$categoryId');
  }

  Future<List<Map<String, dynamic>>> getMembers() async {
    final response = await _dio.get('/users/members/list');
    return List<Map<String, dynamic>>.from(response.data);
  }

  Future<Map<String, dynamic>> createInvite(String role) async {
    final response = await _dio.post('/invites/', data: {'role': role});
    return response.data;
  }

  Future<void> removeMember(int userId) async {
    await _dio.delete('/users/members/$userId');
  }

  Future<List<Connector>> getConnectors() async {
    final response = await _dio.get('/connectors/');
    return (response.data as List)
        .map((e) => Connector.fromJson(e))
        .toList();
  }

  Future<Connector?> getMicrosoftConnector() async {
    final response = await _dio.get('/connectors/microsoft-todo');
    if (response.data == null) return null;
    return Connector.fromJson(response.data);
  }

  Future<MicrosoftAuthUrl> getMicrosoftAuthUrl() async {
    final response = await _dio.get('/connectors/microsoft-todo/auth-url');
    return MicrosoftAuthUrl.fromJson(response.data);
  }

  Future<List<MicrosoftList>> getMicrosoftLists() async {
    final response = await _dio.get('/connectors/microsoft-todo/lists');
    return (response.data['lists'] as List)
        .map((e) => MicrosoftList.fromJson(e))
        .toList();
  }

  Future<Connector> updateMicrosoftConnector({
    required String listId,
    String? listName,
  }) async {
    final response = await _dio.patch(
      '/connectors/microsoft-todo',
      data: {
        'list_id': listId,
        if (listName != null) 'list_name': listName,
      },
    );
    return Connector.fromJson(response.data);
  }

  Future<void> disconnectMicrosoftConnector() async {
    await _dio.delete('/connectors/microsoft-todo');
  }

  Future<Map<String, dynamic>> syncMicrosoftNow() async {
    final response = await _dio.post('/connectors/microsoft-todo/sync-now');
    return Map<String, dynamic>.from(response.data);
  }

  Future<List<PendingRestock>> getPendingRestocks() async {
    final response = await _dio.get('/pending-restock/');
    return (response.data as List)
        .map((e) => PendingRestock.fromJson(e))
        .toList();
  }

  Future<PendingRestock> dismissPendingRestock(int id) async {
    final response = await _dio.post('/pending-restock/$id/dismiss');
    return PendingRestock.fromJson(response.data);
  }
}
