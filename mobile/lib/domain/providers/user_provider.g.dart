// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$usersHash() => r'a9d871f10f8f539cb8151e838126b318b1bb8019';

/// See also [users].
@ProviderFor(users)
final usersProvider = AutoDisposeFutureProvider<List<User>>.internal(
  users,
  name: r'usersProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$usersHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef UsersRef = AutoDisposeFutureProviderRef<List<User>>;
String _$activeUserHash() => r'f544389ae962061bfc48e88d99365ca80076463a';

/// See also [ActiveUser].
@ProviderFor(ActiveUser)
final activeUserProvider = AsyncNotifierProvider<ActiveUser, User?>.internal(
  ActiveUser.new,
  name: r'activeUserProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$activeUserHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ActiveUser = AsyncNotifier<User?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
