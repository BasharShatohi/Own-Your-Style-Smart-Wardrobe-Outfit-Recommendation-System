// lib/core/services/generation_service.dart
import 'package:dio/dio.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter/foundation.dart';

class GenerationService {
  final Dio _dio;
  final GetStorage _box;

  
  GenerationService({Dio? dio, GetStorage? box})
    : _dio = dio ?? Dio(),
      _box = box ?? GetStorage();

  Future<Map<String, dynamic>> generateOutfit({
    required double temperature,
    required String weather,
    required String occasion,
    Duration timeout = const Duration(seconds: 70),
  }) async {
    final token = _box.read('accessToken') ?? '';

    final url = 'http://127.0.0.1:5002/generate-outfit';

    final payload = {
      'weather': weather,
      'occasion': occasion,
      'temperature': temperature,
    };

    final headers = <String, dynamic>{
      'Accept': 'application/json',
      'Content-Type': Headers.jsonContentType,
      if (token.isNotEmpty) 'Authorization': 'Bearer $token',
    };

    try {
      final resp = await _dio
          .post(
            url,
            data: payload,
            options: Options(
              headers: headers,
              validateStatus: (s) => s != null && s < 500,
              responseType: ResponseType.json,
            ),
          )
          .timeout(timeout);

      if (resp.statusCode != 200 && resp.statusCode != 201) {
        throw Exception('Generation failed: ${resp.statusCode} ${resp.data}');
      }

      final data = resp.data;
      if (data is Map<String, dynamic>) return data;
      if (data is Map) return Map<String, dynamic>.from(data);
      throw Exception('Unexpected response shape from generator');
    } catch (e, st) {
      debugPrint('GenerationService.generateOutfit error: $e\n$st');
      rethrow;
    }
  }
}
