import 'package:dartz/dartz.dart';
import 'package:quranapp/core/error/failures.dart';
import 'package:quranapp/features/qiblah/domain/entities/nearby_mosque.dart';
import 'package:quranapp/features/qiblah/domain/entities/qiblah_direction.dart';
import 'package:quranapp/features/qiblah/domain/entities/route_point.dart';
import 'package:quranapp/features/qiblah/domain/entities/user_location.dart';

abstract class QiblahRepository {
  /// Stream of Qiblah direction updates (heading + calculated bearing)
  Stream<Either<Failure, QiblahDirection>> getQiblahStream();

  Future<Either<Failure, bool>> checkLocationPermission();

  Future<Either<Failure, UserLocation>> getCurrentLocation();

  Stream<Either<Failure, UserLocation>> getLocationStream();

  Future<Either<Failure, List<NearbyMosque>>> getNearbyMosques({
    required UserLocation location,
  });

  Future<Either<Failure, List<RoutePoint>>> getRoutePoints({
    required UserLocation origin,
    required UserLocation destination,
  });
}
