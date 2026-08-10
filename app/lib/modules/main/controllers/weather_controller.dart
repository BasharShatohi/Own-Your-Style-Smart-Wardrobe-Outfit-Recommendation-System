
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get_storage/get_storage.dart';
import '../../../core/services/api_service.dart';
import 'package:dio/dio.dart';

class WeatherController extends GetxController {
  final isLoading = false.obs;
  final isGpsActive = false.obs;
  final weather = Rxn<Map<String, dynamic>>();
  final manualCityCtrl = TextEditingController();
  final GetStorage _box = GetStorage();

  
  final double vpnDistanceThresholdKm = 50.0;

  @override
  void onClose() {
    manualCityCtrl.dispose();
    super.onClose();
  }

  
  double _deg2rad(double d) => d * pi / 180.0;
  double _haversineKm(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371.0;
    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);
    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_deg2rad(lat1)) *
            cos(_deg2rad(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  
  Future<void> fetchWeather({bool allowIpFallback = true}) async {
    isLoading.value = true;
    try {
      final gps = await _tryGetGps();
      Map<String, dynamic>? ip;
      if (allowIpFallback) {
        ip = await _tryGetIpGeo();
      }

      if (gps != null) {
        isGpsActive.value = true;
        
        if (ip != null) {
          final dist = _haversineKm(
            gps['lat']!,
            gps['lon']!,
            ip['lat']!,
            ip['lon']!,
          );
          if (dist > vpnDistanceThresholdKm) {
            
            Get.snackbar(
              'Note',
              'VPN/proxy detected — using device GPS for local weather.',
              snackPosition: SnackPosition.BOTTOM,
            );
          }
        }
        await _sendToBackendAndStore({
          'source': 'gps',
          'lat': gps['lat'],
          'lon': gps['lon'],
        });
        return;
      }

      
      if (ip != null) {
        await _sendToBackendAndStore({
          'source': 'ip',
          'lat': ip['lat'],
          'lon': ip['lon'],
        });
        return;
      }

      
      Get.snackbar(
        'Location needed',
        'Please enter your city to get weather.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e, st) {
      debugPrint('fetchWeather error: $e\n$st');
      Get.snackbar(
        'Error',
        'Unable to get weather. Try manual city.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  
  Future<Map<String, double>?> _tryGetGps() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );
      return {'lat': pos.latitude, 'lon': pos.longitude};
    } catch (e) {
      debugPrint('GPS error: $e');
      return null;
    }
  }

  
  Future<Map<String, double>?> _tryGetIpGeo() async {
    try {
      final resp = await Dio(
        BaseOptions(connectTimeout: const Duration(seconds: 6)),
      ).get('https://ipapi.co/json/');
      if (resp.statusCode == 200 && resp.data != null) {
        final m = resp.data is Map<String, dynamic>
            ? resp.data as Map<String, dynamic>
            : Map<String, dynamic>.from(jsonDecode(resp.data.toString()));
        final lat = (m['latitude'] ?? m['lat']);
        final lon = (m['longitude'] ?? m['lon']);
        if (lat != null && lon != null) {
          return {
            'lat': double.parse(lat.toString()),
            'lon': double.parse(lon.toString()),
          };
        }
      }
      return null;
    } catch (e) {
      debugPrint('IP geo error: $e');
      return null;
    }
  }

  
  Future<void> fetchWeatherByCity(String city, {String? country}) async {
    if (city.trim().isEmpty) {
      Get.snackbar('Error', 'Please enter a city.');
      return;
    }
    isLoading.value = true;
    try {
      final payload = {'source': 'manual', 'city': city.trim()};
      if (country != null) payload['country'] = country;
      await _sendToBackendAndStore(payload);
    } catch (e) {
      debugPrint('fetchWeatherByCity error $e');
      Get.snackbar('Error', 'Failed to fetch weather for $city');
    } finally {
      isLoading.value = false;
    }
  }

  
  Future<void> _sendToBackendAndStore(Map<String, dynamic> payload) async {
    final token = _box.read('accessToken') ?? '';
    final options = Options(
      headers: {
        if (token.toString().isNotEmpty) 'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );
    final resp = await ApiService.dio.post(
      'user/weather',
      data: payload,
      options: options,
    );
    if (resp.statusCode == 200) {
      weather.value = Map<String, dynamic>.from(resp.data);
      
      _box.write('last_weather', resp.data);
    } else {
      throw Exception('Backend responded ${resp.statusCode}');
    }
  }
}
