import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:mindsarthi/core/routes/app_routes.dart';
import 'package:mindsarthi/features/personal_user/auth/personal_auth.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MindSarthi());
}

class MindSarthi extends StatelessWidget {
  const MindSarthi({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: PersonalAuth(),
      routes: AppRouter.routes,
    );
  }
}
