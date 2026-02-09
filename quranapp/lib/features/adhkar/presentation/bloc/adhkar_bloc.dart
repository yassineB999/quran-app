import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quranapp/core/network/connectivity_service.dart';
import 'package:quranapp/features/adhkar/domain/usecases/get_adhkar_by_category.dart';
import 'package:quranapp/features/adhkar/presentation/bloc/adhkar_event.dart';
import 'package:quranapp/features/adhkar/presentation/bloc/adhkar_state.dart';

class AdhkarBloc extends Bloc<AdhkarEvent, AdhkarState> {
  final GetAdhkarByCategory getAdhkarByCategory;

  final ConnectivityService connectivityService;
  StreamSubscription? _connectivitySubscription;
  AdhkarEvent? _lastEvent;

  AdhkarBloc({
    required this.getAdhkarByCategory,
    required this.connectivityService,
  }) : super(AdhkarInitial()) {
    on<GetAdhkarByCategoryEvent>(_onGetAdhkarByCategory);
    _setupAutoRetry();
  }

  void _setupAutoRetry() {
    _connectivitySubscription = connectivityService.stateStream.listen((state) {
      if (state is ConnectivityOnline) {
        if (this.state is AdhkarError && _lastEvent != null) {
          add(_lastEvent!);
        }
      }
    });
  }

  Future<void> _onGetAdhkarByCategory(
    GetAdhkarByCategoryEvent event,
    Emitter<AdhkarState> emit,
  ) async {
    _lastEvent = event;
    emit(AdhkarLoading());

    final result = await getAdhkarByCategory(
      GetAdhkarParams(category: event.category),
    );

    result.fold(
      (failure) => emit(AdhkarError(failure)),
      (adhkarList) => emit(
        AdhkarLoaded(
          adhkarList: adhkarList,
          category: event.category,
          title: _getTitleForCategory(event.category),
        ),
      ),
    );
  }

  String _getTitleForCategory(String category) {
    switch (category) {
      case 'morning':
        return 'أذكار الصباح';
      case 'evening':
        return 'أذكار المساء';
      case 'bedtime':
        return 'أذكار النوم';
      default:
        return 'الأذكار';
    }
  }

  @override
  Future<void> close() {
    _connectivitySubscription?.cancel();
    return super.close();
  }
}
