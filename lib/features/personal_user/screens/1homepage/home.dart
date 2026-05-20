import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:mindsarthi/core/theme/app_theme.dart';
import 'package:mindsarthi/core/theme/app_toast.dart';
import 'package:shimmer/shimmer.dart';
import 'package:mindsarthi/features/personal_user/screens/1homepage/MoodInputs/screens/mood_tracker_home_page.dart';
import 'package:mindsarthi/features/personal_user/screens/1homepage/panic_sos/sos_helper.dart';
import 'package:mindsarthi/features/personal_user/screens/1homepage/sidebar.dart';
import 'package:toastification/toastification.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  String? savedPreference;
  String? savedContactOrState;
  bool _isDrawerOpen = false;

  late AnimationController _heroBreathController;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      setState(() => _isScrolled = _scrollController.offset > 0);
    });

    _heroBreathController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _loadUserPreference();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _heroBreathController.dispose();
    super.dispose();
  }

  String _getTimeGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning,';
    if (hour < 17) return 'Good Afternoon,';
    return 'Good Evening,';
  }

  Future<void> _loadUserPreference() async {
    String? preference = await _storage.read(key: 'sos_preference');
    String? contactOrState = await _storage.read(key: 'sos_value');

    if (preference == null || contactOrState == null) {
      // Delay to avoid showing dialog immediately during hero animation load
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) _showChoiceDialog();
      });
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
    }, SetOptions(merge: true));

    setState(() {
      savedPreference = preference;
      savedContactOrState = value;
    });

    if (mounted) {
      AppToast.success(context, 'SOS contact saved successfully');
    }
  }

  Future<String?> _fetchNickname() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (doc.exists) {
      return doc.data()?['nickname'] as String?;
    }
    return null;
  }

  Future<void> _makePhoneCall(String number) async {
    final Uri phoneUri = Uri(scheme: "tel", path: number);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }
  }

  Future<Position?> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }
      if (permission == LocationPermission.deniedForever) return null;

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 4),
        ),
      );
    } catch (e) {
      debugPrint('Error getting location: $e');
      return null;
    }
  }

  /// Sends a pre-composed distress SMS to [number] using the native SMS app.
  /// The user still has to tap Send — this provides consent.
  Future<void> _sendDistressSms(String number) async {
    String message =
        'I need help right now. Please contact me — sent via MindSarthi SOS.';

    final position = await _getCurrentLocation();
    if (position != null) {
      message =
          'I need help right now. My current location is: https://maps.google.com/?q=${position.latitude},${position.longitude} — sent via MindSarthi SOS.';
    }

    final Uri smsUri = Uri(
      scheme: 'sms',
      path: number,
      queryParameters: {'body': message},
    );
    if (await canLaunchUrl(smsUri)) {
      await launchUrl(smsUri);
    } else {
      if (mounted) {
        _showErrorToast('Could not open SMS app.');
      }
    }
  }

  Future<void> _callSavedNumber() async {
    HapticFeedback.heavyImpact();
    try {
      if (savedPreference == "helpline" && savedContactOrState != null) {
        String? helplineNumber = await HelplineService.getStateHelpline(
          savedContactOrState!,
        );
        if (helplineNumber != null && helplineNumber.isNotEmpty) {
          await _makePhoneCall(helplineNumber);
        } else {
          _showErrorToast(
            "We couldn't find a helpline for \"$savedContactOrState\".",
          );
        }
      } else if (savedPreference == "friend" && savedContactOrState != null) {
        await _makePhoneCall(savedContactOrState!);
      } else {
        _showChoiceDialog();
      }
    } catch (e) {
      _showErrorToast("Error: $e");
    }
  }

  /// Shows an action sheet with Call & SMS options (for friend contacts),
  /// or directly calls the helpline.
  void _showSosActionSheet() {
    HapticFeedback.heavyImpact();

    // If no contact set up yet, show setup dialog
    if (savedPreference == null || savedContactOrState == null) {
      _showChoiceDialog();
      return;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isFriend = savedPreference == 'friend';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkBorder : AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.emergency_share_rounded,
                color: AppColors.error,
                size: 36,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Panic Assist',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isFriend
                  ? 'How do you want to reach ${savedContactOrState!}?'
                  : 'Calling $savedContactOrState helpline now…',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 28),

            // ── Call button (always shown) ─────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.phone_rounded),
                label: Text(
                  isFriend ? 'Call Now' : 'Call Helpline',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  _callSavedNumber();
                },
              ),
            ),

            // ── SMS button (only for friend contacts) ─────────────────
            if (isFriend) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.message_rounded),
                  label: const Text(
                    'Send SOS Message',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: BorderSide(color: AppColors.error, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    _sendDistressSms(savedContactOrState!);
                  },
                ),
              ),
            ],

            const SizedBox(height: 12),

            // ── Change contact ─────────────────────────────────────────
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _showChoiceDialog();
              },
              child: Text(
                'Change SOS Contact',
                style: TextStyle(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showErrorToast(String message) {
    toastification.show(
      context: context,
      title: const Text("Something went wrong"),
      description: Text(message),
      type: ToastificationType.error,
      style: ToastificationStyle.flat,
      alignment: Alignment.bottomCenter,
      autoCloseDuration: const Duration(seconds: 3),
    );
  }

  // ── Modals & Dialogs ──────────────────────────────────────────

  void _showChoiceDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.emergency_share_rounded,
                  color: AppColors.error,
                  size: 44,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                "Set up your SOS Contact",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "Choose a reliable contact method we can alert instantly when you’re in distress.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.map_outlined),
                  label: const Text(
                    'Use State Helpline',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    _askForState();
                  },
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.contact_phone_rounded),
                  label: const Text(
                    'Use Friend/Family Contact',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary,
                    side: BorderSide(
                      color: isDark ? AppColors.darkBorder : AppColors.border,
                      width: 2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    _askForContact();
                  },
                ),
              ),
              SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
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
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AnimatedPadding(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(32),
              ),
            ),
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Select Your State",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 24),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: "State",
                    labelStyle: TextStyle(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: isDark ? AppColors.darkBorder : AppColors.border,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 2,
                      ),
                    ),
                  ),
                  dropdownColor: isDark
                      ? AppColors.darkSurface
                      : AppColors.surface,
                  style: TextStyle(
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary,
                  ),
                  isExpanded: true,
                  items: states
                      .map(
                        (state) =>
                            DropdownMenuItem(value: state, child: Text(state)),
                      )
                      .toList(),
                  onChanged: (value) => selectedState = value,
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          side: BorderSide(
                            color: isDark
                                ? AppColors.darkBorder
                                : AppColors.border,
                          ),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          "Cancel",
                          style: TextStyle(
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () async {
                          if (selectedState != null) {
                            await _saveUserPreference(
                              "helpline",
                              selectedState!,
                            );
                            if (context.mounted) Navigator.pop(context);
                          } else {
                            AppToast.error(context, "Please select a state");
                          }
                        },
                        child: const Text(
                          "Save",
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: MediaQuery.of(context).padding.bottom),
              ],
            ),
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
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AnimatedPadding(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(32),
              ),
            ),
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Emergency Contact",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 24),
                IntlPhoneField(
                  style: TextStyle(
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary,
                  ),
                  dropdownTextStyle: TextStyle(
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    labelStyle: TextStyle(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: isDark ? AppColors.darkBorder : AppColors.border,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 2,
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
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          side: BorderSide(
                            color: isDark
                                ? AppColors.darkBorder
                                : AppColors.border,
                          ),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          "Cancel",
                          style: TextStyle(
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () async {
                          if (phoneNumber != null &&
                              phoneNumber!.length >= 10) {
                            await _saveUserPreference("friend", phoneNumber!);
                            if (context.mounted) Navigator.pop(context);
                          } else {
                            AppToast.error(
                              context,
                              "Enter a valid phone number",
                            );
                          }
                        },
                        child: const Text(
                          "Save",
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: MediaQuery.of(context).padding.bottom),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Build Method ──────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      key: _scaffoldKey,
      onDrawerChanged: (isOpen) => setState(() => _isDrawerOpen = isOpen),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: const Sidebar(),
      body: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: <Widget>[
          // Header
          SliverSafeArea(
            bottom: false,
            sliver: SliverToBoxAdapter(
              child: _FadeSlideEntry(delay: 0, child: _buildHeader(isDark)),
            ),
          ),

          // Hero Animation
          SliverToBoxAdapter(
            child: _FadeSlideEntry(
              delay: 1,
              child: _buildAnimatedHeroCard(isDark),
            ),
          ),

          // Mood Tracker
          SliverToBoxAdapter(
            child: _FadeSlideEntry(
              delay: 2,
              child: const Padding(
                padding: EdgeInsets.only(top: 16),
                child: MoodTrackerHomePage(),
              ),
            ),
          ),

          // Relief Resources
          SliverToBoxAdapter(
            child: _FadeSlideEntry(
              delay: 3,
              child: Padding(
                padding: const EdgeInsets.only(top: 32, bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        "Relief Resources",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildReliefSection(screenWidth, isDark),
                  ],
                ),
              ),
            ),
          ),

          // Interactive Cards (Goals & Journal)
          SliverToBoxAdapter(
            child: _FadeSlideEntry(
              delay: 4,
              child: Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Column(
                  children: [
                    _InteractiveCard(
                      title: "Today's Goals",
                      subtitle:
                          "Set and track your daily goals to stay motivated.",
                      iconPath: 'assets/illustrations/Handholdingpen.svg',
                      route: '/todaysgoals',
                      isDark: isDark,
                    ),
                    _InteractiveCard(
                      title: "Journal",
                      subtitle:
                          "Your safe space for reflection, growth, and self-discovery.",
                      iconPath: 'assets/illustrations/Handholdingpen.svg',
                      route: '/journal',
                      isDark: isDark,
                    ),
                    const SizedBox(height: 120), // Padding for FAB
                  ],
                ),
              ),
            ),
          ),
        ],
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: GestureDetector(
        onLongPress: _showSosActionSheet,
        child: Padding(
          padding: const EdgeInsets.only(
            bottom: 90,
          ), // Lift above the custom navigation bar
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _showSosActionSheet,
                borderRadius: BorderRadius.circular(28),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: _isScrolled ? 16 : 24,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.emergency_share_rounded,
                        color: Colors.white,
                      ),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                        child: SizedBox(
                          width: _isScrolled ? 0 : null,
                          child: const Padding(
                            padding: EdgeInsets.only(left: 8.0),
                            child: Text(
                              'Panic Assist',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              if (_isDrawerOpen) {
                Navigator.pop(context);
              } else {
                _scaffoldKey.currentState?.openDrawer();
              }
            },
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface2 : AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.border,
                ),
                boxShadow: [
                  if (!isDark)
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                ],
              ),
              child: Icon(
                _isDrawerOpen ? Icons.close_rounded : Icons.menu_rounded,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: FutureBuilder<String?>(
              future: _fetchNickname(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Shimmer.fromColors(
                    baseColor: isDark
                        ? AppColors.darkShimmerBase
                        : AppColors.shimmerBase,
                    highlightColor: isDark
                        ? AppColors.darkShimmerHighlight
                        : AppColors.shimmerHighlight,
                    child: Container(
                      width: 160,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurface : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  );
                }

                final nickname = snapshot.data ?? 'Friend';
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getTimeGreeting(),
                      style: TextStyle(
                        fontSize: 15,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      nickname.isNotEmpty ? nickname : 'Friend',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedHeroCard(bool isDark) {
    return AnimatedBuilder(
      animation: _heroBreathController,
      builder: (context, child) {
        // Creates a subtle scale pulsing effect (breathe in, breathe out)
        final scale = 1.0 + (_heroBreathController.value * 0.02);
        return Transform.scale(
          scale: scale,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [AppColors.darkPrimaryLight, AppColors.darkSurface2]
                      : [AppColors.primaryLight, AppColors.surface],
                ),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: isDark
                      ? AppColors.darkPrimary.withValues(alpha: 0.2)
                      : AppColors.primary.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    bottom: -20,
                    child: SvgPicture.asset(
                      'assets/illustrations/Illustration.svg',
                      height: 190,
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildReliefSection(double screenWidth, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildPremiumReliefCard(
            Icons.water_drop_rounded,
            'Anxiety\n& Panic',
            '/anxietypanic',
            screenWidth,
            AppColors.primary,
            isDark,
          ),
          _buildPremiumReliefCard(
            Icons.nights_stay_rounded,
            'Depression\nSupport',
            '/depression',
            screenWidth,
            Colors.indigoAccent,
            isDark,
          ),
          _buildPremiumReliefCard(
            Icons.healing_rounded,
            'Self Harm\nIdeation',
            '/selfharm',
            screenWidth,
            Colors.teal,
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumReliefCard(
    IconData icon,
    String label,
    String routeName,
    double screenWidth,
    Color tintColor,
    bool isDark,
  ) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.pushNamed(context, routeName);
      },
      child: Container(
        width: (screenWidth - 72) / 3, // Matches old design width perfectly
        height: 130, // Increased height for center alignment
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.border,
            width: 1.5,
          ),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: tintColor.withValues(alpha: 0.08),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: tintColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 28, color: tintColor),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.textPrimary,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Custom Widgets ──────────────────────────────────────────────

class _InteractiveCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final String iconPath;
  final String route;
  final bool isDark;

  const _InteractiveCard({
    required this.title,
    required this.subtitle,
    required this.iconPath,
    required this.route,
    required this.isDark,
  });

  @override
  State<_InteractiveCard> createState() => _InteractiveCardState();
}

class _InteractiveCardState extends State<_InteractiveCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        HapticFeedback.selectionClick();
        Navigator.pushNamed(context, widget.route);
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutQuad,
        child: Container(
          padding: const EdgeInsets.all(24),
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          decoration: BoxDecoration(
            color: widget.isDark ? AppColors.darkSurface : AppColors.surface,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: widget.isDark ? AppColors.darkBorder : AppColors.border,
              width: 1.5,
            ),
            boxShadow: [
              if (!widget.isDark)
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.06),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: widget.isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: widget.isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: widget.isDark
                      ? AppColors.darkPrimaryLight
                      : AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: SvgPicture.asset(widget.iconPath, width: 36, height: 36),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FadeSlideEntry extends StatefulWidget {
  final Widget child;
  final int delay; // The multiplier for the staggered delay

  const _FadeSlideEntry({required this.child, required this.delay});

  @override
  State<_FadeSlideEntry> createState() => _FadeSlideEntryState();
}

class _FadeSlideEntryState extends State<_FadeSlideEntry> {
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: 150 + (widget.delay * 150)), () {
      if (mounted) setState(() => _isVisible = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 600),
      opacity: _isVisible ? 1.0 : 0.0,
      curve: Curves.easeOutCubic,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
        offset: _isVisible ? Offset.zero : const Offset(0, 0.2),
        child: widget.child,
      ),
    );
  }
}
