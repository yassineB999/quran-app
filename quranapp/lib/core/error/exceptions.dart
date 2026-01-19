/// Exception thrown when a server error occurs
class ServerException implements Exception {
  final String message;
  final int? statusCode;

  const ServerException({
    this.message = 'Server error occurred',
    this.statusCode,
  });

  @override
  String toString() => 'ServerException: $message (status: $statusCode)';
}

/// Exception thrown when a network connectivity error occurs
class NetworkException implements Exception {
  final String message;

  const NetworkException({required this.message});

  @override
  String toString() => 'NetworkException: $message';
}

/// Exception thrown when validation errors occur (e.g., 400 Bad Request)
class ValidationException implements Exception {
  final Map<String, dynamic> errors;

  const ValidationException(this.errors);

  @override
  String toString() => 'ValidationException: $errors';
}

/// Exception thrown when cache operations fail
class CacheException implements Exception {
  final String message;

  const CacheException({this.message = 'Cache error occurred'});

  @override
  String toString() => 'CacheException: $message';
}
