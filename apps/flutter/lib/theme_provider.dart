import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/local_scope.dart';

class ThemeProvider extends ChangeNotifier {
  static const _legacyKeys = [
    'theme_mode',
    'brand_color',
    'bg_color',
    'pure_black_dark_mode',
  ];
  static const _legacyClaimedKey = 'theme_v2_legacy_claimed';
  ThemeMode _themeMode = ThemeMode.system;
  Color _brandColor = const Color(0xFFEFEFEF);
  Color _bgColor = Colors.white;
  bool _pureBlackDarkMode = false;
  String _owner = guestLocalScopeUserId;
  int _revision = 0;
  Future<void> _storage = Future.value();
  late final Future<void> initialized;

  ThemeProvider() {
    initialized = loadFromPrefs();
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
  Color get effectiveBgColor =>
      _pureBlackDarkMode && isDarkTheme ? Colors.black : _bgColor;

  String _key(String owner) => 'theme_v2_${Uri.encodeComponent(owner)}';

  Future<void> _enqueue(Future<void> Function() operation) {
    final next = _storage.then((_) => operation());
    _storage = next.catchError((Object _) {
      debugPrint('Theme settings could not be saved or loaded.');
    });
    return _storage;
  }

  void _reset() {
    _themeMode = ThemeMode.system;
    _brandColor = const Color(0xFFEFEFEF);
    _bgColor = Colors.white;
    _pureBlackDarkMode = false;
  }

  Future<void> bindUserScope(String userId) {
    if (_owner == userId) return _storage;
    _owner = userId;
    ++_revision;
    // Never display the previous account's palette while this account loads.
    _reset();
    notifyListeners();
    return loadFromPrefs();
  }

  Future<void> loadFromPrefs() {
    final owner = _owner;
    final revision = _revision;
    return _enqueue(() async {
      final prefs = await SharedPreferences.getInstance();
      if (owner != _owner || revision != _revision) return;
      var raw = prefs.getString(_key(owner));
      // Old builds saved one device-wide theme. Claim it exactly once using
      // authenticated account identity, never copy it into every account.
      if (raw == null &&
          owner != guestLocalScopeUserId &&
          prefs.getBool(_legacyClaimedKey) != true &&
          _legacyKeys.any(prefs.containsKey)) {
        raw = jsonEncode({
          'mode': prefs.getInt('theme_mode'),
          'brand': prefs.getInt('brand_color'),
          'background': prefs.getInt('bg_color'),
          'pureBlack': prefs.getBool('pure_black_dark_mode'),
        });
        await prefs.setString(_key(owner), raw);
        await prefs.setBool(_legacyClaimedKey, true);
      }
      if (owner != _owner || revision != _revision) return;
      _reset();
      if (raw != null) {
        try {
          final data = jsonDecode(raw) as Map<String, dynamic>;
          final mode = data['mode'];
          if (mode is int && mode >= 0 && mode < ThemeMode.values.length) {
            _themeMode = ThemeMode.values[mode];
          }
          final brand = data['brand'];
          final background = data['background'];
          if (brand is int) _brandColor = Color(brand);
          if (background is int) _bgColor = Color(background);
          _pureBlackDarkMode = data['pureBlack'] == true;
        } catch (_) {
          _reset();
        }
      }
      notifyListeners();
    });
  }

  Future<void> _save() {
    final owner = _owner;
    ++_revision;
    final snapshot = jsonEncode({
      'mode': _themeMode.index,
      'brand': _brandColor.toARGB32(),
      'background': _bgColor.toARGB32(),
      'pureBlack': _pureBlackDarkMode,
    });
    notifyListeners();
    // Capture both identity and palette before any await. Rapid switches and
    // rapid colour changes cannot redirect or reorder these writes.
    return _enqueue(() async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key(owner), snapshot);
    });
  }

  Future<void> setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    return _save();
  }

  Future<void> toggleDarkTheme() =>
      setThemeMode(isDarkTheme ? ThemeMode.light : ThemeMode.dark);

  Future<void> setThemeColors(Color brand, Color bg) {
    _brandColor = brand;
    _bgColor = bg;
    return _save();
  }

  Future<void> setPureBlackDarkMode(bool value) {
    _pureBlackDarkMode = value;
    return _save();
  }

  @override
  void dispose() {
    ++_revision;
    super.dispose();
  }
}
