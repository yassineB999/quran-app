import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:quranapp/core/error/failures.dart';
import 'package:quranapp/core/usecases/usecase.dart';
import 'package:quranapp/features/quran/domain/entities/surah.dart';
import 'package:quranapp/features/quran/domain/repositories/quran_repository.dart';

class GetSurahDetail implements UseCase<Surah, GetSurahDetailParams> {
  final QuranRepository repository;

  GetSurahDetail(this.repository);

  @override
  Future<Either<Failure, Surah>> call(GetSurahDetailParams params) async {
    return await repository.getSurah(params.id);
  }
}

class GetSurahDetailParams extends Equatable {
  final int id;

  const GetSurahDetailParams({required this.id});

  @override
  List<Object?> get props => [id];
}
