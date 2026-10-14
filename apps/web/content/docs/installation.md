## Get the Android beta

Open the Firebase App Distribution invitation sent to your beta-testing email. Sign in with that same Google account, follow Firebase's installation instructions and choose the latest Keihatsu release. Access is limited to invited testers.

If Android asks whether this source can install apps, allow the source you are using to install the beta. Do not enable unrelated installation permissions.

## Update without losing your library

Install a new beta over your current installation. Keep the app installed and keep its data. Uninstalling or clearing storage removes locally downloaded chapters and other device-only data.

The beta updates keep the same Android package and signing identity. If Android says the signatures do not match, stop and report which build you currently have rather than uninstalling to force the update.

## First launch

Open Keihatsu, follow onboarding and sign in with Google. Notification permission is optional. Check your account name before building your library, especially when switching between accounts on a shared device.

## App updates

A new APK can update the app, bundled artwork and native dependencies. Builds that include the Shorebird updater can also receive eligible Dart-code updates through the app's update flow. A full APK update is still required for changes that cannot be delivered that way.

## iOS availability

iOS installation needs an appropriately signed build and an invitation through the distribution channel offered by the project. The Android APK cannot be installed on iOS. See the repository's iOS distribution guide if you are building the project yourself.

## Developer startup

Clone [the repository](https://github.com/404khai/Keihatsu) and use the Flutter version pinned in `apps/flutter/shorebird-release.json`. The Flutter app also uses sibling `navii` and `blobatar` packages; follow `docs/releases/SHOREBIRD_OTA.md` for their reviewed revisions and relative directory layout. Keep signing keys, Firebase configuration and service credentials in ignored local files.

For the website, run `npm ci` then `npm run dev` in `apps/web`. The development site serves `/docs` on port 5001. Markdown pages live in `apps/web/content/docs`; [Edit these docs](/docs/contributing) explains adding pictures.

For the API, follow the repository's API/deployment guide to configure PostgreSQL and the required environment variables privately. Install the locked dependencies, generate Prisma's client, apply reviewed migrations, and run the NestJS development server. Never copy the production database or credentials into example documentation.

For Flutter, run `flutter pub get` in `apps/flutter`, generate Isar schemas with `dart run build_runner build --delete-conflicting-outputs` when models change, then run `flutter run` on your device. Set `API_BASE_URL` with a Dart define to your own HTTPS API when developing against another service. Release builds use the reviewed production settings and existing signing identity through `tool/shorebird.py`.
