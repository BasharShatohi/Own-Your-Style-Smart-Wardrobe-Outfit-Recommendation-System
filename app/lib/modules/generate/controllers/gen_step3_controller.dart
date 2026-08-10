// lib/modules/generate/controllers/gen_step3_controller.dart
import 'package:get/get.dart';
import '../../../core/models/outfit_models.dart';
import 'package:flutter/foundation.dart';
import 'package:get_storage/get_storage.dart';
import '../../../core/services/api_service.dart';
import 'package:dio/dio.dart' as dio;
import '../../../core/services/generation_service.dart'; // <--- new import
import 'package:flutter/material.dart';

class GenStep3Controller extends GetxController {
  final outfits = <Outfit>[].obs;
  final selectedIndex = 0.obs;
  final highlightedLayer = (-1).obs;

  final RxSet<String> likedOutfits = <String>{}.obs;
  final RxSet<String> dislikedOutfits = <String>{}.obs;

  final RxInt measurementVersion = 0.obs;

  /// outfitId -> layerIndex -> {dx,dy,scale,rotation}
  final Map<String, Map<int, Map<String, double>>> layerTransforms = {};

  final GetStorage _box = GetStorage();

  /// Suggestions and gaps parsed from generator response
  final RxList<String> suggestions = <String>[].obs;
  final RxList<String> gaps = <String>[].obs;

  /// IMPORTANT: adjust to backend units (1000 for pixel-like, 100 for percentage, 1 for fraction)
  static const double serverUnitScale = 1000.0;

  /// loading state for regenerate
  final RxBool regenerating = false.obs;

  Map<String, String> get imageHeaders {
    final token = _box.read('accessToken') ?? '';
    return {if (token.isNotEmpty) 'Authorization': 'Bearer $token'};
  }

  @override
  void onInit() {
    super.onInit();

    final args = Get.arguments;
    if (args is Map && args.containsKey('generated')) {
      final data = args['generated'];
      if (data is Map<String, dynamic>) {
        loadFromGeneratedResponse(data);
        return;
      } else if (data is Map) {
        loadFromGeneratedResponse(Map<String, dynamic>.from(data));
        return;
      }
    }

    loadDemo();
  }

  Outfit? get current =>
      (outfits.isNotEmpty && selectedIndex.value < outfits.length)
      ? outfits[selectedIndex.value]
      : null;

  double _rawToFraction(double raw) {
    if (raw > -1.0 && raw < 1.0) return raw;
    return raw / serverUnitScale;
  }

  double _fractionToRaw(double maybeFraction) {
    if (maybeFraction > -1.0 && maybeFraction < 1.0) {
      return maybeFraction * serverUnitScale;
    }
    return maybeFraction;
  }

  void loadFromGeneratedResponse(Map<String, dynamic> resp) {
    try {
      // parse suggestions and gaps (defensive)
      try {
        suggestions.clear();
        final rawSuggests =
            resp['suggests'] ?? resp['suggestions'] ?? resp['suggestions_list'];
        if (rawSuggests is List) {
          for (final s in rawSuggests) {
            if (s == null) continue;
            suggestions.add(s.toString());
          }
        } else if (rawSuggests is String && rawSuggests.trim().isNotEmpty) {
          // if server returned a single string, split on newline or comma heuristically
          suggestions.addAll(
            rawSuggests
                .split(RegExp(r'[\r\n,;]+'))
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty),
          );
        }
      } catch (_) {
        suggestions.clear();
      }

      try {
        gaps.clear();
        final rawGaps = resp['gaps'] ?? resp['missing'] ?? resp['gaps_list'];
        if (rawGaps is List) {
          for (final g in rawGaps) {
            if (g == null) continue;
            gaps.add(g.toString());
          }
        } else if (rawGaps is String && rawGaps.trim().isNotEmpty) {
          gaps.addAll(
            rawGaps
                .split(RegExp(r'[\r\n,;]+'))
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty),
          );
        }
      } catch (_) {
        gaps.clear();
      }

      final rawItems = (resp['items'] as List?) ?? [];
      final order = [
        'footwear',
        'bottoms',
        'tops',
        'outerwear',
        'dresses & rompers',
        'bags',
        'headwear',
        'neckwear',
        'wristwear',
        'handwear',
        'eyewear',
        'other accessories',
      ];

      final List<ItemLayer> layers = [];

