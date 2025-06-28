import 'package:flutter/material.dart';

class InsightsScreen extends StatelessWidget {
  final int dailyTaskCount;
  final double percentCompleted;
  final int reschedules;
  final int selfCareCount;

  const InsightsScreen({
    Key? key,
    required this.dailyTaskCount,
    required this.percentCompleted,
    required this.reschedules,
    required this.selfCareCount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Insights'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color.fromARGB(255, 252, 149, 195), 
                const Color.fromARGB(255, 248, 164, 116), 
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromARGB(255, 244, 197, 213), // Main color
              Color.fromARGB(255, 255, 240, 245), // Lighter, soft pink
              Color.fromARGB(255, 222, 160, 200), // Gentle purple-pink
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            children: [
                Card(
                color: const Color.fromARGB(255, 148, 228, 248), // Change this to your desired color
                margin: const EdgeInsets.symmetric(vertical: 10),
                child: ListTile(
                  leading: Icon(Icons.today, size: 32),
                  title: const Text('Daily task count'),
                  subtitle: const Text('Mood / Activity'),
                  trailing: Text(
                  '$dailyTaskCount',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                ),
              
                Card(
                color: const Color.fromARGB(255, 162, 245, 225), // Different color from the first card
                margin: const EdgeInsets.symmetric(vertical: 10),
                child: ListTile(
                  leading: Icon(Icons.check_circle, size: 32),
                  title: const Text('% completed'),
                  subtitle: const Text('Motivation / Productivity'),
                  trailing: Text(
                  '${(percentCompleted * 100).toStringAsFixed(1)}%',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                ),
            ],
/*            
              _buildInsight(
                'Reschedules',
                '$reschedules',
                'Procrastination',
                Icons.schedule,
              ),
              _buildInsight(
                'Self-care task count',
                '$selfCareCount',
                'Personal Attention',
                Icons.self_improvement,
              ),
*/            
          ),
        ),
      ),
    );
  }
/*
  Widget _buildInsight(String title, String value, String subtitle, IconData icon) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: ListTile(
        leading: Icon(icon, size: 32),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
*/

}