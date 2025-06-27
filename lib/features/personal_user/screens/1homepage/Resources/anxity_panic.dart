import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class Anxity extends StatefulWidget {
  const Anxity({super.key});

  @override
  State<Anxity> createState() => _AnxityState();
}

class _AnxityState extends State<Anxity> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Anxiety and panic attacks'),
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
              icon: Icons.sos_outlined,
              text: 'Panic attack tips',
            ),
            buildCard(
              icon: Icons.self_improvement_outlined,
              text: 'Breathing exercises',
            ),
            buildCard(
              icon: Icons.calculate_outlined,
              text: 'Arithmetic',
            ),
            buildCard(
              icon: Icons.sports_basketball_outlined,
              text: 'Balls game',
            ),
            buildCard(
              icon: Icons.balance_outlined,
              text: 'Seesaw game',
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