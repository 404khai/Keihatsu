# Keihatsu Flutter releases

Use [the Shorebird OTA release guide](../docs/releases/SHOREBIRD_OTA.md) for
Android and Flutter iOS baseline validation, publication, compatible patches,
signing, staging verification and rollback.

The `release.yml` workflow is now manually dispatched and validates Shorebird
baselines without uploading or distributing them. Pushing a `v*` tag no longer
publishes an ordinary Flutter APK. Sign in and initialize the real Shorebird
app ID locally before running it; account credentials belong in service secret
settings, never app assets or chat.

The already distributed Android 0.1.0+6 APK has no Shorebird engine and requires
installation of a new signed baseline before it can receive OTA patches. The
candidate 0.1.0+7 build number must remain unique across parallel beta work.
The separate `apps/ios` SwiftUI app is outside this workflow.
