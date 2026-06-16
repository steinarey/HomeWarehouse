import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:mobile/data/models/category.dart';
import 'package:mobile/domain/providers/core_providers.dart';

part 'categories_provider.g.dart';

@riverpod
Future<List<Category>> categories(CategoriesRef ref) {
  return ref
      .watch(categoryRepositoryProvider)
      .getCategories(includeStock: true);
}
