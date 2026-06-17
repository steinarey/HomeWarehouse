import 'package:mobile/data/api/api_client.dart';
import 'package:mobile/data/models/product.dart';

class ProductRepository {
  final ApiClient _apiClient;

  ProductRepository(this._apiClient);

  Future<List<Product>> getProducts({String? query, int? categoryId}) =>
      _apiClient.getProducts(query: query, categoryId: categoryId);

  Future<Product?> getProductByBarcode(String barcode) =>
      _apiClient.getProductByBarcode(barcode);

  Future<Product> createProduct(Map<String, dynamic> productData) =>
      _apiClient.createProduct(productData);

  Future<Product> updateProduct(int productId, Map<String, dynamic> data) =>
      _apiClient.updateProduct(productId, data);

  Future<void> deleteProduct(int productId) =>
      _apiClient.deleteProduct(productId);
}
