import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:mindsarthi/features/personal_user/screens/1homepage/dailygoals/database.dart';
import 'package:mindsarthi/features/personal_user/screens/1homepage/dailygoals/home.dart';
import 'package:shimmer/shimmer.dart';
import 'package:mindsarthi/features/personal_user/screens/1homepage/MoodInputs/screens/mood_tracker_home_page.dart';
import 'package:mindsarthi/features/personal_user/screens/1homepage/panic_sos/sos_helper.dart';
import 'package:mindsarthi/features/personal_user/screens/1homepage/sidebar.dart';
import 'package:toastification/toastification.dart';
import 'package:url_launcher/url_launcher.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
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
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await _storage.write(key: 'sos_preference', value: preference);
    await _storage.write(key: 'sos_value', value: value);

    await _firestore.collection('users').doc(user.uid).set({
      'sos_preference': preference,
      'sos_value': value,
    }, SetOptions(merge: true)); // merge keeps other existing fields intact

    setState(() {
      savedPreference = preference;
      savedContactOrState = value;
    });

    toastification.show(
      context: context,
      title: const Text("SOS contact saved successfully"),
      autoCloseDuration: const Duration(seconds: 2),
      type: ToastificationType.success,
      style: ToastificationStyle.flat,
      alignment: Alignment.bottomCenter,
      icon: const Icon(Icons.check_circle),
    );
  }

  void _showChoiceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Colors.white,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.deepPurpleAccent[200],
                size: 48,
              ),
              const SizedBox(height: 12),
              Text(
                "Set up your SOS Contact",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Choose a reliable contact method we can alert when you’re in distress.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.map_outlined),
                label: const Text("Use State Helpline"),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.deepPurpleAccent[200],
                  minimumSize: const Size.fromHeight(48),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  _askForState();
                },
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                icon: const Icon(Icons.contact_phone),
                label: const Text("Use Friend/Family Contact"),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.deepPurpleAccent[200],
                  side: BorderSide(color: Colors.deepPurpleAccent[200]!),
                  minimumSize: const Size.fromHeight(48),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  _askForContact();
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _askForState() {
    final List<String> states = [
      "Andhra Pradesh",
      "Arunachal Pradesh",
      "Assam",
      "Bihar",
      "Chhattisgarh",
      "Goa",
      "Gujarat",
      "Haryana",
      "Himachal Pradesh",
      "Jharkhand",
      "Karnataka",
      "Kerala",
      "Madhya Pradesh",
      "Maharashtra",
      "Manipur",
      "Meghalaya",
      "Mizoram",
      "Nagaland",
      "Odisha",
      "Punjab",
      "Rajasthan",
      "Sikkim",
      "Tamil Nadu",
      "Telangana",
      "Tripura",
      "Uttar Pradesh",
      "Uttarakhand",
      "West Bengal",
    ];

    String? selectedState;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      elevation: 12,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return AnimatedPadding(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 24,
            left: 24,
            right: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Select Your State",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurpleAccent[200],
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: "State",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.deepPurpleAccent[200]!,
                    ),
                  ),
                ),
                isExpanded: true,
                items:
                    states.map((state) {
                      return DropdownMenuItem(value: state, child: Text(state));
                    }).toList(),
                onChanged: (value) => selectedState = value,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: Colors.grey[200],
                        foregroundColor: Colors.black87,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      label: const Text("Cancel"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurpleAccent[200],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () async {
                        if (selectedState != null) {
                          await _saveUserPreference("helpline", selectedState!);
                          Navigator.pop(context);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Please select a state"),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.save_rounded),
                      label: const Text("Save"),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _askForContact() {
    String? phoneNumber;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      elevation: 12,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return AnimatedPadding(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 24,
            left: 24,
            right: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Enter Emergency Contact",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurpleAccent[200],
                ),
              ),
              const SizedBox(height: 16),
              IntlPhoneField(
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.deepPurpleAccent[200]!,
                    ),
                  ),
                ),
                initialCountryCode: 'IN',
                onChanged: (phone) => phoneNumber = phone.completeNumber,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: Colors.grey[200],
                        foregroundColor: Colors.black87,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      label: const Text("Cancel"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurpleAccent[200],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () async {
                        if (phoneNumber != null && phoneNumber!.length >= 10) {
                          await _saveUserPreference("friend", phoneNumber!);
                          Navigator.pop(context);
                        } else {
                          toastification.show(
                            context: context,
                            title: const Text("Enter a valid phone number"),
                            autoCloseDuration: const Duration(seconds: 2),
                            type: ToastificationType.error,
                            style: ToastificationStyle.flat,
                            alignment: Alignment.bottomCenter,
                            icon: const Icon(Icons.error),
                          );
                        }
                      },
                      icon: const Icon(Icons.save_alt_rounded),
                      label: const Text("Save"),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Future<void> _callSavedNumber() async {
    try {
      if (savedPreference == "helpline" && savedContactOrState != null) {
        String? helplineNumber = await HelplineService.getStateHelpline(
          savedContactOrState!,
        );

        if (helplineNumber != null && helplineNumber.isNotEmpty) {
          await _makePhoneCall(helplineNumber);
        } else {
          toastification.show(
            context: context,
            title: const Text("Helpline not found"),
            description: Text(
              "We couldn't find a helpline for \"$savedContactOrState\".",
            ),
            type: ToastificationType.error,
            style: ToastificationStyle.flat,
            alignment: Alignment.bottomCenter,
            autoCloseDuration: const Duration(seconds: 3),
          );
        }
      } else if (savedPreference == "friend" && savedContactOrState != null) {
        await _makePhoneCall(savedContactOrState!);
      } else {
        _showChoiceDialog();
      }
    } catch (e) {
      toastification.show(
        context: context,
        title: const Text("Something went wrong"),
        description: Text("Error: $e"),
        type: ToastificationType.error,
        style: ToastificationStyle.flat,
        alignment: Alignment.bottomCenter,
        autoCloseDuration: const Duration(seconds: 3),
      );
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
          _buildSimpleGoalsSection(),
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

  SliverToBoxAdapter _buildSimpleGoalsSection() {
    return SliverToBoxAdapter(
      child: GestureDetector(
        onTap:
            () =>
                Navigator.pushNamed(context, '/todaysgoals'), // Use your route
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
                      'Today\'s Goals',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Set and track your daily goals to stay motivated and productive.',
                      style: TextStyle(fontSize: 14, color: Colors.black),
                    ),
                  ],
                ),
              ),
              SvgPicture.asset(
                'assets/illustrations/Handholdingpen.svg',
                width: 100,
                height: 100,
              ),
            ],
          ),
        ),
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
