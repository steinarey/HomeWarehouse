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
String _$currentUserHash() => r'5d88081a91dee83fa4498835386d3dfcfe931f98';

/// The authenticated user (from /users/me). Driven by the JWT, not local prefs.
///
/// Copied from [currentUser].
@ProviderFor(currentUser)
final currentUserProvider = FutureProvider<User>.internal(
  currentUser,
  name: r'currentUserProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$currentUserHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CurrentUserRef = FutureProviderRef<User>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
