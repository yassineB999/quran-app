import 'package:dartz/dartz.dart';
import 'package:quranapp/core/error/failures.dart';
import 'package:quranapp/core/usecases/usecase.dart';
import 'package:quranapp/features/quran/domain/entities/surah.dart';
import 'package:quranapp/features/quran/domain/repositories/quran_repository.dart';

class GetAllSurahs implements UseCase<List<Surah>, NoParams> {
  final QuranRepository repository;

  GetAllSurahs(this.repository);

  @override
  Future<Either<Failure, List<Surah>>> call(NoParams params) async {
    return await repository.getSurahs();
  }
}
