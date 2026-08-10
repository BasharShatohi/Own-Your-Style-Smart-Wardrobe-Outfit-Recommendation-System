// lib/modules/wardrobe/views/wardrobe_view.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_style.dart';
import '../../../core/routes/app_pages.dart';
import '../controllers/wardrobe_controller.dart';
import '../../../core/models/clothing_item.dart';

class WardrobeView extends GetView<WardrobeController> {
  const WardrobeView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _AddItemFab(
        onPressed: () => Get.toNamed(Routes.ADD_ITEM),
      ),
      body: SafeArea(
        child: Padding(
          padding: AppStyles.screenPadding.copyWith(bottom: 88),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              const Text(
                'My Wardrobe',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Obx(() {
                  if (controller.isLoading.value) {
                    final crossAxisCount =
                        MediaQuery.of(context).size.width > 600 ? 4 : 2;
                    return _ShimmerGrid(
                      count: controller.visibleCategories.length,
                      crossAxisCount: crossAxisCount,
                    );
                  }

                  final cats = controller.visibleCategories;
                  if (cats.isEmpty) {
                    return const Center(
                      child: Text('No categories available.'),
                    );
                  }

                  final crossAxisCount = MediaQuery.of(context).size.width > 600
                      ? 4
                      : 2;
                  return GridView.builder(
                    padding: const EdgeInsets.only(top: 8),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.1,
                    ),
                    itemCount: cats.length,
                    itemBuilder: (_, i) {
                      final cat = cats[i];
                      final displayName = cat.name;
                      final images = controller.items[displayName] ?? [];
                      return _CategoryCard(
                        title: displayName,
                        images: images,
                        headers: controller.imageHeaders,
                        onTap: () => _openCategorySheet(
                          context,
                          displayName,
                          controller.imageHeaders,
                        ),
                      );
                    },
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// NOTE: We no longer use a captured `images` param. The sheet reads the
  /// controller.items[...] observable so it updates live when items change.
  void _openCategorySheet(
    BuildContext context,
    String title,
    Map<String, String> headers,
  ) {
    final ctrl = controller;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        // SafeArea adds the device's real bottom inset instead of guessing it,
        // so the sheet clears gesture and 3-button navigation bars alike.
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // header row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    // dynamic count
                    Obx(() {
                      final imgs = ctrl.items[title] ?? [];
                      return Text(
                        '${imgs.length} items',
                        style: const TextStyle(color: Colors.grey),
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 12),

                // LIST (reactive)
                SizedBox(
                  height: 140,
                  child: Obx(() {
                    final images = ctrl.items[title] ?? [];
                    if (images.isEmpty) {
                      return const Center(child: Text('No items yet.'));
                    }

                    return ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: images.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (_, idx) {
                        final url = images[idx];
                        return Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(
                                AppStyles.borderRadius,
                              ),
                              child: url.startsWith('http')
                                  ? CachedNetworkImage(
                                      imageUrl: url,
                                      httpHeaders: headers,
                                      width: 120,
                                      height: 120,
                                      fit: BoxFit.cover,
                                      placeholder: (_, __) => Container(
                                        width: 120,
                                        height: 120,
                                        color: Colors.grey[200],
                                      ),
                                      errorWidget: (_, __, ___) => Image.asset(
                                        'assets/images/home_looks.png',
                                        width: 120,
                                        height: 120,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : Image.asset(
                                      url,
                                      width: 120,
                                      height: 120,
                                      fit: BoxFit.cover,
                                    ),
                            ),

                            // Delete button overlay
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () {
                                  // Find the item by image URL to get the ID
                                  final item = ctrl.itemsList.firstWhere(
                                    (item) =>
                                        item.imageUrl == url ||
                                        ctrl.normalizeImageUrl(item.imageUrl) ==
                                            url,
                                    orElse: () => ClothingItem(
                                      id: 0,
                                      imageUrl: '',
                                      categoryGroup: '',
                                    ),
                                  );

                                  if (item.id > 0) {
                                    _showDeleteDialog(context, item.id, title);
                                  } else {
                                    // fallback - try to find by normalized match more aggressively
                                    final match = ctrl.itemsList
                                        .firstWhereOrNull(
                                          (it) =>
                                              ctrl.normalizeImageUrl(
                                                it.imageUrl,
                                              ) ==
                                              url,
                                        );
                                    if (match != null && match.id > 0) {
                                      _showDeleteDialog(
                                        context,
                                        match.id,
                                        title,
                                      );
                                    }
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.delete,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  }),
                ),
                const SizedBox(height: 16),

                // add item button
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    Get.toNamed(Routes.ADD_ITEM);
                  },
                  icon: const Icon(Icons.add),
                  label: Text('Add item to $title'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDeleteDialog(
    BuildContext context,
    int itemId,
    String categoryName,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Item'),
          content: const Text('Are you sure you want to delete this item?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context); // close confirmation dialog
                // Call controller delete. The sheet remains open and will update via Obx.
                await controller.deleteItem(itemId, categoryName);
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final String title;
  final List<String> images;
  final Map<String, String> headers;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.title,
    required this.images,
    required this.headers,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final preview = images.isNotEmpty
        ? images.first
        : 'assets/images/home_looks.png';
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppStyles.borderRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned.fill(
              child: preview.startsWith('http')
                  ? CachedNetworkImage(
                      imageUrl: preview,
                      httpHeaders: headers,
                      fit: BoxFit.cover,
                      placeholder: (_, __) =>
                          Container(color: Colors.grey[200]),
                      errorWidget: (_, __, ___) => Image.asset(
                        'assets/images/home_looks.png',
                        fit: BoxFit.cover,
                      ),
                    )
                  : Image.asset(preview, fit: BoxFit.cover),
            ),
            Positioned(
              left: 8,
              top: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            Positioned(
              right: 8,
              bottom: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${images.length}',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddItemFab extends StatelessWidget {
  final VoidCallback onPressed;
  const _AddItemFab({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        elevation: 8,
      ),
      icon: const Icon(Icons.add, size: 22),
      label: const Text(
        'Add Item',
        style: TextStyle(
          fontFamily: 'Montserrat',
          fontWeight: FontWeight.w700,
          fontSize: 16,
        ),
      ),
    );
  }
}

class _ShimmerGrid extends StatefulWidget {
  final int count;
  final int crossAxisCount;
  const _ShimmerGrid({required this.count, required this.crossAxisCount});

  @override
  State<_ShimmerGrid> createState() => _ShimmerGridState();
}

class _ShimmerGridState extends State<_ShimmerGrid>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctr;

  @override
  void initState() {
    super.initState();
    _ctr = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _ctr.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final itemCount = widget.count == 0 ? 6 : widget.count;
    return GridView.builder(
      padding: const EdgeInsets.only(top: 8),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: widget.crossAxisCount,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.1,
      ),
      itemCount: itemCount,
      itemBuilder: (_, __) {
        return AnimatedBuilder(
          animation: _ctr,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppStyles.borderRadius),
                gradient: LinearGradient(
                  colors: [
                    Colors.grey[300]!,
                    Colors.grey[200]!,
                    Colors.grey[300]!,
                  ],
                  stops: [
                    (_ctr.value - 0.3).clamp(0.0, 1.0),
                    _ctr.value.clamp(0.0, 1.0),
                    (_ctr.value + 0.3).clamp(0.0, 1.0),
                  ],
                  begin: const Alignment(-1.0, -0.3),
                  end: const Alignment(1.0, 0.3),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
