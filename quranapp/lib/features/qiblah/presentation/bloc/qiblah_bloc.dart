import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quranapp/features/qiblah/domain/usecases/get_qiblah_stream.dart';
import 'package:quranapp/features/qiblah/presentation/bloc/qiblah_state.dart';

class QiblahBloc extends Bloc<QiblahEvent, QiblahState> {
  final GetQiblahStream getQiblahStream;
  StreamSubscription? _qiblahSubscription;

  QiblahBloc({required this.getQiblahStream}) : super(QiblahInitial()) {
    on<InitQiblahEvent>(_onInitQiblah);
    on<UpdateQiblahEvent>(_onUpdateQiblah);
    on<QiblahErrorEvent>(_onQiblahError);
  }

  Future<void> _onInitQiblah(
    InitQiblahEvent event,
    Emitter<QiblahState> emit,
  ) async {
    emit(QiblahLoading());
    await _qiblahSubscription?.cancel();

    final stream = getQiblahStream();
    _qiblahSubscription = stream.listen((result) {
      result.fold(
        (failure) => add(QiblahErrorEvent(failure)),
        (direction) => add(UpdateQiblahEvent(direction)),
      );
    });
  }

  void _onUpdateQiblah(UpdateQiblahEvent event, Emitter<QiblahState> emit) {
    emit(QiblahLoaded(event.direction));
  }

  void _onQiblahError(QiblahErrorEvent event, Emitter<QiblahState> emit) {
    emit(QiblahError(event.failure));
  }

  @override
  Future<void> close() {
    _qiblahSubscription?.cancel();
    return super.close();
  }
}
