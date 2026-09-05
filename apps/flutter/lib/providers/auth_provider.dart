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
  // Android resolves the server client ID from google-services.json. This may
  // be overridden for platforms/builds without generated Google services.
  static const String _configuredServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
  );

  final AuthApi _authApi = AuthApi(baseUrl: ApiConstants.baseUrl);
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  final UserRepository userRepository;
  final Future<void> Function(String userId)? onLogout;

  User? _user;
  String? _token;
  UserPreferences? _preferences;
  bool _isLoading = false;
  late final Future<void> _googleSignInInitialization;

  User? get user => _user;
  String? get token => _token;
  UserPreferences? get preferences => _preferences;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _token != null;
  String get localScopeUserId => _user?.id ?? guestLocalScopeUserId;

  AuthProvider({this.onLogout, required this.userRepository}) {
    _googleSignInInitialization = _initializeGoogleSignIn();
    _init();
  }

  Future<void> _initializeGoogleSignIn() async {
    final configuredServerClientId = _configuredServerClientId.trim();
    await _googleSignIn.initialize(
      serverClientId: configuredServerClientId.isEmpty
          ? null
          : configuredServerClientId,
    );
    debugPrint('GoogleSignIn initialized');
  }

  Future<void> _init() async {
    try {
      await _googleSignInInitialization;
    } catch (e, stackTrace) {
      debugPrint('GoogleSignIn initialization failed: $e');
      debugPrintStack(stackTrace: stackTrace);
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

  /// Reloads the authoritative profile after an editor route closes.
  ///
  /// Profile updates return before the previous route is revealed. Fetching
  /// the user again prevents that cached route from continuing to render an
  /// older avatar configuration, while retaining the separately loaded stats.
  Future<void> refreshCurrentUser() async {
    if (_token == null) return;

    final currentStats = _user?.stats;
    final refreshedUser = await _authApi.getMe(_token!);
    _user = refreshedUser.copyWith(stats: currentStats);
    notifyListeners();
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
      await _googleSignInInitialization;
      final googleUser = await _googleSignIn.authenticate();
      debugPrint('GoogleSignIn account selected: ${googleUser.email}');

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
      debugPrint('GoogleSignIn failed (${e.code}): ${e.description}');
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw Exception('Google sign-in was canceled.');
      }
      if (e.code == GoogleSignInExceptionCode.clientConfigurationError ||
          e.code == GoogleSignInExceptionCode.providerConfigurationError) {
        throw Exception(
          'Google sign-in is not configured for this Android build: '
          '${e.description ?? e.code}.',
        );
      }
      rethrow;
    } catch (e, stackTrace) {
      _isLoading = false;
      notifyListeners();
      debugPrint('Google authentication failed: $e');
      debugPrintStack(stackTrace: stackTrace);
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
    File? banner,
    double? avatarHue,
    double? avatarShape,
    required String avatarExpression,
    required bool avatarAnimated,
  }) async {
    if (_token == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final updatedUser = await _authApi.updateProfile(
        token: _token!,
        username: username,
        bio: bio,
        banner: banner,
        avatarHue: avatarHue,
        avatarShape: avatarShape,
        avatarExpression: avatarExpression,
        avatarAnimated: avatarAnimated,
      );
      _user = updatedUser.copyWith(stats: _user?.stats);
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
