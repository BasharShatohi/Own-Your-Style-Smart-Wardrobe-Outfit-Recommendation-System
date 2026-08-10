import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http_parser/http_parser.dart';
import '../models/clothing_item.dart';
import 'api_service.dart';

class ClothingRepository {
  final Dio _dio = ApiService.dio;
  final GetStorage _box = GetStorage();

  Future<Map<String, dynamic>> uploadFromBytes({
    required Uint8List imageBytes,
    required Map<String, dynamic> features,
    String filename = 'ai_image.png',
  }) async {
    final token = _box.read('accessToken') ?? '';

    String ext = 'png';
    final dot = filename.lastIndexOf('.');
    if (dot != -1 && dot < filename.length - 1) {
      ext = filename.substring(dot + 1).toLowerCase();
    }

    String mime = 'image/png';
    if (ext == 'jpg' || ext == 'jpeg') mime = 'image/jpeg';
    if (ext == 'webp') mime = 'image/webp';
    if (ext == 'gif') mime = 'image/gif';

    final multipart = MultipartFile.fromBytes(
      imageBytes,
      filename: filename,
      contentType: MediaType(mime.split('/')[0], mime.split('/')[1]),
    );

    final Map<String, dynamic> formMap = <String, dynamic>{'image': multipart};
    features.forEach((k, v) {
      if (v != null) formMap[k] = v.toString();
    });

    final options = Options(
      headers: {
        if (token.isNotEmpty) 'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
      contentType: 'multipart/form-data',
    );

    final formData = FormData.fromMap(formMap);
    final response = await _dio.post(
      'clothingitems',
      data: formData,
      options: options,
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Upload failed: ${response.statusCode} ${response.data}');
    }
    return response.data as Map<String, dynamic>;
  }

  Future<List<ClothingItem>> fetchMyClothingItems() async {
    final token = _box.read('accessToken') ?? '';
    final options = Options(
      headers: {
        if (token.isNotEmpty) 'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    final resp = await _dio.get('my-clothingitems', options: options);

    if (resp.statusCode != 200) {
      throw Exception('Failed to fetch: ${resp.statusCode} ${resp.data}');
    }

    final data = resp.data;
    if (data == null) return [];

    final list = (data['data'] as List?) ?? [];
    return list
        .map((e) => ClothingItem.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> deleteClothingItem(int itemId) async {
    final token = _box.read('accessToken') ?? '';
    final options = Options(
      headers: {
        if (token.isNotEmpty) 'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    final response = await _dio.delete(
      'clothingitems/$itemId',
      options: options,
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception(
        'Failed to delete: ${response.statusCode} ${response.data}',
      );
    }
  }
}
