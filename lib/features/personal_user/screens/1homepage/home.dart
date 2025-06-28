import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shimmer/shimmer.dart';
import 'package:mindsarthi/features/personal_user/screens/1homepage/MoodInputs/screens/mood_tracker_home_page.dart';
import 'package:mindsarthi/features/personal_user/screens/1homepage/dailygoals/data/database.dart';
import 'package:mindsarthi/features/personal_user/screens/1homepage/dailygoals/todaysGoals.dart';
import 'package:mindsarthi/features/personal_user/screens/1homepage/panic_sos/sos_helper.dart';
import 'package:mindsarthi/features/personal_user/screens/1homepage/sidebar.dart';
import 'package:url_launcher/url_launcher.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ToDoDataBase db = ToDoDataBase();
  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  String? savedPreference;
  String? savedContactOrState;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      setState(() => _isScrolled = _scrollController.offset > 0);
    });
    _loadUserPreference();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadUserPreference() async {
    String? preference = await _storage.read(key: 'sos_preference');
    String? contactOrState = await _storage.read(key: 'sos_value');

    if (preference == null || contactOrState == null) {
      _showChoiceDialog();
    } else {
      setState(() {
        savedPreference = preference;
        savedContactOrState = contactOrState;
      });
    }
  }

  Future<void> _saveUserPreference(String preference, String value) async {
    await _storage.write(key: 'sos_preference', value: preference);
    await _storage.write(key: 'sos_value', value: value);
    await _firestore.collection('users').doc('user_sos_data').set({
      'preference': preference,
      'value': value,
    });
    setState(() {
      savedPreference = preference;
      savedContactOrState = value;
    });
  }

  void _showChoiceDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Select SOS Contact"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text("State Helpline"),
                onTap: () {
                  Navigator.pop(context);
                  _askForState();
                },
              ),
              ListTile(
                title: Text("Friend/Family"),
                onTap: () {
                  Navigator.pop(context);
                  _askForContact();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _askForState() {
    TextEditingController stateController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Enter Your State"),
          content: TextField(
            controller: stateController,
            decoration: InputDecoration(hintText: "e.g., Maharashtra"),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                String state = stateController.text.trim();
                if (state.isNotEmpty) {
                  await _saveUserPreference("helpline", state);
                }
                Navigator.pop(context);
              },
              child: Text("Save"),
            ),
          ],
        );
      },
    );
  }

  void _askForContact() {
    TextEditingController contactController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Enter Contact Number"),
          content: TextField(
            controller: contactController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(hintText: "e.g., +91XXXXXXXXXX"),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                String contact = contactController.text.trim();
                if (contact.isNotEmpty) {
                  await _saveUserPreference("friend", contact);
                }
                Navigator.pop(context);
              },
              child: Text("Save"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _callSavedNumber() async {
    if (savedPreference == "helpline" && savedContactOrState != null) {
      String? helplineNumber = await HelplineService.getStateHelpline(
        savedContactOrState!,
      );
      helplineNumber ??= "1800-599-0019";
      _makePhoneCall(helplineNumber);
    } else if (savedPreference == "friend" && savedContactOrState != null) {
      _makePhoneCall(savedContactOrState!);
    } else {
      _showChoiceDialog();
    }
  }

  Future<void> _makePhoneCall(String number) async {
    final Uri phoneUri = Uri(scheme: "tel", path: number);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }
  }

  Future<String?> _fetchNickname() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final doc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
    if (doc.exists) {
      return doc.data()?['nickname'] as String?;
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> _fetchGoals() async {
    await db.loadData();
    return db.toDoList;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      key: _scaffoldKey,
      drawer: Sidebar(),
      body: CustomScrollView(
        controller: _scrollController,
        slivers: <Widget>[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: SvgPicture.asset(
                          'assets/icons/menu.svg',
                          height: 24.0,
                          width: 24.0,
                        ),
                        onPressed:
                            () => _scaffoldKey.currentState?.openDrawer(),
                      ),
                      const SizedBox(width: 10),
                      FutureBuilder<String?>(
                        future: _fetchNickname(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Shimmer.fromColors(
                              baseColor: Colors.grey[300]!,
                              highlightColor: Colors.grey[100]!,
                              child: Container(
                                width: 140,
                                height: 24,
                                color: Colors.white,
                              ),
                            );
                          }

                          final nickname = snapshot.data ?? '';
                          return Row(
                            children: [
                              const Text(
                                'Namaste',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                nickname,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                  Center(
                    child: SvgPicture.asset(
                      'assets/illustrations/Illustration.svg',
                      width: screenWidth * 0.6,
                      height: screenWidth * 0.62,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(child: MoodTrackerHomePage()),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
          _buildSectionTitle("Relief Resources"),
          _buildReliefSection(screenWidth),
          _buildGoalsSection(),
          _buildJournalSection(),
        ],
      ),
      floatingActionButton: GestureDetector(
        onLongPress: _showChoiceDialog,
        child: FloatingActionButton.extended(
          onPressed: _callSavedNumber,
          label: Text(_isScrolled ? '' : 'Panic Assist'),
          icon: SvgPicture.asset(
            'assets/icons/sos.svg',
            width: 24.0,
            height: 24.0,
          ),
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildSectionTitle(String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildReliefSection(double screenWidth) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSupportContainer(
              'assets/icons/Anxiety.png',
              'Anxiety and Panic Attacks',
              '/anxietypanic',
              screenWidth,
            ),
            _buildSupportContainer(
              'assets/icons/depression.png',
              'Depression',
              '/depression',
              screenWidth,
            ),
            _buildSupportContainer(
              'assets/icons/Suicidal.png',
              'Self Harm and Suicidal Ideation',
              '/selfharm',
              screenWidth,
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
    double screenWidth,
  ) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, routeName),
      child: Container(
        width: (screenWidth - 60) / 3,
        height: 170,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black.withOpacity(0.1)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(imagePath, width: 80, height: 80, color: Colors.black),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, color: Colors.black),
            ),
          ],
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildGoalsSection() {
    return SliverToBoxAdapter(
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchGoals(),
        builder: (context, snapshot) {
          final goals = snapshot.data ?? [];
          final hasGoals = goals.isNotEmpty;

          return GestureDetector(
            onTap:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TodaysGoals()),
                ),
            child: Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Today's Goals",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  if (!hasGoals)
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: Center(
                        child: Text(
                          "Add a new Goal",
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    SizedBox(
                      height: 100, // Restrict height to show a few items
                      child: ListView.builder(
                        itemCount: goals.length.clamp(
                          0,
                          3,
                        ), // Show up to 3 items
                        itemBuilder: (context, index) {
                          return ListTile(
                            title: Text(goals[index]['taskName']),
                            trailing: Checkbox(
                              value: goals[index]['completed'],
                              onChanged: (value) {
                                setState(
                                  () => db.updateTask(index, value ?? false),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  if (hasGoals)
                    Align(
                      alignment: Alignment.bottomRight,
                      child: TextButton(
                        onPressed:
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const TodaysGoals(),
                              ),
                            ),
                        child: const Text(
                          "View More",
                          style: TextStyle(
                            fontSize: 16,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  SliverToBoxAdapter _buildJournalSection() {
    return SliverToBoxAdapter(
      child: GestureDetector(
        onTap: () => Navigator.pushNamed(context, '/journal'),
        child: Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10),
            ],
            color: Colors.white,
          ),
          child: Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Journal',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Your safe space for reflection, growth, and self-discovery.',
                      style: TextStyle(fontSize: 14, color: Colors.black),
                    ),
                  ],
                ),
              ),
              SvgPicture.asset(
                'assets/illustrations/Handholdingpen.svg',
                width: 120,
                height: 120,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
