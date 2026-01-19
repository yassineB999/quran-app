import 'package:shared_preferences/shared_preferences.dart';

abstract class QuranLocalDataSource {
  Future<void> saveLastPage(int page);
  Future<int?> getLastPage();
  Future<void> saveLastSurah(int surahId);
  Future<int?> getLastSurah();
  Future<void> saveReadingMode(String mode);
  Future<String?> getReadingMode();
}

const String cachedQuranPageKey = 'CACHED_QURAN_PAGE';
const String cachedQuranSurahKey = 'CACHED_QURAN_SURAH';
const String cachedReadingModeKey = 'CACHED_READING_MODE';

class QuranLocalDataSourceImpl implements QuranLocalDataSource {
  final SharedPreferences sharedPreferences;

  QuranLocalDataSourceImpl({required this.sharedPreferences});

  @override
  Future<int?> getLastPage() async {
    return sharedPreferences.getInt(cachedQuranPageKey);
  }

  @override
  Future<void> saveLastPage(int page) async {
    await sharedPreferences.setInt(cachedQuranPageKey, page);
  }

  @override
  Future<int?> getLastSurah() async {
    return sharedPreferences.getInt(cachedQuranSurahKey);
  }

  @override
  Future<void> saveLastSurah(int surahId) async {
    await sharedPreferences.setInt(cachedQuranSurahKey, surahId);
  }

  @override
  Future<String?> getReadingMode() async {
    return sharedPreferences.getString(cachedReadingModeKey);
  }

  @override
  Future<void> saveReadingMode(String mode) async {
    await sharedPreferences.setString(cachedReadingModeKey, mode);
  }
}
