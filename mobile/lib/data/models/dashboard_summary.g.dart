// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dashboard_summary.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DashboardSummary _$DashboardSummaryFromJson(Map<String, dynamic> json) =>
    DashboardSummary(
      totalCategories: (json['total_categories'] as num).toInt(),
      totalLocations: (json['total_locations'] as num).toInt(),
      lowStockCategories: (json['low_stock_categories'] as num).toInt(),
      lowStockCriticalCategories: (json['low_stock_critical_categories'] as num)
          .toInt(),
    );

Map<String, dynamic> _$DashboardSummaryToJson(DashboardSummary instance) =>
    <String, dynamic>{
      'total_categories': instance.totalCategories,
      'total_locations': instance.totalLocations,
      'low_stock_categories': instance.lowStockCategories,
      'low_stock_critical_categories': instance.lowStockCriticalCategories,
    };
