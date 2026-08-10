import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_style.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/routes/app_pages.dart';

class AddItemView extends StatefulWidget {
  const AddItemView({Key? key}) : super(key: key);

  @override
  State<AddItemView> createState() => _AddItemViewState();
}

class _AddItemViewState extends State<AddItemView> {
  final ImagePicker _picker = ImagePicker();
  XFile? _pickedImage;

  Future<void> _pickImage() async {
    final choice = await showModalBottomSheet<ImageSource>(
      context: context,
      // SafeArea keeps the last tile clear of the system navigation bar —
      // gesture pill or 3-button, whichever the device uses.
      builder: (_) => SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (choice != null) {
      final file = await _picker.pickImage(
        source: choice,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );
      if (file != null) {
        setState(() => _pickedImage = file);
      }
    }
  }

  void _goNext() {
    if (_pickedImage != null) {
      Get.toNamed(Routes.ADD_ITEM2, arguments: {'path': _pickedImage!.path});
    } else {
      Get.snackbar(
        'Please pick an image',
        'You need to select one to continue',
      );
    }
  }

  @override
  Widget build(BuildContext c) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: AppStyles.screenPadding,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'add items to your wardrobe\nand get started generating your outfits',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 16,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 40),

                if (_pickedImage != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppStyles.borderRadius),
                    child: Image.file(
                      File(_pickedImage!.path),
                      width: 150,
                      height: 150,
                      fit: BoxFit.cover,
                    ),
                  ),

                const SizedBox(height: 20),

                CustomButton(
                  text: _pickedImage == null
                      ? ' Upload images'
                      : 'Change Image',
                  onPressed: _pickImage,
                ),

                const SizedBox(height: 20),

                // Next button
                if (_pickedImage != null)
                  CustomButton(text: 'Next', onPressed: _goNext),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
