import 'package:dartz/dartz.dart';
import 'package:quranapp/core/error/failures.dart';
import 'package:quranapp/features/qiblah/domain/entities/user_location.dart';
import 'package:quranapp/features/qiblah/domain/repositories/qiblah_repository.dart';

class GetCurrentLocation {
  final QiblahRepository repository;

  GetCurrentLocation(this.repository);

  Future<Either<Failure, UserLocation>> call() {
    return repository.getCurrentLocation();
  }
}
