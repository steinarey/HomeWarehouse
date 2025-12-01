import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/config/app_constants.dart';
import 'package:mobile/data/api/api_client.dart';
import 'package:mobile/data/repositories/user_repository.dart';
import 'package:mobile/data/repositories/inventory_repository.dart';
import 'package:mobile/data/repositories/product_repository.dart';
import 'package:mobile/data/repositories/category_repository.dart';

part 'core_providers.g.dart';

@Riverpod(keepAlive: true)
SharedPreferences sharedPreferences(SharedPreferencesRef ref) {
  throw UnimplementedError(); // Override in main.dart
}

@Riverpod(keepAlive: true)
class BaseUrl extends _$BaseUrl {
  @override
  String build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getString('base_url') ?? AppConstants.defaultBaseUrl;
  }

  Future<void> setUrl(String url) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString('base_url', url);
    state = url;
  }
}

@Riverpod(keepAlive: true)
Dio dio(DioRef ref) {
  final baseUrl = ref.watch(baseUrlProvider);
  final prefs = ref.watch(sharedPreferencesProvider);

  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 3),
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = prefs.getString('auth_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        // Also add X-Warehouse-Id if available (for future use/completeness)
        // For now, let's just focus on Auth.
        // Actually, we need X-Warehouse-Id for isolation!
        // But where do we store it? Maybe just default to first one on backend if missing.
        // But wait, backend deps.py says:
        // if x_warehouse_id is None: try to find the first warehouse...
        // So X-Warehouse-Id is optional but good to have.
        // Let's stick to Auth first.
        return handler.next(options);
      },
    ),
  );

  return dio;
}

@Riverpod(keepAlive: true)
ApiClient apiClient(ApiClientRef ref) {
  return ApiClient(ref.watch(dioProvider));
}

@Riverpod(keepAlive: true)
UserRepository userRepository(UserRepositoryRef ref) {
  return UserRepository(
    ref.watch(apiClientProvider),
    ref.watch(sharedPreferencesProvider),
  );
}

@Riverpod(keepAlive: true)
InventoryRepository inventoryRepository(InventoryRepositoryRef ref) {
  return InventoryRepository(ref.watch(apiClientProvider));
}

@Riverpod(keepAlive: true)
ProductRepository productRepository(ProductRepositoryRef ref) {
  return ProductRepository(ref.watch(apiClientProvider));
}

@Riverpod(keepAlive: true)
CategoryRepository categoryRepository(CategoryRepositoryRef ref) {
  return CategoryRepository(ref.watch(apiClientProvider));
}

final bottomNavIndexProvider = StateProvider<int>((ref) => 0);
