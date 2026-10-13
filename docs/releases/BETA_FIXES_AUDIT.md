# Android beta build 6 audit

Implementation and automated checks are complete. **Android session restoration
and account-switching runtime acceptance are pending user testing**, at the
user's request. Do not treat the emulator attempts as successful relaunch proof.

## Signed replacement

- Artifact: `output/beta/keihatsu-0.1.0-build6.apk` (ignored, local).
- Download: **56,666,346 bytes** = 56.67 MB / 54.04 MiB, below 65,000,000 bytes.
- Previous supplied beta: 210,788,918 bytes; first optimized universal candidate:
  76,304,658 bytes. Both numbers are actual file measurements.
- Package: `com.example.keihatsu`; versionName `0.1.0`; versionCode `6`.
- All previous ABIs retained: arm64-v8a, armeabi-v7a, x86_64.
- APK SHA-256: `786eb1108f6f52c5f454a5b3e87942f36afc56cd62557483c2b3522ba7f5507e`.
- Release certificate SHA-256: `207b7297ffc99a0feb20dabfd036f9d7aa2f8efcaa27d183d169dbed2ca2080e`, identical to build 5.
- Android APK Signature Scheme v2 verification passes.
- Built serially from `lib/main.dart`, production HTTPS API define and original
  signing configuration; copied and hashed outside the build output tree.
- No fixture token or fixture asset entry was found in the deliverable.

## Size and support tradeoffs

The old APK contained 127,241,298 compressed bytes of Flutter assets and roughly
76.2 MB of uncompressed native libraries. The autumn PNG alone was 69,875,003
bytes. The replacement contains 18,300,531 bytes of Flutter assets and
31,152,686 bytes of compressed native libraries.

All seasonal branding remains. The autumn runtime artwork is resized from 5120
square to 1024 square, matching the other icons; launcher source PNGs are
retained but excluded from the Flutter runtime bundle. All four runtime WebPs
preserve exact RGBA pixels and ICC profiles of their 1024 PNG inputs. A first
conversion dropped colour profiles/transparent RGB; corrected encodings were
visually inspected and checked for exact decoded equality.

The 28 bundled mock covers use WebP quality 90 without dimension changes. Their
payload fell from 23,865,704 to 4,213,906 bytes; minimum measured PSNR is 39.49 dB,
and a decoded full-size cover was inspected against its original.

