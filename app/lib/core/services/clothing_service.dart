import 'dart:io';
import 'package:dio/dio.dart';

class ClothingService {
  static Future<Map<String, dynamic>> analyzeImage(File file) async {
    final form = FormData.fromMap({
      'image': await MultipartFile.fromFile(
        file.path,
        filename: file.path.split(Platform.pathSeparator).last,
      ),
    });
    const url = 'http://127.0.0.1:5001/clothingitems';
    final resp = await Dio().post(url, data: form);
    return resp.data as Map<String, dynamic>;
  }
}
