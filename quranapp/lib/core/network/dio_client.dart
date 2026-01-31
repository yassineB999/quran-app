import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'api_endpoints.dart';
import '../error/exceptions.dart';

class DioClient {
  late final Dio _dio;

  DioClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: const Duration(
          milliseconds: ApiEndpoints.connectTimeout,
        ),
        receiveTimeout: const Duration(
          milliseconds: ApiEndpoints.receiveTimeout,
        ),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Add interceptors
    _dio.interceptors.add(_LoggingInterceptor());
    _dio.interceptors.add(_ErrorInterceptor());
  }

  Dio get dio => _dio;

  /// Set authorization token for authenticated requests
  void setAuthToken(String token) {
    if (token.isEmpty) {
      _dio.options.headers.remove('Authorization');
      return;
    }
    if (token.startsWith('Token ')) {
      _dio.options.headers['Authorization'] = token;
    } else {
      _dio.options.headers['Authorization'] = 'Token $token';
    }
  }

  /// Remove authorization token
  void clearAuthToken() {
    _dio.options.headers.remove('Authorization');
  }

  /// GET request
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _dio.get<T>(
      path,
      queryParameters: queryParameters,
      options: options,
    );
  }

  /// POST request
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _dio.post<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  /// PUT request
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _dio.put<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  /// DELETE request
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _dio.delete<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }
}

/// Logging interceptor for debugging API calls
class _LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      print('┌─────────────────────────────────────────────────────────');
      print('│ 🚀 REQUEST: ${options.method} ${options.uri}');
      if (options.data != null) {
        print('│ 📦 Body: ${options.data}');
      }
      print('└─────────────────────────────────────────────────────────');
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      print('┌─────────────────────────────────────────────────────────');
      print(
        '│ ✅ RESPONSE: ${response.statusCode} ${response.requestOptions.uri}',
      );
      print('│ 📦 Data: ${response.data}');
      print('└─────────────────────────────────────────────────────────');
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Technical error logging disabled - user-friendly errors shown via ErrorMessageMapper
    // if (kDebugMode) {
    //   print('┌─────────────────────────────────────────────────────────');
    //   print('│ ❌ ERROR: ${err.type} ${err.requestOptions.uri}');
    //   print('│ 📦 Message: ${err.message}');
    //   if (err.response?.data != null) {
    //     print('│ 📦 Error Data: ${err.response?.data}');
    //   }
    //   print('└─────────────────────────────────────────────────────────');
    // }
    handler.next(err);
  }
}

/// Error handling interceptor that converts Dio errors to app exceptions
class _ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
        // Connection timeout - likely network issue
        throw const NetworkException(message: 'Pas de connexion Internet');

      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        // Send/receive timeout - slow backend
        throw const NetworkException(
          message: 'Le serveur met plus de temps que prévu',
        );

      case DioExceptionType.connectionError:
        throw const NetworkException(message: 'Pas de connexion Internet');

      case DioExceptionType.badResponse:
        final statusCode = err.response?.statusCode;
        final data = err.response?.data;

        Map<String, dynamic>? errorData;
        if (data is Map<String, dynamic>) {
          errorData = data;
        } else if (data is String) {
          try {
            // Attempt to decode if it's a string
            // errorData = jsonDecode(data); // Requires dart:convert
            // Assuming we don't have dart:convert import here, we rely on Dio's decoding.
            // If Dio didn't decode, it might be due to content-type.
          } catch (_) {}
        }

        if (errorData != null) {
          if (statusCode == 400 &&
              !errorData.containsKey('detail') &&
              !errorData.containsKey('message') &&
              !errorData.containsKey('error')) {
            throw ValidationException(errorData);
          }
        }

        // Server errors (5xx) - backend unavailable
        if (statusCode != null && statusCode >= 500) {
          throw ServerException(
            message: 'Impossible de se connecter pour le moment',
            statusCode: statusCode,
          );
        }

        final message = _extractErrorMessage(err.response);
        throw ServerException(message: message, statusCode: statusCode);

      case DioExceptionType.cancel:
        throw const ServerException(message: 'Requête annulée');

      default:
        throw const ServerException(message: 'Une erreur est survenue');
    }
  }

  String _extractErrorMessage(Response? response) {
    if (response?.data != null) {
      final data = response!.data;

      if (data is Map) {
        if (data.containsKey('error')) {
          return data['error'].toString();
        }
        if (data.containsKey('message')) {
          return data['message'].toString();
        }
        if (data.containsKey('detail')) {
          return data['detail'].toString();
        }
        if (data.containsKey('non_field_errors')) {
          final errs = data['non_field_errors'];
          if (errs is List && errs.isNotEmpty) return errs.first.toString();
          return errs.toString();
        }
      }
      if (data is String && data.length < 200) {
        return data;
      }
    }
    return 'Server error occurred';
  }
}
