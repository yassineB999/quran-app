import 'package:equatable/equatable.dart';
import 'package:quranapp/features/home/domain/entities/daily_hadith.dart';
import 'package:quranapp/features/home/domain/entities/hijri_date.dart';

class HomeState extends Equatable {
  final DailyHadith? dailyHadith;
  final HijriDate? hijriDate;
  final bool isHadithLoading;
  final bool isHijriLoading;
  final String? hadithError;
  final String? hijriError;

  const HomeState({
    this.dailyHadith,
    this.hijriDate,
    this.isHadithLoading = false,
    this.isHijriLoading = false,
    this.hadithError,
    this.hijriError,
  });

  factory HomeState.initial() {
    return const HomeState(isHadithLoading: true, isHijriLoading: true);
  }

  HomeState copyWith({
    DailyHadith? dailyHadith,
    HijriDate? hijriDate,
    bool? isHadithLoading,
    bool? isHijriLoading,
    String? hadithError,
    String? hijriError,
  }) {
    return HomeState(
      dailyHadith: dailyHadith ?? this.dailyHadith,
      hijriDate: hijriDate ?? this.hijriDate,
      isHadithLoading: isHadithLoading ?? this.isHadithLoading,
      isHijriLoading: isHijriLoading ?? this.isHijriLoading,
      hadithError: hadithError,
      hijriError: hijriError,
    );
  }

  @override
  List<Object?> get props => [
    dailyHadith,
    hijriDate,
    isHadithLoading,
    isHijriLoading,
    hadithError,
    hijriError,
  ];
}
