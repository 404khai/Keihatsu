import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/user_preferences.dart';
import '../services/auth_api.dart';
import '../services/api_constants.dart';
import '../services/user_repository.dart';
import '../services/local_scope.dart';
import '../services/credential_store.dart';

class AuthProvider with ChangeNotifier {
  // Android resolves the server client ID from google-services.json. This may
  // be overridden for platforms/builds without generated Google services.
  static const String _configuredServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
  );

  final AuthApi _authApi;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  final UserRepository userRepository;
  final CredentialStore _credentials;
  int _sessionGeneration = 0;
  int _preferenceRevision = 0;
  Future<void> _preferenceWrites = Future.value();
  final Future<void> Function(String userId)? onLogout;

  User? _user;
  String? _token;
  UserPreferences? _preferences;
  bool _isLoading = false;
  late final Future<void> _googleSignInInitialization;
  late final Future<void> initialized;
  bool _restoreFailed = false;
  bool get restoreFailed => _restoreFailed;

  User? get user => _user;
  String? get token => _token;
  UserPreferences? get preferences => _preferences;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _token != null;
  String get localScopeUserId => _user?.id ?? guestLocalScopeUserId;

  AuthProvider({
    this.onLogout,
    required this.userRepository,
    CredentialStore? credentials,
    AuthApi? authApi,
    Future<void> Function()? initializeGoogleSignIn,
  }) : _credentials = credentials ?? CredentialStore(),
       _authApi = authApi ?? AuthApi(baseUrl: ApiConstants.baseUrl) {
    _googleSignInInitialization =
        (initializeGoogleSignIn ?? _initializeGoogleSignIn)();
    // Google SDK availability must not block restoration of an API session.
    _googleSignInInitialization.catchError((Object _) {
      debugPrint('Google sign-in initialization failed.');
    });
    initialized = _loadToken();
  }

  Future<void> _initializeGoogleSignIn() async {
    final configuredServerClientId = _configuredServerClientId.trim();
    await _googleSignIn.initialize(
      serverClientId: configuredServerClientId.isEmpty
          ? null
          : configuredServerClientId,
    );
  }

  Future<void> retrySessionRestore() async {
    await _loadToken();
  }

  Future<void> _loadToken() async {
    final generation = _sessionGeneration;
    _restoreFailed = false;
    String? savedToken;
    try {
      savedToken = await _credentials.read();
    } catch (_) {
      // Preserve the existing session in storage for a later retry.
      if (generation == _sessionGeneration) {
        _restoreFailed = true;
        notifyListeners();
      }
      debugPrint('Secure login storage is temporarily unavailable.');
      return;
    }
    if (generation != _sessionGeneration) return;
    if (savedToken == null) {
      await fetchPreferences();
      return;
    }
    try {
      final user = await _authApi.getMe(savedToken);
      if (generation != _sessionGeneration) return;
      _token = savedToken;
      _user = user;
      _preferences = await userRepository.getPreferences() ?? UserPreferences();
      if (generation != _sessionGeneration) return;
      notifyListeners();
      unawaited(Future.wait([fetchPreferences(), _loadStats()]));
    } catch (error) {
      if (generation != _sessionGeneration) return;
      _token = null;
      // A connection failure must not destroy a migrated, otherwise valid login.
      if (error is! AuthApiException ||
          (error.statusCode != 401 && error.statusCode != 403)) {
        _restoreFailed = true;
        debugPrint('Unable to restore login; the saved session is retained.');
        notifyListeners();
        return;
      }
      try {
        await _credentials.remove();
      } catch (_) {
        debugPrint('Secure login cleanup will be retried.');
      }
      notifyListeners();
    }
  }

  Future<void> _loadStats() async {
    try {
      await refreshUserStats();
    } catch (_) {
      debugPrint('Unable to load user statistics.');
    }
  }

  Future<void> refreshUserStats() async {
    if (_token == null || _user == null) return;
    final token = _token!;
    final userId = _user!.id;
    try {
      final stats = await _authApi.getUserStats(token);
      if (_token != token || _user?.id != userId) return;
      _user = _user!.copyWith(stats: stats);
      notifyListeners();
    } catch (e) {
      if (_token != token || _user?.id != userId) return;
      debugPrint('Failed to refresh user stats.');
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

    final token = _token!;
    final generation = _sessionGeneration;
    final currentStats = _user?.stats;
    final refreshedUser = await _authApi.getMe(token);
    if (generation != _sessionGeneration || token != _token) return;
    _user = refreshedUser.copyWith(stats: currentStats);
    notifyListeners();
  }

  Future<void> fetchPreferences() async {
    final revision = _preferenceRevision;
    final generation = _sessionGeneration;
    final token = _token;
    try {
      final localPrefs = await userRepository.getPreferences();
      if (generation != _sessionGeneration || revision != _preferenceRevision)
        return;
      {
        _preferences = localPrefs ?? _preferences ?? UserPreferences();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading local preferences.');
    }

    if (token != null && generation == _sessionGeneration) {
      try {
        await userRepository.refreshPreferences(token);
        if (generation != _sessionGeneration || revision != _preferenceRevision)
          return;
        final updatedPrefs = await userRepository.getPreferences();
        if (generation != _sessionGeneration || revision != _preferenceRevision)
          return;
        if (updatedPrefs != null) {
          _preferences = updatedPrefs;
          notifyListeners();
        }
      } catch (e) {
        debugPrint('Error fetching preferences.');
      }
    }
  }

  Future<void> updatePreferences(Map<String, dynamic> updates) async {
    _preferences ??= UserPreferences();
    ++_preferenceRevision;
    final generation = _sessionGeneration;
    final token = _token;
    final ownerUserId = localScopeUserId;

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

    final snapshot = _preferences!;
    // Serialize durable writes so rapid grid/row changes cannot finish backwards.
    final write = _preferenceWrites.then((_) async {
      if (generation != _sessionGeneration) return;
      await userRepository.savePreferencesLocally(
        snapshot,
        ownerUserId: ownerUserId,
      );
      if (token != null && generation == _sessionGeneration) {
        await userRepository.updatePreferences(token, updates);
      }
    });
    _preferenceWrites = write.catchError((Object _) {});
    try {
      await write;
    } catch (_) {
      // Keep the user's local choice when the server is unavailable.
      debugPrint('Preference sync will be retried.');
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
    final generation = ++_sessionGeneration;
    _isLoading = true;
    notifyListeners();

    try {
      await _googleSignInInitialization;
      final googleUser = await _googleSignIn.authenticate();

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
      if (generation != _sessionGeneration) return;
      await _credentials.save(authResponse.accessToken);
      if (generation != _sessionGeneration) return;
      _user = authResponse.user;
      _token = authResponse.accessToken;
      _preferences = await userRepository.getPreferences() ?? UserPreferences();
      if (generation != _sessionGeneration) return;

      notifyListeners();
      await Future.wait([fetchPreferences(), _loadStats()]);
      if (generation != _sessionGeneration) return;

      _isLoading = false;
      notifyListeners();
    } on GoogleSignInException catch (e) {
      _isLoading = false;
      notifyListeners();
      debugPrint('Google sign-in failed (${e.code.name}).');
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw Exception('Google sign-in was canceled.');
      }
      if (e.code == GoogleSignInExceptionCode.clientConfigurationError ||
          e.code == GoogleSignInExceptionCode.providerConfigurationError) {
        throw Exception(
          'Google sign-in is not configured for this Android build: '
          'Check the Google sign-in client configuration.',
        );
      }
      rethrow;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      debugPrint('Google authentication failed.');
      rethrow;
    }
  }

  Future<void> logout() async {
    ++_sessionGeneration;
    final logoutUserId = _user?.id;
    try {
      await _credentials.remove();
    } finally {
      try {
        try {
          await _googleSignIn.signOut();
        } catch (_) {}
        // The push-registration callback still needs the old token to revoke it.
        if (onLogout != null && logoutUserId != null) {
          await onLogout!(logoutUserId);
        }
      } finally {
        _user = null;
        _token = null;
        _preferences = null;
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> deleteAccount() async {
    final token = _token;
    if (token == null) {
      throw Exception('You must be signed in to delete your account.');
    }

    _isLoading = true;
    notifyListeners();
    try {
      await _authApi.deleteAccount(token);
      await logout();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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
      _user = updatedUser.copyWith(
        stats: _user?.stats,
        profileBadge: _user?.profileBadge,
      );
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
      _user = updatedUser.copyWith(
        stats: previousUser?.stats,
        profileBadge: previousUser?.profileBadge,
      );
      notifyListeners();
    } catch (e) {
      _user = previousUser;
      notifyListeners();
      rethrow;
    }
  }
}
