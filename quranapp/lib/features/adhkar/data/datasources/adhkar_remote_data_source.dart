import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:quranapp/core/error/exceptions.dart';
import 'package:quranapp/core/network/api_endpoints.dart';
import 'package:quranapp/core/network/dio_client.dart';
import 'package:quranapp/core/network/timeout_config.dart';
import 'package:quranapp/features/adhkar/data/models/adhkar_model.dart';

abstract class AdhkarRemoteDataSource {
  /// Fetches adhkar for a category
  Future<List<AdhkarModel>> getAdhkar(String category);
}

class AdhkarRemoteDataSourceImpl implements AdhkarRemoteDataSource {
  final DioClient dioClient;

  AdhkarRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<List<AdhkarModel>> getAdhkar(String category) async {
    // 1. Fetch Arabic Data
    final arabicResponse = await dioClient.get(
      ApiEndpoints.adhkar(category),
      queryParameters: {'lang': 'ar'},
      options: Options(receiveTimeout: TimeoutConfig.medium),
    );

    if (arabicResponse.statusCode != 200) {
      throw ServerException(
        message: 'Failed to load adhkar',
        statusCode: arabicResponse.statusCode,
      );
    }

    List<AdhkarModel> items = _parseResponse(
      arabicResponse.data,
      isEnglish: false,
    );

    if (kDebugMode) {
      debugPrint('Adhkar ($category) - Arabic count: ${items.length}');
    }

    // 2. Fetch English Data (try for all categories)
    try {
      final englishResponse = await dioClient.get(
        ApiEndpoints.adhkar(category),
        queryParameters: {'lang': 'en'},
        options: Options(receiveTimeout: TimeoutConfig.medium),
      );

      if (englishResponse.statusCode == 200) {
        final englishItems = _parseResponse(
          englishResponse.data,
          isEnglish: true,
        );

        if (kDebugMode) {
          debugPrint(
            'Adhkar ($category) - English count: ${englishItems.length}',
          );
        }

        if (englishItems.isNotEmpty) {
          items = _mergeAdhkar(items, englishItems);
        }
      }
    } catch (e) {
      // English translations might not be available for all categories (e.g. bedtime)
      // or the API might return 422/404. We strictly ignore errors here
      // and return the Arabic content we already have.
      if (kDebugMode) {
        debugPrint('Adhkar English fetch failed/unavailable: $e');
      }
    }

    return items;
  }

  /// Robust parser for both Arabic (mixed keys) and English (list) structures
  List<AdhkarModel> _parseResponse(
    dynamic responseData, {
    required bool isEnglish,
  }) {
    List<dynamic> rawItems = [];

    // Extract 'data' field if present
    dynamic data = responseData;
    if (responseData is Map<String, dynamic> &&
        responseData.containsKey('data')) {
      data = responseData['data'];
    }

    if (data is List) {
      // Standard List
      rawItems = data;
    } else if (data is Map<String, dynamic>) {
      // Complex Map (like Arabic response)
      // 1. Valid items under numeric keys "0", "1", etc.
      // 2. The Map itself might be an item (has content/zekr but NOT numeric key)

      // Collect explicitly indexed items
      final indexedItems = <int, Map<String, dynamic>>{};

      for (final key in data.keys) {
        if (int.tryParse(key) != null) {
          final value = data[key];
          if (value is Map<String, dynamic>) {
            indexedItems[int.parse(key)] = value;
          }
        }
      }

      // Sort by index and add to sorted list
      final sortedKeys = indexedItems.keys.toList()..sort();
      for (final key in sortedKeys) {
        rawItems.add(indexedItems[key]);
      }

      // Check if the root map itself is an item (has content/zekr)
      // And avoid adding if it's just a container (doesn't have content or content is empty/null)
      if (_hasContent(data)) {
        rawItems.add(data);
      }
    }

    // Convert to Models
    return rawItems
        .whereType<Map<String, dynamic>>()
        .map(
          (json) => isEnglish
              ? AdhkarModel.fromEnglishJson(json)
              : AdhkarModel.fromJson(json),
        )
        .toList();
  }

  bool _hasContent(Map<String, dynamic> json) {
    // Check for presence of content fields
    final content = json['content'] ?? json['text'] ?? json['zekr'];
    return content != null && content.toString().isNotEmpty;
  }

  List<AdhkarModel> _mergeAdhkar(List<AdhkarModel> ar, List<AdhkarModel> en) {
    final merged = <AdhkarModel>[];

    // We assume the order matches. The Arabic parser tries to respect numeric keys order.
    // The English parser respects List order.

    for (int i = 0; i < ar.length; i++) {
      final original = ar[i];
      String? translation = original.englishText;

      if (i < en.length) {
        // Prefer the English fetch translation if available
        if (en[i].englishText != null && en[i].englishText!.isNotEmpty) {
          translation = en[i].englishText;
        }
      }

      merged.add(
        AdhkarModel(
          zekr: original.zekr,
          englishText: translation,
          count: original.count,
          reference: original.reference,
          description: original.description,
        ),
      );
    }
    return merged;
  }
}
