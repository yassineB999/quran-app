import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quranapp/core/usecases/usecase.dart';
import 'package:quranapp/features/home/domain/usecases/get_daily_hadith.dart';
import 'package:quranapp/features/home/domain/usecases/get_hijri_date.dart';
import 'package:quranapp/features/home/presentation/bloc/home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  final GetDailyHadith getDailyHadith;
  final GetHijriDate getHijriDate;

  HomeCubit({
    required this.getDailyHadith,
    required this.getHijriDate,
  }) : super(HomeState.initial());

  Future<void> load() async {
    await Future.wait([
      _loadHadith(),
      _loadHijriDate(),
    ]);
  }

  Future<void> _loadHadith() async {
    _emitIfOpen(state.copyWith(isHadithLoading: true, hadithError: null));
    final result = await getDailyHadith(NoParams());
    result.fold(
      (failure) => _emitIfOpen(
        state.copyWith(
          isHadithLoading: false,
          hadithError: failure.message,
        ),
      ),
      (hadith) => _emitIfOpen(
        state.copyWith(
          isHadithLoading: false,
          dailyHadith: hadith,
          hadithError: null,
        ),
      ),
    );
  }

  Future<void> _loadHijriDate() async {
    _emitIfOpen(state.copyWith(isHijriLoading: true, hijriError: null));
    final result = await getHijriDate(GetHijriDateParams(DateTime.now()));
    result.fold(
      (failure) => _emitIfOpen(
        state.copyWith(
          isHijriLoading: false,
          hijriError: failure.message,
        ),
      ),
      (date) => _emitIfOpen(
        state.copyWith(
          isHijriLoading: false,
          hijriDate: date,
          hijriError: null,
        ),
      ),
    );
  }

  void _emitIfOpen(HomeState nextState) {
    if (isClosed) return;
    emit(nextState);
  }
}