      for (final r in rawItems) {
        if (r is! Map) continue;
        final mapR = Map<String, dynamic>.from(r);

        final imageUrl = (mapR['image_url'] ?? mapR['image'] ?? '').toString();
        final normalized = ApiService.normalizeUrl(imageUrl);

        // IMPORTANT: debug print so you can see what will be fetched
        debugPrint(
          'GenStep3Controller: normalized imageUrl -> $normalized (raw="$imageUrl")',
        );

        final categoryGroup = (mapR['category_group'] ?? '').toString();
        final category = (mapR['category'] ?? '').toString();

        final itemId = mapR['id'] is int
            ? mapR['id'] as int
            : (mapR['id'] is String ? int.tryParse(mapR['id']) : null);

        final rawX = (mapR['x'] is num)
            ? (mapR['x'] as num).toDouble()
            : double.tryParse((mapR['x'] ?? '').toString()) ?? 0.0;
        final rawY = (mapR['y'] is num)
            ? (mapR['y'] as num).toDouble()
            : double.tryParse((mapR['y'] ?? '').toString()) ?? 0.0;
        final rawScale = (mapR['scale'] is num)
            ? (mapR['scale'] as num).toDouble()
            : double.tryParse((mapR['scale'] ?? '1').toString()) ?? 1.0;
        final rawRotation = (mapR['rotation'] is num)
            ? (mapR['rotation'] as num).toDouble()
            : double.tryParse((mapR['rotation'] ?? '0').toString()) ?? 0.0;

        final layer = ItemLayer(
          itemId: itemId,
          asset: normalized.isNotEmpty
              ? normalized
              : 'assets/images/home_looks.png',
          category: category.isNotEmpty
              ? category
              : (categoryGroup.isNotEmpty ? categoryGroup : 'Other'),
          group: categoryGroup.isNotEmpty
              ? categoryGroup.toLowerCase()
              : (category.isNotEmpty
                    ? category.toLowerCase()
                    : 'other accessories'),
          layer: (mapR['layer'] ?? 'generated').toString(),
          clipLeftHalf: false,
          clipRightHalf: false,
          visible: true,
          rawX: rawX,
          rawY: rawY,
          rawScale: rawScale,
          rawRotation: rawRotation,
        );

        layers.add(layer);
      }

      layers.sort((a, b) {
        final ai = order.indexWhere((o) => a.group.toLowerCase().contains(o));
        final bi = order.indexWhere((o) => b.group.toLowerCase().contains(o));
        final aIdx = ai == -1 ? order.length : ai;
        final bIdx = bi == -1 ? order.length : bi;
        return aIdx.compareTo(bIdx);
      });

      final outfitId = resp['id'] != null
          ? resp['id'].toString()
          : 'gen_${DateTime.now().millisecondsSinceEpoch}';
      final weather = (resp['weather'] ?? 'clear').toString();
      final temperature = (resp['temperature'] is num)
          ? (resp['temperature'] as num).toDouble()
          : double.tryParse((resp['temperature'] ?? '').toString()) ?? 15.0;
      final age = (resp['age'] is int)
          ? resp['age'] as int
          : (resp['age'] is String ? int.tryParse(resp['age']) : null);
      final interaction = (resp['interaction'] ?? 'none').toString();
      final occasion = (resp['occasion'] ?? '').toString();
      final gender = (resp['gender'] ?? 'male').toString();

      final outfit = Outfit(
        id: outfitId,
        layers: layers,
        weather: weather,
        temperature: temperature,
        age: age,
        interaction: interaction,
        occasion: occasion,
        gender: gender,
      );

      final Map<int, Map<String, double>> transforms = {};
      for (int i = 0; i < layers.length; i++) {
        final l = layers[i];
        final dxFrac = _rawToFraction(l.rawX);
        final dyFrac = _rawToFraction(l.rawY);
        transforms[i] = {
          'dx': dxFrac,
          'dy': dyFrac,
          'scale': l.rawScale,
          'rotation': l.rawRotation,
        };
      }

      outfits.clear();
      outfits.add(outfit);

      if (transforms.isNotEmpty) {
        layerTransforms[outfit.id] = transforms;
      }

