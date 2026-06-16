import 'package:json_annotation/json_annotation.dart';

part 'location.g.dart';

@JsonSerializable()
class Location {
  final int id;
  final String room;
  final String area;
  @JsonKey(name: 'shelf_box')
  final String shelfBox;
  final String? notes;

  Location({
    required this.id,
    required this.room,
    required this.area,
    required this.shelfBox,
    this.notes,
  });

  String get label {
    final parts = [room, area, shelfBox].where((p) => p.isNotEmpty);
    return parts.join(' / ');
  }

  factory Location.fromJson(Map<String, dynamic> json) =>
      _$LocationFromJson(json);
  Map<String, dynamic> toJson() => _$LocationToJson(this);
}
