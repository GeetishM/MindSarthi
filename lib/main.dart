import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mindsarthi/core/routes/app_routes.dart';
import 'package:mindsarthi/features/personal_user/screens/1homepage/Journal/journal_entry.dart';
import 'package:mindsarthi/features/personal_user/screens/5chtbotpage/hive/chat_history.dart';
import 'package:mindsarthi/features/personal_user/screens/5chtbotpage/providers/chat_provider.dart';
import 'package:mindsarthi/features/personal_user/screens/nav.dart';
import 'package:mindsarthi/features/welcome.dart';
import 'package:provider/provider.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive for Journal
  await Hive.initFlutter();
  Hive.registerAdapter(JournalEntryAdapter());
  await Hive.openBox<JournalEntry>('journalBox');
  await Hive.openBox('journalSettings');

  // Initialize ChatProvider Hive + Firebase
  Hive.registerAdapter(ChatHistoryAdapter());
  await Hive.openBox<ChatHistory>('chat_history');
  await ChatProvider.initHive();
  await Firebase.initializeApp();
  
  

  final user = FirebaseAuth.instance.currentUser;

  runApp(
  MultiProvider(
    providers: [
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
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      routes: AppRouter.routes,
      title: 'MindSarthi',
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color.fromARGB(255, 244, 239, 249),
        primarySwatch: Colors.indigo,
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.white,
        ),
        cardTheme: const CardThemeData(
          color: Colors.white,
          elevation: 2,
          margin: EdgeInsets.all(8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasData) {
            return const NavBar();
          } else {
            return const WelcomeScreen();
          }
        },
      ),
    );
  }
}

