import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider extends ChangeNotifier {
  static const String _localeKey = 'app_locale';

  Locale _locale = const Locale('en');
  Locale get locale => _locale;

  bool get isUrdu => _locale.languageCode == 'ur';
  String get fontFamily => isUrdu ? 'JameelNooriNastaleeqKasheeda' : 'Roboto';

  /// Call this once at app startup to load saved locale from SharedPreferences
  Future<void> loadSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCode = prefs.getString(_localeKey);
    if (savedCode != null) {
      _locale = Locale(savedCode);
      notifyListeners();
    }
  }

  /// Toggle between English and Urdu
  Future<void> setLocale(Locale locale) async {
    if (_locale == locale) return;
    _locale = locale;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, locale.languageCode);
  }

  /// Convenience methods
  Future<void> switchToEnglish() => setLocale(const Locale('en'));
  Future<void> switchToUrdu() => setLocale(const Locale('ur'));
}
