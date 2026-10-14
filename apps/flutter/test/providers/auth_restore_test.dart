import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:keihatsu/providers/auth_provider.dart';
import 'package:keihatsu/services/auth_api.dart';
import 'package:keihatsu/services/credential_store.dart';
import 'package:keihatsu/services/user_repository.dart';
import 'package:keihatsu/models/user.dart';
import 'package:keihatsu/models/user_preferences.dart';

class Vault implements CredentialVault {
  String? token = 'persisted';
  @override
  Future<String?> read() async => token;
  @override
  Future<void> write(String value) async {
    token = value;
  }

  @override
  Future<void> delete() async {
    token = null;
  }
}

class Repository implements UserRepository {
  @override
  Future<UserPreferences?> getPreferences() async => null;
  @override
  Future<void> refreshPreferences(String token) async {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class PreferenceRepository extends Repository {
  UserPreferences? saved;
  final refresh = Completer<void>();
  @override
  Future<UserPreferences?> getPreferences() async => saved;
  @override
  Future<void> savePreferencesLocally(
    UserPreferences prefs, {
    String? ownerUserId,
  }) async {
    saved = prefs;
  }

  @override
  Future<void> updatePreferences(
    String token,
    Map<String, dynamic> updates,
  ) async {
    throw StateError('Offline');
  }

  @override
  Future<void> refreshPreferences(String token) => refresh.future;
}

class Api extends AuthApi {
  final me = Completer<User>();
  final stats = Completer<UserStats>();
  @override
  Future<User> getMe(String token) => me.future;
  @override
  Future<UserStats> getUserStats(String token) => stats.future;
}

class SwitchingApi extends AuthApi {
  final oldStats = Completer<UserStats>();
  @override
  Future<User> getMe(String token) async => User(id: token);
  @override
  Future<UserStats> getUserStats(String token) => token == 'persisted'
      ? oldStats.future
      : Future.value(UserStats.fromJson({}));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  AuthProvider provider(
    Api api,
    Vault vault, {
    Future<void> Function()? google,
  }) => AuthProvider(
    userRepository: Repository(),
    credentials: CredentialStore(vault: vault),
    authApi: api,
    initializeGoogleSignIn: google ?? () async {},
  );
  UserStats zero() => UserStats.fromJson({});
  test(
    'secure restart waits for identity, independent of Google SDK and statistics',
    () async {
      final api = Api(), vault = Vault();
      final auth = provider(api, vault, google: () => Completer<void>().future);
      expect(auth.isAuthenticated, false);
      api.me.complete(User(id: 'new-account'));
      await auth.initialized;
      expect(auth.isAuthenticated, true);
      expect(auth.user!.stats, isNull);
      api.stats.complete(zero());
      await Future<void>.delayed(Duration.zero);
      expect(auth.user!.stats!.libraryCount, 0);
      expect(auth.user!.stats!.commentsCount, 0);
      auth.dispose();
    },
  );
  test(
    'delayed startup identity cannot restore a signed-out account',
    () async {
      final api = Api(), vault = Vault();
      final auth = provider(api, vault);
      await Future<void>.delayed(Duration.zero);
      await auth.logout();
      api.me.complete(User(id: 'old-account'));
      await auth.initialized;
      expect(auth.user, isNull);
      expect(await CredentialStore(vault: vault).read(), isNull);
      auth.dispose();
    },
  );
  test('old statistics cannot contaminate the next account', () async {
    final api = Api(), vault = Vault();
    final auth = provider(api, vault);
    api.me.complete(User(id: 'old-account'));
    await auth.initialized;
    await auth.logout();
    await CredentialStore(vault: vault).save('next-account');
    final nextApi = Api()..me.complete(User(id: 'new-account'));
    final next = provider(nextApi, vault);
    await next.initialized;
    nextApi.stats.complete(zero());
    api.stats.complete(
      UserStats.fromJson({'libraryCount': 99, 'commentsCount': 18}),
    );
    await Future<void>.delayed(Duration.zero);
    expect(auth.user, isNull);
    expect(next.user!.stats!.libraryCount, 0);
    expect(next.user!.stats!.commentsCount, 0);
    auth.dispose();
    next.dispose();
  });
  test(
    'switching accounts in one provider ignores a late old-account response',
    () async {
      final api = SwitchingApi(), vault = Vault();
      final auth = AuthProvider(
        userRepository: Repository(),
        credentials: CredentialStore(vault: vault),
        authApi: api,
        initializeGoogleSignIn: () async {},
      );
      await auth.initialized;
      await CredentialStore(vault: vault).save('next-account');
      await auth.retrySessionRestore();
      await Future<void>.delayed(Duration.zero);
      api.oldStats.complete(UserStats.fromJson({'libraryCount': 99}));
      await Future<void>.delayed(Duration.zero);
      expect(auth.user!.id, 'next-account');
      expect(auth.user!.stats!.libraryCount, 0);
      auth.dispose();
    },
  );
  test(
    'a failed preference sync and late refresh cannot reset a chosen grid',
    () async {
      final api = Api(), vault = Vault(), repository = PreferenceRepository();
      final auth = AuthProvider(
        userRepository: repository,
        credentials: CredentialStore(vault: vault),
        authApi: api,
        initializeGoogleSignIn: () async {},
      );
      api.me.complete(User(id: 'reader'));
      await auth.initialized;
      await auth.updatePreferences({
        'categories_display_mode': 'compact grid',
        'library_items_per_row': 2,
      });
      expect(auth.preferences!.categoriesDisplayMode, 'compact grid');
      expect(repository.saved!.libraryItemsPerRow, 2);
      repository.refresh.complete();
      await Future<void>.delayed(Duration.zero);
      expect(auth.preferences!.categoriesDisplayMode, 'compact grid');
      await auth.updatePreferences({
        'categories_display_mode': 'comfortable grid',
        'library_items_per_row': 4,
      });
      expect(repository.saved!.categoriesDisplayMode, 'comfortable grid');
      expect(repository.saved!.libraryItemsPerRow, 4);
      api.stats.complete(UserStats.fromJson({}));
      await Future<void>.delayed(Duration.zero);
      auth.dispose();
    },
  );
  test(
    'temporary API failure preserves credential and exposes retry state',
    () async {
      final api = Api(), vault = Vault();
      final auth = provider(api, vault);
      await Future<void>.delayed(Duration.zero);
      api.me.completeError(const AuthApiException(503));
      await auth.initialized;
      expect(auth.restoreFailed, true);
      expect(vault.token, 'persisted');
      auth.dispose();
    },
  );
  test('unauthorized saved token is removed securely', () async {
    final api = Api(), vault = Vault();
    final auth = provider(api, vault);
    await Future<void>.delayed(Duration.zero);
    api.me.completeError(const AuthApiException(401));
    await auth.initialized;
    expect(auth.restoreFailed, false);
    expect(await CredentialStore(vault: vault).read(), isNull);
    auth.dispose();
  });
}
