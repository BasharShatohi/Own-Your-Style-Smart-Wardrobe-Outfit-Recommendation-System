
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:dio/dio.dart';
import '../../../core/services/clothing_repository.dart';
import '../../../core/models/clothing_item.dart';
import '../../../core/services/api_service.dart';
import '../../../core/routes/app_pages.dart';
import '../../../core/widgets/snackbar_util.dart';

class WardrobeCategory {
  final String key;
  final String name;
  final String gender;
  const WardrobeCategory({
    required this.key,
    required this.name,
    required this.gender,
  });
}

class WardrobeController extends GetxController {
  final GetStorage _box = GetStorage();
  final ClothingRepository _repo = Get.find<ClothingRepository>();

  late String userGender;
  final isLoading = true.obs;

  final List<WardrobeCategory> allCategories = const [
    WardrobeCategory(key: 'tops', name: 'Tops', gender: 'unisex'),
    WardrobeCategory(key: 'outerwear', name: 'Outerwear', gender: 'unisex'),
    WardrobeCategory(key: 'bottoms', name: 'Bottoms', gender: 'unisex'),
    WardrobeCategory(key: 'skirts', name: 'Skirts', gender: 'female'),
    WardrobeCategory(key: 'dresses_rompers', name: 'Dresses & Rompers', gender: 'female'),
    WardrobeCategory(key: 'footwear', name: 'Footwear', gender: 'unisex'),
    WardrobeCategory(key: 'headwear', name: 'Headwear', gender: 'unisex'),
    WardrobeCategory(key: 'bags', name: 'Bags', gender: 'unisex'),
    WardrobeCategory(key: 'neckwear', name: 'Neckwear', gender: 'unisex'),
    WardrobeCategory(key: 'earwear', name: 'Earwear', gender: 'unisex'),
    WardrobeCategory(key: 'wristwear', name: 'Wristwear', gender: 'unisex'),
    WardrobeCategory(key: 'handwear', name: 'Handwear', gender: 'unisex'),
    WardrobeCategory(key: 'eyewear', name: 'Eyewear', gender: 'unisex'),
    WardrobeCategory(key: 'socks_hosiery', name: 'Socks & Hosiery', gender: 'unisex'),
    WardrobeCategory(key: 'other_accessories', name: 'Other Accessories', gender: 'unisex'),
  ];

  final RxMap<String, List<String>> items = <String, List<String>>{}.obs;
  final RxList<ClothingItem> itemsList = <ClothingItem>[].obs;

  List<WardrobeCategory> get visibleCategories =>
      allCategories.where((c) => c.gender == 'unisex' || c.gender == userGender).toList();

  Map<String, String> get imageHeaders {
    final token = _box.read('accessToken') ?? '';
    return {if (token.isNotEmpty) 'Authorization': 'Bearer $token'};
  }

  @override
  void onInit() {
    super.onInit();
    userGender = (_box.read('gender') ?? 'male').toString().toLowerCase();
    _rebuildVisibleItemsFromLocal();
    _fetchRemoteItems();
  }

  void _rebuildVisibleItemsFromLocal() {
    final Map<String, List<String>> next = {};
    for (final cat in visibleCategories) {
      next[cat.name] = [];
    }
    items.assignAll(next);
  }

