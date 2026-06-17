// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'location_contents.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LocationBatch _$LocationBatchFromJson(Map<String, dynamic> json) =>
    LocationBatch(
      id: (json['id'] as num).toInt(),
      quantity: (json['quantity'] as num).toInt(),
      expiryDate: json['expiry_date'] as String?,
    );

Map<String, dynamic> _$LocationBatchToJson(LocationBatch instance) =>
    <String, dynamic>{
      'id': instance.id,
      'quantity': instance.quantity,
      'expiry_date': instance.expiryDate,
    };

LocationProduct _$LocationProductFromJson(Map<String, dynamic> json) =>
    LocationProduct(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      totalQuantity: (json['total_quantity'] as num).toInt(),
      batches: (json['batches'] as List<dynamic>)
          .map((e) => LocationBatch.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$LocationProductToJson(LocationProduct instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'total_quantity': instance.totalQuantity,
      'batches': instance.batches,
    };

LocationCategory _$LocationCategoryFromJson(Map<String, dynamic> json) =>
    LocationCategory(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      totalQuantity: (json['total_quantity'] as num).toInt(),
      products: (json['products'] as List<dynamic>)
          .map((e) => LocationProduct.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$LocationCategoryToJson(LocationCategory instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'total_quantity': instance.totalQuantity,
      'products': instance.products,
    };

LocationContents _$LocationContentsFromJson(Map<String, dynamic> json) =>
    LocationContents(
      location: Location.fromJson(json['location'] as Map<String, dynamic>),
      totalQuantity: (json['total_quantity'] as num).toInt(),
      categories: (json['categories'] as List<dynamic>)
          .map((e) => LocationCategory.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$LocationContentsToJson(LocationContents instance) =>
    <String, dynamic>{
      'location': instance.location,
      'total_quantity': instance.totalQuantity,
      'categories': instance.categories,
    };
