import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  const Failure([this.message = 'Unexpected Error']);

  @override
  List<Object?> get props => [message];
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Une erreur est survenue']);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Cache Failure']);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Pas de connexion Internet']);
}

class ValidationFailure extends Failure {
  final Map<String, dynamic> errors;

  const ValidationFailure({
    String message = 'Validation error',
    required this.errors,
  }) : super(message);

  @override
  List<Object?> get props => [message, errors];
}
