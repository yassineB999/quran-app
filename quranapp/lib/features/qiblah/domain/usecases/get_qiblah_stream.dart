import 'package:dartz/dartz.dart';
import 'package:quranapp/core/error/failures.dart';

import 'package:quranapp/features/qiblah/domain/entities/qiblah_direction.dart';
import 'package:quranapp/features/qiblah/domain/repositories/qiblah_repository.dart';

class GetQiblahStream {
  final QiblahRepository repository;

  GetQiblahStream(this.repository);

  Stream<Either<Failure, QiblahDirection>> call() {
    return repository.getQiblahStream();
  }
}
