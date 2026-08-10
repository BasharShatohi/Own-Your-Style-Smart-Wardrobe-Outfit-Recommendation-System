// lib/modules/looks/bindings/looks_binding.dart
import 'package:get/get.dart';
import '../controllers/looks_controller.dart';

class LooksBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LooksController>(() => LooksController(), fenix: true);
  }
}
