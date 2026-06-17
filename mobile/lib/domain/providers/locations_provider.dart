import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:mobile/data/models/location.dart';
import 'package:mobile/domain/providers/core_providers.dart';

part 'locations_provider.g.dart';

@riverpod
Future<List<Location>> locationsList(LocationsListRef ref) {
  return ref.watch(locationRepositoryProvider).getLocations();
}
