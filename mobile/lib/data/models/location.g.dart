// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'location.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Location _$LocationFromJson(Map<String, dynamic> json) => Location(
  id: (json['id'] as num).toInt(),
  room: json['room'] as String,
  area: json['area'] as String,
  shelfBox: json['shelf_box'] as String,
  notes: json['notes'] as String?,
);

Map<String, dynamic> _$LocationToJson(Location instance) => <String, dynamic>{
  'id': instance.id,
  'room': instance.room,
  'area': instance.area,
  'shelf_box': instance.shelfBox,
  'notes': instance.notes,
};
