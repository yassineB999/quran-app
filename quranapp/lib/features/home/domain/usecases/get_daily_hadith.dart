import 'package:dartz/dartz.dart';
import 'package:quranapp/core/error/failures.dart';
import 'package:quranapp/core/usecases/usecase.dart';
import 'package:quranapp/features/home/domain/entities/daily_hadith.dart';
import 'package:quranapp/features/home/domain/repositories/home_repository.dart';

class GetDailyHadith implements UseCase<DailyHadith, NoParams> {
  final HomeRepository repository;

  GetDailyHadith(this.repository);

  @override
  Future<Either<Failure, DailyHadith>> call(NoParams params) {
    return repository.getDailyHadith();
  }
}
