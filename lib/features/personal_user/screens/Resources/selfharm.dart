import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class SelfHarm extends StatefulWidget {
  const SelfHarm({super.key});

  @override
  State<SelfHarm> createState() => _SelfHarmState();
}

class _SelfHarmState extends State<SelfHarm> {
  @override
  Widget build(BuildContext context) {
    return  Scaffold(
      appBar: AppBar(
        title: const Text('Self harm'),
        leading: IconButton(
          onPressed: () {
            Navigator.pushNamed(context, '/navbar');
          },
          icon: const Icon(
            Icons.arrow_back_ios,
            size: 20,
            color: Colors.black,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            buildCard(
              icon: Icons.volunteer_activism_outlined,
              text: 'How can I help myself?',
            ),
            buildCard(
              icon: Icons.favorite_outline,
              text: 'What helped me',
            ),
            buildCard(
              icon: Icons.health_and_safety,
              text: 'Emergency plan',
            ),
            buildCard(
              icon: Icons.calendar_today_outlined,
              text: 'How long do I manage',
            ),
            buildCard(
              icon: Icons.self_improvement_outlined,
              text: 'Breathing exercises',
            ),
          ],
        ),
      ),
    );
  }

  Widget buildCard({required IconData icon, required String text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Card(
        color: Color(0xFFD1C4E9),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          leading: Icon(icon, color: Colors.black),
          title: Text(
            text,
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          trailing: const Icon(Icons.arrow_forward, color: Colors.black),
          onTap: () {
            // Show SVG image in a dialog
            showDialog(
              context: context,
              builder: (context) => Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SvgPicture.asset(
                    'lib/assets/In progress-amico.svg',
                    height: 200,
                    width: 200,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}