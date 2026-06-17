import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:mobile/data/models/pending_restock.dart';
import 'package:mobile/domain/providers/core_providers.dart';

part 'pending_restock_provider.g.dart';

@riverpod
Future<List<PendingRestock>> pendingRestocks(PendingRestocksRef ref) {
  return ref.watch(pendingRestockRepositoryProvider).getPendingRestocks();
}
