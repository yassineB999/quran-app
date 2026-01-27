import 'package:dartz/dartz.dart';
import 'package:quranapp/core/error/failures.dart';
import 'package:quranapp/features/hadith/domain/entities/hadith.dart';
import 'package:quranapp/features/hadith/domain/entities/hadith_edition.dart';

abstract class HadithRepository {
  Future<Either<Failure, List<HadithEdition>>> getEditions();
  Future<Either<Failure, List<Hadith>>> getHadiths(String editionId);
}
