import 'package:json_annotation/json_annotation.dart';

part 'pending_restock.g.dart';

@JsonSerializable()
class PendingRestock {
  final int id;
  @JsonKey(name: 'category_id')
  final int categoryId;
  @JsonKey(name: 'category_name')
  final String categoryName;
  final String source;
  final String status;
  @JsonKey(name: 'external_task_id')
  final String? externalTaskId;
  @JsonKey(name: 'current_stock')
  final int currentStock;
  @JsonKey(name: 'min_stock')
  final int minStock;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  PendingRestock({
    required this.id,
    required this.categoryId,
    required this.categoryName,
    required this.source,
    required this.status,
    this.externalTaskId,
    required this.currentStock,
    required this.minStock,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PendingRestock.fromJson(Map<String, dynamic> json) =>
      _$PendingRestockFromJson(json);
  Map<String, dynamic> toJson() => _$PendingRestockToJson(this);
}
