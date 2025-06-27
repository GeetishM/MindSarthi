import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class ConsultPage extends StatelessWidget {
  const ConsultPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Consult an Expert",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        automaticallyImplyLeading: false, // This line removes the back button
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your Sessions',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 150,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: const [
                      SessionCard(
                        name: 'Sandeep Maheshwari',
                        status: 'Upcoming',
                        dateTime: '16-07-24, 05:30 PM',
                      ),
                      SizedBox(width: 16),
                      SessionCard(
                        name: 'Another Session',
                        status: 'Completed',
                        dateTime: '25-06-24, 04:00 PM',
                      ),
                      // Add more SessionCard widgets here if needed
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Book a Session',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                FilterButton(),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              children: const [
                TherapistCard(
                  name: 'Dr. John Doe',
                  experience: '10 years',
                  startingPrice: 'Starts at 50 Rs/hr',
                  expertiseTags: [
                    'OCD',
                    'Sleep Disorders',
                    'Stress Management'
                  ],
                ),
                TherapistCard(
                  name: 'Dr. Jane Smith',
                  experience: '8 years',
                  startingPrice: 'Starts at 70 Rs/hr',
                  expertiseTags: ['Anxiety', 'Depression', 'Child Counseling'],
                ),
                // Add more TherapistCard widgets here if needed
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class FilterButton extends StatelessWidget {
  const FilterButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(4.0),
      ),
      child: PopupMenuButton<String>(
        icon: const Row(
          children: [
            Text('Filter'),
            Icon(Icons.arrow_drop_down_outlined),
          ],
        ),
        onSelected: (String value) {
          // Handle the filter logic here
        },
        itemBuilder: (BuildContext context) {
          return {'Filter 1', 'Filter 2', 'Filter 3'}.map((String choice) {
            return PopupMenuItem<String>(
              value: choice,
              child: Text(choice),
            );
          }).toList();
        },
      ),
    );
  }
}

class TherapistCard extends StatelessWidget {
  final String name;
  final String experience;
  final String startingPrice;
  final List<String> expertiseTags;

  const TherapistCard({
    super.key,
    required this.name,
    required this.experience,
    required this.startingPrice,
    required this.expertiseTags,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 80,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('Experience: $experience'),
                  const SizedBox(height: 4),
                  Text(
                    'Starting at: $startingPrice',
                    maxLines: 2, // Limit the text to 2 lines if you want
                    overflow:
                        TextOverflow.ellipsis, // Show "..." if it overflows
                    softWrap: true, // Allow the text to wrap to the next line),
                  )
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text(
                'Expertise:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: expertiseTags.map((tag) {
                      return Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                            vertical: 4, horizontal: 8),
                        decoration: BoxDecoration(
                          color: Color(0xFFD1C4E9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(tag),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
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
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              backgroundColor: Colors.deepPurple[500],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
            child: const Text(
              'Book a Session',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SessionCard extends StatelessWidget {
  final String name;
  final String status;
  final String dateTime;

  const SessionCard({
    super.key,
    required this.name,
    required this.status,
    required this.dateTime,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: Container(
        color: Colors.white,
        width: 300,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 80,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(width: 16),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        status,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.teal,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        dateTime,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black54,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
