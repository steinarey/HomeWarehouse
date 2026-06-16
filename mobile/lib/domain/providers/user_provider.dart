import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:mobile/data/models/user.dart';
import 'package:mobile/domain/providers/core_providers.dart';

part 'user_provider.g.dart';

@riverpod
Future<List<User>> users(UsersRef ref) {
  return ref.watch(userRepositoryProvider).getUsers();
}

/// The authenticated user (from /users/me). Driven by the JWT, not local prefs.
@Riverpod(keepAlive: true)
Future<User> currentUser(CurrentUserRef ref) {
  return ref.watch(userRepositoryProvider).getCurrentUser();
}
