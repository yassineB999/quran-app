import 'package:dartz/dartz.dart';
import 'package:quranapp/core/error/failures.dart';

abstract class UseCase<ResultType, Params> {
  Future<Either<Failure, ResultType>> call(Params params);
}

class NoParams {}
