import 'package:json_annotation/json_annotation.dart';

part 'inventory_action.g.dart';

@JsonSerializable()
class InventoryAction {
  final int id;
  @JsonKey(name: 'user_id')
  final int? userId;
  @JsonKey(name: 'action_type')
  final String actionType;
  final String? source;
  @JsonKey(name: 'product_id')
  final int? productId;
  @JsonKey(name: 'category_id')
  final int? categoryId;
  @JsonKey(name: 'quantity_delta')
  final int quantityDelta;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  final bool undone;

  // Helper fields for UI display
  @JsonKey(name: 'category_name')
  final String? categoryName;
  @JsonKey(name: 'product_name')
  final String? productName;
  @JsonKey(name: 'user_name')
  final String? userName;

  InventoryAction({
    required this.id,
    this.userId,
    required this.actionType,
    this.source,
    this.productId,
    this.categoryId,
    required this.quantityDelta,
    required this.createdAt,
    required this.undone,
    this.categoryName,
    this.productName,
    this.userName,
  });

  factory InventoryAction.fromJson(Map<String, dynamic> json) =>
      _$InventoryActionFromJson(json);
  Map<String, dynamic> toJson() => _$InventoryActionToJson(this);
}
