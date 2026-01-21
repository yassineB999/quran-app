import 'package:dartz/dartz.dart';
import 'package:quranapp/core/error/exceptions.dart';
import 'package:quranapp/core/error/failures.dart';
import 'package:quranapp/core/network/network_info.dart';
import 'package:quranapp/features/home/data/datasources/home_remote_data_source.dart';
import 'package:quranapp/features/home/domain/entities/daily_hadith.dart';
import 'package:quranapp/features/home/domain/entities/hijri_date.dart';
import 'package:quranapp/features/home/domain/repositories/home_repository.dart';

class HomeRepositoryImpl implements HomeRepository {
  final HomeRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  HomeRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, DailyHadith>> getDailyHadith() async {
    if (await networkInfo.isConnected) {
      try {
        final hadith = await remoteDataSource.getDailyHadith();
        return Right(hadith);
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
  Future<Either<Failure, HijriDate>> getHijriDate(DateTime date) async {
    if (await networkInfo.isConnected) {
      try {
        final hijriDate = await remoteDataSource.getHijriDate(date);
        return Right(hijriDate);
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
