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
      backgroundColor: Colors.white, // Flat white background
      appBar: AppBar(
        title: const Text('Insights'),
        backgroundColor: Colors.deepPurpleAccent[200],
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          // fontWeight: FontWeight.bold,
          fontSize: 24,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Card(
              color: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: Colors.deepPurpleAccent[100]!,
                  width: 1.5,
                ),
              ),
              margin: const EdgeInsets.symmetric(vertical: 10),
              child: ListTile(
                leading: Icon(Icons.today, size: 32, color: Colors.deepPurpleAccent[200]),
                title: const Text('Daily task count', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Mood / Activity'),
                trailing: Text(
                  '$dailyTaskCount',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
              ),
            ),
            Card(
              color: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: Colors.deepPurpleAccent[100]!,
                  width: 1.5,
                ),
              ),
              margin: const EdgeInsets.symmetric(vertical: 10),
              child: ListTile(
                leading: Icon(Icons.check_circle, size: 32, color: Colors.deepPurpleAccent[200]),
                title: const Text('% completed', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Motivation / Productivity'),
                trailing: Text(
                  '${(percentCompleted * 100).toStringAsFixed(1)}%',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
              ),
            ),
            Card(
              color: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: Colors.deepPurpleAccent[100]!,
                  width: 1.5,
                ),
              ),
              margin: const EdgeInsets.symmetric(vertical: 10),
              child: ListTile(
                leading: Icon(Icons.schedule, size: 32, color: Colors.deepPurpleAccent[200]),
                title: const Text('Reschedules', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Procrastination'),
                trailing: Text(
                  '$reschedules',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
              ),
            ),
            Card(
              color: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: Colors.deepPurpleAccent[100]!,
                  width: 1.5,
                ),
              ),
              margin: const EdgeInsets.symmetric(vertical: 10),
              child: ListTile(
                leading: Icon(Icons.self_improvement, size: 32, color: Colors.deepPurpleAccent[200]),
                title: const Text('Self-care task count', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Personal Attention'),
                trailing: Text(
                  '$selfCareCount',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}