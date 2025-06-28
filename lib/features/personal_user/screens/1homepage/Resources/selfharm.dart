import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:lottie/lottie.dart';
import 'package:mindsarthi/features/personal_user/screens/1homepage/Resources/spotify_screen.dart';

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
              icon: Icons.self_improvement_outlined,
              text: 'Breathing exercises',
              onTap: () => showDialog(
                context: context,
                builder: (context) => Dialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Lottie.asset(
                          'assets/lottie/Breathing.json',
                          height: 250,
                          width: 250,
                          repeat: true,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Breathe in... Breathe out...',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            buildCard(
              icon: Icons.music_note_rounded,
              text: 'Music for relaxation',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (_) => const SpotifyPlayerScreen(
                          playlistId:
                              '3n9e5pXW7kb3SDgvaxgvnL', // Replace with yours
                        ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget buildCard({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Card(
        color: const Color(0xFFD1C4E9),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
          onTap: onTap,
        ),
      ),
    );
  }
}
