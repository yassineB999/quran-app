import 'package:dartz/dartz.dart';
import 'package:quranapp/core/error/failures.dart';
import 'package:quranapp/core/location/domain/entities/user_location.dart';
import 'package:quranapp/features/mosques/domain/entities/mosque.dart';
import 'package:quranapp/features/mosques/domain/entities/route_point.dart';

abstract class MosqueRepository {
  Future<Either<Failure, List<Mosque>>> getNearbyMosques({
    required UserLocation location,
  });

  Future<Either<Failure, List<RoutePoint>>> getRouteToMosque({
    required UserLocation origin,
    required UserLocation destination,
  });
}
