import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mindsarthi/core/theme/app_theme.dart';
import 'package:mindsarthi/core/theme/app_toast.dart';
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
    final screenWidth = MediaQuery.of(context).size.width;
    final iconSize = screenWidth < 360 ? 20.0 : 22.0;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final now = DateTime.now();
        final backPressedRecently = _lastBackPressed != null &&
            now.difference(_lastBackPressed!) < const Duration(seconds: 2);

        if (backPressedRecently) {
          exit(0);
        } else {
          _lastBackPressed = now;
          AppToast.info(context, 'Press back again to exit');
        }
      },
      child: Scaffold(
        body: _pages[_currentIndex],
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            color: AppColors.white,
            border: Border(
              top: BorderSide(color: AppColors.border, width: 1),
            ),
          ),
          child: NavigationBar(
            height: 64,
            backgroundColor: AppColors.white,
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) {
              setState(() => _currentIndex = index);
            },
            destinations: [
              _navItem('Home', 'assets/icons/home.svg', 'assets/icons/homeFill.svg', iconSize),
              _navItem('Consult', 'assets/icons/stethoscope.svg', 'assets/icons/stethoscopeFill.svg', iconSize),
              _navItem('Insight', 'assets/icons/book-open-cover.svg', 'assets/icons/book-open-cover-fill.svg', iconSize),
              _navItem('Community', 'assets/icons/users-class.svg', 'assets/icons/users-class-fill.svg', iconSize),
              _navItem('ChatPal', 'assets/icons/chatbot-speech-bubble.svg', 'assets/icons/chatbot-speech-bubble-fill.svg', iconSize),
            ],
          ),
        ),
      ),
    );
  }

  NavigationDestination _navItem(
    String label,
    String icon,
    String selectedIcon,
    double size,
  ) {
    return NavigationDestination(
      label: label,
      icon: SvgPicture.asset(icon, height: size, colorFilter: const ColorFilter.mode(AppColors.textSecondary, BlendMode.srcIn)),
      selectedIcon: SvgPicture.asset(selectedIcon, height: size, colorFilter: const ColorFilter.mode(AppColors.primary, BlendMode.srcIn)),
    );
  }
}
