import 'package:dartz/dartz.dart';
import 'package:quranapp/core/error/failures.dart';
import 'package:quranapp/core/location/domain/entities/user_location.dart';
import 'package:quranapp/features/mosques/domain/entities/route_point.dart';
import 'package:quranapp/features/mosques/domain/repositories/mosque_repository.dart';

class GetRouteToMosque {
  final MosqueRepository repository;

  GetRouteToMosque(this.repository);

  Future<Either<Failure, List<RoutePoint>>> call({
    required UserLocation origin,
    required UserLocation destination,
  }) {
    return repository.getRouteToMosque(
      origin: origin,
      destination: destination,
    );
  }
}
