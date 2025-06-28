import 'package:flutter/widgets.dart';
import 'package:mindsarthi/features/personal_user/screens/1homepage/Resources/anxity_panic.dart';
import 'package:mindsarthi/features/personal_user/screens/1homepage/Resources/depression.dart';
import 'package:mindsarthi/features/personal_user/screens/1homepage/Resources/selfharm.dart';

class AppRouter {
  static Map<String, WidgetBuilder> get routes {
    return {
    '/anxietypanic': (context) => const Anxity(),
    '/depression': (context) => const Depression(),
    '/selfharm': (context) => const SelfHarm(),
    };
  }
}