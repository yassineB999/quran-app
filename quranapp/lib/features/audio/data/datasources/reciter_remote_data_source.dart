import 'dart:io';

import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:quranapp/core/error/exceptions.dart';
import 'package:quranapp/core/network/api_endpoints.dart';
import 'package:quranapp/core/network/dio_client.dart';
import 'package:quranapp/features/audio/data/models/recitation_result_model.dart';
import 'package:quranapp/features/audio/data/models/reciter_model.dart';
import 'package:quranapp/features/audio/data/models/audio_info_model.dart';

/// Abstract data source for reciter operations
abstract class ReciterRemoteDataSource {
  Future<List<ReciterModel>> getReciters();
  Future<AudioInfoModel> getAudioUrl(int reciterId, int surahId);
  Future<RecitationResultModel> checkRecitation(
    String filePath,
    int surahId,
    int ayahId,
  );
}

/// Implementation of ReciterRemoteDataSource
class ReciterRemoteDataSourceImpl implements ReciterRemoteDataSource {
  final DioClient dioClient;

  ReciterRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<List<ReciterModel>> getReciters() async {
    final response = await dioClient.get(ApiEndpoints.reciters);

    if (response.statusCode == 200) {
      final List<dynamic> data = response.data['data'];
      return data.map((e) => ReciterModel.fromJson(e)).toList();
    } else {
      throw ServerException(
        message: 'Failed to load reciters',
        statusCode: response.statusCode,
      );
    }
  }

  @override
  Future<AudioInfoModel> getAudioUrl(int reciterId, int surahId) async {
    final response = await dioClient.get(
      ApiEndpoints.audio(reciterId, surahId),
    );

    if (response.statusCode == 200) {
      return AudioInfoModel.fromJson(response.data);
    } else {
      throw ServerException(
        message: 'Failed to load audio URL',
        statusCode: response.statusCode,
      );
    }
  }

  @override
  Future<RecitationResultModel> checkRecitation(
    String filePath,
    int surahId,
    int ayahId,
  ) async {
    final fileName = filePath.split(Platform.pathSeparator).last;
    final formData = FormData.fromMap({
      'audio': await MultipartFile.fromFile(
        filePath,
        filename: fileName,
        contentType: MediaType('audio', 'wav'),
      ),
      'surah_id': surahId,
      'ayah_id': ayahId,
    });

    final response = await dioClient.post(
      ApiEndpoints.recitationCheck,
      data: formData,
    );

    if (response.statusCode == 200) {
      return RecitationResultModel.fromJson(response.data);
    } else {
      throw ServerException(
        message: 'Failed to check recitation',
        statusCode: response.statusCode,
      );
    }
  }
}
