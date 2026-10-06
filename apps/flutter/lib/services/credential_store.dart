import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract interface class CredentialVault {
  Future<String?> read();
  Future<void> write(String token);
  Future<void> delete();
}

class PlatformCredentialVault implements CredentialVault {
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
    // Avoid requiring an additional macOS provisioning entitlement.
    mOptions: MacOsOptions(useDataProtectionKeyChain: false),
  );

  @override
  Future<String?> read() => _storage.read(key: 'accessToken');
  @override
  Future<void> write(String token) =>
      _storage.write(key: 'accessToken', value: token);
  @override
  Future<void> delete() => _storage.delete(key: 'accessToken');
}

/// Moves old sessions into the platform vault without discarding them on error.
class CredentialStore {
  CredentialStore({CredentialVault? vault})
    : _vault = vault ?? PlatformCredentialVault();

  final CredentialVault _vault;
  static const _tokenKey = 'accessToken';
  static const _signedOutKey = 'credentialsSignedOut';
  Future<void> _pending = Future<void>.value();

  // Login, startup and logout can overlap. Preserve their operation order.
  Future<T> _serialize<T>(Future<T> Function() operation) {
    final result = _pending.then((_) => operation());
    _pending = result.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return result;
  }

  Future<void> _removeLegacy(SharedPreferences prefs) async {
    if (!await prefs.remove(_tokenKey)) {
      throw StateError('Unable to remove the old login safely.');
    }
  }

  Future<String?> read() => _serialize(() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_signedOutKey) == true) {
      // Retry an interrupted cleanup, but never revive a signed-out session.
      await _vault.delete();
      await _removeLegacy(prefs);
      return null;
    }
    var token = await _vault.read();
    final legacy = prefs.getString(_tokenKey);
    if (token == null && legacy != null) {
      await _vault.write(legacy);
      token = await _vault.read();
      if (token != legacy) {
        throw StateError('Unable to save the login securely.');
      }
    }
    if (legacy != null && token != null) await _removeLegacy(prefs);
    return token;
  });

  Future<void> save(String token) => _serialize(() async {
    final prefs = await SharedPreferences.getInstance();
    await _vault.write(token);
    if (await _vault.read() != token) {
      throw StateError('Unable to save the login securely.');
    }
    await _removeLegacy(prefs);
    if (!await prefs.remove(_signedOutKey)) {
      throw StateError('Unable to finish saving the login securely.');
    }
  });

  Future<void> remove() => _serialize(() async {
    final prefs = await SharedPreferences.getInstance();
    if (!await prefs.setBool(_signedOutKey, true)) {
      throw StateError('Unable to finish signing out. Please try again.');
    }
    // Remove plaintext even when the device vault is temporarily unavailable.
    await _removeLegacy(prefs);
    await _vault.delete();
  });
}
