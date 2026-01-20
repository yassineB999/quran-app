import 'package:dartz/dartz.dart';
import 'package:quranapp/core/error/exceptions.dart';
import 'package:quranapp/core/error/failures.dart';
import 'package:quranapp/features/quran/data/datasources/quran_local_data_source.dart';
import 'package:quranapp/features/quran/data/datasources/quran_remote_data_source.dart';
import 'package:quranapp/features/quran/domain/entities/surah.dart';
import 'package:quranapp/features/quran/domain/entities/surah_page_range.dart';
import 'package:quranapp/features/quran/domain/repositories/quran_repository.dart';
import 'package:quranapp/core/network/network_info.dart';

class QuranRepositoryImpl implements QuranRepository {
  final QuranRemoteDataSource remoteDataSource;
  final QuranLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  QuranRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<Surah>>> getSurahs() async {
    if (await networkInfo.isConnected) {
      try {
        final remoteSurahs = await remoteDataSource.getSurahs();
        return Right(remoteSurahs);
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
  Future<Either<Failure, Surah>> getSurah(int id) async {
    if (await networkInfo.isConnected) {
      try {
        final remoteSurah = await remoteDataSource.getSurah(id);
        return Right(remoteSurah);
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
  Future<Either<Failure, List<Verse>>> getQuranPage(int page) async {
    if (await networkInfo.isConnected) {
      try {
        final remoteVerses = await remoteDataSource.getQuranPage(page);
        return Right(remoteVerses);
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
  Future<Either<Failure, SurahPageRange>> getSurahPageRange(int surahId) async {
    if (await networkInfo.isConnected) {
      try {
        final pageRange = await remoteDataSource.getSurahPageRange(surahId);
        return Right(pageRange);
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
  Future<Either<Failure, int?>> getLastPage() async {
    try {
      final page = await localDataSource.getLastPage();
      return Right(page);
    } catch (e) {
      return const Left(CacheFailure('Failed to load last page'));
    }
  }

  @override
  Future<Either<Failure, void>> saveLastPage(int page) async {
    try {
      await localDataSource.saveLastPage(page);
      return const Right(null);
    } catch (e) {
      return const Left(CacheFailure('Failed to save last page'));
    }
  }

  @override
  Future<Either<Failure, int?>> getLastSurah() async {
    try {
      final surahId = await localDataSource.getLastSurah();
      return Right(surahId);
    } catch (e) {
      return const Left(CacheFailure('Failed to load last surah'));
    }
  }

  @override
  Future<Either<Failure, void>> saveLastSurah(int surahId) async {
    try {
      await localDataSource.saveLastSurah(surahId);
      return const Right(null);
    } catch (e) {
      return const Left(CacheFailure('Failed to save last surah'));
    }
  }

  @override
  Future<Either<Failure, String?>> getReadingMode() async {
    try {
      final mode = await localDataSource.getReadingMode();
      return Right(mode);
    } catch (e) {
      return const Left(CacheFailure('Failed to load reading mode'));
    }
  }

  @override
  Future<Either<Failure, void>> saveReadingMode(String mode) async {
    try {
      await localDataSource.saveReadingMode(mode);
      return const Right(null);
    } catch (e) {
      return const Left(CacheFailure('Failed to save reading mode'));
    }
  }
}
