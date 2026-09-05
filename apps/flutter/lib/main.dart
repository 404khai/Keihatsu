import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'dart:ui';

import 'theme_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/offline_library_provider.dart';
import 'providers/download_provider.dart';
import 'providers/floating_nav_provider.dart';

import 'models/local_models.dart';
import 'services/sources_api.dart';
import 'services/library_api.dart';
import 'services/auth_api.dart';
import 'services/file_service.dart';
import 'services/history_repository.dart';
import 'services/local_scope.dart';
import 'services/sync_manager.dart';
import 'services/sources_repository.dart';
import 'services/manga_repository.dart';
import 'services/library_repository.dart';
import 'services/session_bootstrap_service.dart';
import 'services/user_repository.dart';

// Screens
import 'screens/Onboarding.dart';
import 'screens/HomePage.dart';
import 'screens/RegisterScreen.dart';
import 'screens/LoginScreen.dart';
import 'screens/OnboardingFlow.dart';
import 'screens/LibraryScreen.dart';
import 'screens/HistoryScreen.dart';
import 'screens/ProfileScreen.dart';
import 'screens/AppearancePage.dart';
import 'screens/ExtensionsScreen.dart';
import 'screens/SettingsScreen.dart';
import 'screens/UpdatesScreen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  try {
    await Firebase.initializeApp();
    // Pass all uncaught "fatal" errors from the framework to Crashlytics
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework to Crashlytics
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
    debugPrint('Make sure you have added google-services.json to android/app/');
  }

  final themeProvider = ThemeProvider();
  // Wait for the theme to load from preferences before running the app
  // This prevents the flicker from white to the saved theme
  await themeProvider.loadFromPrefs();

  final dir = await getApplicationDocumentsDirectory();
  final isar = await Isar.open([
    LocalSourceSchema,
    LocalMangaSchema,
    LocalChapterSchema,
    LocalPageSchema,
    LocalLibraryEntrySchema,
    LocalCategorySchema,
    LocalCategoryAssignmentSchema,
    SyncOperationSchema,
    LocalUserPreferencesSchema,
    DownloadQueueItemSchema,
  ], directory: dir.path);

  final fileService = FileService();
  final sourcesApi = SourcesApi();
  final libraryApi = LibraryApi();
  final authApi = AuthApi();

  // Mutable token getter — starts as null, gets wired to AuthProvider after it's created
  String? Function() _getToken = () => null;
  String Function() _getCurrentUserId = () => guestLocalScopeUserId;

  final syncManager = SyncManager(
    isar: isar,
    libraryApi: libraryApi,
    getToken: () => _getToken(),
    getCurrentUserId: () => _getCurrentUserId(),
  );

  final sourcesRepo = SourcesRepository(
    isar: isar,
    api: sourcesApi,
    fileService: fileService,
  );
  final mangaRepo = MangaRepository(
    isar: isar,
    api: sourcesApi,
    fileService: fileService,
    libraryApi: libraryApi,
    syncManager: syncManager,
    getCurrentUserId: () => _getCurrentUserId(),
  );
  final libraryRepo = LibraryRepository(
    isar: isar,
    api: libraryApi,
    syncManager: syncManager,
    getCurrentUserId: () => _getCurrentUserId(),
  );
  final historyRepo = HistoryRepository(
    isar: isar,
    api: libraryApi,
    getCurrentUserId: () => _getCurrentUserId(),
  );
  final userRepo = UserRepository(
    isar: isar,
    api: authApi,
    fileService: fileService,
    getCurrentUserId: () => _getCurrentUserId(),
  );
  final sessionBootstrapService = SessionBootstrapService(
    libraryRepository: libraryRepo,
    historyRepository: historyRepo,
  );

  // Create AuthProvider and wire up the token getter for SyncManager
  final authProvider = AuthProvider(
    userRepository: userRepo,
    onLogout: (_) async {},
  );

  // NOW wire the SyncManager's token getter to the real AuthProvider
  _getToken = () => authProvider.token;
  _getCurrentUserId = () => authProvider.localScopeUserId;

  // When auth state changes (login/logout), trigger the sync queue
  String? lastBootstrappedUserId;
  authProvider.addListener(() {
    if (authProvider.token != null && authProvider.user != null) {
      final currentUserId = authProvider.user!.id;
      if (lastBootstrappedUserId != currentUserId) {
        lastBootstrappedUserId = currentUserId;
        sessionBootstrapService.bootstrapUserData(
          token: authProvider.token!,
          userId: currentUserId,
        );
      }
      syncManager.processSyncQueue();
    } else {
      lastBootstrappedUserId = null;
    }
  });

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider.value(value: authProvider),
        // Repositories
        Provider.value(value: sourcesRepo),
        Provider.value(value: mangaRepo),
        Provider.value(value: libraryRepo),
        Provider.value(value: historyRepo),
        Provider.value(value: userRepo),
        // Providers using Repositories
        ChangeNotifierProxyProvider<AuthProvider, OfflineLibraryProvider>(
          create: (context) => OfflineLibraryProvider(
            libraryRepo: libraryRepo,
            mangaRepo: mangaRepo,
            getToken: () =>
            Provider.of<AuthProvider>(context, listen: false).token,
          ),
          update: (context, auth, previous) {
            previous!.bindUserScope(auth.localScopeUserId);
            return previous;
          },
        ),
        ChangeNotifierProvider(create: (_) => FloatingNavProvider()),
        ChangeNotifierProxyProvider<AuthProvider, DownloadProvider>(
          create: (context) => DownloadProvider(
            isar: isar,
            mangaRepo: mangaRepo,
            getToken: () =>
            Provider.of<AuthProvider>(context, listen: false).token,
          ),
          update: (context, auth, previous) => previous!,
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Keihatsu',
      themeMode: themeProvider.themeMode,
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: themeProvider.brandColor,
        scaffoldBackgroundColor: themeProvider.bgColor,
        colorScheme: ColorScheme.fromSeed(
          seedColor: themeProvider.brandColor,
          primary: themeProvider.brandColor,
          brightness: Brightness.light,
        ),
        textTheme: GoogleFonts.getTextTheme('Delius'),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: themeProvider.brandColor,
        scaffoldBackgroundColor: themeProvider.pureBlackDarkMode
            ? Colors.black
            : null,
        colorScheme: ColorScheme.fromSeed(
          seedColor: themeProvider.brandColor,
          primary: themeProvider.brandColor,
          brightness: Brightness.dark,
          surface: themeProvider.pureBlackDarkMode ? Colors.black : null,
        ),
        textTheme: GoogleFonts.getTextTheme(
          'Delius',
        ).apply(bodyColor: Colors.white, displayColor: Colors.white),
        useMaterial3: true,
      ),
      initialRoute: authProvider.isAuthenticated ? '/home' : '/onboarding',
      routes: {
        '/onboarding': (context) => const Onboarding(),
        '/onboardingFlow': (context) => const OnboardingFlow(),
        '/register': (context) => const RegisterScreen(),
        '/login': (context) => const LoginScreen(),
        '/library': (context) => const LibraryScreen(),
        '/history': (context) => const HistoryScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/appearance': (context) => const AppearancePage(),
        '/home': (context) => const HomePage(),
        '/updates': (context) => const UpdatesScreen(),
        '/extensions': (context) => const ExtensionsScreen(),
        '/settings': (context) => const SettingsScreen(),
      },
    );
  }
}
