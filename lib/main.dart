import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mindsarthi/core/routes/app_routes.dart';
import 'package:mindsarthi/features/personal_user/auth/personal_auth.dart';
import 'package:mindsarthi/features/personal_user/screens/1homepage/Journal/journal_entry.dart';
import 'package:mindsarthi/features/personal_user/screens/1homepage/Journal/journal.dart';
import 'package:mindsarthi/features/personal_user/screens/5chtbotpage/providers/chat_provider.dart';
import 'package:mindsarthi/features/personal_user/screens/nav.dart';
import 'package:provider/provider.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive for Journal
  await Hive.initFlutter();
  Hive.registerAdapter(JournalEntryAdapter());
  await Hive.openBox<JournalEntry>('journalBox');
  await Hive.openBox('journalSettings');

  // Initialize ChatProvider Hive + Firebase
  await ChatProvider.initHive();
  await Firebase.initializeApp();

  final user = FirebaseAuth.instance.currentUser;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ChatProvider()),
      ],
      child: MindSarthi(isLoggedIn: user != null),
    ),
  );
}

class MindSarthi extends StatelessWidget {
  final bool isLoggedIn;
  const MindSarthi({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
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
      home: isLoggedIn ? const NavBar() : const PersonalAuth(),
      routes: AppRouter.routes,
      
    );
  }
}
