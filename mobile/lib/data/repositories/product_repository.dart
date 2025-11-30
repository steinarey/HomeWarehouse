import 'package:mobile/data/api/api_client.dart';
import 'package:mobile/data/models/product.dart';

class ProductRepository {
  final ApiClient _apiClient;

  ProductRepository(this._apiClient);

  Future<List<Product>> getProducts({String? query}) =>
      _apiClient.getProducts(query: query);

  Future<Product?> getProductByBarcode(String barcode) =>
      _apiClient.getProductByBarcode(barcode);

  Future<Product> createProduct(Map<String, dynamic> productData) =>
      _apiClient.createProduct(productData);
}
