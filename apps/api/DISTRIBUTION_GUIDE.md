
# Keihatsu Build & Distribute Script

This script helps you build the release APK and optionally upload it to Firebase App Distribution.

## 1. Build Release APK
Run the following command to build the APK:
```powershell
cd Keihatsu
flutter build apk --release
```

## 2. Firebase App Distribution (CLI)
To upload to Firebase App Distribution from your terminal:

### Prerequisites:
1. Install Firebase CLI: `npm install -g firebase-tools`
2. Login: `firebase login`
3. Find your App ID in Firebase Console (Project Settings -> General).

### Upload Command:
```powershell
firebase appdistribution:distribute build/app/outputs/flutter-apk/app-release.apk `
    --app "YOUR_FIREBASE_APP_ID" `
    --groups "testers" `
    --release-notes "Beta version for testers"
```

---

## 3. Why Railway over Render?
For this specific project (Keihatsu API), **Railway is better** for these reasons:

1.  **Puppeteer Support**: Puppeteer requires specific system libraries (Chrome/Chromium). Railway's Docker support is more robust for these "heavy" dependencies.
2.  **No "Sleep" on Free Tier**: Render's free tier puts your API to sleep after 15 minutes of inactivity, causing a 30-second delay for the first request. Railway (using trial credits) keeps it active.
3.  **Database Integration**: Railway's internal networking between your API and PostgreSQL is faster and easier to set up.
4.  **Prisma Compatibility**: I've optimized your `Dockerfile` for Railway's build environment.
