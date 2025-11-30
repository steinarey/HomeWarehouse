import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:mobile/data/models/user.dart';
import 'package:mobile/domain/providers/core_providers.dart';

part 'user_provider.g.dart';

@riverpod
Future<List<User>> users(UsersRef ref) {
  return ref.watch(userRepositoryProvider).getUsers();
}

@Riverpod(keepAlive: true)
class ActiveUser extends _$ActiveUser {
  @override
  FutureOr<User?> build() async {
    return ref.watch(userRepositoryProvider).getActiveUser();
  }

  Future<void> setUser(User user) async {
    await ref.read(userRepositoryProvider).setActiveUser(user);
    state = AsyncData(user);
  }
}
