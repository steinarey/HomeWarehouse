// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dashboard_summary.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DashboardSummary _$DashboardSummaryFromJson(Map<String, dynamic> json) =>
    DashboardSummary(
      totalCategories: (json['total_categories'] as num).toInt(),
      lowStockCategories: (json['low_stock_categories'] as num).toInt(),
      lowStockCriticalCategories: (json['low_stock_critical_categories'] as num)
          .toInt(),
      recentActions: (json['recent_actions'] as List<dynamic>)
          .map((e) => InventoryAction.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$DashboardSummaryToJson(DashboardSummary instance) =>
    <String, dynamic>{
      'total_categories': instance.totalCategories,
      'low_stock_categories': instance.lowStockCategories,
      'low_stock_critical_categories': instance.lowStockCriticalCategories,
      'recent_actions': instance.recentActions,
    };
