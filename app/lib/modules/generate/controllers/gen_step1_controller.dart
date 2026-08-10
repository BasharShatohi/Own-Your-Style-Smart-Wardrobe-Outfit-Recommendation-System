// lib/modules/generate/controllers/gen_step1_controller.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/routes/app_pages.dart';
import '../../../core/models/weather_info.dart' as model;
import '../../../core/services/weather_service.dart';

class GenStep1Controller extends GetxController {
  final TextEditingController cityCtrl = TextEditingController();
  final TextEditingController countryCtrl = TextEditingController();

  final RxInt weatherIndex = 0.obs;
  final RxInt occasionIndex = (-1).obs; // -1: none selected

  final RxString city = ''.obs;
  final RxString country = ''.obs;

  final Rx<model.WeatherInfo?> weather = Rx<model.WeatherInfo?>(null);
  final RxBool isFetchingWeather = false.obs;
  final RxString weatherError = ''.obs;
  final RxBool canProceed = false.obs;

  late final WeatherService _weatherService;

  GenStep1Controller({WeatherService? weatherService}) {
    _weatherService = weatherService ?? WeatherService();
  }

  @override
  void onInit() {
    super.onInit();

    cityCtrl.addListener(() {
      final v = cityCtrl.text.trim();
      if (city.value != v) city.value = v;
    });
    countryCtrl.addListener(() {
      final v = countryCtrl.text.trim();
      if (country.value != v) country.value = v;
    });

    ever<model.WeatherInfo?>(weather, (_) => _updateCanProceed());
    ever<int>(occasionIndex, (_) => _updateCanProceed());
  }

  void _updateCanProceed() {
    canProceed.value = weather.value != null && occasionIndex.value >= 0;
  }

  void selectWeather(int idx) => weatherIndex.value = idx;
  void selectOccasion(int idx) => occasionIndex.value = idx;

  Future<void> fetchWeatherManually() async {
    final c = city.value.trim();
    final cc = country.value.trim();
    if (c.isEmpty) {
      weatherError.value = 'Please enter a city.';
      return;
    }

    isFetchingWeather.value = true;
    weatherError.value = '';
    weather.value = null;

    try {
      final info = await _weatherService.fetchByCity(
        city: c,
        countryCode: cc.isEmpty ? null : cc,
      );
      weather.value = info;
      _setWeatherIndexFromCondition(info.condition);
    } catch (e, st) {
      debugPrint('fetchWeatherManually error: $e\n$st');
      weatherError.value = e is WeatherException
          ? e.message
          : 'Failed to fetch weather. Check city/country and network.';
    } finally {
      isFetchingWeather.value = false;
    }
  }

