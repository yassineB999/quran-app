import 'package:dartz/dartz.dart';
import 'package:quranapp/core/error/failures.dart';
import 'package:quranapp/features/qiblah/domain/entities/user_location.dart';
import 'package:quranapp/features/qiblah/domain/repositories/qiblah_repository.dart';

class GetLocationStream {
  final QiblahRepository repository;

  GetLocationStream(this.repository);

  Stream<Either<Failure, UserLocation>> call() {
    return repository.getLocationStream();
  }
}
