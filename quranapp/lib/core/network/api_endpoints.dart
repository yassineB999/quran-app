/// Centralized API endpoints for the Laravel API.
/// Update the baseUrl to match your API server.
class ApiEndpoints {
  static const String baseUrl = 'http://192.168.1.6:8001/api';
  // Connection timeout in milliseconds
  static const int connectTimeout = 30000;
  static const int receiveTimeout = 30000;

  // Quran endpoints
  static const String surahs = '/surahs';
  static String surahDetails(int id) => '$surahs/$id';
  static String surahPages(int surahId) => '$surahs/$surahId/pages';

  static String quranPage(int page) => '/pages/$page';

  // Reciter endpoints
  static const String reciters = '/reciters';
  static String audio(int reciterId, int surahId) =>
      '/audio/$reciterId/$surahId';
  static const String recitationCheck = '/recitation/check';

  // Hadith endpoints
  static const String hadithDaily = '/hadith/daily';

  // Hijri calendar endpoints
  static String hijriCalendarMonth(int year, int month) =>
      '/hijri/calendar/$year/$month';
}
