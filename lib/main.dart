import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mindsarthi/core/routes/app_routes.dart';
import 'package:mindsarthi/core/theme/app_theme.dart';
import 'package:mindsarthi/core/theme/theme_provider.dart';
import 'package:mindsarthi/core/widgets/error_boundary.dart';
import 'package:mindsarthi/core/widgets/role_router.dart';
import 'package:mindsarthi/features/personal_user/screens/1homepage/Journal/journal_entry.dart';
import 'package:mindsarthi/features/personal_user/screens/5chtbotpage/hive/chat_history.dart';
import 'package:mindsarthi/features/personal_user/screens/5chtbotpage/providers/chat_provider.dart';
import 'package:mindsarthi/features/personal_user/screens/1homepage/dailygoals/task.dart';
import 'package:mindsarthi/features/welcome.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mindsarthi/core/localization/app_localizations.dart';
import 'package:mindsarthi/core/localization/locale_provider.dart';
import 'package:mindsarthi/core/services/notification_service.dart';
import 'package:toastification/toastification.dart';
import 'package:mindsarthi/features/personal_user/screens/3insightpage/insight_data.dart';
import 'package:mindsarthi/features/personal_user/screens/1homepage/MoodInputs/models/mood_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Global Flutter error handler ─────────────────────────────────────────
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    // TODO: Forward to Crashlytics → FirebaseCrashlytics.instance.recordFlutterFatalError(details);
  };

  // ── Global async / platform error handler ────────────────────────────────
  PlatformDispatcher.instance.onError = (error, stack) {
    // TODO: Forward to Crashlytics → FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    debugPrint('Unhandled async error: $error\n$stack');
    return true; // Returning true marks the error as handled
  };

  await Hive.initFlutter();

  Hive.registerAdapter(JournalEntryAdapter());
  await Hive.openBox<JournalEntry>('journalBox');
  await Hive.openBox('journalSettings');

  Hive.registerAdapter(ChatHistoryAdapter());
  await Hive.openBox<ChatHistory>('chat_history');
  await ChatProvider.initHive();

  Hive.registerAdapter(TaskAdapter());
  await Hive.openBox<Task>('tasksBox');
  await Hive.openBox('mybox');

  await Firebase.initializeApp();
  await NotificationService.initialize();
  Insight.seedInsights();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => MoodProvider()),
      ],
      child: const MindSarthi(),
    ),
  );
}

class MindSarthi extends StatelessWidget {
  const MindSarthi({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final localeProvider = context.watch<LocaleProvider>();

    // ── Branded error widget instead of raw red screen ───────────────────
    ErrorWidget.builder = (FlutterErrorDetails details) =>
        AppErrorWidget(details: details);

    return ToastificationWrapper(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'MindSarthi',
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: themeProvider.themeMode,
        locale: localeProvider.locale,
        supportedLocales: const [
          Locale('en'),
          Locale('hi'),
          Locale('bn'),
        ],
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        // Use onGenerateRoute instead of home + routes to avoid
        // Navigator history-empty assertion on theme rebuilds.
        initialRoute: '/',
        onGenerateRoute: (settings) {
          // Named routes from AppRouter
          final namedRoutes = AppRouter.routes;
          if (namedRoutes.containsKey(settings.name)) {
            return MaterialPageRoute(
              builder: namedRoutes[settings.name]!,
              settings: settings,
            );
          }

          // Default '/' route — auth gate
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => const _AuthGate(),
          );
        },
      ),
    );
  }
}

/// Auth gate extracted as a standalone widget so it can be used
/// with [onGenerateRoute] instead of [MaterialApp.home].
class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor:
                isDark ? AppColors.darkBackground : AppColors.background,
            body: Center(
              child: CircularProgressIndicator(
                color: isDark ? AppColors.darkPrimary : AppColors.primary,
                strokeWidth: 2.5,
              ),
            ),
          );
        }
        if (snapshot.hasData) {
          return const RoleRouter();
        } else {
          return const WelcomeScreen();
        }
      },
    );
  }
}
