import 'package:mobile/data/api/api_client.dart';
import 'package:mobile/data/models/user.dart';

class UserRepository {
  final ApiClient _apiClient;

  UserRepository(this._apiClient);

  Future<List<User>> getUsers() => _apiClient.getUsers();

  Future<User> getCurrentUser() => _apiClient.getCurrentUser();
}