  /// Geolocator never prompts on its own — [Geolocator.getCurrentPosition]
  /// just throws when permission is missing. The runtime request has to be
  /// made explicitly, which is what actually shows the system dialog.
  ///
  /// Returns an error message to display, or null when access is granted.
  Future<String?> _ensureLocationAccess() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return 'Location services are turned off. Please enable GPS and try again.';
    }

    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      // This is the call that shows the system permission dialog.
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      return 'Location permission is permanently denied. Enable it for this app '
          'in system settings, or enter your city manually.';
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.unableToDetermine) {
      return 'Location permission denied. Allow location access or enter your '
          'city manually.';
    }

    return null;
  }

  Future<void> detectWeatherViaGps() async {
    weatherError.value = '';
    isFetchingWeather.value = true;
    weather.value = null;

    try {
      final accessError = await _ensureLocationAccess();
      if (accessError != null) {
        weatherError.value = accessError;
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          timeLimit: Duration(seconds: 15),
        ),
      );

      final info = await _weatherService.fetchByCoords(
        lat: pos.latitude,
        lon: pos.longitude,
      );

      weather.value = info;

      if ((info.city).isNotEmpty) city.value = info.city;
      if ((info.country).isNotEmpty) country.value = info.country;

      _setWeatherIndexFromCondition(info.condition);
    } catch (e, st) {
      debugPrint('detectWeatherViaGps error: $e\n$st');

      if (e is WeatherException) {
        weatherError.value = e.message;
      } else if (e is LocationServiceDisabledException) {
        weatherError.value =
            'Location services are turned off. Please enable GPS and try again.';
      } else if (e is PermissionDeniedException) {
        weatherError.value =
            'Location permission denied. Allow location access or enter your '
            'city manually.';
      } else if (e is TimeoutException) {
        weatherError.value =
            'Could not get a GPS fix. Try again outdoors, or enter your city '
            'manually.';
      } else {
        weatherError.value =
            'Failed to detect weather via GPS. Please try again or enter city '
            'manually.';
      }
    } finally {
      isFetchingWeather.value = false;
    }
  }

  String _normalizeWeatherCondition(String cond) {
    final c = cond.toLowerCase();
    // rain-like
    if (c.contains('rain') ||
        c.contains('drizzle') ||
        c.contains('shower') ||
        c.contains('thunder') ||
        c.contains('sleet')) {
      return 'rainy';
    }
    // snow-like
    if (c.contains('snow') ||
        c.contains('blizzard') ||
        c.contains('ice') ||
        c.contains('flurry')) {
      return 'snowy';
    }

    if (c.contains('cloud') ||
        c.contains('mist') ||
        c.contains('fog') ||
        c.contains('haze') ||
        c.contains('smoke') ||
        c.contains('sand') ||
        c.contains('dust') ||
        c.contains('ash') ||
        c.contains('squall') ||
        c.contains('tornado')) {
      return 'cloudy';
    }
    // default: clear
    return 'clear';
  }

  void _setWeatherIndexFromCondition(String cond) {
    // The backend sends '' when the upstream payload is sparse, and it means
    // "unknown", not "clear". _normalizeWeatherCondition would default it to
    // 'clear' and quietly feed sunny weather into the outfit generator, so
    // keep whatever the user selected and ask them to confirm instead.
    if (cond.trim().isEmpty) {
      weatherError.value =
          'Weather condition unavailable — please select it manually.';
      return;
    }

    final normalized = _normalizeWeatherCondition(cond);

    switch (normalized) {
      case 'rainy':
        weatherIndex.value = 2;
        break;
      case 'cloudy':
        weatherIndex.value = 1;
        break;
      case 'snowy':
        weatherIndex.value = 3;
        break;
      case 'clear':
      default:
        weatherIndex.value = 0;
        break;
    }
  }

  String _weatherTokenFromIndex(int idx) {
    switch (idx) {
      case 1:
        return 'cloudy';
      case 2:
        return 'rainy';
      case 3:
        return 'snowy';
      case 0:
      default:
        return 'clear';
    }
  }

  void next() {
    if (!canProceed.value) {
      Get.snackbar(
        'Action required',
        'Please fetch local weather and select occasion.',
      );
      return;
    }

    final temp = (weather.value?.temperatureCelsius is num)
        ? (weather.value!.temperatureCelsius as num).toDouble()
        : 15.0;

    // Determine weather token to send to backend — prefer normalized condition from the real fetched condition,
    // otherwise fall back to UI index mapping.
    String weatherStr = 'clear';
    try {
      final condRaw = (weather.value?.condition ?? '').toString();
      if (condRaw.trim().isNotEmpty) {
        weatherStr = _normalizeWeatherCondition(condRaw);
      } else {
        weatherStr = _weatherTokenFromIndex(weatherIndex.value);
      }
    } catch (_) {
      weatherStr = _weatherTokenFromIndex(weatherIndex.value);
    }

    Get.toNamed(
      Routes.GEN_STEP2,
      arguments: {
        'occasionIndex': occasionIndex.value,
        'weather': weatherStr,
        'temperature': temp,
      },
    );
  }

  @override
  void onClose() {
    cityCtrl.dispose();
    countryCtrl.dispose();
    super.onClose();
  }
}
