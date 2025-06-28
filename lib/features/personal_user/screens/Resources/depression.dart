import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class Depression extends StatefulWidget {
  const Depression({super.key});

  @override
  State<Depression> createState() => _DepressionState();
}

class _DepressionState extends State<Depression> {
  @override
  Widget build(BuildContext context) {
    return  Scaffold(
      appBar: AppBar(
        title: Text('Depression'),
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
            _buildCard(
              context,
              icon: Icons.volunteer_activism,
              text: 'What can help me',
            ),
            _buildCard(
              context,
              icon: Icons.calendar_today,
              text: 'Activity planner',
            ),
            _buildCard(
              context,
              icon: Icons.sentiment_satisfied,
              text: 'What made me happy',
            ),
            _buildCard(
              context,
              icon: Icons.emoji_events,
              text: 'My successes',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, {required IconData icon, required String text}) {
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
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
          trailing: Icon(Icons.arrow_forward, color: Colors.black),
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