
import 'package:get/get.dart';
import '../../../core/services/clothing_repository.dart';
import '../controllers/wardrobe_controller.dart';

class WardrobeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ClothingRepository>(() => ClothingRepository(), fenix: true);
    Get.lazyPut<WardrobeController>(() => WardrobeController(), fenix: true);
  }
}