import 'package:dartz/dartz.dart';
import 'package:quranapp/core/error/failures.dart';
import 'package:quranapp/features/adhkar/domain/entities/adhkar.dart';

abstract class AdhkarRepository {
  Future<Either<Failure, List<Adhkar>>> getAdhkar(String category);
}
