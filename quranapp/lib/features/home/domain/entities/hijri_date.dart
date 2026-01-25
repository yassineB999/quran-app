import 'package:equatable/equatable.dart';

class HijriDate extends Equatable {
  final String day;
  final String month;
  final String year;
  final String weekdayEn;
  final String weekdayAr;

  const HijriDate({
    required this.day,
    required this.month,
    required this.year,
    required this.weekdayEn,
    required this.weekdayAr,
  });

  @override
  List<Object?> get props => [day, month, year, weekdayEn, weekdayAr];
}
