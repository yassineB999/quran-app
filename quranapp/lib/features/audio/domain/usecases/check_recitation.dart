import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:quranapp/core/error/failures.dart';
import 'package:quranapp/core/usecases/usecase.dart';
import 'package:quranapp/features/audio/domain/entities/recitation_result.dart';
import 'package:quranapp/features/audio/domain/repositories/reciter_repository.dart';

class CheckRecitation implements UseCase<RecitationResult, CheckRecitationParams> {
  final ReciterRepository repository;

  CheckRecitation(this.repository);

  @override
  Future<Either<Failure, RecitationResult>> call(CheckRecitationParams params) async {
    return await repository.checkRecitation(
      params.filePath,
      params.surahId,
      params.ayahId,
    );
  }
}

class CheckRecitationParams extends Equatable {
  final String filePath;
  final int surahId;
  final int ayahId;

  const CheckRecitationParams({
    required this.filePath,
    required this.surahId,
    required this.ayahId,
  });

  @override
  List<Object?> get props => [filePath, surahId, ayahId];
}
