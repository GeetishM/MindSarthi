import 'package:flutter/material.dart';

class SupportResourcePage extends StatelessWidget {
  const SupportResourcePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Available Support Resources'),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSupportContainer(
              'lib/personal/assets/Anxiety illustration.svg',
              'Anxiety and Panic Attacks',
              '/anxietypanic',
              context,
            ),
            SizedBox(height: 10),
            _buildSupportContainer(
              'lib/personal/assets/depression.svg',
              'Depression',
              '/depression',
              context,
            ),
            SizedBox(height: 10),
            _buildSupportContainer(
              'lib/personal/assets/selfHarm.svg',
              'Self Harm and Suicidal Ideation',
              '/selfharm',
              context,
            ),
          ],
        ),
      ),
    );
  }

  GestureDetector _buildSupportContainer(
    String imagePath,
    String label,
    String routeName,
    BuildContext context,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, routeName);
      },
      child: Container(
        height: 170,
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 255, 255, 255),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.black,
            width: 0.1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              imagePath,
              width: 80,
              height: 80,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
