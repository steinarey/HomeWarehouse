import 'package:mobile/data/api/api_client.dart';
import 'package:mobile/data/models/location.dart';
import 'package:mobile/data/models/location_contents.dart';

class LocationRepository {
  final ApiClient _apiClient;

  LocationRepository(this._apiClient);

  Future<List<Location>> getLocations() => _apiClient.getLocations();

  Future<Location> createLocation(Map<String, dynamic> data) =>
      _apiClient.createLocation(data);

  Future<Location> updateLocation(int id, Map<String, dynamic> data) =>
      _apiClient.updateLocation(id, data);

  Future<void> deleteLocation(int id) => _apiClient.deleteLocation(id);

  Future<LocationContents> getLocationContents(int id) =>
      _apiClient.getLocationContents(id);
}
