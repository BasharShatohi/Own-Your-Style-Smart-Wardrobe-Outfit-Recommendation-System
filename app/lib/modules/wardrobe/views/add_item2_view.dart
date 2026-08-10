// lib/modules/add_item/views/add_item2_view.dart
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_style.dart';
import '../../../core/widgets/custom_button.dart';
import '../controllers/add_item2_controller.dart';

class AddItem2View extends GetView<AddItem2Controller> {
  const AddItem2View({Key? key}) : super(key: key);

  Widget _buildFeatureRows(Map<String, dynamic> feats) {
    if (feats.isEmpty) return const SizedBox.shrink();

    final rows = feats.entries
        .where(
          (e) =>
              e.key != 'imageData' &&
              e.key != 'imageMimeType' &&
              e.key != 'description',
        )
        .map((e) {
          final key = e.key;
          final value = e.value;
          String text;
          if (value is List) {
            text = value.join(', ');
          } else {
            text = value?.toString() ?? '';
          }
          final label = key
              .split('_')
              .map(
                (w) =>
                    w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}',
              )
              .join(' ');
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 130,
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: AppColors.textGrey,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    text,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
              ],
            ),
          );
        })
        .toList();

    return Column(children: rows);
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<AddItem2Controller>();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text(' Analyze item & Save '),
      ),
      body: SafeArea(
        child: Obx(() {
          if (ctrl.isAnalyzing.value) {
            return const Center(child: CircularProgressIndicator());
          }

          if (ctrl.isNotFashionImage.value) {
            return SingleChildScrollView(
              padding: AppStyles.screenPadding,
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppStyles.borderRadius),
                    child: ctrl.imagePath.value.isNotEmpty
                        ? Image.file(
                            File(ctrl.imagePath.value),
                            height: 200,
                            fit: BoxFit.contain,
                          )
                        : const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color.fromARGB(255, 238, 234, 234),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.red.shade400,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Not a fashion item detected',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.red.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'We couldn\'t detect any clothing, shoes, or accessories in your image. Please try uploading a photo of:',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.red.shade600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildFashionExample('👕', 'Tops'),
                            _buildFashionExample('👖', 'Bottoms'),
                            _buildFashionExample('👠', 'Shoes'),
                            _buildFashionExample('👜', 'Bags'),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Get.back(),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text('Go Back'),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: ctrl.retryUpload,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red.shade400,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  'Try Again',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }

          final Uint8List? imgBytes = ctrl.aiImage.value;
          final Map<String, dynamic> feats = Map<String, dynamic>.from(
            ctrl.features,
          );

          if (imgBytes == null || feats.isEmpty) {
            return const Center(child: Text('No data'));
          }

          final String description = feats['description']?.toString() ?? '';

          return SingleChildScrollView(
            padding: AppStyles.screenPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // image
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppStyles.borderRadius),
                  child: Image.memory(
                    imgBytes,
                    height: 220,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 18),

                // description (if present)
                if (description.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(description),
                  ),

                // features read-only
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: AppColors.border),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _buildFeatureRows(feats),
                  ),
                ),

                const SizedBox(height: 18),

                // bottom actions: Edit and Save (save uses controller.saveImage)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            Get.to(() => const AddItem2EditorView()),
                        icon: const Icon(Icons.edit),
                        label: const Text('Edit attributes'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: ctrl.isSaving.value ? null : ctrl.saveImage,
                        icon: ctrl.isSaving.value
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.save),
                        label: Text(ctrl.isSaving.value ? 'Saving...' : 'Save'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildFashionExample(String emoji, String label) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: Text(emoji, style: const TextStyle(fontSize: 24)),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textGrey,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// Editor view: full editable UI (single-select only from pre-defined lists)
class AddItem2EditorView extends StatelessWidget {
  const AddItem2EditorView({Key? key}) : super(key: key);

  String _pretty(String key) {
    return key
        .split(RegExp(r'[_\s]'))
        .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<AddItem2Controller>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Attributes'),
        backgroundColor: AppColors.primary,
      ),
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Obx(() {
          if (ctrl.isAnalyzing.value)
            return const Center(child: CircularProgressIndicator());
          final Uint8List? imgBytes = ctrl.aiImage.value;
          if (imgBytes == null)
            return const Center(child: Text('No image data'));

          // determine selected group (default to first key in ATTRIBUTES if missing)
          final selectedGroup =
              (ctrl.features['category_group'] ?? '').toString().isNotEmpty
              ? (ctrl.features['category_group'] as String)
              : ctrl.ATTRIBUTES.keys.first;
          final groupAttrs = ctrl.ATTRIBUTES[selectedGroup] ?? {};

          return SingleChildScrollView(
            padding: AppStyles.screenPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppStyles.borderRadius),
                  child: Image.memory(
                    imgBytes,
                    height: 180,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 14),

                // Category Group (choose only from defined groups)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Category Group',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value:
                            ctrl.features['category_group']
                                    ?.toString()
                                    .isNotEmpty ==
                                true
                            ? ctrl.features['category_group']?.toString()
                            : null,
                        items: ctrl.ATTRIBUTES.keys
                            .map(
                              (g) => DropdownMenuItem(value: g, child: Text(g)),
                            )
                            .toList(),
                        onChanged: (s) {
                          if (s != null) ctrl.changeCategoryGroup(s);
                        },
                        decoration: const InputDecoration(),
                      ),
                    ],
                  ),
                ),

                // Category (only from category list for selected group)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Category',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value:
                            (ctrl.features['category'] ?? '')
                                .toString()
                                .isNotEmpty
                            ? ctrl.features['category']?.toString()
                            : null,
                        items:
                            (ctrl.CATEGORY_LIST_BY_GROUP[selectedGroup] ??
                                    ['Other'])
                                .map(
                                  (c) => DropdownMenuItem(
                                    value: c,
                                    child: Text(c),
                                  ),
                                )
                                .toList(),
                        onChanged: (s) {
                          if (s != null) ctrl.setString('category', s);
                        },
                        decoration: const InputDecoration(),
                      ),
                    ],
                  ),
                ),

                // Color group (only allow predefined groups)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Color Group',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value:
                            (ctrl.features['color_group'] ?? '')
                                .toString()
                                .isNotEmpty
                            ? ctrl.features['color_group']?.toString()
                            : null,
                        items: ctrl.COLOR_GROUPS
                            .map(
                              (g) => DropdownMenuItem(value: g, child: Text(g)),
                            )
                            .toList(),
                        onChanged: (s) {
                          if (s != null) ctrl.setString('color_group', s);
                        },
                        decoration: const InputDecoration(),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // Attributes for the selected group - only show attributes defined in ATTRIBUTES and restrict to their lists
                ...groupAttrs.entries.map((entry) {
                  final attrKey = entry.key;
                  final options = List<String>.from(entry.value);
                  final pretty = _pretty(attrKey);
                  String current = '';
                  final curVal = ctrl.features[attrKey];
                  if (curVal is List && curVal.isNotEmpty) {
                    current = curVal.first.toString();
                  } else if (curVal != null) {
                    current = curVal.toString();
                  }

                  Widget suffixIcon = const SizedBox.shrink();
                  if (attrKey == 'pattern') {
                    suffixIcon = IconButton(
                      icon: const Icon(Icons.info_outline),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) {
                            return AlertDialog(
                              title: const Text('Patterns'),
                              content: SizedBox(
                                width: double.maxFinite,
                                child: ListView(
                                  shrinkWrap: true,
                                  children: ctrl
                                      .CLIP_PATTERN_DESCRIPTIONS
                                      .entries
                                      .map(
                                        (p) => ListTile(
                                          title: Text(p.key),
                                          subtitle: Text(p.value),
                                        ),
                                      )
                                      .toList(),
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Close'),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    );
                  } else if (attrKey == 'material') {
                    suffixIcon = IconButton(
                      icon: const Icon(Icons.info_outline),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) {
                            return AlertDialog(
                              title: const Text('Materials'),
                              content: SizedBox(
                                width: double.maxFinite,
                                child: ListView(
                                  shrinkWrap: true,
                                  children: ctrl
                                      .CLIP_MATERIAL_DESCRIPTIONS
                                      .entries
                                      .map(
                                        (m) => ListTile(
                                          title: Text(m.key),
                                          subtitle: Text(m.value),
                                        ),
                                      )
                                      .toList(),
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Close'),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    );
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pretty,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: AppColors.textGrey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: options.contains(current) ? current : null,
                          borderRadius: BorderRadius.circular(12),
                          icon: const Icon(
                            Icons.expand_more,
                            color: AppColors.primary,
                          ),
                          style: const TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 15,
                            color: AppColors.textDark,
                          ),
                          items: options
                              .map(
                                (o) =>
                                    DropdownMenuItem(value: o, child: Text(o)),
                              )
                              .toList(),
                          onChanged: (s) {
                            if (s != null) {
                              ctrl.setString(attrKey, s);
                            }
                          },
                          // Fill, radius and focus ring come from the shared
                          // inputDecorationTheme.
                          decoration: InputDecoration(suffixIcon: suffixIcon),
                        ),
                      ],
                    ),
                  );
                }).toList(),

                const SizedBox(height: 12),

                // Save and Cancel
                Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        text: 'Cancel',
                        onPressed: () => Get.back(),
                        isLoading: false,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomButton(
                        text: 'Save',
                        onPressed: ctrl.isSaving.value ? null : ctrl.saveImage,
                        isLoading: ctrl.isSaving.value,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        }),
      ),
    );
  }
}
