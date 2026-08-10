// lib/modules/looks/controllers/looks_controller.dart
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter/foundation.dart'; // Ensure this import is present for debugPrint
import 'package:dio/dio.dart' as dio;

import '../../../core/models/outfit_models.dart';
import '../../../core/services/api_service.dart';
import '../../../core/widgets/snackbar_util.dart';

class LooksController extends GetxController {
  final RxList<Outfit> outfits = <Outfit>[].obs;
  final RxBool loading = false.obs;
  final RxString error = ''.obs;
  final GetStorage _box = GetStorage();

  final RxMap<String, Map<int, Map<String, double>>> outfitTransforms =
      <String, Map<int, Map<String, double>>>{}.obs;

  static const double SERVER_CANVAS_SIZE = 1000.0;

  Map<String, String> get _authHeaders {
    final token = _box.read('accessToken') ?? '';
    final headers = <String, String>{'Accept': 'application/json'};
    if (token.isNotEmpty) headers['Authorization'] = 'Bearer $token';
    return headers;
  }

  /// Public getter that views can use to supply to image network loaders
  Map<String, String> get imageHeaders => _authHeaders.map((k, v) => MapEntry(k, v));

  @override
  void onInit() {
    super.onInit();
    fetchOutfits();
  }

  Future<void> fetchOutfits() async {
    loading.value = true;
    error.value = '';
    try {
      final opts = dio.Options(headers: _authHeaders, validateStatus: (s) => s != null && s < 500);
      final dio.Response resp = await ApiService.dio.get('outfits', options: opts);

      if (resp.statusCode == 200) {
        final data = resp.data;
        debugPrint('OUTFITS RAW RESPONSE: ${resp.data}');

        final List<dynamic> listData;
        if (data is List) {
          listData = data;
        } else if (data is Map && data['data'] is List) {
          listData = data['data'] as List;
        } else if (data is Map && data.containsKey('items')) {
          listData = [data];
        } else {
          listData = [];
        }

        final parsed = listData.map<Outfit>((o) {
          final m = Map<String, dynamic>.from(o as Map);
          return Outfit.fromApiMap(m);
        }).toList();

        outfits.assignAll(parsed);

        // Build transform map using rawX/rawY/rawScale/rawRotation
        final Map<String, Map<int, Map<String, double>>> transforms = {};
        for (final outfit in outfits) {
          double serverSize = SERVER_CANVAS_SIZE; // use same for x and y if unknown
          dynamic rawMap;
          try {
            rawMap = listData.firstWhere((e) => e is Map && e['id']?.toString() == outfit.id, orElse: () => null);
          } catch (_) {
            rawMap = null;
          }
          if (rawMap is Map) {
            if (rawMap['canvas_size'] != null) {
              serverSize = (rawMap['canvas_size'] as num).toDouble();
            } else if (rawMap['canvas_width'] != null) {
              serverSize = (rawMap['canvas_width'] as num).toDouble();
            }
          }

          final Map<int, Map<String, double>> tForOutfit = {};
          for (int i = 0; i < outfit.layers.length; i++) {
            final layer = outfit.layers[i];
            final dx = _toFraction(layer.rawX, serverSize);
            final dy = _toFraction(layer.rawY, serverSize);
            final s = layer.rawScale;
            final rot = layer.rawRotation;
            tForOutfit[i] = {'dx': dx, 'dy': dy, 'scale': s, 'rotation': rot};
          }
          transforms[outfit.id] = tForOutfit;
        }

        outfitTransforms.assignAll(transforms);
      } else if (resp.statusCode == 401) {
        error.value = 'Not authorized';
      } else {
        final code = resp.statusCode ?? 0;
        error.value = 'Server error ($code)';
        debugPrint('fetchOutfits server error $code: ${resp.data}');
      }
    } on dio.DioException catch (e) {
      debugPrint('fetchOutfits DioException: ${e.message} ${e.response}');
      error.value = 'Failed to load looks';
    } catch (e, st) {
      debugPrint('fetchOutfits unknown error: $e\n$st');
      error.value = 'Failed to load looks';
    } finally {
      loading.value = false;
    }
  }

  double _toFraction(double raw, double serverCanvasSize) {
    if (raw > -1.0 && raw < 1.0) return raw;
    if (serverCanvasSize == 0) return raw;
    return raw / serverCanvasSize;
  }

  Map<int, Map<String, double>> initialTransformsFor(String outfitId) {
    return outfitTransforms[outfitId] ?? {};
  }

  void updateLayerTransform(String outfitId, int layerIndex, double dx, double dy, double scale, double rotation) {
    final map = outfitTransforms.putIfAbsent(outfitId, () => {});
    map[layerIndex] = {'dx': dx, 'dy': dy, 'scale': scale, 'rotation': rotation};
    outfitTransforms[outfitId] = map;
    outfitTransforms.refresh();
  }

  Future<void> deleteOutfit(String id) async {
    try {
      final resp = await ApiService.deleteOutfit(id);
      if (resp.statusCode == 200 || resp.statusCode == 204) {
        SnackbarUtil.showSuccess('Outfit deleted successfully');
        outfits.removeWhere((outfit) => outfit.id == id);
      } else {
        SnackbarUtil.showError('Failed to delete outfit: ${resp.statusCode}');
      }
    } catch (e) {
      SnackbarUtil.showError('Failed to delete outfit: $e');
    }
  }
}