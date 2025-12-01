import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/domain/providers/core_providers.dart';

final membersProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((
  ref,
) async {
  final api = ref.watch(apiClientProvider);
  return api.getMembers();
});

final inviteProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>((ref, role) async {
      final api = ref.watch(apiClientProvider);
      return api.createInvite(role);
    });

final removeMemberProvider = FutureProvider.autoDispose.family<void, int>((
  ref,
  userId,
) async {
  final api = ref.watch(apiClientProvider);
  await api.removeMember(userId);
});
