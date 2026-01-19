import 'package:dartz/dartz.dart';
import 'package:quranapp/core/error/failures.dart';
import 'package:quranapp/core/usecases/usecase.dart';
import 'package:quranapp/features/audio/domain/entities/reciter.dart';
import 'package:quranapp/features/audio/domain/repositories/reciter_repository.dart';

/// Use case to get all available reciters
class GetReciters implements UseCase<List<Reciter>, NoParams> {
  final ReciterRepository repository;

  GetReciters(this.repository);

  @override
  Future<Either<Failure, List<Reciter>>> call(NoParams params) {
    return repository.getReciters();
  }
}
