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
import 'package:mindsarthi/features/welcome.dart';
import 'package:provider/provider.dart';
import 'package:toastification/toastification.dart';

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

  await Hive.openBox('mybox');

  await Firebase.initializeApp();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
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

    // ── Branded error widget instead of raw red screen ───────────────────
    ErrorWidget.builder = (FlutterErrorDetails details) =>
        AppErrorWidget(details: details);

    return ToastificationWrapper(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        routes: AppRouter.routes,
        title: 'MindSarthi',
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: themeProvider.themeMode,
        home: StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Scaffold(
                backgroundColor: themeProvider.isDark
                    ? AppColors.darkBackground
                    : AppColors.background,
                body: Center(
                  child: CircularProgressIndicator(
                    color: themeProvider.isDark
                        ? AppColors.darkPrimary
                        : AppColors.primary,
                    strokeWidth: 2.5,
                  ),
                ),
              );
            }
            if (snapshot.hasData) {
              // ── Route by role instead of always NavBar ──────────────────
              return const RoleRouter();
            } else {
              return const WelcomeScreen();
            }
          },
        ),
      ),
    );
  }
}
