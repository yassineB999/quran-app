import 'package:quranapp/core/error/exceptions.dart';
import 'package:quranapp/core/constants/app_constants.dart';
import 'package:quranapp/core/network/api_endpoints.dart';
import 'package:quranapp/core/network/dio_client.dart';
import 'package:quranapp/features/qiblah/data/models/nearby_mosque_model.dart';
import 'package:quranapp/features/qiblah/data/models/route_point_model.dart';

abstract class QiblahRemoteDataSource {
  Future<List<NearbyMosqueModel>> getNearbyMosques({
    required double latitude,
    required double longitude,
  });

  Future<List<RoutePointModel>> getRoutePoints({
    required double originLatitude,
    required double originLongitude,
    required double destinationLatitude,
    required double destinationLongitude,
  });
}

class QiblahRemoteDataSourceImpl implements QiblahRemoteDataSource {
  final DioClient dioClient;

  QiblahRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<List<NearbyMosqueModel>> getNearbyMosques({
    required double latitude,
    required double longitude,
  }) async {
    final response = await dioClient.get(
      ApiEndpoints.nearbyMosques,
      queryParameters: {'lat': latitude, 'lng': longitude},
    );

    if (response.statusCode == 200) {
      final data = response.data['data'] as List<dynamic>;
      return data
          .map((item) => NearbyMosqueModel.fromJson(item))
          .toList(growable: false);
    }

    throw ServerException(
      message: 'Failed to load nearby mosques',
      statusCode: response.statusCode,
    );
  }

  @override
  Future<List<RoutePointModel>> getRoutePoints({
    required double originLatitude,
    required double originLongitude,
    required double destinationLatitude,
    required double destinationLongitude,
  }) async {
    final response = await dioClient.dio.get(
      '${AppConstants.osrmRouteUrl}/$originLongitude,$originLatitude;$destinationLongitude,$destinationLatitude',
      queryParameters: {'overview': 'full', 'geometries': 'geojson'},
    );

    if (response.statusCode == 200) {
      final routes = response.data['routes'] as List<dynamic>? ?? [];
      if (routes.isEmpty) {
        throw const ServerException(message: 'No route available');
      }
      final geometry = routes.first['geometry'];
      final coordinates = geometry['coordinates'] as List<dynamic>? ?? [];
      return coordinates
          .map((coord) => RoutePointModel.fromCoordinates(coord))
          .toList(growable: false);
    }

    throw ServerException(
      message: 'Failed to load route',
      statusCode: response.statusCode,
    );
  }
}
