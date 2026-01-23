import 'package:dartz/dartz.dart';
import 'package:quranapp/core/error/failures.dart';
import 'package:quranapp/features/qiblah/domain/repositories/qiblah_repository.dart';

class CheckLocationPermission {
  final QiblahRepository repository;

  CheckLocationPermission(this.repository);

  Future<Either<Failure, bool>> call() {
    return repository.checkLocationPermission();
  }
}
