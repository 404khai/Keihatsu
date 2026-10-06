> These findings were addressed on 6 October. See [applied fixes and verification](../2026-10-06/CHANGES.md). The report below records the original audit.

# Flutter and native iOS security assessment

Date: 2026-10-04. Baseline: `ab486ba75b3aa921eec0e64d8e731c06c4e7e7ad` plus the existing working tree. Application source was not changed. Pre-existing edits in the Xcode project, native debug plist, and web package manifest were preserved.

**Five findings: two high, two medium, one low.** Severity assumes an attacker can influence API/source metadata or observe insecure network traffic where specified. These are client-side findings, not proof that the production backend permits malicious metadata or that a shipped binary is exploitable.

| ID | Severity | App | Finding | Evidence |
| --- | --- | --- | --- | --- |
| SEC-01 | High | Flutter, particularly Android | Default API uses HTTP and Android permits cleartext | Configuration inspection; executable default-URL probe |
| SEC-02 | Medium | Flutter on Android/iOS | Bearer token persists in ordinary preferences | Direct read/write code inspection |
| SEC-03 | High | Flutter | Untrusted identifiers escape storage paths for writes and recursive deletion | Actual FileService, loopback server and temporary sentinels |
| SEC-04 | Medium | Native iOS | Dot identifiers escape the archive root | Actual ChapterArchiveStore compiled and executed against temporary sentinels |
| SEC-05 | Low | Flutter | Authentication logs expose email and raw error bodies | Direct logging code inspection |

## SEC-01 — insecure default API transport (CWE-319)

Evidence: `apps/flutter/lib/services/api_constants.dart:7–10` defaults to a LAN HTTP URL with no release distinction. `apps/flutter/android/app/src/main/AndroidManifest.xml:12` enables `usesCleartextTraffic` in the main manifest. `auth_api.dart:27–32` sends the Google ID token to that URL; authenticated calls such as lines 57–60 send the bearer token. The first Dart probe confirms the default scheme is HTTP. This was not a packet-capture test of a signed Android release. A build that overrides the URL with HTTPS does not have the default-endpoint exposure; the permissive configuration remains.

Impact: an observer or active attacker on the network path can obtain credentials or modify content when this configuration is used. Flutter iOS ATS may block the default HTTP URL; this assessment does not claim an ATS bypass. Native iOS release API configuration already rejects HTTP.

Recommended patch:

1. Require an explicit HTTPS `API_BASE_URL` for profile/release builds. Validate scheme, nonempty host, absence of credentials/query/fragment before any API client is used. Fail closed for missing or invalid configuration; use runtime checks, not Dart assertions which disappear in release.
2. Keep a LAN HTTP fallback only in debug builds. Set `android:usesCleartextTraffic="false"` in the main manifest; permit development HTTP only in the debug overlay. Enforce HTTPS in Dart too because platform policy alone is insufficient for every network stack or caller.
3. Validate injected `baseUrl` constructor arguments as well as the shared default. Existing API constructors use const default arguments, so changing `ApiConstants.baseUrl` into a runtime getter requires updating those constructors.
4. Test a release-configured client against HTTP, HTTPS, userinfo and invalid URLs; inspect the merged release manifest and capture traffic in a test build using fake tokens. Consider rejecting cross-origin or HTTPS-to-HTTP redirects for authenticated requests.

