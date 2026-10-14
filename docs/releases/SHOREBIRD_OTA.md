# Flutter OTA releases

Scope: `apps/flutter` Android and Flutter iOS. The separate SwiftUI application
in `apps/ios` cannot receive Dart patches from Shorebird.

The distributed **0.1.0+6** APK was built with ordinary Flutter and contains no
Shorebird updater. It cannot receive these patches. The next baseline candidate
is **0.1.0+7**; check for any newer distributed build before reserving/publishing
that number. Merge the intended beta changes (including separately developed
Bachs support, if wanted) before publishing a baseline. Do not distribute two
different binaries under the same app/version/build number.

## One-time account and project setup

This is already completed for this checkout. Keep the existing app ID; do not
run `init` again. The commands below document first-time setup.

Install the CLI following [Shorebird's quick start](https://docs.shorebird.dev/quick-start/).
The local installation lives in `~/.shorebird/bin`; it does not replace the
system Flutter SDK. Sign in in your own terminal/browser:

```sh
~/.shorebird/bin/shorebird login
cd apps/flutter
python3 tool/shorebird.py init
```

Initialization creates the real public app ID, `shorebird.yaml`, and its entry
under `flutter.assets`. The wrapper sets `auto_update: true`. Review and commit
these changes. It refuses to overwrite an existing ID. If a Keihatsu Shorebird
project already exists, retrieve its config from that project instead of
creating a second app; include the config as an asset and use `auto_update: true`.
The real app ID is now initialized as `e595434f-ae36-4616-b092-0957112dc68e`.
No baseline has been uploaded or distributed yet. Do not reinitialize this app
or create a replacement ID for patches to an existing baseline.

Never put account/API keys in app assets or Dart defines. Local browser login
is sufficient for development. CI uses a Shorebird **API key** stored as the
Actions secret `SHOREBIRD_TOKEN`; old `login:ci` tokens stopped working on
October 1, 2026. Configure secrets in the service's secret UI, never in chat.

## Runtime behavior

The Shorebird engine checks/downloads on launch in the background. A downloaded
patch becomes active on the next **full process restart**, not while a chapter
is open. Offline launches continue using the installed baseline/current patch.
An unavailable update server does not gate the reader. Network checks are only
triggered by the user through Settings; there are no startup network gates,
mandatory update screens, hot restarts or forced process exits.

After the first rendered frame, Dart reads local boot metadata only and records
`shorebird_available`, `shorebird_patch` and `shorebird_release` in Crashlytics.
Patch zero means baseline; `unavailable` means no successful local read. Reads
time out and failures are swallowed. Ordinary Flutter/debug builds report the
updater unavailable. This package alone does **not** enable OTA: the baseline
must be built with Shorebird's engine.

## Update sheet

Settings → **App updates** opens the same floating card used by logout/delete
account. It shows checking, available, downloading, ready, up-to-date, unavailable,
and offline/retry states. **Download update** requests a download; **Later** or
**Continue reading** dismisses the sheet without cancelling background updates.
The native automatic updater remains enabled. A successful SDK update call is
not assumed to mean ready: the controller waits for different current/next local
patch metadata, including when the automatic updater was already downloading.

A foreground local-only probe runs on startup/resume and every ten seconds while
active. When a downloaded patch is ready, a sheet appears once per pending patch
in that process. It waits until a named top-level page is visible and another
modal is closed; reader/detail and sign-in/onboarding routes are excluded. No
network requests are added to app startup or these periodic probes. A paused app
stops polling. Rollback to the baseline also produces a restart-ready message.

The ready sheet says to close Keihatsu completely and reopen it. **Got it**
dismisses the message; it does not pretend to restart the app or force-exit iOS.
A manually requested check/download has bounded waits and generic retry copy;
local read failures remain quiet. The sheet has no patch-note/version claims
because Shorebird does not supply user-facing release notes through this SDK.

## Reproducible build inputs and signing

`apps/flutter/shorebird-release.json` pins Flutter **3.44.0** and the current
HTTPS API URL. Validate this Flutter version with Shorebird before publishing;
changing the engine requires a new baseline. Both baseline and patches use the
same `APP_VERSION` and `API_BASE_URL` values. Patch commands target the exact
`x.y.z+build` release, never `latest`, and Shorebird selects its recorded engine.

Keep the original `android/key.properties` and keystore outside version control.
The tooling/Gradle fail on missing release signing; there is no debug-key
fallback. The wrapper checks the keystore certificate against the public SHA-256
pinned in `shorebird-release.json` and rejects a different key. Preserve package `com.example.keihatsu` and the signing certificate
to upgrade existing installations without uninstalling or losing downloads.
Restore `android/app/google-services.json` locally. Do not rotate the signing
key merely to enable OTA. Compare the generated APK certificate to build 6 with
Android SDK `apksigner verify --print-certs` before distribution.

The existing Navii/Blobatar packages are sibling path dependencies. Place their
repositories next to Keihatsu (symlinks are fine locally). The validation
workflow checks out reviewed commits `b1cbdabb5865719e686b9debdd2a7248860a9940`
and `bf52859375e955dec4ebbc2b53316bcef0ce7ad3`. Review/pin package changes before
a baseline; do not publish from mutable/uncommitted dependency sources. The
wrapper conservatively fingerprints their native/assets/config files too.

For Flutter iOS, configure the Runner signing team, bundle identifier, Apple
distribution certificate and provisioning profile in Xcode. Firebase, Google
sign-in and push entitlements/configuration must match that identifier. This
repository's Runner currently uses `com.example.keihatsu`, targets iOS 15+
for Xcode 27 compatibility, and has no signing team configured. An unsigned archive proves compilation only and cannot be
installed or previewed as a signed physical-device release.

## Validate a new baseline without uploading

From `apps/flutter` after initialization:

```sh
python3 tool/shorebird.py check android
python3 tool/shorebird.py release android --plan
python3 tool/shorebird.py release android
python3 tool/shorebird.py release ios --no-codesign
```

Build commands default to Shorebird `--dry-run`. They upload neither releases
nor patches and do not send tester emails. Successful validation writes a
`build/shorebird/keihatsu-PLATFORM-VERSION-validated.json` receipt. An unpublished
receipt is deliberately rejected for patching.

Android defaults to a universal APK supporting ARM32, ARM64 and x86_64. For
smaller downloads to confirmed ARM64 devices use:

```sh
python3 tool/shorebird.py release android --arch arm64
```

The wrapper puts Shorebird's `--target-platform` **before** the Flutter `--`
separator. An ARM64 APK cannot serve ARM32/x86_64 testers. For Play delivery use
`--artifact aab` (universal architectures); Play selects device-specific splits.
JNI compression and Flutter's default icon tree shaking are retained. Measure
Shorebird-built outputs separately: the existing 56.67 MB build 6 and ordinary
Flutter smoke builds do not predict the Shorebird baseline's size. Do not use
`flutter build apk` to rebuild a distributed OTA baseline.

## Publish the baseline only when approved for release

These commands are documented for a deliberate release, not automated tests:

```sh
python3 tool/shorebird.py release android --publish
python3 tool/shorebird.py release ios --export-options /local/ExportOptions.plist --publish
```

Publishing requires a clean reviewed checkout. Save the generated
`*-published.json` receipt alongside the exact signed artifacts in private
release storage; keep receipts for every supported baseline. A later dry-run
does not overwrite the published receipt. The command uploads compiled
baseline artifacts to Shorebird only. Store upload/Firebase distribution and
tester notifications remain separate, explicitly authorized actions. Users
must install that **exact Shorebird-built baseline** once.

## Validate a compatible patch

Keep `pubspec.yaml` at the baseline version. Use its published receipt:

```sh
python3 tool/shorebird.py patch android \
  --release-version 0.1.0+7 \
  --baseline /private/releases/keihatsu-android-0.1.0+7-published.json
python3 tool/shorebird.py patch ios --no-codesign \
  --release-version 0.1.0+7 \
  --baseline /private/releases/keihatsu-ios-0.1.0+7-published.json
```

This builds/validates without upload. Native code, bundled assets, dependency
graph/configuration or release-settings changes require a new baseline through
this conservative wrapper. Dart UI/logic fixes can be patched. It never passes
`--allow-native-diffs` or `--allow-asset-diffs`; Shorebird also checks compiled
artifacts for compatibility. The wrapper is intentionally stricter than
Shorebird about Dart-only dependency updates.

Adding `--publish` to the reviewed patch command uploads to **staging only**.
For QA use `shorebird preview --platform android --release-version 0.1.0+7
--track staging` (or `--platform ios` on a signed physical iOS device). Restart
once to download, then fully stop/relaunch to activate; verify patch metadata,
offline reader/downloads, login, sync, and notifications. App background/foreground
alone is not guaranteed to restart the process. iOS simulators cannot prove
Shorebird patch application.

After separate release authorization, promote the exact patch to `stable` in
the Shorebird console. Default-installed clients listen to `stable`; a beta
APK from Firebase does not automatically listen to Shorebird's `beta` track.
If a patch fails QA, do not promote it. For a production problem, use the
console rollback for that exact app/platform/release, then verify a connected
client detects it and uses the intended code after restart. Offline clients
cannot receive an immediate rollback; retain a full store/Firebase update path.
Keep Isar migrations backward-compatible: changing local storage is not undone
by rolling back Dart code. Use normal App Review for substantial new features;
OTA remains subject to store policies.

## GitHub workflow

The former tag-triggered ordinary Flutter APK publisher has been replaced by
manual **Shorebird baseline validation**. It cannot publish to Shorebird, GitHub
Releases, Firebase or the stores. Run it on this branch after committing the
real Shorebird configuration and configuring `SHOREBIRD_TOKEN`. Android also
requires the existing `KEYSTORE_BASE64`, `KEY_ALIAS`, `KEY_PASSWORD`,
`STORE_PASSWORD`, and real `GOOGLE_SERVICES_JSON` Actions secrets. Private path
dependencies may require `DEPENDENCY_READ_TOKEN` with read-only repo access.
The workflow passes secrets through environment variables, removes local
signing files afterward and retains only the validation receipt. iOS CI builds
an unsigned archive. The workflow reads its Flutter/dependency pins from `shorebird-release.json`;
review updates there when intentionally preparing a new baseline.

References: [initialization](https://docs.shorebird.dev/code-push/initialize/),
[release/architecture flags](https://docs.shorebird.dev/code-push/release/),
[patch validation](https://docs.shorebird.dev/code-push/patch/),
[background behavior](https://docs.shorebird.dev/code-push/update-strategies/),
[CI/API keys](https://docs.shorebird.dev/code-push/ci/github/),
[staging](https://docs.shorebird.dev/code-push/guides/staging-patches/).
