import 'package:get/get.dart';

class MainController extends GetxController {
  
  final selectedIndex = 0.obs;

  void changeTab(int idx) => selectedIndex.value = idx;
}
