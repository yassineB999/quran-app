import 'package:dartz/dartz.dart';
import 'package:quranapp/core/error/exceptions.dart';
import 'package:quranapp/core/error/failures.dart';
import 'package:quranapp/core/network/network_info.dart';
import 'package:quranapp/features/qiblah/data/datasources/qiblah_local_data_source.dart';
import 'package:quranapp/features/qiblah/data/datasources/qiblah_remote_data_source.dart';
import 'package:quranapp/features/qiblah/domain/entities/nearby_mosque.dart';
import 'package:quranapp/features/qiblah/domain/entities/qiblah_direction.dart';
import 'package:quranapp/features/qiblah/domain/entities/route_point.dart';
import 'package:quranapp/features/qiblah/domain/entities/user_location.dart';
import 'package:quranapp/features/qiblah/domain/repositories/qiblah_repository.dart';

class QiblahRepositoryImpl implements QiblahRepository {
  final QiblahLocalDataSource localDataSource;
  final QiblahRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  QiblahRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Stream<Either<Failure, QiblahDirection>> getQiblahStream() async* {
    try {
      final stream = localDataSource.getQiblahStream();
      await for (final direction in stream) {
        yield Right(direction);
      }
    } on ServerException catch (e) {
      yield Left(ServerFailure(e.message));
    } catch (e) {
      yield Left(ServerFailure(e.toString()));
    }
  }

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

  @override
  Future<Either<Failure, List<NearbyMosque>>> getNearbyMosques({
    required UserLocation location,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final results = await remoteDataSource.getNearbyMosques(
        latitude: location.latitude,
        longitude: location.longitude,
      );
      return Right(results);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<RoutePoint>>> getRoutePoints({
    required UserLocation origin,
    required UserLocation destination,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final results = await remoteDataSource.getRoutePoints(
        originLatitude: origin.latitude,
        originLongitude: origin.longitude,
        destinationLatitude: destination.latitude,
        destinationLongitude: destination.longitude,
      );
      return Right(results);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
