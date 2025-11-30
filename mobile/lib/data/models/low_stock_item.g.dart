// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'low_stock_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LowStockItem _$LowStockItemFromJson(Map<String, dynamic> json) => LowStockItem(
  categoryId: (json['category_id'] as num).toInt(),
  name: json['name'] as String,
  currentStock: (json['current_stock'] as num).toInt(),
  minStock: (json['min_stock'] as num).toInt(),
  targetStock: (json['target_stock'] as num?)?.toInt(),
  recommendedBuyQuantity: (json['recommended_buy_quantity'] as num).toInt(),
  isCritical: json['is_critical'] as bool,
);

Map<String, dynamic> _$LowStockItemToJson(LowStockItem instance) =>
    <String, dynamic>{
      'category_id': instance.categoryId,
      'name': instance.name,
      'current_stock': instance.currentStock,
      'min_stock': instance.minStock,
      'target_stock': instance.targetStock,
      'recommended_buy_quantity': instance.recommendedBuyQuantity,
      'is_critical': instance.isCritical,
    };
