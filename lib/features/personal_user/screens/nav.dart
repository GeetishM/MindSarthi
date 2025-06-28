import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mindsarthi/features/personal_user/screens/1homepage/home.dart';
import 'package:mindsarthi/features/personal_user/screens/2consultpage/consult.dart';
import 'package:mindsarthi/features/personal_user/screens/3insightpage/insight.dart';
import 'package:mindsarthi/features/personal_user/screens/4communitypage/community.dart';
import 'package:mindsarthi/features/personal_user/screens/5chtbotpage/screen/chat_screen.dart';

class NavBar extends StatefulWidget {
  const NavBar({super.key});

  @override
  State<NavBar> createState() => _NavBarState();
}

class _NavBarState extends State<NavBar> {
  int _currentIndex = 0;
  DateTime? _lastBackPressed;

  final List<Widget> _pages = [
    const HomePage(),
    const ConsultPage(),
    const InsightPage(),
    CommunityPage(),
    const ChatScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final iconSize = screenWidth < 360 ? 20.0 : 24.0;
    final labelStyle = screenWidth < 360
        ? const TextStyle(fontSize: 11, fontWeight: FontWeight.normal)
        : const TextStyle(fontSize: 12, fontWeight: FontWeight.normal);

    return WillPopScope(
      onWillPop: () async {
        final now = DateTime.now();
        final backPressedRecently = _lastBackPressed != null &&
            now.difference(_lastBackPressed!) < const Duration(seconds: 2);

        if (backPressedRecently) {
          exit(0);
        } else {
          _lastBackPressed = now;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Press back again to exit'),
              duration: Duration(seconds: 2),
            ),
          );
          return false;
        }
      },
      child: Scaffold(
        body: _pages[_currentIndex],
        bottomNavigationBar: NavigationBarTheme(
          data: NavigationBarThemeData(
            labelTextStyle: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return labelStyle.copyWith(fontWeight: FontWeight.bold);
              }
              return labelStyle;
            }),
          ),
          child: NavigationBar(
            height: 64,
            backgroundColor: theme.scaffoldBackgroundColor,
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) {
              setState(() => _currentIndex = index);
            },
            destinations: [
              NavigationDestination(
                label: 'Home',
                icon: SvgPicture.asset(
                  'assets/icons/home.svg',
                  height: iconSize,
                ),
                selectedIcon: SvgPicture.asset(
                  'assets/icons/homeFill.svg',
                  height: iconSize,
                ),
              ),
              NavigationDestination(
                label: 'Consult',
                icon: SvgPicture.asset(
                  'assets/icons/stethoscope.svg',
                  height: iconSize,
                ),
                selectedIcon: SvgPicture.asset(
                  'assets/icons/stethoscopeFill.svg',
                  height: iconSize,
                ),
              ),
              NavigationDestination(
                label: 'Insight',
                icon: SvgPicture.asset(
                  'assets/icons/book-open-cover.svg',
                  height: iconSize,
                ),
                selectedIcon: SvgPicture.asset(
                  'assets/icons/book-open-cover-fill.svg',
                  height: iconSize,
                ),
              ),
              NavigationDestination(
                label: 'Community',
                icon: SvgPicture.asset(
                  'assets/icons/users-class.svg',
                  height: iconSize,
                ),
                selectedIcon: SvgPicture.asset(
                  'assets/icons/users-class-fill.svg',
                  height: iconSize,
                ),
              ),
              NavigationDestination(
                label: 'ChatPal',
                icon: SvgPicture.asset(
                  'assets/icons/chatbot-speech-bubble.svg',
                  height: iconSize,
                ),
                selectedIcon: SvgPicture.asset(
                  'assets/icons/chatbot-speech-bubble-fill.svg',
                  height: iconSize,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
