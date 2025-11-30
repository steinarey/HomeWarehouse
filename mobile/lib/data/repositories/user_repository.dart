import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/data/api/api_client.dart';
import 'package:mobile/data/models/user.dart';

class UserRepository {
  final ApiClient _apiClient;
  final SharedPreferences _prefs;

  static const String _activeUserIdKey = 'active_user_id';

  UserRepository(this._apiClient, this._prefs);

  Future<List<User>> getUsers() => _apiClient.getUsers();

  Future<void> setActiveUser(User user) async {
    await _prefs.setInt(_activeUserIdKey, user.id);
  }

  int? getActiveUserId() {
    return _prefs.getInt(_activeUserIdKey);
  }

  Future<User?> getActiveUser() async {
    final id = getActiveUserId();
    if (id == null) return null;

    // In a real app we might cache the user object or fetch it by ID
    // For now, we'll fetch all users and find the one matching ID
    // Optimization: Add get-user-by-id endpoint or cache locally
    try {
      final users = await getUsers();
      return users.firstWhere((u) => u.id == id);
    } catch (e) {
      return null;
    }
  }
}