Reference: [Android cleartext communication risks](https://developer.android.com/privacy-and-security/risks/cleartext-communications).

## SEC-02 — bearer tokens in preferences (CWE-922)

Evidence: `apps/flutter/lib/providers/auth_provider.dart:63–64` restores `accessToken` from SharedPreferences; line 239 writes it there. These are ordinary preferences, not a platform credential vault. The inspected backend config uses a seven-day access-token lifetime (`apps/api/src/auth/auth.module.ts:18`), increasing the replay window if a token is recovered. No real token was extracted or replayed.

Impact requires access to app data, a relevant backup, or a compromised device; another ordinary sandboxed app does not automatically get access. OS file encryption is distinct from application credential storage.

Recommended patch: introduce an injectable credential store backed by iOS Keychain and Android Keystore-protected encryption, for example [flutter_secure_storage](https://pub.dev/packages/flutter_secure_storage). Select a version compatible with the app's SDK/minimum OS constraints and resolve/test its platform configuration. Follow this migration order:

```dart
var token = await secureStorage.read(key: 'accessToken');
final legacy = prefs.getString('accessToken');
if (token == null && legacy != null) {
  await secureStorage.write(key: 'accessToken', value: legacy);
  token = legacy;
}
// Only remove legacy data after successful vault read/write.
await prefs.remove('accessToken');
```

On login, persist securely before publishing an authenticated session. On logout, account deletion and invalid-session handling, clear both stores; surface/retry vault deletion failures instead of silently declaring cleanup complete. Exclude credentials and encryption artifacts from inappropriate backup/restore flows. Test legacy migration, write failure, relaunch, logout and account deletion. Short-lived access tokens plus a revocable refresh flow are a separate backend improvement, not a client-only patch.

Native iOS already uses `KeychainTokenStore` with `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`; that attribute supports background access after the first unlock and prevents migration to another device. [Apple documentation](https://developer.apple.com/documentation/security/ksecattraccessibleafterfirstunlockthisdeviceonly).

## SEC-03 — Flutter file traversal (CWE-22)

Evidence: `apps/flutter/lib/services/file_service.dart:216` joins arbitrary `subPath` without containment validation. `sources_repository.dart:140–143` supplies `icons/${remote.id}.png`; `manga_repository.dart:234–237` supplies raw source/manga IDs for thumbnails. `_safeComponent` at line 382 strips slashes but accepts `.` and `..`; `deleteChapterPageDirectory` at lines 399–413 recursively deletes the constructed path.

Reproduced using the actual FileService:

- Download `icons/../../victim.png` from a loopback HTTP server: a sentinel is written outside the mocked Documents directory.
- Call `deleteChapterPageDirectory('..', '..', 'victim')`: a sentinel directory adjacent to Documents is recursively deleted.

Both tests are isolated within a newly created temporary directory. Exploitation needs attacker-influenced metadata and the relevant download/delete flow. Reach is limited by filesystem permissions: this does not bypass the iOS/Android OS sandbox. Flutter's Android public storage implementation and all-files permission can expand the accessible area.

Recommended patch: apply the supplied `path-containment.patch` after review. It rejects absolute/dot-segment download paths, checks normalized containment, and makes empty/dot-only chapter components non-traversing. The same probes against temporary patched source confirm the outside sentinels survive and the malicious write is refused.

Follow-up: replace lossy filename sanitization with collision-resistant opaque IDs, validate icon/thumbnail helper paths consistently, and keep downloads in app-scoped storage with explicit export. The targeted patch does not solve pre-existing symlink attacks by a local writer in shared storage; canonical containment/no-follow file operations or private storage are needed for that threat model. Mapping reserved identifiers to `_` avoids traversal but can cause naming collisions; a versioned ID-to-path scheme is the durable fix.

## SEC-04 — native archive traversal (CWE-22)

Evidence: `apps/ios/Keihatsu/Core/Storage/ChapterArchiveStore.swift:93–97` builds the archive URL from `safe(sourceID)` and `safe(mangaID)`. `safe` at lines 298–301 accepts `..`. `delete` at lines 203–206 removes that URL.

Reproduction: source `..`, manga `..`, chapter `victim` resolves `Documents/downloads/../../victim.cbz` outside Documents. The standalone Swift probe compiles the real storage class and domain types, writes a temporary sentinel at that location, invokes `delete`, and confirms deletion. This is a host-side execution of the actual Foundation/storage code, not a simulator UI exploit. Archive writes use the same URL builder, but an out-of-root package write was not separately reproduced. Native impact is more constrained than Flutter's arbitrary raw icon paths: two parent components and the `.cbz` suffix, within permitted filesystem access.

Recommended patch: the Swift part of `path-containment.patch` neutralizes empty, `.` and `..` components. The patched native probe confirms the outside sentinel remains. Add boundary checks at final read/write/delete operations and use collision-resistant storage names as a follow-up; account for security-scoped external download directories and symlinks.

## SEC-05 — personal data in authentication logs (CWE-532)

Evidence: `apps/flutter/lib/providers/auth_provider.dart:217` logs the selected Google email. `apps/flutter/lib/services/auth_api.dart:41` logs the complete failed response body; lines 43 and 52 also propagate/log it. These calls are not guarded by `kDebugMode`. Email leakage is explicit; token leakage through server error bodies is only a possibility, not a demonstrated event.

Recommended patch: remove the account-email log; replace raw body/exception logging with sanitized status code, operation name and a non-sensitive request identifier. Keep any additional diagnostics debug-only. Audit Crashlytics/error reporting boundaries and test with sentinel email/token strings to ensure they do not appear in captured logs. Do not log bearer headers or Google ID tokens.

## Tests and limitations

| Check | Result |
| --- | --- |
| Existing Flutter suite | **23 passed, 2 failed**: widget smoke test lacks ThemeProvider; source rollout expectation disagrees with current flags |
| Flutter vulnerability probes | **3 passed**, confirming the vulnerable behavior; these are evidence probes, not green security regression tests |
| Native standalone probe | Confirmed archive traversal; HTTP and dot API path rejection checks passed |
| Proposed path patch | Flutter traversal probes passed with secure expectations; native outside sentinel survived; `git apply --check` passed |
| Flutter analysis of `lib test` | 0 errors, 123 warnings, 216 info messages; existing warnings remain |
| Unscoped Flutter analysis | 26,233 issues, mostly polluted by generated/vendor checkout trees; scoped analysis above is the useful result |
| Native simulator unit suite | **Blocked at compilation**: BrowsingRepositoryStub, ReaderRepositoryStub and ReaderHistoryRepositorySpy actor-isolation conformance errors; no test-pass claim |
| OSV dependency queries | 184 hosted Pub versions + 27 unique SwiftPM revisions: **zero advisory matches returned** |

The dependency scan used [OSV querybatch](https://google.github.io/osv.dev/post-v1-querybatch/) and saved every result in `dependency-results.json`. It covers checked-in mobile/macOS SwiftPM lockfiles and Flutter hosted packages. A commit returning no match is not proof that OSV knows that commit. Local path dependencies, the Dart git dependency, CocoaPods' local plugin code, Android transitive Maven dependencies, OS/SDK vulnerabilities and unlisted advisories are not comprehensively covered. No package upgrade is prescribed without an advisory match or compatibility assessment.

The code/configuration review also checked credential handling, release/debug transport settings, request path encoding, archive storage and obvious private-key/client-secret patterns. No obvious embedded private key was found in the inspected source; this was not a git-history secret scan. Firebase public client config and OAuth client IDs were not classified as secret credentials.

Not performed: production endpoint attacks, live-account authorization/IDOR testing, token replay, signed release binary inspection, TLS interception on devices, archive bomb stress testing or a complete MASVS certification. Resource caps for CBZ input/page decoding and surfaced native Keychain deletion failures deserve follow-up, but are not counted as proven additional vulnerabilities here.

## Reproduction and patch delivery

From the repository root:

```sh
bash docs/security/2026-10-04/run_probes.sh
python3 docs/security/2026-10-04/scan_dependencies.py
```

The first script runs baseline evidence probes, generates temporary patched implementations, and tests the proposed path fix without changing app source. It requires Flutter and a recent macOS Swift toolchain. Fixed temporary filenames make it unsuitable for simultaneous runs. The HTTP probe remains a finding in the patched run: this patch only addresses path traversal.

The proposed patch is **not applied**. To review/apply separately:

```sh
git apply --check docs/security/2026-10-04/path-containment.patch
git apply docs/security/2026-10-04/path-containment.patch
```

Promote secure assertions into the normal test suites when implementing the fixes. The baseline evidence probes intentionally expect the original vulnerabilities and will need updating after fixes. Complete native regression testing after resolving the existing test compilation errors. Prioritize SEC-01 and SEC-03 before release, then SEC-02/SEC-04 and log cleanup.
