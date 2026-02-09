import 'package:equatable/equatable.dart';
import 'package:quranapp/core/error/failures.dart';
import 'package:quranapp/features/qiblah/domain/entities/qiblah_direction.dart';

abstract class QiblahEvent extends Equatable {
  const QiblahEvent();
  @override
  List<Object?> get props => [];
}

class InitQiblahEvent extends QiblahEvent {}

class UpdateQiblahEvent extends QiblahEvent {
  final QiblahDirection direction;
  const UpdateQiblahEvent(this.direction);
  @override
  List<Object?> get props => [direction];
}

class QiblahErrorEvent extends QiblahEvent {
  final Failure failure;
  const QiblahErrorEvent(this.failure);
  @override
  List<Object?> get props => [failure];
}

// States
abstract class QiblahState extends Equatable {
  const QiblahState();
  @override
  List<Object?> get props => [];
}

class QiblahInitial extends QiblahState {}

class QiblahLoading extends QiblahState {}

class QiblahLoaded extends QiblahState {
  final QiblahDirection direction;
  const QiblahLoaded(this.direction);
  @override
  List<Object?> get props => [direction];
}

class QiblahError extends QiblahState {
  final Failure failure;
  const QiblahError(this.failure);
  @override
  List<Object?> get props => [failure];
}
