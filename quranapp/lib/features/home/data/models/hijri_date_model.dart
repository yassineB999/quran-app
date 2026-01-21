import 'package:quranapp/features/home/domain/entities/hijri_date.dart';

class HijriDateModel extends HijriDate {
  const HijriDateModel({
    required super.day,
    required super.month,
    required super.year,
  });

  factory HijriDateModel.fromParts({
    required String day,
    required String month,
    required String year,
  }) {
    return HijriDateModel(
      day: day,
      month: month,
      year: year,
    );
  }
}
