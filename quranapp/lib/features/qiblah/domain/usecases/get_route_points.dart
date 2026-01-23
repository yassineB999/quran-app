import 'package:dartz/dartz.dart';
import 'package:quranapp/core/error/failures.dart';
import 'package:quranapp/features/qiblah/domain/entities/route_point.dart';
import 'package:quranapp/features/qiblah/domain/entities/user_location.dart';
import 'package:quranapp/features/qiblah/domain/repositories/qiblah_repository.dart';

class GetRoutePoints {
  final QiblahRepository repository;

  GetRoutePoints(this.repository);

  Future<Either<Failure, List<RoutePoint>>> call({
    required UserLocation origin,
    required UserLocation destination,
  }) {
    return repository.getRoutePoints(
      origin: origin,
      destination: destination,
    );
  }
}
