import 'package:json_annotation/json_annotation.dart';
import 'inventory_action.dart';

part 'dashboard_summary.g.dart';

@JsonSerializable()
class DashboardSummary {
  @JsonKey(name: 'total_categories')
  final int totalCategories;
  @JsonKey(name: 'low_stock_categories')
  final int lowStockCategories;
  @JsonKey(name: 'low_stock_critical_categories')
  final int lowStockCriticalCategories;
  @JsonKey(name: 'recent_actions')
  final List<InventoryAction> recentActions;

  DashboardSummary({
    required this.totalCategories,
    required this.lowStockCategories,
    required this.lowStockCriticalCategories,
    required this.recentActions,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> json) =>
      _$DashboardSummaryFromJson(json);
  Map<String, dynamic> toJson() => _$DashboardSummaryToJson(this);
}
