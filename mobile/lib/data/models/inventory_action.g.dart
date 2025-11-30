// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inventory_action.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InventoryAction _$InventoryActionFromJson(Map<String, dynamic> json) =>
    InventoryAction(
      id: (json['id'] as num).toInt(),
      userId: (json['user_id'] as num?)?.toInt(),
      actionType: json['action_type'] as String,
      source: json['source'] as String?,
      productId: (json['product_id'] as num?)?.toInt(),
      categoryId: (json['category_id'] as num?)?.toInt(),
      quantityDelta: (json['quantity_delta'] as num).toInt(),
      createdAt: DateTime.parse(json['created_at'] as String),
      undone: json['undone'] as bool,
      categoryName: json['category_name'] as String?,
      productName: json['product_name'] as String?,
      userName: json['user_name'] as String?,
    );

Map<String, dynamic> _$InventoryActionToJson(InventoryAction instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'action_type': instance.actionType,
      'source': instance.source,
      'product_id': instance.productId,
      'category_id': instance.categoryId,
      'quantity_delta': instance.quantityDelta,
      'created_at': instance.createdAt.toIso8601String(),
      'undone': instance.undone,
      'category_name': instance.categoryName,
      'product_name': instance.productName,
      'user_name': instance.userName,
    };
