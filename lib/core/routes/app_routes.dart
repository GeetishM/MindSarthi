import 'package:flutter/widgets.dart';
<<<<<<< HEAD
import 'package:mindsarthi/features/organizational_user/auth/organizational_auth.dart';
import 'package:mindsarthi/features/personal_user/auth/personal_auth.dart';
=======
import 'package:mindsarthi/features/personal_user/screens/1homepage/Journal/journal.dart';
>>>>>>> 87255c931d68039a6558cfbba6b152636fd70a69
import 'package:mindsarthi/features/personal_user/screens/1homepage/Resources/anxity_panic.dart';
import 'package:mindsarthi/features/personal_user/screens/1homepage/Resources/depression.dart';
import 'package:mindsarthi/features/personal_user/screens/1homepage/Resources/selfharm.dart';
import 'package:mindsarthi/features/professional_user/auth/professional_auth.dart';
import 'package:mindsarthi/features/welcome.dart';

class AppRouter {
  static Map<String, WidgetBuilder> get routes {
    return {
<<<<<<< HEAD
      '/welcome': (context) => const WelcomeScreen(), 

      '/personalauth': (context) => const PersonalAuth(),
      '/professionalauth': (context) => const ProfessionalAuth(),
      '/organizationalauth': (context) => const OrganizationalAuth(),

      '/anxietypanic': (context) => const Anxity(),
      '/depression': (context) => const Depression(),
      '/selfharm': (context) => const SelfHarm(),
=======
    '/anxietypanic': (context) => const Anxity(),
    '/depression': (context) => const Depression(),
    '/selfharm': (context) => const SelfHarm(),
      '/journal': (context) => const Journal(),
>>>>>>> 87255c931d68039a6558cfbba6b152636fd70a69
    };
  }
}
