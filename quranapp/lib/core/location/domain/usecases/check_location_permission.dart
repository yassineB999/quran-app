import 'package:dartz/dartz.dart';
import 'package:quranapp/core/error/failures.dart';
import 'package:quranapp/core/location/domain/repositories/location_repository.dart';

class CheckLocationPermission {
  final LocationRepository repository;

  CheckLocationPermission(this.repository);

  Future<Either<Failure, bool>> call() {
    return repository.checkLocationPermission();
  }
}
