
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_style.dart';
import '../controllers/gen_step2_controller.dart';

class GenStep2View extends GetView<GenStep2Controller> {
  const GenStep2View({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Get.put(GenStep2Controller());  
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: AppStyles.screenPadding,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                
                Image.asset(
                  'assets/images/qqq.png',
                  width: 150,
                  fit: BoxFit.contain,
                ),

                const SizedBox(height: 24),

                const Text(
                  'Please wait a second…',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 16,
                    color: AppColors.textDark,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 16),

                
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(AppColors.primary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
