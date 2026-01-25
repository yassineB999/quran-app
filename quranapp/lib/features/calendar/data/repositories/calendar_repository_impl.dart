import 'package:dartz/dartz.dart';
import 'package:quranapp/core/error/exceptions.dart';
import 'package:quranapp/core/error/failures.dart';
import 'package:quranapp/core/network/network_info.dart';
import 'package:quranapp/features/calendar/data/datasources/calendar_remote_data_source.dart';
import 'package:quranapp/features/calendar/domain/entities/hijri_calendar_day.dart';
import 'package:quranapp/features/calendar/domain/repositories/calendar_repository.dart';

/// Implementation of CalendarRepository.
class CalendarRepositoryImpl implements CalendarRepository {
  final CalendarRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  CalendarRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, HijriCalendarMonth>> getCalendarMonth({
    required int year,
    required int month,
    bool refresh = false,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }

    try {
      final result = await remoteDataSource.getCalendarMonth(
        year: year,
        month: month,
        refresh: refresh,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
