import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SnackbarUtil {
  /// Uses Flutter's ScaffoldMessenger rather than Get.snackbar: the GetX
  /// snackbar silently fails to render on this Flutter version, so form
  /// errors (bad credentials, validation) were never reaching the user.
  /// ScaffoldMessenger also positions itself above the keyboard on its own.
  static void _show(String message, Color background) {
    FocusManager.instance.primaryFocus?.unfocus();

    final context = Get.context;
    if (context == null) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(color: Colors.white, fontSize: 15),
          ),
          backgroundColor: background,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(12),
          duration: const Duration(seconds: 3),
        ),
      );
  }

  static void showError(String message) {
    _show(message, Colors.red.shade700);
  }

  static void showSuccess(String message) {
    _show(message, Colors.green.shade700);
  }
}
