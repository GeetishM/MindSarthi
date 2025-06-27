import 'package:flutter/material.dart';
import 'package:mindsarthi/features/personal_user/screens/3insightpage/insight_card.dart';
import 'package:mindsarthi/features/personal_user/screens/3insightpage/insight_data.dart';
import 'package:mindsarthi/features/personal_user/screens/3insightpage/insight_details_page.dart';

 // Import the data file

class InsightPage extends StatelessWidget {
  const InsightPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Insights"),
        automaticallyImplyLeading: false, // This line removes the back button
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                tagChip('ALL'),
                tagChip('For You'),
                tagChip('Adult ADHD'),
                tagChip('Insomnia'),
                tagChip('Panic Attacks'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: insightsList.length, // Use the length of insightsList
              itemBuilder: (context, index) {
                // Get the current insight
                final insight = insightsList[index];

                return InsightCard(
                  heading: insight.heading,
                  content: insight.content,
                  author: insight.author,
                  date: insight.date,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => InsightDetailPage(
                          heading: insight.heading,
                          content: insight.content,
                          author: insight.author,
                          date: insight.date,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget tagChip(String label) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Chip(
        label: Center(child: Text(label)),
        backgroundColor: Color(0xFFD1C4E9),
      ),
    );
  }
}
