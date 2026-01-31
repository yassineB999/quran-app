import 'package:quranapp/core/error/failures.dart';

/// Helper class to map failures to user-friendly French error messages
class ErrorMessageMapper {
  static String mapFailureToMessage(Failure failure) {
    switch (failure) {
      case NetworkFailure():
        // Check if it's a timeout (slow backend) or connection issue
        if (failure.message.contains('temps') ||
            failure.message.contains('prévu')) {
          return 'Le serveur met plus de temps que prévu';
        }
        return 'Pas de connexion Internet';

      case ServerFailure():
        if (failure.message.contains('Impossible de se connecter')) {
          return 'Impossible de se connecter pour le moment';
        }
        return 'Une erreur est survenue. Veuillez réessayer plus tard.';

      case CacheFailure():
        return 'Erreur de stockage local';

      case ValidationFailure():
        return 'Données invalides';

      default:
        return 'Une erreur est survenue';
    }
  }
}
