import 'package:dio/dio.dart';
import 'package:quranapp/core/error/exceptions.dart';
import 'package:quranapp/core/network/api_endpoints.dart';
import 'package:quranapp/core/network/dio_client.dart';
import 'package:quranapp/core/network/timeout_config.dart';
import 'package:quranapp/features/home/data/models/daily_hadith_model.dart';
import 'package:quranapp/features/home/data/models/hijri_date_model.dart';

abstract class HomeRemoteDataSource {
  Future<DailyHadithModel> getDailyHadith();
  Future<HijriDateModel> getHijriDate(DateTime date);
}

class HomeRemoteDataSourceImpl implements HomeRemoteDataSource {
  final DioClient dioClient;

  HomeRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<DailyHadithModel> getDailyHadith() async {
    final response = await dioClient.get(
      ApiEndpoints.hadithDaily,
      options: Options(receiveTimeout: TimeoutConfig.fast),
    );
    if (response.statusCode == 200) {
      final payload = response.data;
      final data = payload is Map<String, dynamic> ? payload['data'] : null;
      if (data is Map<String, dynamic>) {
        final model = DailyHadithModel.fromMap(data);
        if (model.arabic.trim().isNotEmpty &&
            model.translation.trim().isNotEmpty &&
            model.reference.trim().isNotEmpty) {
          return model;
        }
      }
      throw const ServerException(message: 'Hadith data is unavailable');
    } else {
      throw ServerException(
        message: 'Failed to load daily hadith',
        statusCode: response.statusCode,
      );
    }
  }

  @override
  Future<HijriDateModel> getHijriDate(DateTime date) async {
    final response = await dioClient.get(
      ApiEndpoints.hijriCalendarMonth(date.year, date.month),
      options: Options(receiveTimeout: TimeoutConfig.fast),
    );
    if (response.statusCode == 200) {
      final payload = response.data;
      final data = payload is Map<String, dynamic> ? payload['data'] : null;
      final days = data is Map<String, dynamic> ? data['data'] : null;

      if (days is List) {
        for (final item in days) {
          if (item is! Map<String, dynamic>) continue;

          final gregorian = item['gregorian'];
          if (gregorian is! Map<String, dynamic>) continue;

          final dayValue = gregorian['day']?.toString();
          if (dayValue == null || int.tryParse(dayValue) != date.day) continue;

          return HijriDateModel.fromMap(item);
        }
      }
      throw const ServerException(message: 'Hijri date is unavailable');
    } else {
      throw ServerException(
        message: 'Failed to load Hijri date',
        statusCode: response.statusCode,
      );
    }
  }

  // Helper methods _extractGregorianDay and _extractHijriDate removed as they are no longer needed
  // logic is now handled by HijriDateModel.fromMap and simplified loop
}
