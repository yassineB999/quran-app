import 'package:equatable/equatable.dart';

class HijriDate extends Equatable {
  final String day;
  final String month;
  final String year;

  const HijriDate({
    required this.day,
    required this.month,
    required this.year,
  });

  @override
  List<Object?> get props => [day, month, year];
}
