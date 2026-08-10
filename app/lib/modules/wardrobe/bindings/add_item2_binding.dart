import 'package:get/get.dart';
import '../controllers/add_item2_controller.dart';
import '../../../core/services/clothing_repository.dart';

class AddItem2Binding extends Bindings {
  @override
  void dependencies() {
    
    Get.lazyPut<ClothingRepository>(() => ClothingRepository());
    Get.lazyPut<AddItem2Controller>(() => AddItem2Controller());
  }
}
