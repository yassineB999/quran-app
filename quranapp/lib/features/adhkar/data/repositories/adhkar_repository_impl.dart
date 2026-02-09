import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:quranapp/core/error/exceptions.dart';
import 'package:quranapp/core/error/failures.dart';
import 'package:quranapp/features/adhkar/data/datasources/adhkar_remote_data_source.dart';
import 'package:quranapp/features/adhkar/domain/entities/adhkar.dart';
import 'package:quranapp/features/adhkar/domain/repositories/adhkar_repository.dart';
import 'package:quranapp/core/network/network_info.dart';

class AdhkarRepositoryImpl implements AdhkarRepository {
  final AdhkarRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  AdhkarRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<Adhkar>>> getAdhkar(String category) async {
    if (await networkInfo.isConnected) {
      try {
        final adhkarList = await remoteDataSource.getAdhkar(category);
        return Right(adhkarList);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } on NetworkException catch (e) {
        return Left(NetworkFailure(e.message));
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Adhkar error: $e');
        }
        return const Left(ServerFailure('Unexpected error getting adhkar'));
      }
    } else {
      return const Left(NetworkFailure());
    }
  }
}
