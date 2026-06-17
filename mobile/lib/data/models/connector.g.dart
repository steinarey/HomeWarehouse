// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'connector.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Connector _$ConnectorFromJson(Map<String, dynamic> json) => Connector(
  id: (json['id'] as num).toInt(),
  kind: json['kind'] as String,
  status: json['status'] as String,
  msUserEmail: json['ms_user_email'] as String?,
  selectedListId: json['selected_list_id'] as String?,
  selectedListName: json['selected_list_name'] as String?,
  lastSyncedAt: json['last_synced_at'] == null
      ? null
      : DateTime.parse(json['last_synced_at'] as String),
  lastError: json['last_error'] as String?,
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$ConnectorToJson(Connector instance) => <String, dynamic>{
  'id': instance.id,
  'kind': instance.kind,
  'status': instance.status,
  'ms_user_email': instance.msUserEmail,
  'selected_list_id': instance.selectedListId,
  'selected_list_name': instance.selectedListName,
  'last_synced_at': instance.lastSyncedAt?.toIso8601String(),
  'last_error': instance.lastError,
  'created_at': instance.createdAt.toIso8601String(),
  'updated_at': instance.updatedAt.toIso8601String(),
};

MicrosoftAuthUrl _$MicrosoftAuthUrlFromJson(Map<String, dynamic> json) =>
    MicrosoftAuthUrl(
      authUrl: json['auth_url'] as String,
      state: json['state'] as String,
    );

Map<String, dynamic> _$MicrosoftAuthUrlToJson(MicrosoftAuthUrl instance) =>
    <String, dynamic>{
      'auth_url': instance.authUrl,
      'state': instance.state,
    };

MicrosoftList _$MicrosoftListFromJson(Map<String, dynamic> json) =>
    MicrosoftList(
      id: json['id'] as String,
      displayName: json['display_name'] as String,
      isOwner: json['is_owner'] as bool?,
      wellKnownListName: json['well_known_list_name'] as String?,
    );

Map<String, dynamic> _$MicrosoftListToJson(MicrosoftList instance) =>
    <String, dynamic>{
      'id': instance.id,
      'display_name': instance.displayName,
      'is_owner': instance.isOwner,
      'well_known_list_name': instance.wellKnownListName,
    };
