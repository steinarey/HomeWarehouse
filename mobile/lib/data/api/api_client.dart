import 'package:dio/dio.dart';
import 'package:mobile/data/models/user.dart';
import 'package:mobile/data/models/category.dart';
import 'package:mobile/data/models/product.dart';
import 'package:mobile/data/models/inventory_action.dart';
import 'package:mobile/data/models/dashboard_summary.dart';
import 'package:mobile/data/models/low_stock_item.dart';

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

  Future<List<Product>> getProducts({String? query}) async {
    final response = await _dio.get(
      '/products/',
      queryParameters: {if (query != null) 'q': query},
    );
    return (response.data as List).map((e) => Product.fromJson(e)).toList();
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
    required int userId,
    String source = 'manual',
  }) async {
    final response = await _dio.post(
      '/inventory/restock',
      data: {
        'product_id': productId,
        'quantity_packages': quantityPackages,
        'user_id': userId,
        'source': source,
      },
    );
    return InventoryAction.fromJson(response.data);
  }

  Future<InventoryAction> consume({
    required int productId,
    required int quantityUnits,
    required int userId,
    String source = 'manual',
  }) async {
    final response = await _dio.post(
      '/inventory/consume',
      data: {
        'product_id': productId,
        'quantity_units': quantityUnits,
        'user_id': userId,
        'source': source,
      },
    );
    return InventoryAction.fromJson(response.data);
  }

  Future<InventoryAction> undoAction(int actionId, int userId) async {
    final response = await _dio.post(
      '/inventory/undo/$actionId',
      queryParameters: {'user_id': userId},
    );
    return InventoryAction.fromJson(response.data);
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

  Future<void> deleteCategory(int categoryId) async {
    await _dio.delete('/categories/$categoryId');
  }
}
