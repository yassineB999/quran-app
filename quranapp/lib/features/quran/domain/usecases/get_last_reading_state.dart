import 'package:dartz/dartz.dart';
import 'package:quranapp/core/error/failures.dart';
import 'package:quranapp/core/usecases/usecase.dart';
import 'package:quranapp/features/quran/domain/repositories/quran_repository.dart';

class ReadingState {
  final String mode; // 'page' or 'surah'
  final int? page;
  final int? surahId;

  ReadingState({required this.mode, this.page, this.surahId});
}

class GetLastReadingState implements UseCase<ReadingState, NoParams> {
  final QuranRepository repository;

  GetLastReadingState(this.repository);

  @override
  Future<Either<Failure, ReadingState>> call(NoParams params) async {
    final modeResult = await repository.getReadingMode();
    final pageResult = await repository.getLastPage();
    final surahResult = await repository.getLastSurah();

    String mode = 'page'; // Default
    int? page = 1;
    int? surahId = 1;

    modeResult.fold((l) => null, (r) => mode = r ?? 'page');
    pageResult.fold((l) => null, (r) => page = r);
    surahResult.fold((l) => null, (r) => surahId = r);

    return Right(ReadingState(mode: mode, page: page, surahId: surahId));
  }
}
