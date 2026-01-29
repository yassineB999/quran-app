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

  /// Fetches calendar data for a specific Gregorian year.
  Future<List<HijriCalendarMonthModel>> getCalendarYear({
    required int year,
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

  @override
  Future<List<HijriCalendarMonthModel>> getCalendarYear({
    required int year,
    bool refresh = false,
  }) async {
    // Note: The API is paginated by default (per_page=6), but we want ALL months (12).
    // So we request per_page=12.
    final response = await dioClient.get<Map<String, dynamic>>(
      ApiEndpoints.hijriCalendarYear(year),
      queryParameters: {'per_page': 12, if (refresh) 'refresh': 'true'},
    );

    final data = response.data!;
    final monthsList = data['months'] as List<dynamic>? ?? [];

    return monthsList.map((monthJson) {
      // The year API returns items like { "month": 1, "data": {...}, "cached": ... }
      // Our HijriCalendarMonthModel.fromJson expects top-level "year" and "month" fields.
      // "month" is present. "year" might be missing in the item, so we inject it.
      final jsonWithYear = Map<String, dynamic>.from(monthJson as Map);
      jsonWithYear['year'] = year; // Ensure year is present for the model
      return HijriCalendarMonthModel.fromJson(jsonWithYear);
    }).toList();
  }
}
