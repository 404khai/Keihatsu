# Shorebird integration validation — 2026-10-14

Validated on `feat/flutter-shorebird-ota`, based on admin commit `02d36bd`.
This integration did not change the admin or Bachs worktrees. Scope is `apps/flutter` Android
and Flutter iOS; native SwiftUI `apps/ios` is unchanged.

## Account and configuration

- User completed browser login. Created **Keihatsu Flutter** with real public
  app ID `e595434f-ae36-4616-b092-0957112dc68e`.
- Installed Shorebird CLI **1.6.128**. Release tooling pins Shorebird's Flutter
  **3.44.0**, framework revision `1a55eb72b61a6c8acac0bf7f7d4738f399f83a0f`.
- Bundled `shorebird.yaml` has `auto_update: true` on both platforms.
- Candidate release is **0.1.0+7**, API remains the existing HTTPS beta origin.
- Read-only Shorebird release inventory after validation: **zero releases**.
  No baseline or patch was uploaded, distributed, promoted or purchased.

## Build and signing results

`CI=true python3 tool/shorebird.py release android` passed with the wrapper's
default `--dry-run` and universal architecture configuration:

- Signed APK: **60,002,284 bytes** (60.00 MB / 57.22 MiB).
- Dart code present for **armeabi-v7a, arm64-v8a and x86_64**.
- Package `com.example.keihatsu`, versionName `0.1.0`, versionCode **7**.
- APK certificate matches the exact existing build-6 artifact from the
  beta-fixes worktree. The public SHA-256 is pinned in release settings; the
  wrapper also verifies the keystore certificate without exposing passwords.
- Real Shorebird app ID/background configuration verified in APK assets.
- Unpublished validation receipt generated; its settings/native/assets inputs
  still match the final checkout.

The ARM64 Shorebird validation APK was **38,196,422 bytes** (38.20 MB / 36.43 MiB)
with Dart code for arm64-v8a only. It was installed solely on the isolated QA
emulator. The first wrapper run detected a build-setting change made during
implementation; the final universal run was repeated with stable inputs and
passed. Use the universal baseline until tester device architectures are known.
The previous non-Shorebird universal build 6 was 56.67 MB; OTA adds some baseline
overhead and the smaller ARM64 option changes device coverage.

`CI=true python3 tool/shorebird.py release ios --no-codesign` also passed with
default `--dry-run`:

- Generated unsigned **Runner.xcarchive**, reported as 240.5 MB including archive
  contents/symbols. This is not an IPA download-size measurement.
- Archive metadata: `com.example.keihatsu`, **0.1.0+7**, minimum iOS **15.0**.
- Real Shorebird background config verified inside App.framework assets.
- No `_CodeSignature` present, as requested. No installable/signed iOS release
  or physical-device patch activation is claimed.
- Generated unpublished iOS validation receipt; inputs/settings match checkout.

Ordinary Flutter smoke builds also passed before Shorebird builds. The first
iOS attempt failed because Xcode 27 rejected deployment targets below iOS 15;
Runner, framework metadata and old CocoaPods deployment targets now use iOS
15 or higher. This changes Flutter iOS device eligibility to **iOS 15+**.

## Android runtime and offline check

Opened the previously idle **BetaVerification35** Android 15 emulator through
T3's Device panel, separate from the booted Pixel_8 used by other work.
Installed the signed ARM64 Shorebird validation APK on `emulator-5556`.

Disabled both Wi-Fi and mobile data, then cold-launched Keihatsu. Engine logs
confirmed **no active patch**, a request for **stable / 0.1.0+7**, a network
failure on the updater's background thread, and **successful launch**. The
sign-in screen rendered; choosing **Skip for now** reached the guest library
while offline. The emulator's original network service settings were restored.

This verifies baseline engine startup and offline guest navigation. The test
library was empty, so downloaded-chapter reading/data retention was not exercised
in that emulator. Patch download/application cannot be verified without an
uploaded baseline and a real staging patch, which were explicitly excluded from
testing. iOS simulator use would not prove patch application either.

## Automated checks

- **4 OTA diagnostic tests passed**, including unavailable ordinary builds,
  current patch versus baseline, read failures, and bounded stalled reads.
  Fakes reject unexpected network calls.
- **10 release-tool tests passed**: dry-run defaults, architecture flag placement,
  exact version/staging targeting, unpublished receipt rejection, native/new
  asset changes, hosted `path` dependency parsing, API URL restrictions, and
  certificate identity/password handling.
- Analyzer passed for the diagnostic service and tests.
- Full Flutter suite: **46 passed, 2 failed**. Both failures were reproduced
  from an isolated archive of untouched parent commit `02d36bd`: the stale
  counter `widget_test.dart` lacks app providers, and `source_rollout_test.dart`
  disagrees with existing source rollout state. They were left outside OTA scope.
- Workflow YAML, all embedded shell steps, signing-injection Python, Podfile,
  plist/project syntax and Git whitespace checks passed locally. GitHub Actions
  was not run; its secrets must be configured privately.
- A patch command using the actual **unpublished** validation receipt was
  rejected before building/uploading. Shorebird cloud inventory remains empty.

## Before delivering OTA to testers

1. Integrate the desired Bachs/beta changes into the baseline source. Reserve a
   unique build number higher than the newest distributed APK; `+7` is a candidate,
   not permission to reuse a number from concurrent beta work.
2. Publish from a clean reviewed checkout and pinned clean path packages.
   The local Blobatar checkout has pre-existing README/pubspec metadata edits;
   these were preserved, and the wrapper rejects publishing from dirty packages.
   CI uses clean pinned dependency checkouts.
3. Deliberately upload a signed Shorebird baseline, then separately authorize
   Firebase/store delivery of that exact binary. Build **0.1.0+6 has no updater**
   and must be replaced once before any patch can reach those 15 testers.
4. For Flutter iOS, configure the signing team, owned bundle identifier and
   corresponding Firebase/Google sign-in/push settings, distribution certificate
   and provisioning/export profile. Then validate on a physical signed iOS device.
5. For CI, add a Shorebird API key as `SHOREBIRD_TOKEN` and the existing Android
   signing/Firebase secrets through GitHub's secret UI; private dependencies may
   require a read-only `DEPENDENCY_READ_TOKEN`. The manual workflow validates only.
6. After separate authorization for a staging patch, validate actual download,
   full-restart activation, offline downloaded chapters, sync and rollback before
   promoting that exact release/patch to stable.

Use [the release/patch runbook](SHOREBIRD_OTA.md). Local build artifacts and
unpublished receipts are under the ignored `output/ota-validation/` directory;
they have not been shared with testers or attached to a public release.
