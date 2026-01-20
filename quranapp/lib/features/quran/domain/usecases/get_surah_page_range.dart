import 'package:dartz/dartz.dart';
import 'package:quranapp/core/error/failures.dart';
import 'package:quranapp/core/usecases/usecase.dart';
import 'package:quranapp/features/quran/domain/entities/surah_page_range.dart';
import 'package:quranapp/features/quran/domain/repositories/quran_repository.dart';

/// Use case to get the page range for a specific surah.
/// Returns the first and last page where the surah appears.
class GetSurahPageRange extends UseCase<SurahPageRange, int> {
  final QuranRepository repository;

  GetSurahPageRange(this.repository);

  @override
  Future<Either<Failure, SurahPageRange>> call(int surahId) async {
    return await repository.getSurahPageRange(surahId);
  }
}
