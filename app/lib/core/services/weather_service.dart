import 'package:dio/dio.dart';
import '../models/weather_info.dart';
import 'api_service.dart';

/// A weather failure with a message already fit to show the user.
class WeatherException implements Exception {
  final String message;
  const WeatherException(this.message);

  @override
  String toString() => message;
}

/// Calls the Laravel `GET /api/weather` proxy rather than OpenWeatherMap
/// directly, so the API key stays server-side and never ships in the APK.
/// Requests carry the stored Bearer token, so the user must be logged in.
class WeatherService {
  WeatherService();

  Future<WeatherInfo> fetchByCity({required String city, String? countryCode}) {
    final cc = countryCode?.trim() ?? '';
    return _fetch({
      'city': city.trim(),
      if (cc.isNotEmpty) 'country': cc.toUpperCase(),
    });
  }

  Future<WeatherInfo> fetchByCoords({
    required double lat,
    required double lon,
  }) {
    return _fetch({'lat': lat, 'lon': lon});
  }

  Future<WeatherInfo> _fetch(Map<String, dynamic> query) async {
    final Response response;
    try {
      response = await ApiService.getWeather(query);
    } on DioException catch (e) {
      // ApiService treats <500 as non-throwing, so anything caught here is a
      // 5xx or a transport failure. 502 (upstream down) and 503 (key not
      // configured) are deliberately identical to the client.
      final status = e.response?.statusCode;
      if (status == 502 || status == 503) {
        throw const WeatherException(
          'Weather service is unavailable right now. Please try again later.',
        );
      }
      if (e.response != null) {
        throw const WeatherException(
          'The server ran into a problem fetching weather.',
        );
      }
      throw const WeatherException(
        'Could not reach the server. Check your connection and try again.',
      );
    }

    final status = response.statusCode;
    final data = response.data;

    if (status == 200 && data is Map) {
      return WeatherInfo.fromJson(Map<String, dynamic>.from(data));
    }

    throw WeatherException(_messageFor(status, data));
  }

  /// 404 and 503 send `{"message": ...}`; 422 sends `{"errors": {field: [...]}}`.
  String _messageFor(int? status, dynamic body) {
    if (status == 401) {
      return 'Your session expired. Please sign in again.';
    }

    if (body is Map) {
      final errors = body['errors'];
      if (errors is Map && errors.isNotEmpty) {
        final first = errors.values.first;
        if (first is List && first.isNotEmpty) return first.first.toString();
        if (first != null) return first.toString();
      }

      final message = body['message'];
      if (message != null && message.toString().trim().isNotEmpty) {
        return message.toString();
      }
    }

    if (status == 404) return 'City not found. Check the spelling and country.';

    return 'Failed to fetch weather. Please try again.';
  }
}
