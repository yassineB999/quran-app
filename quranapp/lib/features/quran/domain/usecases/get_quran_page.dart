import 'package:dartz/dartz.dart';
import 'package:quranapp/core/error/failures.dart';
import 'package:quranapp/features/quran/domain/entities/surah.dart';
import 'package:quranapp/features/quran/domain/repositories/quran_repository.dart';

class GetQuranPage {
  final QuranRepository repository;

  GetQuranPage(this.repository);

  Future<Either<Failure, List<Verse>>> call(int page) async {
    return await repository.getQuranPage(page);
  }
}
