import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _themeModeKey = 'theme_mode';
  static const String _brandColorKey = 'brand_color';
  static const String _bgColorKey = 'bg_color';
  static const String _pureBlackKey = 'pure_black_dark_mode';

  static const Color roseBlushBrand = Color(0xFFFFBEEB);
  static const Color roseBlushBg = Color(0xFFFBEBF7);
  static const Color sunriseGoldBrand = Color(0xFFF9E216);
  static const Color sunriseGoldBg = Color(0xFFFBFBEB);

  ThemeMode _themeMode = ThemeMode.system;
  Color _brandColor = Colors.black;
  Color _bgColor = Colors.white;
  bool _pureBlackDarkMode = false;

  ThemeProvider() {
    loadFromPrefs();
  }

  ThemeMode get themeMode => _themeMode;
  Color get brandColor => _brandColor;
  Color get bgColor => _bgColor;
  bool get pureBlackDarkMode => _pureBlackDarkMode;
  bool get isDarkTheme =>
      _themeMode == ThemeMode.dark ||
      (_themeMode == ThemeMode.system &&
          WidgetsBinding.instance.platformDispatcher.platformBrightness ==
              Brightness.dark);

  bool get isDarkMode => isDarkTheme;

  Color get effectiveBgColor {
    if (_pureBlackDarkMode && isDarkTheme) {
      return Colors.black;
    }
    return _bgColor;
  }

  bool get isRoseBlush =>
      _brandColor.value == roseBlushBrand.value &&
      _bgColor.value == roseBlushBg.value;

  bool get isSunriseGold =>
      _brandColor.value == sunriseGoldBrand.value &&
      _bgColor.value == sunriseGoldBg.value;

  Future<void> loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();

    final modeIndex = prefs.getInt(_themeModeKey);
    if (modeIndex != null) {
      _themeMode = ThemeMode.values[modeIndex];
    }

    final brandValue = prefs.getInt(_brandColorKey);
    if (brandValue != null) {
      _brandColor = Color(brandValue);
    }

    final bgValue = prefs.getInt(_bgColorKey);
    if (bgValue != null) {
      _bgColor = Color(bgValue);
    }

    _pureBlackDarkMode = prefs.getBool(_pureBlackKey) ?? false;

    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeModeKey, mode.index);
  }

  Future<void> toggleDarkTheme() async {
    final ThemeMode newMode =
        isDarkTheme ? ThemeMode.light : ThemeMode.dark;
    await setThemeMode(newMode);
  }

  Future<void> setThemeColors(Color brand, Color bg) async {
    _brandColor = brand;
    _bgColor = bg;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_brandColorKey, brand.value);
    await prefs.setInt(_bgColorKey, bg.value);
  }

  Future<void> setPureBlackDarkMode(bool value) async {
    _pureBlackDarkMode = value;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_pureBlackKey, value);
  }
}
