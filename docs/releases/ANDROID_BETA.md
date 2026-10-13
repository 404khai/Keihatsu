# Android beta distribution

The first beta is **0.1.0 (Android build 5)**, package `com.example.keihatsu`.
It uses the existing release signing certificate and the live Netcup HTTPS API.
The old GitHub `v1.0.0` APK actually identifies itself as `1.2.0`, build 4.
Android uses the numeric build number for upgrades, so build 5 can replace it
without removing tester data. Future beta builds must use 6, 7, and so on.

## Firebase console: notify the existing testers

1. Open the prepared release: https://console.firebase.google.com/project/keihatsu-4539d/appdistribution/app/android:com.example.keihatsu/releases/4t4nsjdl7v1q8
2. Select the **Keihatsu Android** app
   (`1:887783028868:android:6a680c4ac1e7f6b97aaad1`).
3. Upload `output/beta/keihatsu-0.1.0-build5.apk` from the repository root if the
   prepared release is not already listed.
4. Paste `docs/releases/0.1.0-beta-notes.txt` into the release notes.
5. Select the testers you want to notify. The project currently retains 13 testers
   and has no tester groups. A group such as `beta-testers` is optional and makes
   later distributions easier.
6. Click **Distribute**. Firebase handles invitations/update emails. Testers open
   the email on Android, sign in with the invited account, and install using the
   Firebase tester flow. Android may ask them to allow installs from that source.

Firebase's distribution emails do not use the application's SMTP credentials.
Distribution is private; it does not require a public GitHub release or Git tag.

## Build another beta

From `apps/flutter`:

```sh
flutter build apk --release \
  --build-name=0.1.0 --build-number=6 \
  --dart-define=APP_VERSION=0.1.0 \
  --dart-define=API_BASE_URL=https://keihatsu.159.195.86.119.sslip.io
```

Use a higher build number for every update. Preserve `android/key.properties`
and the existing keystore; never commit them. When the owned API domain is
ready, replace API_BASE_URL in the build command.

## CLI distribution (after selecting a tester group)

```sh
firebase appdistribution:distribute output/beta/keihatsu-0.1.0-build5.apk \
  --project keihatsu-4539d \
  --app 1:887783028868:android:6a680c4ac1e7f6b97aaad1 \
  --release-notes-file docs/releases/0.1.0-beta-notes.txt \
  --groups beta-testers
```

Create/populate `beta-testers` in the console first. The `--groups` option causes
Firebase to distribute and notify those testers. Omitting testers/groups uploads
and prepares the release without notifying anyone.

The workstation's Homebrew Node executable currently has a missing dynamic
library. Until repaired, invoke the working Node 24 installation explicitly:

```sh
/Users/admin/.nvm/versions/node/v24.16.0/bin/node /opt/homebrew/bin/firebase \
  appdistribution:distribute output/beta/keihatsu-0.1.0-build5.apk \
  --project keihatsu-4539d \
  --app 1:887783028868:android:6a680c4ac1e7f6b97aaad1 \
  --release-notes-file docs/releases/0.1.0-beta-notes.txt \
  --groups beta-testers
```

## GitHub public-release versions

`grvt8/Keihatsu` redirects to `404khai/Keihatsu`. The `v1.0.0` release/tag moved
with the repository. It is currently not immutable, so its GitHub release and
Git tag can both be deleted and recreated later. Deleting just the release does
not remove the tag. Existing downloaded APKs and cloned tags remain out there.

Prefer preserving release history and choosing a new public version. If you
explicitly choose to reuse `v1.0.0`, remove the release and remote/local tag when
ready, then create the new tag from the tested public-launch commit. Neither the
old release nor its tag has been changed during this beta preparation.

The existing GitHub release workflow publishes APKs, and its Firebase secret is
only a placeholder. It does not currently send beta updates through Firebase.
Use Firebase directly for this beta.
