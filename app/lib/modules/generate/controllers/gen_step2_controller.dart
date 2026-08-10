
import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import '../../../core/routes/app_pages.dart';
import '../../../core/services/generation_service.dart';

class GenStep2Controller extends GetxController {
  final GenerationService _generationService = GenerationService();
  final RxBool isWorking = true.obs;
  final RxString statusMessage = 'Generating outfit...'.obs;

  @override
  void onInit() {
    super.onInit();
    
    WidgetsBinding.instance.addPostFrameCallback((_) => _startGeneration());
  }

  Future<void> _startGeneration() async {
    try {
      final args = Get.arguments;
      double temperature = 15.0;
      String weather = 'clear';
      int occasionIndex = -1;

      if (args is Map) {
        if (args['temperature'] is num) temperature = (args['temperature'] as num).toDouble();
        if (args['weather'] is String) weather = args['weather'] as String;
        if (args['occasionIndex'] is int) occasionIndex = args['occasionIndex'] as int;
      }

     
      final occasions = [
        'casual',
        'formal',
        'sport',
        'party',
        'wedding',
        'beachwear',
        'lounge',
        'other',
      ];
      final occasion = (occasionIndex >= 0 && occasionIndex < occasions.length)
          ? occasions[occasionIndex]
          : 'casual';

      statusMessage.value = 'Contacting generator...';

      final resp = await _generationService.generateOutfit(
        temperature: temperature,
        weather: weather,
        occasion: occasion,
      );

      
      isWorking.value = false;
      Get.offNamed(Routes.GEN_STEP3, arguments: {'generated': resp});
    } catch (e, st) {
      debugPrint('Generation error: $e\n$st');
      isWorking.value = false;
      statusMessage.value = 'Generation failed';
      Get.snackbar('Generation failed', e.toString(), snackPosition: SnackPosition.BOTTOM);
      
      Get.offNamed(Routes.GEN_STEP3);
    }
  }
}
