import 'package:mobile/data/api/api_client.dart';
import 'package:mobile/data/models/pending_restock.dart';

class PendingRestockRepository {
  final ApiClient _apiClient;

  PendingRestockRepository(this._apiClient);

  Future<List<PendingRestock>> getPendingRestocks() =>
      _apiClient.getPendingRestocks();

  Future<PendingRestock> dismiss(int id) =>
      _apiClient.dismissPendingRestock(id);
}
