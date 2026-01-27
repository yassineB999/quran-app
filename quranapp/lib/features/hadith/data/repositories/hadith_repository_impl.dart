import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:quranapp/core/error/exceptions.dart';
import 'package:quranapp/core/error/failures.dart';
import 'package:quranapp/features/hadith/data/datasources/hadith_remote_data_source.dart';
import 'package:quranapp/features/hadith/domain/entities/hadith.dart';
import 'package:quranapp/features/hadith/domain/entities/hadith_edition.dart';
import 'package:quranapp/features/hadith/domain/repositories/hadith_repository.dart';

class HadithRepositoryImpl implements HadithRepository {
  final HadithRemoteDataSource remoteDataSource;

  HadithRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<HadithEdition>>> getEditions() async {
    try {
      final remoteEditions = await remoteDataSource.getEditions();
      return Right(remoteEditions);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      if (kDebugMode) {
        debugPrint(e.toString());
      }
      return const Left(ServerFailure('Unexpected error getting editions'));
    }
  }

  @override
  Future<Either<Failure, List<Hadith>>> getHadiths(String editionId) async {
    try {
      final remoteHadiths = await remoteDataSource.getHadiths(editionId);
      return Right(remoteHadiths);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      if (kDebugMode) {
        debugPrint(e.toString());
      }
      return const Left(ServerFailure('Unexpected error getting hadiths'));
    }
  }
}
