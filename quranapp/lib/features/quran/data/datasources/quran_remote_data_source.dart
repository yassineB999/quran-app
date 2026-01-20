import 'package:quranapp/core/error/exceptions.dart';
import 'package:quranapp/core/network/api_endpoints.dart';
import 'package:quranapp/core/network/dio_client.dart';
import 'package:quranapp/features/quran/data/models/surah_model.dart';
import 'package:quranapp/features/quran/data/models/surah_page_range_model.dart';

abstract class QuranRemoteDataSource {
  Future<List<SurahModel>> getSurahs();
  Future<SurahModel> getSurah(int id);
  Future<List<VerseModel>> getQuranPage(int page);
  Future<SurahPageRangeModel> getSurahPageRange(int surahId);
}

class QuranRemoteDataSourceImpl implements QuranRemoteDataSource {
  final DioClient dioClient;

  QuranRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<List<SurahModel>> getSurahs() async {
    final response = await dioClient.get(ApiEndpoints.surahs);

    if (response.statusCode == 200) {
      final List<dynamic> data = response.data['data'];
      return data.map((e) => SurahModel.fromJson(e)).toList();
    } else {
      throw ServerException(
        message: 'Failed to load surahs',
        statusCode: response.statusCode,
      );
    }
  }

  @override
  Future<SurahModel> getSurah(int id) async {
    final response = await dioClient.get(ApiEndpoints.surahDetails(id));

    if (response.statusCode == 200) {
      return SurahModel.fromJson(response.data['data']);
    } else {
      throw ServerException(
        message: 'Failed to load surah',
        statusCode: response.statusCode,
      );
    }
  }

  @override
  Future<List<VerseModel>> getQuranPage(int page) async {
    final response = await dioClient.get(ApiEndpoints.quranPage(page));

    if (response.statusCode == 200) {
      final List<dynamic> data = response.data['data'];
      return data.map((e) => VerseModel.fromJson(e)).toList();
    } else {
      throw ServerException(
        message: 'Failed to load page $page',
        statusCode: response.statusCode,
      );
    }
  }

  @override
  Future<SurahPageRangeModel> getSurahPageRange(int surahId) async {
    final response = await dioClient.get(ApiEndpoints.surahPages(surahId));

    if (response.statusCode == 200) {
      return SurahPageRangeModel.fromJson(response.data['data']);
    } else {
      throw ServerException(
        message: 'Failed to load page range for surah $surahId',
        statusCode: response.statusCode,
      );
    }
  }
}
