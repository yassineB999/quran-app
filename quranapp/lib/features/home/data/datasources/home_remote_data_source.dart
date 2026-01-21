import 'package:quranapp/core/error/exceptions.dart';
import 'package:quranapp/core/network/api_endpoints.dart';
import 'package:quranapp/core/network/dio_client.dart';
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
    final response = await dioClient.get(ApiEndpoints.hadithDaily);
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
    );
    if (response.statusCode == 200) {
      final payload = response.data;
      final data = payload is Map<String, dynamic> ? payload['data'] : null;
      final days = data is Map<String, dynamic> ? data['data'] : null;
      if (days is List) {
        for (final item in days) {
          if (item is! Map<String, dynamic>) continue;
          final gregorian = item['gregorian'];
          final gregorianDay = _extractGregorianDay(gregorian);
          if (gregorianDay == null) continue;
          if (int.tryParse(gregorianDay) != date.day) continue;
          final hijri = item['hijri'];
          final hijriDate = _extractHijriDate(hijri);
          if (hijriDate != null) {
            return hijriDate;
          }
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

  String? _extractGregorianDay(dynamic gregorian) {
    if (gregorian is Map<String, dynamic>) {
      final dayValue = gregorian['day']?.toString();
      if (dayValue != null && dayValue.trim().isNotEmpty) {
        return dayValue;
      }
      final dateValue = gregorian['date']?.toString();
      if (dateValue != null && dateValue.contains('-')) {
        return dateValue.split('-').first;
      }
    }
    return null;
  }

  HijriDateModel? _extractHijriDate(dynamic hijri) {
    if (hijri is Map<String, dynamic>) {
      final day = hijri['day']?.toString();
      final year = hijri['year']?.toString();
      String? month;
      final monthValue = hijri['month'];
      if (monthValue is Map<String, dynamic>) {
        month = monthValue['en']?.toString();
      } else if (monthValue != null) {
        month = monthValue.toString();
      }
      if (day != null &&
          year != null &&
          month != null &&
          day.trim().isNotEmpty &&
          year.trim().isNotEmpty &&
          month.trim().isNotEmpty) {
        return HijriDateModel.fromParts(day: day, month: month, year: year);
      }
    }
    return null;
  }
}
