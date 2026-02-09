import 'package:equatable/equatable.dart';
import 'package:quranapp/core/error/failures.dart';
import 'package:quranapp/features/adhkar/domain/entities/adhkar.dart';

abstract class AdhkarState extends Equatable {
  const AdhkarState();

  @override
  List<Object> get props => [];
}

class AdhkarInitial extends AdhkarState {}

class AdhkarLoading extends AdhkarState {}

class AdhkarLoaded extends AdhkarState {
  final List<Adhkar> adhkarList;
  final String category;
  final String title;

  const AdhkarLoaded({
    required this.adhkarList,
    required this.category,
    required this.title,
  });

  @override
  List<Object> get props => [adhkarList, category, title];
}

class AdhkarError extends AdhkarState {
  final Failure failure;

  const AdhkarError(this.failure);

  @override
  List<Object> get props => [failure];
}
