import 'package:equatable/equatable.dart';

abstract class AdhkarEvent extends Equatable {
  const AdhkarEvent();

  @override
  List<Object?> get props => [];
}

class GetAdhkarByCategoryEvent extends AdhkarEvent {
  final String category;

  const GetAdhkarByCategoryEvent(this.category);

  @override
  List<Object?> get props => [category];
}
