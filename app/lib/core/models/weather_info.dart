class WeatherInfo {
  final String city;
  final String country;
  final double temperatureCelsius;
  final String condition;
  final int humidity;
  final double windSpeedMetersPerSec;
  final String iconCode;

  const WeatherInfo({
    required this.city,
    required this.country,
    required this.temperatureCelsius,
    required this.condition,
    required this.humidity,
    required this.windSpeedMetersPerSec,
    required this.iconCode,
  });

  /// Parses the flat 7-key payload from the backend's `GET /api/weather`
  /// proxy. `condition` may legitimately be empty — the server sends `''`
  /// when the upstream payload is sparse, and it means "unknown", never
  /// "clear". Callers must not map an empty condition onto a category.
  factory WeatherInfo.fromJson(Map<String, dynamic> json) {
    return WeatherInfo(
      city: json['city']?.toString() ?? '',
      country: json['country']?.toString() ?? '',
      temperatureCelsius: _toDouble(json['temperature_celsius']),
      condition: json['condition']?.toString() ?? '',
      humidity: _toInt(json['humidity']),
      windSpeedMetersPerSec: _toDouble(json['wind_speed_mps']),
      iconCode: (json['icon_code']?.toString().isNotEmpty ?? false)
          ? json['icon_code'].toString()
          : '01d',
    );
  }

  bool get hasKnownCondition => condition.trim().isNotEmpty;

  static double _toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '') ?? 0;
  }

  static int _toInt(dynamic v) {
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }
}
