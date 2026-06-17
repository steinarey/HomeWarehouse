import 'package:json_annotation/json_annotation.dart';
import 'package:mobile/data/models/location.dart';

part 'location_contents.g.dart';

@JsonSerializable()
class LocationBatch {
  final int id;
  final int quantity;
  @JsonKey(name: 'expiry_date')
  final String? expiryDate;

  LocationBatch({required this.id, required this.quantity, this.expiryDate});

  factory LocationBatch.fromJson(Map<String, dynamic> json) =>
      _$LocationBatchFromJson(json);
  Map<String, dynamic> toJson() => _$LocationBatchToJson(this);
}

@JsonSerializable()
class LocationProduct {
  final int id;
  final String name;
  @JsonKey(name: 'total_quantity')
  final int totalQuantity;
  final List<LocationBatch> batches;

  LocationProduct({
    required this.id,
    required this.name,
    required this.totalQuantity,
    required this.batches,
  });

  factory LocationProduct.fromJson(Map<String, dynamic> json) =>
      _$LocationProductFromJson(json);
  Map<String, dynamic> toJson() => _$LocationProductToJson(this);
}

@JsonSerializable()
class LocationCategory {
  final int id;
  final String name;
  @JsonKey(name: 'total_quantity')
  final int totalQuantity;
  final List<LocationProduct> products;

  LocationCategory({
    required this.id,
    required this.name,
    required this.totalQuantity,
    required this.products,
  });

  factory LocationCategory.fromJson(Map<String, dynamic> json) =>
      _$LocationCategoryFromJson(json);
  Map<String, dynamic> toJson() => _$LocationCategoryToJson(this);
}

@JsonSerializable()
class LocationContents {
  final Location location;
  @JsonKey(name: 'total_quantity')
  final int totalQuantity;
  final List<LocationCategory> categories;

  LocationContents({
    required this.location,
    required this.totalQuantity,
    required this.categories,
  });

  factory LocationContents.fromJson(Map<String, dynamic> json) =>
      _$LocationContentsFromJson(json);
  Map<String, dynamic> toJson() => _$LocationContentsToJson(this);
}