      measurementVersion.value++;
      update();
    } catch (e, st) {
      debugPrint('loadFromGeneratedResponse failed: $e\n$st');
      // clear suggestions/gaps so demo won't show stale info
      suggestions.clear();
      gaps.clear();
      loadDemo();
    }
  }

  void loadDemo() {
    outfits.clear();
    suggestions.clear();
    gaps.clear();

    outfits.add(
      Outfit(
        id: 'demo1',
        layers: [
          ItemLayer(
            asset: 'assets/images/dress.png',
            category: 'Denim dress',
            group: 'dresses & rompers',
            layer: 'base',
            clipLeftHalf: false,
            clipRightHalf: false,
            rawX: 0.0,
            rawY: 0.0,
            rawScale: 1.0,
            rawRotation: 0.0,
          ),
          ItemLayer(
            asset: 'assets/images/Heel pumps.png',
            category: 'pump',
            group: 'footwear',
            layer: 'mid',
            clipLeftHalf: false,
            clipRightHalf: false,
            rawX: 0.0,
            rawY: 0.0,
            rawScale: 1.0,
            rawRotation: 0.0,
          ),
        ],
        occasion: 'casual',
        gender: 'male',
      ),
    );

    // example demo suggestion/gap
    suggestions.addAll([
      'Try a blazer for a sharper look',
      'Add a neutral bag to balance colors',
    ]);
    gaps.addAll(['Sunglasses — sunglasses']);

    measurementVersion.value++;
    update();
  }

  void highlightLayer(int idx) {
    highlightedLayer.value = (highlightedLayer.value == idx) ? -1 : idx;
  }

  void setLayerTransform(
    int outfitIndex,
    int layerIndex,
    double dxFraction,
    double dyFraction,
    double scale,
    double rotationDeg,
  ) {
    if (outfitIndex < 0 || outfitIndex >= outfits.length) return;
    final outfitId = outfits[outfitIndex].id;
    final mapForOutfit = layerTransforms.putIfAbsent(outfitId, () => {});
    mapForOutfit[layerIndex] = {
      'dx': dxFraction,
      'dy': dyFraction,
      'scale': scale,
      'rotation': rotationDeg,
    };
    layerTransforms[outfitId] = mapForOutfit;
    update();
  }

  /// Regenerate using GenerationService with the same temperature, weather, occasion of the current outfit.
  Future<void> regenerate() async {
    final o = current;
    if (o == null) {
      Get.snackbar(
        'Error',
        'No outfit to regenerate from',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final double temp = o.temperature;
    final String occasion = o.occasion;
    final String weather = o.weather;

    regenerating.value = true;
    try {
      final resp = await GenerationService().generateOutfit(
        temperature: temp,
        weather: weather,
        occasion: occasion,
      );

      // generateOutfit is typed Future<Map<String, dynamic>>, so the shape is
      // guaranteed here; a malformed body surfaces as a throw instead.
      loadFromGeneratedResponse(resp);
      Get.snackbar(
        'Regenerated',
        'A new outfit was generated',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e, st) {
      debugPrint('regenerate() error: $e\n$st');
      Get.snackbar('Regenerate failed', e.toString());
    } finally {
      regenerating.value = false;
    }
  }

  void toggleLike(String outfitId) {
    if (likedOutfits.contains(outfitId)) {
      likedOutfits.remove(outfitId);
    } else {
      likedOutfits.add(outfitId);
      dislikedOutfits.remove(outfitId);
    }
  }

  void toggleDislike(String outfitId) {
    if (dislikedOutfits.contains(outfitId)) {
      dislikedOutfits.remove(outfitId);
    } else {
      dislikedOutfits.add(outfitId);
      likedOutfits.remove(outfitId);
    }
  }

  Future<void> save() async {
    final outfit = current;
    if (outfit == null) {
      Get.snackbar(
        'Error',
        'No outfit to save',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final transformsForOutfit = layerTransforms[outfit.id] ?? {};

    // Build items payload
    final itemsPayload = <Map<String, dynamic>>[];

    for (int i = 0; i < outfit.layers.length; i++) {
      final layer = outfit.layers[i];
      final t = transformsForOutfit[i];

      final xRaw = (t != null && t['dx'] != null)
          ? _fractionToRaw(t['dx']!)
          : layer.rawX;
      final yRaw = (t != null && t['dy'] != null)
          ? _fractionToRaw(t['dy']!)
          : layer.rawY;

      final scale = (t != null && t['scale'] != null)
          ? t['scale']!
          : layer.rawScale;
      final rotation = (t != null && t['rotation'] != null)
          ? t['rotation']!
          : layer.rawRotation;

      final itemMap = <String, dynamic>{
        'id': layer.itemId,
        'x': xRaw,
        'y': yRaw,
        'scale': double.parse((scale).toStringAsFixed(4)),
        'rotation': double.parse((rotation).toStringAsFixed(2)),
        'layer': layer.layer,
      };

      itemsPayload.add(itemMap);
    }

    final payload = <String, dynamic>{
      'user_id': _box.read('userId') ?? 1,
      'weather': outfit.weather,
      'temperature': outfit.temperature,
      'occasion': outfit.occasion,
      'gender': outfit.gender,
      'age': outfit.age,
      'interaction': (likedOutfits.contains(outfit.id)
          ? 'liked'
          : (dislikedOutfits.contains(outfit.id)
                ? 'disliked'
                : outfit.interaction)),
      'items': itemsPayload,
    };

    try {
      final dio.Response resp = await ApiService.createOutfit(payload);
      if (resp.statusCode == 201 || resp.statusCode == 200) {
        Get.snackbar(
          'Saved',
          'Outfit saved successfully',
          snackPosition: SnackPosition.BOTTOM,
        );
        Get.offNamed('/looks');
      } else {
        debugPrint('Create outfit failed: ${resp.statusCode} ${resp.data}');
        Get.snackbar(
          'Save failed',
          'Server error: ${resp.statusCode}',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } on dio.DioException catch (e) {
      final status = e.response?.statusCode;
      debugPrint(
        'save() DioException: $status ${e.response?.data} ${e.message}',
      );
      Get.snackbar('Save failed', 'Network or server error');
    } catch (e, st) {
      debugPrint('save() error: $e\n$st');
      Get.snackbar(
        'Save failed',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}
