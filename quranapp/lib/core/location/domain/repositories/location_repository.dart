import 'package:dartz/dartz.dart';
import 'package:quranapp/core/error/failures.dart';
import 'package:quranapp/core/location/domain/entities/user_location.dart';

abstract class LocationRepository {
  Future<Either<Failure, bool>> checkLocationPermission();
  Future<Either<Failure, UserLocation>> getCurrentLocation();
  Stream<Either<Failure, UserLocation>> getLocationStream();
}
