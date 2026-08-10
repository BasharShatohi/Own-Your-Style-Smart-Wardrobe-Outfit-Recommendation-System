// lib/modules/looks/views/looks_view.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_colors.dart';
import '../controllers/looks_controller.dart';
import 'look_detail_view.dart'; // <- correct relative import (same folder)

class LooksView extends GetView<LooksController> {
  const LooksView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<LooksController>();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Looks'),
        backgroundColor: AppColors.primary,
      ),
      body: SafeArea(
        child: Obx(() {
          if (ctrl.loading.value)
            return const Center(child: CircularProgressIndicator());
          if (ctrl.error.value.isNotEmpty)
            return Center(child: Text(ctrl.error.value));
          if (ctrl.outfits.isEmpty)
            return const Center(child: Text('No saved outfits yet'));

          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.78,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: ctrl.outfits.length,
            itemBuilder: (ctx, i) {
              final outfit = ctrl.outfits[i];
              return GestureDetector(
                onTap: () {
                  final transforms = ctrl.initialTransformsFor(outfit.id);
                  Get.to(
                    () => LookDetailView(
                      outfit: outfit,
                      initialTransforms: transforms,
                    ),
                  );
                },
                child: Card(
                  elevation: 2,
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16),
                          ),
                          child: Image.asset(
                            'assets/images/qqq.png',
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 8, 8, 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                outfit.occasion.isNotEmpty
                                    ? _stylizeOccasion(outfit.occasion)
                                    : 'Unnamed',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 12,
                                  color: Color.fromARGB(255, 10, 10, 14),
                                  fontFamily: 'ComicNeue',
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                size: 18,
                                color: AppColors.danger,
                              ),
                              onPressed: () =>
                                  _showDeleteDialog(context, outfit.id),
                              padding: const EdgeInsets.all(6),
                              constraints: const BoxConstraints(),
                              tooltip: 'Remove Outfit',
                              style: IconButton.styleFrom(
                                backgroundColor: AppColors.background,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }

  String _stylizeOccasion(String occasion) {
    final words = occasion.split(' ');
    if (words.length > 1) {
      return words
          .map(
            (word) =>
                '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}',
          )
          .join(' ');
    }
    return occasion.toUpperCase();
  }

  void _showDeleteDialog(BuildContext context, String outfitId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Outfit'),
          content: const Text(
            'Are you sure you want to delete this outfit? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await controller.deleteOutfit(outfitId);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}
