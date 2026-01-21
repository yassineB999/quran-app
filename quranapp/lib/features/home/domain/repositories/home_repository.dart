import 'package:dartz/dartz.dart';
import 'package:quranapp/core/error/failures.dart';
import 'package:quranapp/features/home/domain/entities/daily_hadith.dart';
import 'package:quranapp/features/home/domain/entities/hijri_date.dart';

abstract class HomeRepository {
  Future<Either<Failure, DailyHadith>> getDailyHadith();
  Future<Either<Failure, HijriDate>> getHijriDate(DateTime date);
}
