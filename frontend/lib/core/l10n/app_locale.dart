import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'translations.dart';

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier();
});

class LocaleNotifier extends StateNotifier<Locale> {
  static const String _key = 'selected_locale';

  LocaleNotifier() : super(const Locale('en')) {
    _loadSavedLocale();
  }

  Future<void> _loadSavedLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final code = prefs.getString(_key);
      if (code != null && (code == 'en' || code == 'te')) {
        state = Locale(code);
      }
    } catch (_) {}
  }

  Future<void> setLocale(String languageCode) async {
    if (languageCode != 'en' && languageCode != 'te') return;
    state = Locale(languageCode);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, languageCode);
    } catch (_) {}
  }

  void toggleLocale() {
    if (state.languageCode == 'en') {
      setLocale('te');
    } else {
      setLocale('en');
    }
  }
}

extension LocalizationExtension on BuildContext {
  AppStrings get tr {
    // Check if Telugu or default to English
    final locale = Localizations.localeOf(this);
    if (locale.languageCode == 'te') {
      return AppStrings.te;
    }
    return AppStrings.en;
  }
}
