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
  

  final List<Widget> _pages = [
    const HomePage(),
    const ConsultPage(),
    const InsightPage(),
    CommunityPage(),
    const ChatScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          // backgroundColor: Color(0xFFE0F7FA), // Add background color
          // indicatorColor: Color(0xff89deeb),
          iconTheme: WidgetStateProperty.all(const IconThemeData()),
          labelTextStyle: WidgetStateProperty.resolveWith((Set<WidgetState> states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(fontWeight: FontWeight.bold);
            }
            return const TextStyle(fontWeight: FontWeight.normal);
          }),
        ),
        child: NavigationBar(
          onDestinationSelected: (int index) {
            setState(() {
              _currentIndex = index;
            });
          },
          selectedIndex: _currentIndex,
          destinations: [
            NavigationDestination(
              selectedIcon: SizedBox(
                height: 24, // Adjust the height as needed
                child: SvgPicture.asset('assets/icons/homeFill.svg'),
              ),
              icon: SizedBox(
                height: 24, // Adjust the height as needed
                child: SvgPicture.asset('assets/icons/home.svg'),
              ),
              label: 'Home',
            ),
            NavigationDestination(
              selectedIcon: SizedBox(
                height: 24, // Adjust the height as needed
                child: SvgPicture.asset('assets/icons/stethoscopeFill.svg'),
              ),
              icon: SizedBox(
                height: 24, // Adjust the height as needed
                child: SvgPicture.asset('assets/icons/stethoscope.svg'),
              ),
              label: 'Consult',
            ),
            NavigationDestination(
              selectedIcon: SizedBox(
                height: 24, // Adjust the height as needed
                child: SvgPicture.asset('assets/icons/book-open-cover-fill.svg'),
              ),
              icon: SizedBox(
                height: 24, // Adjust the height as needed
                child: SvgPicture.asset('assets/icons/book-open-cover.svg'),
              ),
              label: 'Insight',
            ),
            NavigationDestination(
              selectedIcon: SizedBox(
                height: 24, // Adjust the height as needed
                child: SvgPicture.asset('assets/icons/users-class-fill.svg'),
              ),
              icon: SizedBox(
                height: 24, // Adjust the height as needed
                child: SvgPicture.asset('assets/icons/users-class.svg'),
              ),
              label: 'Community',
            ),
            NavigationDestination(
              selectedIcon: SizedBox(
                height: 24, // Adjust the height as needed
                child: SvgPicture.asset('assets/icons/chatbot-speech-bubble-fill.svg'),
              ),
              icon: SizedBox(
                height: 24, // Adjust the height as needed
                child: SvgPicture.asset('assets/icons/chatbot-speech-bubble.svg'),
              ),
              label: 'ChatPal',
            ),
          ],
        ),
      ),
    );
  }
}
