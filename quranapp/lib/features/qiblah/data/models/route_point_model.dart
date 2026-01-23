import 'package:quranapp/features/qiblah/domain/entities/route_point.dart';

class RoutePointModel extends RoutePoint {
  const RoutePointModel({
    required super.latitude,
    required super.longitude,
  });

  factory RoutePointModel.fromCoordinates(List<dynamic> coordinates) {
    return RoutePointModel(
      longitude: (coordinates[0] as num).toDouble(),
      latitude: (coordinates[1] as num).toDouble(),
    );
  }
}
