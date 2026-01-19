import 'package:dartz/dartz.dart';
import 'package:quranapp/core/error/failures.dart';
import 'package:quranapp/core/usecases/usecase.dart';
import 'package:quranapp/features/quran/domain/repositories/quran_repository.dart';

class SaveReadingProgress implements UseCase<void, int> {
  final QuranRepository repository;

  SaveReadingProgress(this.repository);

  @override
  Future<Either<Failure, void>> call(int page) async {
    return await repository.saveLastPage(page);
  }
}
