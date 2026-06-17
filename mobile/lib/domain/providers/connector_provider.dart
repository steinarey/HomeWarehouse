import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:mobile/data/models/connector.dart';
import 'package:mobile/domain/providers/core_providers.dart';

part 'connector_provider.g.dart';

@riverpod
Future<Connector?> microsoftConnector(MicrosoftConnectorRef ref) {
  return ref.watch(connectorRepositoryProvider).getMicrosoftConnector();
}

@riverpod
Future<List<MicrosoftList>> microsoftLists(MicrosoftListsRef ref) {
  return ref.watch(connectorRepositoryProvider).getMicrosoftLists();
}
