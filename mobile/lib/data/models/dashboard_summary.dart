import 'package:json_annotation/json_annotation.dart';

part 'dashboard_summary.g.dart';

@JsonSerializable()
class DashboardSummary {
  @JsonKey(name: 'total_categories')
  final int totalCategories;
  @JsonKey(name: 'total_locations')
  final int totalLocations;
  @JsonKey(name: 'low_stock_categories')
  final int lowStockCategories;
  @JsonKey(name: 'low_stock_critical_categories')
  final int lowStockCriticalCategories;

  DashboardSummary({
    required this.totalCategories,
    required this.totalLocations,
    required this.lowStockCategories,
    required this.lowStockCriticalCategories,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> json) =>
      _$DashboardSummaryFromJson(json);
  Map<String, dynamic> toJson() => _$DashboardSummaryToJson(this);
}
