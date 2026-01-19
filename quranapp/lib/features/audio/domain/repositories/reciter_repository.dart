import 'package:dartz/dartz.dart';
import 'package:quranapp/core/error/failures.dart';
import 'package:quranapp/features/audio/domain/entities/reciter.dart';
import 'package:quranapp/features/audio/domain/entities/audio_info.dart';

import 'package:quranapp/features/audio/domain/entities/recitation_result.dart';

/// Abstract repository for reciter and audio operations
abstract class ReciterRepository {
  /// Get all available reciters
  Future<Either<Failure, List<Reciter>>> getReciters();

  /// Get audio URL for a specific reciter and surah
  Future<Either<Failure, AudioInfo>> getAudioUrl(int reciterId, int surahId);

  /// Check recitation audio
  Future<Either<Failure, RecitationResult>> checkRecitation(String filePath, int surahId, int ayahId);
}
