# Keihatsu 📖

A modern, offline-first manga and light novel reader. This monorepo contains the Flutter application, NestJS API, and native SwiftUI application.

## Repository Structure

```text
apps/
├── flutter/  # Cross-platform Flutter application
├── api/      # NestJS/TypeScript backend
└── ios/      # Native SwiftUI application
```

## 🌟 Key Features

- **Extension System**: Discover content from various sources via a modular extension architecture.
- **Offline-First Library**: Fast, local database management using **Isar DB** for a responsive experience even without internet.
- **Persistent Themes**: Fully customizable UI with persistent brand colors, light/dark modes, and "Pure Black" OLED support.
- **Advanced Reader**: High-performance reader with chapter bookmarking, history tracking, and smooth navigation.
- **Download Manager**: Save chapters locally for offline reading with background download support.
- **Global Search**: Search for manga across all enabled extensions simultaneously.
- **Community**: Real-time nested comments and interactive user profiles.
- **Smart Sync**: Seamlessly sync your library, history, and preferences with the Keihatsu API.

## 🛠️ Tech Stack

- **Framework**: [Flutter](https://flutter.dev/)
- **State Management**: [Provider](https://pub.dev/packages/provider)
- **Database**: [Isar](https://isar.dev/) (NoSQL, high performance)
- **Local Storage**: [Shared Preferences](https://pub.dev/packages/shared_preferences)
- **Networking**: [http](https://pub.dev/packages/http) & [Dio](https://pub.dev/packages/dio)
- **Icons & Fonts**: [Phosphor Icons](https://pub.dev/packages/phosphor_flutter) & [Google Fonts](https://pub.dev/packages/google_fonts)

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (latest stable)
- Node.js and npm
- Xcode
- Android Studio / VS Code with Flutter extension

### Flutter Application

1. Enter the Flutter application:
   ```bash
   cd apps/flutter
   ```
2. Install its existing dependencies:
   ```bash
   flutter pub get
   ```
3. Generate local database schemas:
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```
4. Configure API Endpoint:
    - Open `apps/flutter/lib/services/api_constants.dart` from the repository root.
    - Update `baseUrl` to point to your running backend API.

5. Run the app:
   ```bash
   flutter run
   ```

### API

```bash
cd apps/api
npm run start:dev
```

### Native iOS Application

Open `apps/ios/Keihatsu.xcodeproj` in Xcode.

## 📂 Project Structure

```text
apps/flutter/lib/
├── components/          # Reusable UI widgets
├── models/              # Data models and Isar schemas
├── providers/           # State management
├── screens/             # Feature pages
├── services/            # API clients and repository logic
└── theme_provider.dart  # Global UI styling and persistence
```

## 🛡️ License

MIT License. See [LICENSE](LICENSE) for details.
