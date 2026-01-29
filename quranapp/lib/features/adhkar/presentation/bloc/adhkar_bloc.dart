import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quranapp/features/adhkar/domain/usecases/get_adhkar_by_category.dart';
import 'package:quranapp/features/adhkar/presentation/bloc/adhkar_event.dart';
import 'package:quranapp/features/adhkar/presentation/bloc/adhkar_state.dart';

class AdhkarBloc extends Bloc<AdhkarEvent, AdhkarState> {
  final GetAdhkarByCategory getAdhkarByCategory;

  AdhkarBloc({required this.getAdhkarByCategory}) : super(AdhkarInitial()) {
    on<GetAdhkarByCategoryEvent>(_onGetAdhkarByCategory);
  }

  Future<void> _onGetAdhkarByCategory(
    GetAdhkarByCategoryEvent event,
    Emitter<AdhkarState> emit,
  ) async {
    emit(AdhkarLoading());

    final result = await getAdhkarByCategory(
      GetAdhkarParams(category: event.category),
    );

    result.fold(
      (failure) => emit(AdhkarError(failure.message)),
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
}
