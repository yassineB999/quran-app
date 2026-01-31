import 'package:dio/dio.dart';
import 'package:quranapp/core/error/exceptions.dart';
import 'package:quranapp/core/network/api_endpoints.dart';
import 'package:quranapp/core/network/dio_client.dart';
import 'package:quranapp/core/network/timeout_config.dart';
import 'package:quranapp/features/hadith/data/models/hadith_edition_model.dart';
import 'package:quranapp/features/hadith/data/models/hadith_model.dart';

abstract class HadithRemoteDataSource {
  Future<List<HadithEditionModel>> getEditions();
  Future<List<HadithModel>> getHadiths(String editionId);
}

class HadithRemoteDataSourceImpl implements HadithRemoteDataSource {
  final DioClient dioClient;

  HadithRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<List<HadithEditionModel>> getEditions() async {
    final response = await dioClient.get(
      ApiEndpoints.hadithEditions,
      options: Options(receiveTimeout: TimeoutConfig.medium),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = response.data['data'] ?? {};
      final List<HadithEditionModel> editions = [];

      data.forEach((key, value) {
        if (value is Map<String, dynamic>) {
          final String collectionName = value['name'] ?? key;
          final List<dynamic> collection = value['collection'] ?? [];
          editions.addAll(
            collection.map(
              (e) => HadithEditionModel.fromJson(
                e as Map<String, dynamic>,
                collectionName: collectionName,
              ),
            ),
          );
        }
      });

      return editions;
    } else {
      throw ServerException(
        message: 'Failed to load hadith editions',
        statusCode: response.statusCode,
      );
    }
  }

  @override
  Future<List<HadithModel>> getHadiths(String editionId) async {
    final response = await dioClient.get(
      ApiEndpoints.hadithShow(editionId),
      options: Options(receiveTimeout: TimeoutConfig.medium),
      queryParameters: {'lang': 'ar,en'},
    );

    if (response.statusCode == 200) {
      final dynamic data = response.data['data'];
      List<dynamic> hadiths = [];

      if (data is List) {
        hadiths = data;
      } else if (data is Map<String, dynamic>) {
        if (data.containsKey('hadiths')) {
          hadiths = data['hadiths'];
        } else if (data.containsKey('items')) {
          hadiths = data['items'];
        } else if (data.containsKey('data')) {
          // Some APIs nest data inside data
          final inner = data['data'];
          if (inner is List) hadiths = inner;
        }
      }

      return hadiths.map((e) => HadithModel.fromJson(e)).toList();
    } else {
      throw ServerException(
        message: 'Failed to load hadiths for edition $editionId',
        statusCode: response.statusCode,
      );
    }
  }
}
