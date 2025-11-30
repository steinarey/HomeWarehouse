import 'package:json_annotation/json_annotation.dart';

part 'category.g.dart';

@JsonSerializable()
class Category {
  final int id;
  final String name;
  final String? description;
  @JsonKey(name: 'is_critical')
  final bool isCritical;
  @JsonKey(name: 'is_one_off')
  final bool isOneOff;
  @JsonKey(name: 'min_stock')
  final int minStock;
  @JsonKey(name: 'target_stock')
  final int? targetStock;
  @JsonKey(name: 'nfc_tag_id')
  final String? nfcTagId;

  // These might come from summary endpoints, so they are optional
  @JsonKey(name: 'current_stock')
  final int? currentStock;
  @JsonKey(name: 'is_below_min')
  final bool? isBelowMin;

  Category({
    required this.id,
    required this.name,
    this.description,
    required this.isCritical,
    required this.isOneOff,
    required this.minStock,
    this.targetStock,
    this.nfcTagId,
    this.currentStock,
    this.isBelowMin,
  });

  factory Category.fromJson(Map<String, dynamic> json) =>
      _$CategoryFromJson(json);
  Map<String, dynamic> toJson() => _$CategoryToJson(this);
}
