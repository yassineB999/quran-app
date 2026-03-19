/// Centralized API endpoints for the Laravel API.
/// Configure via --dart-define at build time:
///   flutter run --dart-define=API_BASE_URL=http://YOUR_IP:9080/api
///   flutter run --dart-define=WS_BASE_URL=ws://YOUR_IP:8000/ws/recite
class ApiEndpoints {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://192.168.1.8:9080/api',
  );
  static const int connectTimeout = 20000;
  static const int receiveTimeout = 30000;

  // Quran endpoints
  static const String surahs = '/surahs';
  static String surahDetails(int id) => '$surahs/$id';
  static String surahPages(int surahId) => '$surahs/$surahId/pages';

  static String quranPage(int page) => '/pages/$page';
  static String tafseer(int surahId, int ayahId) => '/tafseer/$surahId/$ayahId';

  // Reciter endpoints
  static const String reciters = '/reciters';
  static String audio(int reciterId, int surahId) =>
      '/audio/$reciterId/$surahId';
  static const String recitationCheck = '/recitation/check';

  // Hadith endpoints
  static const String hadithDaily = '/hadith/daily';
  static const String hadithEditions = '/hadith/editions';
  static String hadithShow(String edition) => '/hadith/$edition';

  // Hijri calendar endpoints
  static String hijriCalendarMonth(int year, int month) =>
      '/hijri/calendar/$year/$month';
  static String hijriCalendarYear(int year) => '/hijri/calendar/$year';

  // Mosque endpoints
  static const String nearbyMosques = '/mosques/nearby';

  // Adhkar endpoints
  static String adhkar(String category) => '/adhkar/$category';

  // Recitation WebSocket
  static const String recitationWebSocket = String.fromEnvironment(
    'WS_BASE_URL',
    defaultValue: 'ws://192.168.1.8:8000/ws/recite', // Use PC's LAN IP for real device
  );
  static String surahWords(int id) => '$surahs/$id/words';
}
