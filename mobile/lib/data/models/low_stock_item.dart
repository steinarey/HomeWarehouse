import 'package:json_annotation/json_annotation.dart';

part 'low_stock_item.g.dart';

@JsonSerializable()
class LowStockItem {
  @JsonKey(name: 'category_id')
  final int categoryId;
  final String name;
  @JsonKey(name: 'current_stock')
  final int currentStock;
  @JsonKey(name: 'min_stock')
  final int minStock;
  @JsonKey(name: 'target_stock')
  final int? targetStock;
  @JsonKey(name: 'recommended_buy_quantity')
  final int recommendedBuyQuantity;
  @JsonKey(name: 'is_critical')
  final bool isCritical;

  LowStockItem({
    required this.categoryId,
    required this.name,
    required this.currentStock,
    required this.minStock,
    this.targetStock,
    required this.recommendedBuyQuantity,
    required this.isCritical,
  });

  factory LowStockItem.fromJson(Map<String, dynamic> json) =>
      _$LowStockItemFromJson(json);
  Map<String, dynamic> toJson() => _$LowStockItemToJson(this);
}
