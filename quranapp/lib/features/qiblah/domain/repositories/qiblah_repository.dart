import 'package:dartz/dartz.dart';
import 'package:quranapp/core/error/failures.dart';
import 'package:quranapp/features/qiblah/domain/entities/qiblah_direction.dart';

abstract class QiblahRepository {
  /// Stream of Qiblah direction updates (heading + calculated bearing)
  Stream<Either<Failure, QiblahDirection>> getQiblahStream();
}
