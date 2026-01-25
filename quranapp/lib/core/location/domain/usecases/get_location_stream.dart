import 'package:dartz/dartz.dart';
import 'package:quranapp/core/error/failures.dart';
import 'package:quranapp/core/location/domain/entities/user_location.dart';
import 'package:quranapp/core/location/domain/repositories/location_repository.dart';

class GetLocationStream {
  final LocationRepository repository;

  GetLocationStream(this.repository);

  Stream<Either<Failure, UserLocation>> call() {
    return repository.getLocationStream();
  }
}
