import 'package:dartz/dartz.dart';
import 'package:quranapp/core/error/failures.dart';
import 'package:quranapp/core/location/domain/entities/user_location.dart';
import 'package:quranapp/features/mosques/domain/entities/mosque.dart';
import 'package:quranapp/features/mosques/domain/repositories/mosque_repository.dart';

class GetNearbyMosques {
  final MosqueRepository repository;

  GetNearbyMosques(this.repository);

  Future<Either<Failure, List<Mosque>>> call({required UserLocation location}) {
    return repository.getNearbyMosques(location: location);
  }
}
