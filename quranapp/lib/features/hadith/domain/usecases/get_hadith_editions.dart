import 'package:dartz/dartz.dart';
import 'package:quranapp/core/error/failures.dart';
import 'package:quranapp/core/usecases/usecase.dart';
import 'package:quranapp/features/hadith/domain/entities/hadith_edition.dart';
import 'package:quranapp/features/hadith/domain/repositories/hadith_repository.dart';

class GetHadithEditions implements UseCase<List<HadithEdition>, NoParams> {
  final HadithRepository repository;

  GetHadithEditions(this.repository);

  @override
  Future<Either<Failure, List<HadithEdition>>> call(NoParams params) async {
    return await repository.getEditions();
  }
}
