import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:mobile/data/models/dashboard_summary.dart';
import 'package:mobile/data/models/low_stock_item.dart';
import 'package:mobile/domain/providers/core_providers.dart';

part 'dashboard_provider.g.dart';

@riverpod
Future<DashboardSummary> dashboard(DashboardRef ref) {
  return ref.watch(inventoryRepositoryProvider).getDashboard();
}

@riverpod
Future<List<LowStockItem>> lowStock(LowStockRef ref) {
  return ref.watch(inventoryRepositoryProvider).getLowStock();
}
