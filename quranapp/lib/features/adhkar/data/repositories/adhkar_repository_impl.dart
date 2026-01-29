import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:quranapp/core/error/exceptions.dart';
import 'package:quranapp/core/error/failures.dart';
import 'package:quranapp/features/adhkar/data/datasources/adhkar_remote_data_source.dart';
import 'package:quranapp/features/adhkar/domain/entities/adhkar.dart';
import 'package:quranapp/features/adhkar/domain/repositories/adhkar_repository.dart';

class AdhkarRepositoryImpl implements AdhkarRepository {
  final AdhkarRemoteDataSource remoteDataSource;

  AdhkarRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<Adhkar>>> getAdhkar(String category) async {
    try {
      final adhkarList = await remoteDataSource.getAdhkar(category);
      return Right(adhkarList);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Adhkar error: $e');
      }
      return const Left(ServerFailure('Unexpected error getting adhkar'));
    }
  }
}
