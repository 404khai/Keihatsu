import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:keihatsu/services/credential_store.dart';

class FakeVault implements CredentialVault {
  String? token;
  bool failWrite = false, failDelete = false;
  @override
  Future<String?> read() async => token;
  @override
  Future<void> write(String value) async {
    if (failWrite) throw StateError('Device locked');
    token = value;
  }

  @override
  Future<void> delete() async {
    if (failDelete) throw StateError('Device locked');
    token = null;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test('legacy session migrates once without losing login', () async {
    SharedPreferences.setMockInitialValues({'accessToken': 'existing-session'});
    final vault = FakeVault();
    final store = CredentialStore(vault: vault);
    expect(await store.read(), 'existing-session');
    expect(vault.token, 'existing-session');
    expect(
      (await SharedPreferences.getInstance()).containsKey('accessToken'),
      false,
    );
    expect(await CredentialStore(vault: vault).read(), 'existing-session');
  });
  test('failed migration preserves legacy session for a later retry', () async {
    SharedPreferences.setMockInitialValues({'accessToken': 'existing-session'});
    final vault = FakeVault()..failWrite = true;
    final store = CredentialStore(vault: vault);
    await expectLater(store.read(), throwsStateError);
    expect(
      (await SharedPreferences.getInstance()).getString('accessToken'),
      'existing-session',
    );
    vault.failWrite = false;
    expect(await store.read(), 'existing-session');
  });
  test('existing vault session wins over a stale plaintext session', () async {
    SharedPreferences.setMockInitialValues({'accessToken': 'old-session'});
    final store = CredentialStore(
      vault: FakeVault()..token = 'current-session',
    );
    expect(await store.read(), 'current-session');
    expect(
      (await SharedPreferences.getInstance()).containsKey('accessToken'),
      false,
    );
  });
  test('failed logout cannot revive the session on restart', () async {
    final vault = FakeVault()
      ..token = 'session'
      ..failDelete = true;
    final store = CredentialStore(vault: vault);
    await expectLater(store.remove(), throwsStateError);
    await expectLater(CredentialStore(vault: vault).read(), throwsStateError);
    vault.failDelete = false;
    expect(await CredentialStore(vault: vault).read(), isNull);
    expect(vault.token, isNull);
  });
  test(
    'save and logout operations remain ordered, and login works afterwards',
    () async {
      final vault = FakeVault();
      final store = CredentialStore(vault: vault);
      await Future.wait([store.save('session'), store.remove()]);
      expect(await store.read(), isNull);
      await store.save('new-session');
      expect(await store.read(), 'new-session');
    },
  );
}
