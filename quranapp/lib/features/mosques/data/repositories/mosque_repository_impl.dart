import 'package:dartz/dartz.dart';
import 'package:quranapp/core/error/exceptions.dart';
import 'package:quranapp/core/error/failures.dart';
import 'package:quranapp/core/location/domain/entities/user_location.dart';
import 'package:quranapp/core/network/network_info.dart';
import 'package:quranapp/features/mosques/data/datasources/mosque_remote_data_source.dart';
import 'package:quranapp/features/mosques/domain/entities/mosque.dart';
import 'package:quranapp/features/mosques/domain/entities/route_point.dart';
import 'package:quranapp/features/mosques/domain/repositories/mosque_repository.dart';

class MosqueRepositoryImpl implements MosqueRepository {
  final MosqueRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  MosqueRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<Mosque>>> getNearbyMosques({
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
  Future<Either<Failure, List<RoutePoint>>> getRouteToMosque({
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
