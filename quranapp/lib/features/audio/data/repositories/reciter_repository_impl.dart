import 'package:dartz/dartz.dart';
import 'package:quranapp/core/error/exceptions.dart';
import 'package:quranapp/core/error/failures.dart';
import 'package:quranapp/core/network/network_info.dart';
import 'package:quranapp/features/audio/data/datasources/reciter_remote_data_source.dart';
import 'package:quranapp/features/audio/domain/entities/audio_info.dart';
import 'package:quranapp/features/audio/domain/entities/reciter.dart';
import 'package:quranapp/features/audio/domain/repositories/reciter_repository.dart';

import 'package:quranapp/features/audio/domain/entities/recitation_result.dart';

/// Implementation of ReciterRepository
class ReciterRepositoryImpl implements ReciterRepository {
  final ReciterRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  ReciterRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<Reciter>>> getReciters() async {
    if (await networkInfo.isConnected) {
      try {
        final reciters = await remoteDataSource.getReciters();
        return Right(reciters);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } on NetworkException catch (e) {
        return Left(NetworkFailure(e.message));
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return const Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, AudioInfo>> getAudioUrl(
    int reciterId,
    int surahId,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final audioInfo = await remoteDataSource.getAudioUrl(
          reciterId,
          surahId,
        );
        return Right(audioInfo);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } on NetworkException catch (e) {
        return Left(NetworkFailure(e.message));
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return const Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, RecitationResult>> checkRecitation(
    String filePath,
    int surahId,
    int ayahId,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.checkRecitation(
          filePath,
          surahId,
          ayahId,
        );
        return Right(result);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } on NetworkException catch (e) {
        return Left(NetworkFailure(e.message));
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return const Left(NetworkFailure());
    }
  }
}
