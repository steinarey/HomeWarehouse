import 'package:mobile/data/api/api_client.dart';
import 'package:mobile/data/models/connector.dart';

class ConnectorRepository {
  final ApiClient _apiClient;

  ConnectorRepository(this._apiClient);

  Future<List<Connector>> getConnectors() => _apiClient.getConnectors();

  Future<Connector?> getMicrosoftConnector() =>
      _apiClient.getMicrosoftConnector();

  Future<MicrosoftAuthUrl> getMicrosoftAuthUrl() =>
      _apiClient.getMicrosoftAuthUrl();

  Future<List<MicrosoftList>> getMicrosoftLists() =>
      _apiClient.getMicrosoftLists();

  Future<Connector> updateMicrosoftConnector({
    required String listId,
    String? listName,
  }) =>
      _apiClient.updateMicrosoftConnector(listId: listId, listName: listName);

  Future<void> disconnectMicrosoftConnector() =>
      _apiClient.disconnectMicrosoftConnector();

  Future<Map<String, dynamic>> syncMicrosoftNow() =>
      _apiClient.syncMicrosoftNow();
}
