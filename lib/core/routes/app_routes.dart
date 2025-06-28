import 'package:flutter/widgets.dart';
import 'package:hive/hive.dart';

import 'package:mindsarthi/features/personal_user/auth/personal_auth.dart';
import 'package:mindsarthi/features/personal_user/screens/1homepage/Journal/journal.dart';
import 'package:mindsarthi/features/personal_user/screens/1homepage/Resources/anxity_panic.dart';
import 'package:mindsarthi/features/personal_user/screens/1homepage/Resources/depression.dart';
import 'package:mindsarthi/features/personal_user/screens/1homepage/Resources/selfharm.dart';
import 'package:mindsarthi/features/personal_user/screens/1homepage/dailygoals/home.dart';

import 'package:mindsarthi/features/welcome.dart';

class AppRouter {
  static Map<String, WidgetBuilder> get routes {
    return {
      '/welcome': (context) => const WelcomeScreen(), 

      '/personalauth': (context) => const PersonalAuth(),
      '/professionalauth': (context) => const ProfessionalAuth(),
      '/organizationalauth': (context) => const OrganizationalAuth(),

      '/anxietypanic': (context) => const Anxity(),
      '/depression': (context) => const Depression(),
      '/selfharm': (context) => const SelfHarm(),
      '/journal': (context) => const Journal(),

      '/todaysgoals': (context) {
        // Ensure the box is opened before accessing it
        final box = Hive.box('mybox');
        return TodaysGoals(box: box);
      },
    };
  }
}