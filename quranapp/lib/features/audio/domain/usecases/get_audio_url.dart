import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:quranapp/core/error/failures.dart';
import 'package:quranapp/core/usecases/usecase.dart';
import 'package:quranapp/features/audio/domain/entities/audio_info.dart';
import 'package:quranapp/features/audio/domain/repositories/reciter_repository.dart';

/// Use case to get audio URL for a reciter and surah
class GetAudioUrl implements UseCase<AudioInfo, GetAudioUrlParams> {
  final ReciterRepository repository;

  GetAudioUrl(this.repository);

  @override
  Future<Either<Failure, AudioInfo>> call(GetAudioUrlParams params) {
    return repository.getAudioUrl(params.reciterId, params.surahId);
  }
}

class GetAudioUrlParams extends Equatable {
  final int reciterId;
  final int surahId;

  const GetAudioUrlParams({required this.reciterId, required this.surahId});

  @override
  List<Object?> get props => [reciterId, surahId];
}
