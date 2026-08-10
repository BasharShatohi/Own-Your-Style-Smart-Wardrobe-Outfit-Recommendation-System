import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class ThemeController extends GetxController {
  final _box = GetStorage();
  final themeMode = ThemeMode.system.obs;
  static const _key = 'themeMode'; // 'system' | 'light' | 'dark'

  @override
  void onInit() {
    final saved = _box.read<String>(_key);
    themeMode.value = _from(saved);
    super.onInit();
  }

  void setThemeMode(ThemeMode mode) {
    themeMode.value = mode;
    _box.write(_key, _to(mode));
  }

  void toggleDark(bool isDark) =>
      setThemeMode(isDark ? ThemeMode.dark : ThemeMode.light);

  static ThemeMode _from(String? v) => v == 'light'
      ? ThemeMode.light
      : v == 'dark'
      ? ThemeMode.dark
      : ThemeMode.system;

  static String _to(ThemeMode m) => m == ThemeMode.light
      ? 'light'
      : m == ThemeMode.dark
      ? 'dark'
      : 'system';
}