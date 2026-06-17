import 'package:json_annotation/json_annotation.dart';

part 'connector.g.dart';

@JsonSerializable()
class Connector {
  final int id;
  final String kind;
  final String status;
  @JsonKey(name: 'ms_user_email')
  final String? msUserEmail;
  @JsonKey(name: 'selected_list_id')
  final String? selectedListId;
  @JsonKey(name: 'selected_list_name')
  final String? selectedListName;
  @JsonKey(name: 'last_synced_at')
  final DateTime? lastSyncedAt;
  @JsonKey(name: 'last_error')
  final String? lastError;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  Connector({
    required this.id,
    required this.kind,
    required this.status,
    this.msUserEmail,
    this.selectedListId,
    this.selectedListName,
    this.lastSyncedAt,
    this.lastError,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Connector.fromJson(Map<String, dynamic> json) =>
      _$ConnectorFromJson(json);
  Map<String, dynamic> toJson() => _$ConnectorToJson(this);
}

@JsonSerializable()
class MicrosoftAuthUrl {
  @JsonKey(name: 'auth_url')
  final String authUrl;
  final String state;

  MicrosoftAuthUrl({required this.authUrl, required this.state});

  factory MicrosoftAuthUrl.fromJson(Map<String, dynamic> json) =>
      _$MicrosoftAuthUrlFromJson(json);
  Map<String, dynamic> toJson() => _$MicrosoftAuthUrlToJson(this);
}

@JsonSerializable()
class MicrosoftList {
  final String id;
  @JsonKey(name: 'display_name')
  final String displayName;
  @JsonKey(name: 'is_owner')
  final bool? isOwner;
  @JsonKey(name: 'well_known_list_name')
  final String? wellKnownListName;

  MicrosoftList({
    required this.id,
    required this.displayName,
    this.isOwner,
    this.wellKnownListName,
  });

  factory MicrosoftList.fromJson(Map<String, dynamic> json) =>
      _$MicrosoftListFromJson(json);
  Map<String, dynamic> toJson() => _$MicrosoftListToJson(this);
}
