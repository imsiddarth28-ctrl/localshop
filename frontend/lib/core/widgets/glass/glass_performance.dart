import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_tokens.dart';

class GlassPerformanceNotifier extends StateNotifier<GlassTier> {
  GlassPerformanceNotifier() : super(_probeInitialTier()) {
    _loadUserPreference();
  }

  static GlassTier _probeInitialTier() {
    // Web or high performance modern mobile devices default to high
    if (kIsWeb) return GlassTier.high;
    // On Android/iOS check platform capabilities
    return GlassTier.high;
  }

  Future<void> _loadUserPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final reduceEffects = prefs.getBool('reduce_glass_effects') ?? false;
      if (reduceEffects) {
        state = GlassTier.low;
      }
    } catch (_) {}
  }

  Future<void> setTier(GlassTier tier) async {
    state = tier;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('reduce_glass_effects', tier == GlassTier.low);
    } catch (_) {}
  }
}

final glassTierProvider = StateNotifierProvider<GlassPerformanceNotifier, GlassTier>((ref) {
  return GlassPerformanceNotifier();
});
