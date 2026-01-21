import 'package:dartz/dartz.dart';
import 'package:quranapp/core/error/failures.dart';
import 'package:quranapp/core/usecases/usecase.dart';
import 'package:quranapp/features/home/domain/entities/hijri_date.dart';
import 'package:quranapp/features/home/domain/repositories/home_repository.dart';

class GetHijriDate implements UseCase<HijriDate, GetHijriDateParams> {
  final HomeRepository repository;

  GetHijriDate(this.repository);

  @override
  Future<Either<Failure, HijriDate>> call(GetHijriDateParams params) {
    return repository.getHijriDate(params.date);
  }
}

class GetHijriDateParams {
  final DateTime date;

  GetHijriDateParams(this.date);
}
