import 'package:dartz/dartz.dart';
import 'package:quranapp/core/error/failures.dart';
import 'package:quranapp/core/error/exceptions.dart';
import 'package:quranapp/core/network/network_info.dart';
import 'package:quranapp/features/qiblah/data/datasources/qiblah_local_data_source.dart';
import 'package:quranapp/features/qiblah/data/datasources/qiblah_remote_data_source.dart';
import 'package:quranapp/features/qiblah/domain/entities/qiblah_direction.dart';
import 'package:quranapp/features/qiblah/domain/repositories/qiblah_repository.dart';

class QiblahRepositoryImpl implements QiblahRepository {
  final QiblahLocalDataSource localDataSource;
  final QiblahRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  QiblahRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
    required this.networkInfo,
  });

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
}
