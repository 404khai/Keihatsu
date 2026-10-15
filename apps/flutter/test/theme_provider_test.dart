import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:keihatsu/theme_provider.dart';
import 'package:keihatsu/services/local_scope.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'themes restore independently across accounts, guest and process recreation',
    () async {
      final theme = ThemeProvider();
      await theme.initialized;
      await theme.bindUserScope('account-a');
      await theme.setThemeColors(Colors.orange, Colors.grey);
      await theme.setThemeMode(ThemeMode.dark);
      await theme.setPureBlackDarkMode(true);
      final switchGuest = theme.bindUserScope(guestLocalScopeUserId);
      expect(theme.brandColor, const Color(0xFFEFEFEF)); // Reset synchronously.
      await switchGuest;
      await theme.setThemeColors(Colors.purple, Colors.white);
      await theme.bindUserScope('account-b');
      expect(theme.themeMode, ThemeMode.system);
      expect(theme.pureBlackDarkMode, false);
      expect(theme.brandColor, const Color(0xFFEFEFEF));
      await theme.setThemeColors(Colors.blue, Colors.white);
      await theme.setThemeMode(ThemeMode.light);
      theme.dispose();

      final restored = ThemeProvider();
      await restored.initialized;
      expect(restored.brandColor.toARGB32(), Colors.purple.toARGB32());
      await restored.bindUserScope('account-a');
      expect(restored.brandColor.toARGB32(), Colors.orange.toARGB32());
      expect(restored.bgColor.toARGB32(), Colors.grey.toARGB32());
      expect(restored.themeMode, ThemeMode.dark);
      expect(restored.pureBlackDarkMode, true);
      await restored.bindUserScope('account-b');
      expect(restored.brandColor.toARGB32(), Colors.blue.toARGB32());
      expect(restored.themeMode, ThemeMode.light);
      expect(restored.pureBlackDarkMode, false);
      restored.dispose();
    },
  );

  test(
    'the unowned legacy theme migrates once, not into every account',
    () async {
      SharedPreferences.setMockInitialValues({
        'brand_color': Colors.orange.toARGB32(),
        'bg_color': Colors.grey.toARGB32(),
        'theme_mode': ThemeMode.dark.index,
        'pure_black_dark_mode': true,
      });
      final theme = ThemeProvider();
      await theme.initialized;
      expect(theme.brandColor, const Color(0xFFEFEFEF));
      await theme.bindUserScope('account-a');
      expect(theme.brandColor.toARGB32(), Colors.orange.toARGB32());
      expect(theme.pureBlackDarkMode, true);
      await theme.bindUserScope('account-b');
      expect(theme.brandColor, const Color(0xFFEFEFEF));
      expect(theme.pureBlackDarkMode, false);
      await theme.bindUserScope('account-a');
      expect(theme.brandColor.toARGB32(), Colors.orange.toARGB32());
      theme.dispose();
    },
  );

  test(
    'rapid account switching cannot redirect pending writes or apply a stale load',
    () async {
      final theme = ThemeProvider();
      await theme.initialized;
      await theme.bindUserScope('account-a');
      final saveA = theme.setThemeColors(Colors.red, Colors.black);
      final loadB = theme.bindUserScope('account-b');
      final saveB = theme.setThemeColors(Colors.green, Colors.white);
      await Future.wait([saveA, loadB, saveB]);
      expect(theme.brandColor.toARGB32(), Colors.green.toARGB32());
      await theme.bindUserScope('account-a');
      expect(theme.brandColor.toARGB32(), Colors.red.toARGB32());
      final staleB = theme.bindUserScope('account-b');
      final latestA = theme.bindUserScope('account-a');
      await Future.wait([staleB, latestA]);
      expect(theme.brandColor.toARGB32(), Colors.red.toARGB32());
      await theme.bindUserScope('account-b');
      expect(theme.brandColor.toARGB32(), Colors.green.toARGB32());
      theme.dispose();
    },
  );

  test(
    'corrupt account settings use defaults rather than another account palette',
    () async {
      SharedPreferences.setMockInitialValues({
        'theme_v2_account-a': 'broken JSON',
      });
      final theme = ThemeProvider();
      await theme.initialized;
      await theme.setThemeColors(Colors.red, Colors.black);
      await theme.bindUserScope('account-a');
      expect(theme.brandColor, const Color(0xFFEFEFEF));
      expect(theme.themeMode, ThemeMode.system);
      theme.dispose();
    },
  );
}
