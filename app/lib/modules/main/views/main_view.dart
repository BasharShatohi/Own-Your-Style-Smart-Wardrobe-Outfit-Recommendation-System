import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../generate/views/gen_step1_view.dart';
import '../../wardrobe/views/wardrobe_view.dart';
import '../../looks/views/looks_view.dart';
import '../controllers/main_controller.dart';
import 'tabs/home_tab.dart';
import 'tabs/profile_tab.dart';

class MainView extends GetView<MainController> {
  const MainView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final idx = controller.selectedIndex.value;
      return Scaffold(
        body: _buildBody(idx),
        // Colours come from AppTheme.bottomNavigationBarTheme so the bar stays
        // consistent with the rest of the app.
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: idx,
          onTap: controller.changeTab,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(
              icon: Icon(Icons.auto_awesome),
              label: 'Generate',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.checkroom),
              label: 'Wardrobe',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.style), label: 'Looks'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      );
    });
  }

  Widget _buildBody(int idx) {
    switch (idx) {
      case 0:
        return const HomeTab();
      case 1:
        return const GenStep1View();
      case 2:
        return const WardrobeView();
      case 3:
        return const LooksView();
      case 4:
        return const ProfileTab();
      default:
        return const HomeTab();
    }
  }
}
