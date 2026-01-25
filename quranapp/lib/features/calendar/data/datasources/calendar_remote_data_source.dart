import 'package:quranapp/core/network/api_endpoints.dart';
import 'package:quranapp/core/network/dio_client.dart';
import 'package:quranapp/features/calendar/data/models/hijri_calendar_day_model.dart';

/// Abstract data source for calendar operations.
abstract class CalendarRemoteDataSource {
  /// Fetches calendar data for a specific Gregorian year/month.
  Future<HijriCalendarMonthModel> getCalendarMonth({
    required int year,
    required int month,
    bool refresh = false,
  });
}

/// Implementation of CalendarRemoteDataSource using DioClient.
class CalendarRemoteDataSourceImpl implements CalendarRemoteDataSource {
  final DioClient dioClient;

  CalendarRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<HijriCalendarMonthModel> getCalendarMonth({
    required int year,
    required int month,
    bool refresh = false,
  }) async {
    final response = await dioClient.get<Map<String, dynamic>>(
      ApiEndpoints.hijriCalendarMonth(year, month),
      queryParameters: refresh ? {'refresh': 'true'} : null,
    );

    return HijriCalendarMonthModel.fromJson(response.data!);
  }
}
