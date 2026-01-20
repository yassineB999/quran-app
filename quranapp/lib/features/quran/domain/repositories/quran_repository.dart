import 'package:dartz/dartz.dart';
import 'package:quranapp/core/error/failures.dart';
import 'package:quranapp/features/quran/domain/entities/surah.dart';
import 'package:quranapp/features/quran/domain/entities/surah_page_range.dart';

abstract class QuranRepository {
  Future<Either<Failure, List<Surah>>> getSurahs();
  Future<Either<Failure, Surah>> getSurah(int id);
  Future<Either<Failure, List<Verse>>> getQuranPage(int page);
  Future<Either<Failure, SurahPageRange>> getSurahPageRange(int surahId);
  Future<Either<Failure, void>> saveLastPage(int page);
  Future<Either<Failure, int?>> getLastPage();
  Future<Either<Failure, int?>> getLastSurah();
  Future<Either<Failure, void>> saveLastSurah(int surahId);
  Future<Either<Failure, String?>> getReadingMode();
  Future<Either<Failure, void>> saveReadingMode(String mode);
}
