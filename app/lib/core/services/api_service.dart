// lib/core/services/api_service.dart
import 'dart:io' show Platform;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get_storage/get_storage.dart';

class ApiService {
  
  static String baseUrl = 'http://127.0.0.1:8000/api/';

  static Dio? _dio;

  static Dio get dio {
    _dio ??= Dio(BaseOptions(baseUrl: baseUrl));
    return _dio!;
  }

  static void setBaseUrl(String url) {
    final u = url.trim();
    if (u.isEmpty) return;
    baseUrl = u.endsWith('/') ? u : '$u/';
    resetDio();
    debugPrint('ApiService: baseUrl set to $baseUrl');
  }

  static void resetDio() {
    _dio = Dio(BaseOptions(baseUrl: baseUrl));
  }

  static String _tokenFromStore() {
    try {
      final box = GetStorage();
      return box.read('accessToken') ?? '';
    } catch (_) {
      return '';
    }
  }

  static Options _authOptions({Map<String, String>? extraHeaders}) {
    final token = _tokenFromStore();
    final headers = <String, String>{
      'Accept': 'application/json',
      if (token.isNotEmpty) 'Authorization': 'Bearer $token',
      if (extraHeaders != null) ...extraHeaders,
    };
    return Options(
      headers: headers,
      validateStatus: (s) => s != null && s < 500,
    );
  }

  static Future<Response> listOutfits() =>
      dio.get('outfits', options: _authOptions());
  static Future<Response> getOutfit(int id) =>
      dio.get('outfits/$id', options: _authOptions());
  static Future<Response> createOutfit(Map<String, dynamic> payload) =>
      dio.post('outfits', data: payload, options: _authOptions());
  static Future<Response> deleteOutfit(String id) =>
      dio.delete('outfits/$id', options: _authOptions());

 
  static Future<Response> getWeather(Map<String, dynamic> query) =>
      dio.get('weather', queryParameters: query, options: _authOptions());

  static String imageUrlForItemId(int id) {
    try {
      final base = Uri.parse(baseUrl);
      final origin = Uri(
        scheme: base.scheme,
        host: base.host,
        port: base.hasPort ? base.port : null,
      );
      
      final apiPrefix = '/api';
      return '${origin.toString()}$apiPrefix/clothing-images/$id';
    } catch (_) {
      return '/api/clothing-images/$id';
    }
  }

  /// Normalize image URL returned by backend.
  /// - If backend returns a relative path like "clothing_images/1/..", we create an absolute URL
  ///   using the origin of `baseUrl` (so we won't accidentally add an extra '/api/' segment).
  /// - If backend returns an absolute URL that points to 'localhost' or '127.0.0.1',
  ///   replace the host with something reachable from the device:
  ///     * If `baseUrl` origin is not localhost, map to that origin.
  ///     * Otherwise, if Android emulator -> map to 10.0.2.2
  static String normalizeUrl(String raw) {
    try {
      if (raw.isEmpty) return raw;

      // If already absolute
      if (raw.startsWith('http://') || raw.startsWith('https://')) {
        final parsed = Uri.parse(raw);
        String host = parsed.host;
        int? port = parsed.hasPort ? parsed.port : null;
        String scheme = parsed.scheme;

        // If backend returned localhost/127.0.0.1, map it to something reachable:
        if (host == 'localhost' || host == '127.0.0.1') {
          // prefer baseUrl origin if it points elsewhere (e.g. ngrok)
          try {
            final baseUri = Uri.parse(baseUrl);
            if (baseUri.host != 'localhost' && baseUri.host != '127.0.0.1') {
              // replace host+port+scheme with baseUri origin
              final newUri = Uri(
                scheme: baseUri.scheme,
                host: baseUri.host,
                port: baseUri.hasPort ? baseUri.port : null,
                path: parsed.path,
                query: parsed.query,
                fragment: parsed.fragment,
              );
              return newUri.toString();
            }
          } catch (_) {}

          // else if running on Android emulator, use 10.0.2.2
          try {
            if (Platform.isAndroid) {
              host = '127.0.0.1';
              // keep original scheme/port if possible
              final newUri = Uri(
                scheme: scheme,
                host: host,
                port: port,
                path: parsed.path,
                query: parsed.query,
                fragment: parsed.fragment,
              );
              return newUri.toString();
            }
          } catch (_) {}
        }

        // No remapping needed
        return parsed.toString();
      }

      // Relative path case -> join with origin of baseUrl (NOT with baseUrl directly to avoid double '/api/api')
      final base = Uri.parse(baseUrl);
      String originHost = base.host;
      final originPort = base.hasPort ? base.port : null;
      final originScheme = base.scheme;

      // If base host is localhost and running on Android emulator, map to 10.0.2.2
      try {
        if (Platform.isAndroid &&
            (originHost == '127.0.0.1' || originHost == 'localhost')) {
          originHost = '127.0.0.1';
        }
      } catch (_) {}

      final trimmed = raw.startsWith('/') ? raw.substring(1) : raw;
      final originPrefix =
          '$originScheme://$originHost${originPort != null ? ':$originPort' : ''}';
      return '$originPrefix/$trimmed';
    } catch (e) {
      if (!kReleaseMode)
        debugPrint('ApiService.normalizeUrl error for "$raw": $e');
      return raw;
    }
  }
}
