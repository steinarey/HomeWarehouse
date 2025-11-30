// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'category.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Category _$CategoryFromJson(Map<String, dynamic> json) => Category(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
  description: json['description'] as String?,
  isCritical: json['is_critical'] as bool,
  isOneOff: json['is_one_off'] as bool,
  minStock: (json['min_stock'] as num).toInt(),
  targetStock: (json['target_stock'] as num?)?.toInt(),
  nfcTagId: json['nfc_tag_id'] as String?,
  currentStock: (json['current_stock'] as num?)?.toInt(),
  isBelowMin: json['is_below_min'] as bool?,
);

Map<String, dynamic> _$CategoryToJson(Category instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'description': instance.description,
  'is_critical': instance.isCritical,
  'is_one_off': instance.isOneOff,
  'min_stock': instance.minStock,
  'target_stock': instance.targetStock,
  'nfc_tag_id': instance.nfcTagId,
  'current_stock': instance.currentStock,
  'is_below_min': instance.isBelowMin,
};
