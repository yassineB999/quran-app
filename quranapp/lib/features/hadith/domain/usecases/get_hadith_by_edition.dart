import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:quranapp/core/error/failures.dart';
import 'package:quranapp/core/usecases/usecase.dart';
import 'package:quranapp/features/hadith/domain/entities/hadith.dart';
import 'package:quranapp/features/hadith/domain/repositories/hadith_repository.dart';

class GetHadithByEdition
    implements UseCase<List<Hadith>, GetHadithByEditionParams> {
  final HadithRepository repository;

  GetHadithByEdition(this.repository);

  @override
  Future<Either<Failure, List<Hadith>>> call(
    GetHadithByEditionParams params,
  ) async {
    return await repository.getHadiths(params.editionId);
  }
}

class GetHadithByEditionParams extends Equatable {
  final String editionId;

  const GetHadithByEditionParams({required this.editionId});

  @override
  List<Object?> get props => [editionId];
}
