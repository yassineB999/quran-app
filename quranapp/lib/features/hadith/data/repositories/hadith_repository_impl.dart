import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:quranapp/core/error/exceptions.dart';
import 'package:quranapp/core/error/failures.dart';
import 'package:quranapp/core/network/network_info.dart';
import 'package:quranapp/features/hadith/data/datasources/hadith_remote_data_source.dart';
import 'package:quranapp/features/hadith/domain/entities/hadith.dart';
import 'package:quranapp/features/hadith/domain/entities/hadith_edition.dart';
import 'package:quranapp/features/hadith/domain/repositories/hadith_repository.dart';

class HadithRepositoryImpl implements HadithRepository {
  final HadithRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  HadithRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<HadithEdition>>> getEditions() async {
    if (await networkInfo.isConnected) {
      try {
        final remoteEditions = await remoteDataSource.getEditions();
        return Right(remoteEditions);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } on NetworkException catch (e) {
        return Left(NetworkFailure(e.message));
      } catch (e) {
        if (kDebugMode) {
          debugPrint(e.toString());
        }
        return const Left(ServerFailure('Unexpected error getting editions'));
      }
    } else {
      return const Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, List<Hadith>>> getHadiths(String editionId) async {
    if (await networkInfo.isConnected) {
      try {
        final remoteHadiths = await remoteDataSource.getHadiths(editionId);
        return Right(remoteHadiths);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } on NetworkException catch (e) {
        return Left(NetworkFailure(e.message));
      } catch (e) {
        if (kDebugMode) {
          debugPrint(e.toString());
        }
        return const Left(ServerFailure('Unexpected error getting hadiths'));
      }
    } else {
      return const Left(NetworkFailure());
    }
  }
}
