// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pending_restock.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PendingRestock _$PendingRestockFromJson(Map<String, dynamic> json) =>
    PendingRestock(
      id: (json['id'] as num).toInt(),
      categoryId: (json['category_id'] as num).toInt(),
      categoryName: json['category_name'] as String,
      source: json['source'] as String,
      status: json['status'] as String,
      externalTaskId: json['external_task_id'] as String?,
      currentStock: (json['current_stock'] as num).toInt(),
      minStock: (json['min_stock'] as num).toInt(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$PendingRestockToJson(PendingRestock instance) =>
    <String, dynamic>{
      'id': instance.id,
      'category_id': instance.categoryId,
      'category_name': instance.categoryName,
      'source': instance.source,
      'status': instance.status,
      'external_task_id': instance.externalTaskId,
      'current_stock': instance.currentStock,
      'min_stock': instance.minStock,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };
