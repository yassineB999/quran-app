import 'package:dartz/dartz.dart';
import 'package:quranapp/core/error/exceptions.dart';
import 'package:quranapp/core/error/failures.dart';
import 'package:quranapp/features/qiblah/data/datasources/qiblah_local_data_source.dart';
import 'package:quranapp/features/qiblah/domain/entities/qiblah_direction.dart';
import 'package:quranapp/features/qiblah/domain/repositories/qiblah_repository.dart';

class QiblahRepositoryImpl implements QiblahRepository {
  final QiblahLocalDataSource localDataSource;

  QiblahRepositoryImpl({required this.localDataSource});

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
}
