import 'package:mobile/data/api/api_client.dart';
import 'package:mobile/data/models/category.dart';

class CategoryRepository {
  final ApiClient _apiClient;

  CategoryRepository(this._apiClient);

  Future<List<Category>> getCategories({bool includeStock = false}) =>
      _apiClient.getCategories(includeStock: includeStock);

  Future<Category> updateCategory(int categoryId, Map<String, dynamic> data) =>
      _apiClient.updateCategory(categoryId, data);

  Future<Category> createCategory(Map<String, dynamic> data) =>
      _apiClient.createCategory(data);

  Future<void> deleteCategory(int categoryId) =>
      _apiClient.deleteCategory(categoryId);
}
