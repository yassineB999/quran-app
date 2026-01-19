import 'package:dartz/dartz.dart';
import 'package:quranapp/core/error/failures.dart';
import 'package:quranapp/core/usecases/usecase.dart';
import 'package:quranapp/features/quran/domain/repositories/quran_repository.dart';

class SaveReadingStateParams {
  final String mode; // 'page' or 'surah'
  final int? page;
  final int? surahId;

  SaveReadingStateParams({required this.mode, this.page, this.surahId});
}

class SaveReadingState implements UseCase<void, SaveReadingStateParams> {
  final QuranRepository repository;

  SaveReadingState(this.repository);

  @override
  Future<Either<Failure, void>> call(SaveReadingStateParams params) async {
    await repository.saveReadingMode(params.mode);
    if (params.page != null) {
      await repository.saveLastPage(params.page!);
    }
    if (params.surahId != null) {
      await repository.saveLastSurah(params.surahId!);
    }
    return const Right(null);
  }
}
