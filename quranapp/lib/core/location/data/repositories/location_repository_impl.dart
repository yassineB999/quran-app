import 'package:dartz/dartz.dart';
import 'package:quranapp/core/error/exceptions.dart';
import 'package:quranapp/core/error/failures.dart';
import 'package:quranapp/core/location/data/datasources/location_local_data_source.dart';
import 'package:quranapp/core/location/domain/entities/user_location.dart';
import 'package:quranapp/core/location/domain/repositories/location_repository.dart';

class LocationRepositoryImpl implements LocationRepository {
  final LocationLocalDataSource localDataSource;

  LocationRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, bool>> checkLocationPermission() async {
    try {
      final result = await localDataSource.requestLocationPermission();
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserLocation>> getCurrentLocation() async {
    try {
      final position = await localDataSource.getCurrentPosition();
      return Right(
        UserLocation(
          latitude: position.latitude,
          longitude: position.longitude,
        ),
      );
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Stream<Either<Failure, UserLocation>> getLocationStream() async* {
    try {
      await for (final position in localDataSource.getPositionStream()) {
        yield Right(
          UserLocation(
            latitude: position.latitude,
            longitude: position.longitude,
          ),
        );
      }
    } on ServerException catch (e) {
      yield Left(ServerFailure(e.message));
    } catch (e) {
      yield Left(ServerFailure(e.toString()));
    }
  }
}
