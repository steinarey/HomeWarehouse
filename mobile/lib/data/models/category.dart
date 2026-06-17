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
  @JsonKey(name: 'consumption_rate')
  final int? consumptionRate;
  @JsonKey(name: 'location_id')
  final int? locationId;

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
    this.consumptionRate,
    this.locationId,
    this.currentStock,
    this.isBelowMin,
  });

  factory Category.fromJson(Map<String, dynamic> json) =>
      _$CategoryFromJson(json);
  Map<String, dynamic> toJson() => _$CategoryToJson(this);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Category &&
        other.id == id &&
        other.name == name &&
        other.description == description &&
        other.isCritical == isCritical &&
        other.isOneOff == isOneOff &&
        other.minStock == minStock &&
        other.targetStock == targetStock &&
        other.nfcTagId == nfcTagId &&
        other.consumptionRate == consumptionRate &&
        other.locationId == locationId &&
        other.currentStock == currentStock &&
        other.isBelowMin == isBelowMin;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      name,
      description,
      isCritical,
      isOneOff,
      minStock,
      targetStock,
      nfcTagId,
      consumptionRate,
      locationId,
      currentStock,
      isBelowMin,
    );
  }
}
