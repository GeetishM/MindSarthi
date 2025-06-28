import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:mindsarthi/features/user_selector/user_selection.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallDevice = size.height < 600;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: size.height - MediaQuery.of(context).padding.vertical),
            child: IntrinsicHeight(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),

                  // Heading
                  Text(
                    "Hi, I’m MindSarthi 👋",
                    style: TextStyle(
                      fontSize: size.width * 0.06, // responsive font size
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 16),

                  // Subtitle
                  Text(
                    "Your pocket companion for\neveryday mental wellness.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: size.width * 0.04,
                      fontStyle: FontStyle.italic,
                      color: Colors.black87,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Illustration
                  SvgPicture.asset(
                    'assets/illustrations/Solidarity-pana 1.svg',
                    height: isSmallDevice ? 180 : size.height * 0.3,
                  ),

                  const SizedBox(height: 40),

                  // Get Started Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const UserSelection(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurpleAccent[200],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'Get Started',
                        style: TextStyle(
                          fontSize: size.width * 0.045,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