`android.packaging.jniLibs.useLegacyPackaging=true` compresses JNI libraries
inside the APK. Android extracts the selected ABI during installation, so the
**installed storage is larger than the download**. No ABI or app function was
removed. Actual installed-size measurement and ARM32/x86_64 runtime checks are
pending. [AGP packaging documentation](https://developer.android.com/reference/tools/gradle-api/7.3/com/android/build/api/variant/JniLibsApkPackaging).

## Account statistics and sessions

The profile's 120-minute, 10-item and 18-comment defaults are removed. Reading
time, titles read today, comments and library size use authenticated account
statistics. Missing statistics display an em dash; empty/guest values display
zero. Google login now fetches statistics immediately. Late old-account stats
and profile-refresh responses are ignored; preference refreshes retain their
original account scope.

Startup previously read `SharedPreferences.accessToken` even though secure
migration deletes that key, and MaterialApp chose its initial route before
restoration finished. Startup now awaits `AuthProvider.initialized`, uses the
provider's validated session, and restores independently of Google SDK startup
and statistics/preferences requests. Temporary failures retain credentials and
show Retry/Continue offline. Unauthorized sessions are removed. The existing
verified platform vault migration, serialized writes and sign-out markers remain.
JWT lifetime is still seven days; expiration still requires authentication.

An isolated Android 15 emulator installed the signed build-6 APK successfully,
and legacy credential removal/platform-vault files were observed. Whole-device
System UI ANRs, renderer/helper timeouts and notification prompts prevented a
completed UI relaunch acceptance test. The user chose to perform that testing.
These attempts do not prove restoration after termination. Diagnostic credentials
and session-bearing fixture files were removed; the original AVD was not wiped.

## Badges and live account-count audit

The API supplies `profileBadge` from database email/role, never display names.
Only `404khai@gmail.com` with ADMIN receives `developer` (hardware icon).
`dexgamingacct@gmail.com` receives `android_beta_tester` (Android icon) and retains
USER role. Other identities receive null. Cosmetic badges grant no permissions.
The API policy was deployed to the existing beta server with a source backup and
without a schema migration or account/library mutation.

Live `auth/me` responses verified the two distinct badges. At audit time:

- PostgreSQL: **2 users**, both Google accounts.
- `admin/analytics.totalUsers`: **2**.
- `admin/stats.totalUsers`: **2**.
- Firebase App Distribution: **15 testers** (initial preparation retained 13).

Both admin totals use unfiltered `prisma.user.count()`; the web dashboard fetches
analytics with `cache: no-store`. Firebase testers are invitations/distribution
access, not PostgreSQL accounts. No accounts were manufactured. The admin card
now explicitly describes registered app accounts and separates invitations.
The deployed API returns library 4/comments 1/read-today 3 for the developer and
library 1/comments 0/read-today 1 for dex at audit time; these values can change.

## Verification evidence

All paths below are relative to this beta-fixes worktree. Generated output is
ignored; it is not committed.

- `output/beta/android-build-final.log`: successful production build.
- `output/beta/apk-audit.json`, `apk-signature.txt`, `old-apk-signature.txt`,
  `apk-badging.txt`, `apk-manifest.txt`, and the APK `.sha256`: artifact audit.
- `output/beta/flutter-tests.log`: **25 passed** across auth restoration/races,
  credential migration, HTTP security, file containment, statistics and seasons.
- `apps/flutter/test/providers/auth_restore_test.dart`: startup/logout races,
  retained credentials on temporary failure, unauthorized cleanup, new account
  zeros and same-provider switching with delayed previous-account statistics.
- `output/beta/api-all-tests.log`: **22 suites passed; 51 passed, 3 skipped**.
- `output/beta/api-tests.log`: **11 targeted API tests passed**, including
  zero/scoped account stats, badge identity policy and authentication.
- `output/beta/api-build.log`: successful Nest build.
- `output/beta/flutter-analyze.log`: no errors; five existing informational
  findings (file naming, indirect http_parser dependency, existing print calls).
- `output/beta/icon-quality-audit.json`, `cover-quality-audit.json`:
  image equality/quality checks.
- `output/beta/production-audit.json`, `server-deploy.log`: live API audit/deploy.
- `output/beta/build6-install.txt`: signed APK installation success.

A new-account zero-stat contract was tested automatically; no new production
account was created for this audit. Live developer/tester badges were checked
through the deployed API; visual badge/account-switch/relaunch acceptance remains
user testing. No build-6 Firebase upload, distribution or tester notification was
performed.

## User acceptance and redistribution

1. Install build 6 **as an update**, without uninstalling or clearing data. If
   already signed in, verify it restores that account and preserves the library.
2. Sign in if necessary. Force-stop Keihatsu from Android Settings, then reopen
   from its launcher. Repeat after a device restart; verify no login prompt and
   the same account/library. Explicit logout should still require sign-in.
3. Verify a new account starts at zero before adding/reading/commenting. Add an
   item/read/comment and refresh Profile; verify those actual values. Sign out
   and switch accounts; verify the previous account's counts never appear.
4. Check the developer's hardware badge, dex's Android badge, and no badge on a
   regular account. Changing a username must not change badge ownership.
5. Check admin totals against accounts that actually signed in. Firebase's
   tester count is a separate invitation count; new app sign-ins legitimately
   increase the backend total.

Upload the build-6 APK as a **new Firebase App Distribution release** using the
same Android app. Uploading without testers/groups prepares it without sending
notifications. After acceptance, choose the existing testers and Distribute to
notify them of the update. Use `0.1.0-build6-beta-notes.txt`. Do not replace the
build-5 binary or downgrade build numbers. No keystore change, uninstall or public
GitHub release is needed.
