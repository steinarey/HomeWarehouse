// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Product _$ProductFromJson(Map<String, dynamic> json) => Product(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
  categoryId: (json['category_id'] as num).toInt(),
  barcode: json['barcode'] as String?,
  packageSize: (json['package_size'] as num?)?.toInt() ?? 1,
  photoUrl: json['photo_url'] as String?,
  categoryName: json['category_name'] as String?,
);

Map<String, dynamic> _$ProductToJson(Product instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'category_id': instance.categoryId,
  'barcode': instance.barcode,
  'package_size': instance.packageSize,
  'photo_url': instance.photoUrl,
  'category_name': instance.categoryName,
};
