import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mindsarthi/core/routes/app_routes.dart';
import 'package:mindsarthi/core/theme/app_theme.dart';
import 'package:mindsarthi/core/theme/theme_provider.dart';
import 'package:mindsarthi/core/widgets/error_boundary.dart';
import 'package:mindsarthi/core/widgets/role_router.dart';
import 'package:mindsarthi/features/personal_user/screens/1homepage/Journal/journal_entry.dart';
import 'package:mindsarthi/features/personal_user/screens/5chtbotpage/hive/chat_history.dart';
import 'package:mindsarthi/features/personal_user/screens/5chtbotpage/hive/knowledge_article.dart';
import 'package:mindsarthi/features/personal_user/screens/5chtbotpage/providers/chat_provider.dart';
import 'package:mindsarthi/features/personal_user/screens/1homepage/dailygoals/task.dart';
import 'package:mindsarthi/features/personal_user/screens/1homepage/MoodInputs/models/mood_entry.dart';
import 'package:mindsarthi/features/welcome.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mindsarthi/core/localization/app_localizations.dart';
import 'package:mindsarthi/core/localization/locale_provider.dart';
import 'package:mindsarthi/core/services/notification_service.dart';
import 'package:mindsarthi/core/services/sync_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide ChangeNotifierProvider;
import 'package:toastification/toastification.dart';
import 'package:mindsarthi/features/personal_user/screens/3insightpage/insight_data.dart';
import 'package:mindsarthi/features/personal_user/screens/1homepage/MoodInputs/models/mood_provider.dart';
import 'package:mindsarthi/features/app_lock/app_lock_wrapper.dart';
import 'package:mindsarthi/features/auth/auth_repository.dart';

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
  Hive.registerAdapter(KnowledgeArticleAdapter());
  await Hive.openBox<KnowledgeArticle>('knowledgeBase');
  await ChatProvider.initHive();

  Hive.registerAdapter(TaskAdapter());
  await Hive.openBox<Task>('tasksBox');
  
  Hive.registerAdapter(MoodEntryAdapter());
  await Hive.openBox<MoodEntry>('moodsBox');

  await Hive.openBox('mybox');
  await Hive.openBox('notificationsBox');

  await NotificationService.initialize();
  Insight.seedInsights();
  SyncService().syncAll();

  runApp(
    ProviderScope(
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => LocaleProvider()),
          ChangeNotifierProvider(create: (_) => ChatProvider()),
          ChangeNotifierProvider(create: (_) => MoodProvider()),
        ],
        child: const MindSarthi(),
      ),
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
        theme: AppTheme.getThemeForRole(themeProvider.currentRole, isDark: false),
        darkTheme: AppTheme.getThemeForRole(themeProvider.currentRole, isDark: true),
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
class _AuthGate extends ConsumerWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return authState.when(
      data: (user) {
        if (user != null) {
          return const AppLockWrapper(child: RoleRouter());
        } else {
          return const WelcomeScreen();
        }
      },
      loading: () => Scaffold(
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
        body: Center(
          child: CircularProgressIndicator(
            color: isDark ? AppColors.darkPrimary : AppColors.primary,
            strokeWidth: 2.5,
          ),
        ),
      ),
      error: (err, stack) {
        debugPrint('AuthGate Error: $err');
        return const WelcomeScreen();
      },
    );
  }
}
