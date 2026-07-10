import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/user_preferences.dart';
import '../services/auth_api.dart';
import '../services/api_constants.dart';
import '../services/user_repository.dart';
import '../services/local_scope.dart';

class AuthProvider with ChangeNotifier {
  static const String _webClientId =
      '887783028868-hgp7fi78npk9otdkk6hil8ot74asaj83.apps.googleusercontent.com';

  final AuthApi _authApi = AuthApi(baseUrl: ApiConstants.baseUrl);
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  final UserRepository userRepository;
  final Future<void> Function(String userId)? onLogout;

  User? _user;
  String? _token;
  UserPreferences? _preferences;
  bool _isLoading = false;
  bool _isInitialized = false;

  User? get user => _user;
  String? get token => _token;
  UserPreferences? get preferences => _preferences;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _token != null;
  String get localScopeUserId => _user?.id ?? guestLocalScopeUserId;

  AuthProvider({this.onLogout, required this.userRepository}) {
    _init();
  }

  Future<void> _init() async {
    try {
      await _googleSignIn.initialize(serverClientId: _webClientId);
      _isInitialized = true;
    } catch (e) {
      debugPrint('GoogleSignIn initialization failed: $e');
    }
    await _loadToken();
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('accessToken');
    if (_token != null) {
      try {
        _user = await _authApi.getMe(_token!);
        try {
          final stats = await _authApi.getUserStats(_token!);
          _user = _user!.copyWith(stats: stats);
        } catch (e) {
          debugPrint('Failed to load user stats: $e');
        }

        await fetchPreferences();
        notifyListeners();
      } catch (e) {
        _token = null;
        await prefs.remove('accessToken');
        notifyListeners();
      }
    }
  }

  Future<void> refreshUserStats() async {
    if (_token == null || _user == null) return;
    try {
      final stats = await _authApi.getUserStats(_token!);
      _user = _user!.copyWith(stats: stats);
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to refresh user stats: $e');
      rethrow;
    }
  }

  Future<void> fetchPreferences() async {
    try {
      final localPrefs = await userRepository.getPreferences();
      if (localPrefs != null) {
        _preferences = localPrefs;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading local preferences: $e');
    }

    if (_token != null) {
      try {
        await userRepository.refreshPreferences(_token!);
        final updatedPrefs = await userRepository.getPreferences();
        if (updatedPrefs != null) {
          _preferences = updatedPrefs;
          notifyListeners();
        }
      } catch (e) {
        debugPrint('Error fetching preferences: $e');
      }
    }
  }

  Future<void> updatePreferences(Map<String, dynamic> updates) async {
    if (_preferences == null) return;

    final oldPreferences = _preferences;

    Map<String, SourcePreference>? newSourcePreferences;
    if (updates.containsKey('source_preferences')) {
      final sourceUpdates =
          updates['source_preferences'] as Map<String, dynamic>;
      newSourcePreferences = Map.from(_preferences!.sourcePreferences);
      sourceUpdates.forEach((key, value) {
        if (value is Map<String, dynamic>) {
          newSourcePreferences![key] = SourcePreference.fromJson(value);
        }
      });
    }

    _preferences = _preferences!.copyWith(
      libraryDisplayStyle: updates['library_display_style'],
      libraryItemsPerRow: updates['library_items_per_row'],
      overlayShowDownloaded: updates['overlay_show_downloaded'],
      overlayShowUnread: updates['overlay_show_unread'],
      overlayShowLanguage: updates['overlay_show_language'],
      tabsShowCategories: updates['tabs_show_categories'],
      tabsShowItemCount: updates['tabs_show_item_count'],
      categoriesDisplayMode: updates['categories_display_mode'],
      sourcePreferences: newSourcePreferences,
    );
    notifyListeners();

    await userRepository.savePreferencesLocally(_preferences!);

    if (_token != null) {
      try {
        await userRepository.updatePreferences(_token!, updates);
      } catch (e) {
        debugPrint('Error updating preferences: $e');
        _preferences = oldPreferences;
        if (oldPreferences != null) {
          await userRepository.savePreferencesLocally(oldPreferences);
        }
        notifyListeners();
        rethrow;
      }
    }
  }

  Future<void> updateSourcePreference(
    String sourceId, {
    bool? enabled,
    bool? pinned,
  }) async {
    if (_token == null || _preferences == null) return;

    final currentPrefs =
        _preferences!.sourcePreferences[sourceId] ?? SourcePreference();
    final newPrefs = SourcePreference(
      enabled: enabled ?? currentPrefs.enabled,
      pinned: pinned ?? currentPrefs.pinned,
    );

    try {
      await updatePreferences({
        'source_preferences': {sourceId: newPrefs.toJson()},
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<void> loginWithGoogle() async {
    _isLoading = true;
    notifyListeners();

    try {
      if (!_isInitialized) {
        await _googleSignIn.initialize(serverClientId: _webClientId);
        _isInitialized = true;
      }

      try {
        await _googleSignIn.signOut();
      } catch (_) {}

      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();

      final GoogleSignInAuthentication googleAuth = googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      if (idToken == null) {
        throw Exception(
          'Google returned a null ID Token. Add your debug SHA-1 fingerprint '
          'to Firebase Console and re-download google-services.json.',
        );
      }

      final prefs = await SharedPreferences.getInstance();
      final hasSeenOnboarding = prefs.getBool('hasSeenOnboarding');

      final authResponse = await _authApi.loginWithGoogle(
        idToken,
        isOnboarded: hasSeenOnboarding,
      );
      _user = authResponse.user;
      _token = authResponse.accessToken;

      await prefs.setString('accessToken', _token!);

      await fetchPreferences();

      _isLoading = false;
      notifyListeners();
    } on GoogleSignInException catch (e) {
      _isLoading = false;
      notifyListeners();
      if (e.code == GoogleSignInExceptionCode.canceled) {
        return;
      }
      rethrow;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}

    final logoutUserId = _user?.id;
    if (onLogout != null && logoutUserId != null) {
      await onLogout!(logoutUserId);
    }

    _user = null;
    _token = null;
    _preferences = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('accessToken');
    notifyListeners();
  }

  Future<void> updateProfile({
    String? username,
    String? bio,
    File? avatar,
    File? banner,
  }) async {
    if (_token == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final updatedUser = await _authApi.updateProfile(
        token: _token!,
        username: username,
        bio: bio,
        avatar: avatar,
        banner: banner,
      );
      _user = updatedUser;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateProfileVisibility(bool isProfilePublic) async {
    if (_token == null || _user == null) return;

    final previousUser = _user;
    _user = _user!.copyWith(isProfilePublic: isProfilePublic);
    notifyListeners();

    try {
      final updatedUser = await _authApi.updateProfileVisibility(
        token: _token!,
        isProfilePublic: isProfilePublic,
      );
      _user = updatedUser.copyWith(stats: previousUser?.stats);
      notifyListeners();
    } catch (e) {
      _user = previousUser;
      notifyListeners();
      rethrow;
    }
  }
}
