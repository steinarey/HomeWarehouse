import 'package:json_annotation/json_annotation.dart';

part 'product.g.dart';

@JsonSerializable()
class Product {
  final int id;
  final String name;
  @JsonKey(name: 'category_id')
  final int categoryId;
  final String? barcode;
  @JsonKey(name: 'package_size')
  final int packageSize;
  @JsonKey(name: 'photo_url')
  final String? photoUrl;

  // Optional fields that might be included in some responses
  @JsonKey(name: 'category_name')
  final String? categoryName;

  Product({
    required this.id,
    required this.name,
    required this.categoryId,
    this.barcode,
    this.packageSize = 1,
    this.photoUrl,
    this.categoryName,
  });

  factory Product.fromJson(Map<String, dynamic> json) =>
      _$ProductFromJson(json);
  Map<String, dynamic> toJson() => _$ProductToJson(this);
}
