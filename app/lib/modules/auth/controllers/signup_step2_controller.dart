import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import '../../../core/routes/app_pages.dart';
import '../../../core/services/api_service.dart';
import '../../wardrobe/controllers/wardrobe_controller.dart';

class SignUpStep2Controller extends GetxController {
  final firstNameCtrl = TextEditingController();
  final lastNameCtrl = TextEditingController();
  final birthdayCtrl = TextEditingController();

  var gender = 'Male'.obs;
  final isLoading = false.obs;
  final fieldErrors = <String, String>{}.obs;

  void setGender(String? g) {
    if (g != null) gender.value = g;
  }

  Future<void> pickBirthday() async {
    final d = await showDatePicker(
      context: Get.context!,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (d != null) {
      final formatted = DateFormat('yyyy-MM-dd').format(d);
      birthdayCtrl.text = formatted;
    }
  }

  String formatBirthday(String input) {
    try {
      final formats = ['M/d/yyyy', 'MM/dd/yyyy', 'yyyy-MM-dd'];
      for (var format in formats) {
        try {
          final date = DateFormat(format).parse(input);
          return DateFormat('yyyy-MM-dd').format(date);
        } catch (_) {}
      }
      return input;
    } catch (e) {
      return input;
    }
  }

  String? _extractErrorsFromMap(Map respData) {
    fieldErrors.clear();

    if (respData.containsKey('errors') && respData['errors'] is Map) {
      try {
        final errors = Map<String, dynamic>.from(respData['errors']);
        errors.forEach((field, msgs) {
          String message;
          if (msgs is List && msgs.isNotEmpty) {
            message = msgs.map((e) => e.toString()).join(' ');
          } else if (msgs is String) {
            message = msgs;
          } else {
            message = msgs?.toString() ?? '';
          }
          fieldErrors[field] = message;
        });
        if (fieldErrors.isNotEmpty) return fieldErrors.values.first;
      } catch (_) {}
    }

    if (respData.containsKey('error') && respData['error'] is Map) {
      try {
        final errors = Map<String, dynamic>.from(respData['error']);
        errors.forEach((field, msgs) {
          String message;
          if (msgs is List && msgs.isNotEmpty) {
            message = msgs.map((e) => e.toString()).join(' ');
          } else if (msgs is String) {
            message = msgs;
          } else {
            message = msgs?.toString() ?? '';
          }
          fieldErrors[field] = message;
        });
        if (fieldErrors.isNotEmpty) return fieldErrors.values.first;
      } catch (_) {}
    }

    if (respData.containsKey('message')) {
      final m = respData['message']?.toString();
      if (m != null && m.isNotEmpty) return m;
    }

    String? found;
    void search(dynamic x) {
      if (found != null) return;
      if (x is String && x.isNotEmpty) {
        found = x;
      } else if (x is List && x.isNotEmpty) {
        for (var el in x) {
          search(el);
          if (found != null) return;
        }
      } else if (x is Map) {
        for (var v in x.values) {
          search(v);
          if (found != null) return;
        }
      }
    }

    search(respData);
    return found;
  }

  Future<void> createAccount() async {
    fieldErrors.clear();

    final formattedBirthday = formatBirthday(birthdayCtrl.text);

    // safely get args
    final args = Get.arguments;
    final email = (args is Map && args['email'] is String)
        ? args['email'] as String
        : '';
    final password = (args is Map && args['password'] is String)
        ? args['password'] as String
        : '';

    if (firstNameCtrl.text.isEmpty ||
        lastNameCtrl.text.isEmpty ||
        birthdayCtrl.text.isEmpty) {
      Get.snackbar(
        'Error',
        'All fields are required',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    if (email.isEmpty || password.isEmpty) {
      Get.snackbar(
        'Error',
        'Missing email or password from previous step',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    isLoading.value = true;
    try {
      final response = await ApiService.dio.post(
        'register',
        data: {
          "first_name": firstNameCtrl.text,
          "last_name": lastNameCtrl.text,
          "email": email,
          "password": password,
          "password_confirmation": password,
          "birthday": formattedBirthday,
          "gender": gender.value.toLowerCase(),
          "avatar_url": "http://example.com/avatar.jpg",
        },
      );

      debugPrint('REGISTER response.statusCode: ${response.statusCode}');
      debugPrint('REGISTER response.data: ${response.data}');

      final data = response.data;
      if (data is Map) {
        // success snackbar - green
        Get.snackbar(
          'Success',
          data['message']?.toString() ?? 'Account created',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );

        await Future.delayed(const Duration(seconds: 1));
        final box = GetStorage();
        final g = (data['gender'] ?? gender.value).toString().toLowerCase();

        // Extract token (support both keys), then store. GetStorage is not
        // encrypted, so it holds the session token only — never the password.
        final token = (data['accessToken'] ?? data['access_token'] ?? '')
            .toString();

        box.write('first_name', data['first_name'] ?? '');
        box.write('last_name', data['last_name'] ?? '');
        box.write('email', data['email'] ?? '');
        box.write('gender', g);
        box.write('accessToken', token);

        if (Get.isRegistered<WardrobeController>()) {
          Get.find<WardrobeController>().setUserGender(g);
        }

        Get.offAllNamed(Routes.MAIN);
      } else {
        Get.snackbar(
          'Success',
          data.toString(),
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        Get.offAllNamed(Routes.MAIN);
      }
    } on DioException catch (e) {
      debugPrint('DioException: ${e.toString()}');
      debugPrint('DioException response: ${e.response}');
      debugPrint(
        'DioException response.data runtimeType: ${e.response?.data.runtimeType}',
      );

      final respData = e.response?.data;
      final status = e.response?.statusCode;

      String? messageToShow;

      if (respData is Map) {
        if (status == 422 ||
            respData.containsKey('errors') ||
            respData.containsKey('error')) {
          messageToShow = _extractErrorsFromMap(respData);
        } else {
          messageToShow = _extractErrorsFromMap(respData);
        }
      } else if (respData is String) {
        messageToShow = respData;
      }

      if (messageToShow != null && messageToShow.isNotEmpty) {
        Get.snackbar(
          'Error',
          messageToShow,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      } else {
        final fallback = (respData != null)
            ? respData.toString()
            : 'Registration failed. Please try again.';
        Get.snackbar(
          'Error',
          fallback,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e, st) {
      debugPrint('Unexpected error in createAccount: $e\n$st');
      Get.snackbar(
        'Error',
        'Unexpected error. Please try again.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    firstNameCtrl.dispose();
    lastNameCtrl.dispose();
    birthdayCtrl.dispose();
    super.onClose();
  }
}
