import 'package:dartz/dartz.dart';
import 'package:quranapp/core/error/failures.dart';
import 'package:quranapp/core/usecases/usecase.dart';
import 'package:quranapp/features/quran/domain/repositories/quran_repository.dart';

class GetReadingProgress implements UseCase<int?, NoParams> {
  final QuranRepository repository;

  GetReadingProgress(this.repository);

  @override
  Future<Either<Failure, int?>> call(NoParams params) async {
    return await repository.getLastPage();
  }
}
