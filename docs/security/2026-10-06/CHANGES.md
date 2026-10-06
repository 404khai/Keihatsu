# Security fixes applied — 6 October 2026

All five findings from the 4 October assessment now have code fixes.

## What changed, simply

- **Login traffic is encrypted in release builds.** Flutter uses the approved HTTPS Railway API address by default. Insecure or malformed API addresses are rejected in release/profile builds, including addresses passed directly to API constructors. Local HTTP servers still work in debug builds. Android's release manifest blocks cleartext traffic; its debug overlay permits development HTTP. API clients also refuse insecure outgoing requests and automatic redirects so credentials cannot be forwarded to a redirected address.
- **Saved logins use the phone's secure storage.** Flutter now uses iOS Keychain and Android Keystore-protected storage. Existing saved logins are copied and checked before their old preference entry is removed. A migration failure preserves the old session for retry. Login is published only after secure saving succeeds.
- **Signing out stays signed out.** Login/startup/logout storage operations are ordered. A persistent sign-out marker prevents a session from reappearing after interrupted vault cleanup. Cleanup failures are surfaced and retried on the next read. The push-registration callback keeps access to the old token long enough to revoke registration. Temporary API outages no longer erase the saved login.
- **Downloads stay in their intended folders.** Both apps neutralize parent-directory identifiers and validate paths before file operations. Existing symbolic links leading outside storage are rejected. Normal filenames are retained, so existing valid offline downloads remain readable. Flutter's directory cleanup no longer follows symbolic links.
- **Authentication logs reveal less.** Email, raw failed sign-in response bodies, profile-error body logging and arbitrary authentication exceptions were removed from diagnostics. Status codes and generic messages remain. Profile validation messages can still be displayed to the user.

Android backup rules exclude only the secure-storage data/key files, preserving ordinary preferences and other app backups. Vault keys cannot be meaningfully transferred to another device; users should sign in again there. Existing historical backups cannot be retroactively cleaned. Shared Android download storage is preserved for compatibility; these checks protect against metadata traversal and existing escaping links, but do not claim atomic protection against a local process racing filesystem changes.

## Compatibility

No backend routes, payload formats, existing valid download naming, minimum OS versions or ordinary navigation flows were changed. `API_BASE_URL` overrides remain supported, subject to HTTPS validation for release/profile. The chosen default is `https://keihatsu-api-production.up.railway.app`. Its unauthenticated HEAD response currently returns HTTP 404 with a Railway fallback header; backend availability is a separate deployment requirement. No live account or token was used to test that service.

Secure storage is pinned to `flutter_secure_storage` 9.2.4 to match the existing platform constraints, with the Flutter/CocoaPods lockfiles and desktop plugin registrants updated. It uses the native iOS Keychain and Keystore-protected Android storage. macOS uses its legacy Keychain without adding provisioning entitlements. [Plugin documentation](https://pub.dev/packages/flutter_secure_storage/versions/9.2.4).

## Verification

- Flutter suite after changes: **36 passed, 2 failed**. The two failures are unchanged from the original audit: the obsolete widget smoke test lacks ThemeProvider and the source rollout assertion disagrees with current flags. All 13 newly added tests passed.
- Native standalone security regression: **6 checks passed**, including out-of-root deletion prevention, symlink rejection, unchanged valid chapter paths, normal package/read roundtrip, HTTP rejection and API dot-segment rejection. It compiles the actual storage/networking source and domain models.
- Native SwiftUI app: **Xcode simulator build succeeded**. The existing full native test target still has the actor-isolation compilation blockers documented in the original audit; added XCTest download tests are available once those are resolved.
- Android release manifest task: **succeeded**; the merged manifest has cleartext disabled and both backup-rule references.
- Flutter iOS secure-storage CocoaPod: **build succeeded** using a command-only iOS 15 deployment override required by this machine's iOS 27 SDK. The repository's minimum OS remains unchanged. CocoaPods install and SwiftPM resolution also succeeded.
- Full Flutter iOS simulator build: **blocked** by an uncategorized Xcode exit status 255 even after package resolution; full binary/runtime verification remains incomplete.
- Scoped Flutter analysis: **0 errors**, 123 existing warnings and 210 info messages. `git diff --check` passed.
- Current OSV scan: **217 queries, no advisory matches returned**, with the same ecosystem/commit-coverage limits as the original audit.

The secure-storage unit tests use an injected fake vault to exercise migration/failure behavior; they do not claim a real-device sign-in/Keystore test. Filesystem tests use isolated temporary sentinels. No production credentials were accessed.

## Running the checks

From `apps/flutter`:

```sh
flutter test test/services/api_security_test.dart \
  test/services/auth_api_security_test.dart \
  test/services/credential_store_test.dart \
  test/services/file_security_test.dart \
  test/services/file_service_test.dart \
  test/services/extension_cbz_test.dart \
  test/services/sources_api_test.dart
```

From the repository root:

```sh
bash docs/security/2026-10-06/run_native_regression.sh
python3 docs/security/2026-10-06/scan_dependencies.py
```

The 4 October evidence probes and patch are historical artifacts and intentionally expect the old source/behavior; use the regression tests above for the fixed code.
