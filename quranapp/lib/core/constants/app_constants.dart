class AppConstants {
  // App info
  static const String appName = 'Quran App';
  static const String appVersion = '1.0.0';

  // Splash screen
  static const Duration splashDuration = Duration(seconds: 3);

  // Animation durations
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);
  static const Duration slowAnimationDuration = Duration(milliseconds: 500);

  // Quran constants
  static const int totalSurahs = 114;
  static const int totalAyahs = 6236;
  static const int totalJuzs = 30;

  // Cache keys
  static const String cachedSurahsKey = 'CACHED_SURAHS';
  static const String cachedAyahsKey = 'CACHED_AYAHS';
  static const String cachedSettingsKey = 'CACHED_SETTINGS';

  static const String openStreetMapTileUrl =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const String osrmRouteUrl =
      'https://router.project-osrm.org/route/v1/driving';

  // Prevent instantiation
  AppConstants._();
}
