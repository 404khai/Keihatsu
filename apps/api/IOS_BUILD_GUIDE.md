# Keihatsu iOS Build Guide

Building an iOS app requires a **macOS environment** with Xcode installed. Since you are currently on Windows, you have two main options:

1.  **Use a Mac**: If you have access to a Mac (yours, a friend's, or a cloud Mac rental).
2.  **Use a Cloud Build Service**: Use a CI/CD service like Codemagic or GitHub Actions to build the app in the cloud.

## 1. Preparation (Do this on Windows first)

Before building, ensure your project is configured correctly.

### A. Firebase Configuration
1.  Go to the [Firebase Console](https://console.firebase.google.com/).
2.  Open your project settings.
3.  Add an **iOS App** if you haven't already.
    -   **Bundle ID**: `com.example.keihatsu` (or whatever you set in `ios/Runner.xcodeproj/project.pbxproj` - check `PRODUCT_BUNDLE_IDENTIFIER`).
4.  Download the `GoogleService-Info.plist` file.
5.  Place this file in `Keihatsu/ios/Runner/GoogleService-Info.plist`.

### B. Configure Google Sign-In
1.  Open `Keihatsu/ios/Runner/Info.plist`.
2.  Find the `CFBundleURLTypes` section (I have added a placeholder for you).
3.  Replace `com.googleusercontent.apps.REPLACE_WITH_YOUR_REVERSE_CLIENT_ID` with the `REVERSE_CLIENT_ID` from your `GoogleService-Info.plist`.

### C. App Icons
Run the following command to generate iOS app icons:
```bash
cd Keihatsu
flutter pub run flutter_launcher_icons
```

## 2. Option A: Building on a Mac

If you have access to a Mac:

1.  **Install Xcode**: Download from the Mac App Store.
2.  **Install CocoaPods**:
    ```bash
    sudo gem install cocoapods
    ```
3.  **Install Flutter**: Follow the [Flutter installation guide for macOS](https://docs.flutter.dev/get-started/install/macos).
4.  **Build the App**:
    ```bash
    cd Keihatsu
    flutter build ipa
    ```
    This will create an `.ipa` file in `build/ios/ipa/`.

## 3. Option B: Building with Codemagic (Recommended for Windows Users)

Codemagic is a CI/CD service specialized for Flutter that offers a generous free tier (500 build minutes/month).

1.  **Push your code to GitHub/GitLab/Bitbucket**.
2.  **Sign up for Codemagic** and connect your repository.
3.  **Configure the Workflow**:
    -   Select "Flutter App" as the project type.
    -   Enable "iOS" platform.
    -   Set the "Build mode" to "Release".
4.  **Signing (Crucial)**:
    -   You need an **Apple Developer Account** ($99/year).
    -   Generate a **Certificate** and **Provisioning Profile** in the Apple Developer Portal.
    -   Upload these to Codemagic in the "Code signing identities" section.
5.  **Start Build**: Click "Start new build". Codemagic will spin up a Mac VM, build your app, and give you the `.ipa` file.

## 4. Option C: Building with GitHub Actions

You can also use GitHub Actions to build on a macOS runner, but setting up signing is more complex.

1.  Create `.github/workflows/ios_build.yml`.
2.  Use the `macos-latest` runner.
3.  Decode your signing certificates from GitHub Secrets.
4.  Run `flutter build ios --release --no-codesign`.
5.  Sign the app manually using `codesign` or Fastlane.
