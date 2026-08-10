import 'package:get/get.dart';

import '../../generate/controllers/gen_step1_controller.dart';
import '../../generate/controllers/gen_step2_controller.dart';
import '../../generate/controllers/gen_step3_controller.dart';
import '../../profile/controllers/profile_controller.dart';
import '../../wardrobe/controllers/wardrobe_controller.dart';
import '../../../core/services/clothing_repository.dart';
import '../controllers/main_controller.dart';
import '../../looks/controllers/looks_controller.dart'; // Add this import

class MainBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => MainController());

    if (!Get.isRegistered<ClothingRepository>()) {
      Get.lazyPut<ClothingRepository>(() => ClothingRepository(), fenix: true);
    }
    Get.lazyPut(() => WardrobeController(), fenix: true);

    Get.lazyPut(() => ProfileController());

    Get.lazyPut(() => GenStep1Controller(), fenix: true);
    Get.lazyPut(() => GenStep2Controller(), fenix: true);
    Get.lazyPut(() => GenStep3Controller(), fenix: true);

    Get.lazyPut<LooksController>(() => LooksController(), fenix: true);
  }
}
