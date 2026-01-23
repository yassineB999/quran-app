import 'package:dartz/dartz.dart';
import 'package:quranapp/core/error/failures.dart';
import 'package:quranapp/features/qiblah/domain/entities/nearby_mosque.dart';
import 'package:quranapp/features/qiblah/domain/entities/user_location.dart';
import 'package:quranapp/features/qiblah/domain/repositories/qiblah_repository.dart';

class GetNearbyMosques {
  final QiblahRepository repository;

  GetNearbyMosques(this.repository);

  Future<Either<Failure, List<NearbyMosque>>> call(UserLocation location) {
    return repository.getNearbyMosques(location: location);
  }
}