  Future<void> _fetchRemoteItems() async {
    isLoading.value = true;
    try {
      final list = await _repo.fetchMyClothingItems();
      itemsList.assignAll(list);

      
      debugPrint('Fetched ${list.length} items:');
      for (final item in list) {
        debugPrint('  - ID: ${item.id}, Category: ${item.categoryGroup}, Image: ${item.imageUrl}');
      }

      final Map<String, List<String>> grouped = {};
      for (final cat in visibleCategories) {
        grouped[cat.name] = [];
      }
      grouped['Other Accessories'] = grouped['Other Accessories'] ?? [];

      for (final it in list) {
        final groupName = it.categoryGroup.isNotEmpty ? it.categoryGroup : 'Other Accessories';
        final matched = allCategories.firstWhere(
          (c) => c.name.toLowerCase() == groupName.toLowerCase(),
          orElse: () => const WardrobeCategory(
            key: 'other_accessories',
            name: 'Other Accessories',
            gender: 'unisex',
          ),
        );

        
        final normalizedUrl = normalizeImageUrl(it.imageUrl);
        grouped[matched.name] = (grouped[matched.name] ?? [])..add(normalizedUrl);
      }

      items.assignAll(grouped);
    } catch (e, st) {
      debugPrint('Failed to fetch wardrobe items: $e\n$st');
    } finally {
      isLoading.value = false;
    }
  }

 
  String normalizeImageUrl(String rawUrl) {
    try {
      if (rawUrl.isEmpty) return rawUrl;

      final base = Uri.parse(ApiService.dio.options.baseUrl);
      final origin = Uri(
        scheme: base.scheme,
        host: base.host,
        port: base.hasPort ? base.port : null,
      );
      final originPrefix =
          '${origin.scheme}://${origin.host}${origin.hasPort ? ':${origin.port}' : ''}';

      
      if (!rawUrl.startsWith('http://') && !rawUrl.startsWith('https://')) {
        final withSlash = rawUrl.startsWith('/') ? rawUrl : '/$rawUrl';
        return '$originPrefix$withSlash';
      }

      
      final parsed = Uri.parse(rawUrl);
      if (parsed.host == '127.0.0.1' || parsed.host == 'localhost') {
        final replaced = parsed.replace(
          scheme: origin.scheme,
          host: origin.host,
          port: origin.hasPort ? origin.port : null,
        ).toString();
        return replaced;
      }

      
      if (origin.scheme == 'https' && parsed.scheme == 'http') {
        return parsed.replace(scheme: 'https').toString();
      }

      return rawUrl;
    } catch (e) {
      debugPrint('Error normalizing URL "$rawUrl": $e');
      return rawUrl;
    }
  }

 
  
Future<void> deleteItem(int itemId, String categoryName) async {
  try {
   
    await _repo.deleteClothingItem(itemId);
    
    
    itemsList.removeWhere((item) => item.id == itemId);
    
    
    _updateSpecificCategory(categoryName);
    
    SnackbarUtil.showSuccess('Item deleted successfully');
    
  } on DioException catch (e) {
    final status = e.response?.statusCode;
    
   
    String? message = 'Delete failed'; 
    try {
      if (e.response?.data is Map) {
        final data = e.response?.data as Map;
        message = data['message']?.toString(); 
      } else if (e.response?.data is String) {
        message = e.response?.data.toString();
      }
    } catch (_) {
      message = 'Delete failed';
    }
    
    
    final finalMessage = message ?? 'Delete failed';
    
    if (status == 401) {
      SnackbarUtil.showError('Not authorized. Please login again.');
      Get.offAllNamed(Routes.LOGIN);
    } else if (status == 404) {
      SnackbarUtil.showError('Item not found. It may have been already deleted.');
    } else {
      SnackbarUtil.showError('Delete failed: $finalMessage');
    }
  } catch (e) {
    SnackbarUtil.showError('Unexpected error: $e');
  }
}

 
  void _updateSpecificCategory(String categoryName) {
    try {
      
      final categoryItems = itemsList.where((item) {
        final groupName = item.categoryGroup.isNotEmpty ? item.categoryGroup : 'Other Accessories';
        return groupName.toLowerCase() == categoryName.toLowerCase();
      }).toList();

      
      final normalizedUrls = categoryItems.map((item) => normalizeImageUrl(item.imageUrl)).toList();
      
      
      items[categoryName] = normalizedUrls;
      
     
      items.refresh();
      
    } catch (e) {
      debugPrint('Error updating category $categoryName: $e');
    }
  }

  void setUserGender(String gender) {
    userGender = gender.toLowerCase();
    _box.write('gender', userGender);
    _rebuildVisibleItemsFromLocal();
    _fetchRemoteItems();
  }

  void addItemToCategory(String categoryName, String imageUrl) {
    final list = items[categoryName] ?? [];
    list.insert(0, imageUrl);
    items[categoryName] = List.from(list);
  }

  void refreshItems() => _fetchRemoteItems();
}