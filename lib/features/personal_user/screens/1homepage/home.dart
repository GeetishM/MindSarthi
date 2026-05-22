import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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
  final GlobalKey? menuKey;
  const HomePage({super.key, this.menuKey});

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

  String _formatTimeLabel(DateTime dt) {
    final now = DateTime.now();
    final difference = now.difference(dt);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else {
      return '${dt.day}/${dt.month}';
    }
  }

  void _showNotificationsBottomSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.darkSurface2 : AppColors.white;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final borderCol = isDark ? AppColors.darkBorder : AppColors.border;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return ValueListenableBuilder(
          valueListenable: Hive.box('notificationsBox').listenable(),
          builder: (context, Box box, _) {
            final list = box.values.toList().reversed.toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                border: Border.all(color: borderCol, width: 0.8),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  // Drag Handle
                  Container(
                    width: 36,
                    height: 5,
                    decoration: BoxDecoration(
                      color: borderCol,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Notifications',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: textPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
                        if (list.isNotEmpty)
                          TextButton(
                            onPressed: () async {
                              for (var key in box.keys) {
                                final item = Map<String, dynamic>.from(box.get(key));
                                item['isRead'] = true;
                                await box.put(key, item);
                              }
                            },
                            child: const Text(
                              'Mark all as read',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Divider(color: borderCol, height: 1),
                  
                  // List
                  Expanded(
                    child: list.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  CupertinoIcons.bell_slash,
                                  size: 64,
                                  color: textSecondary.withOpacity(0.3),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'All caught up!',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: textPrimary,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'You have no new notifications.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(24),
                            itemCount: list.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final item = Map<String, dynamic>.from(list[index] as Map);
                              final bool isRead = item['isRead'] ?? false;
                              final String id = item['id'] ?? '';
                              final String title = item['title'] ?? '';
                              final String body = item['body'] ?? '';
                              final String timestampStr = item['timestamp'] ?? '';
                              
                              String timeLabel = '';
                              if (timestampStr.isNotEmpty) {
                                try {
                                  final dt = DateTime.parse(timestampStr);
                                  timeLabel = _formatTimeLabel(dt);
                                } catch (_) {}
                              }

                              return Dismissible(
                                key: Key(id),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 20),
                                  decoration: BoxDecoration(
                                    color: AppColors.error,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Icon(
                                    CupertinoIcons.trash,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                onDismissed: (direction) async {
                                  await box.delete(id);
                                  AppToast.success(context, 'Notification dismissed');
                                },
                                child: GestureDetector(
                                  onTap: () async {
                                    if (!isRead) {
                                      item['isRead'] = true;
                                      await box.put(id, item);
                                    }
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 150),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: isRead 
                                          ? (isDark ? AppColors.darkBackground : Colors.grey.shade50)
                                          : (isDark ? AppColors.darkSurface : Colors.teal.shade50.withOpacity(0.3)),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: isRead 
                                            ? borderCol 
                                            : AppColors.primary.withOpacity(0.3),
                                        width: isRead ? 0.8 : 1.2,
                                      ),
                                    ),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        if (!isRead)
                                          Container(
                                            margin: const EdgeInsets.only(top: 4, right: 8),
                                            width: 8,
                                            height: 8,
                                            decoration: const BoxDecoration(
                                              color: AppColors.primary,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      title,
                                                      style: TextStyle(
                                                        fontWeight: isRead ? FontWeight.w600 : FontWeight.w800,
                                                        fontSize: 14,
                                                        color: textPrimary,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    timeLabel,
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color: textSecondary.withOpacity(0.7),
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                body,
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: isRead ? textSecondary : textPrimary.withOpacity(0.9),
                                                  height: 1.3,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  
                  if (list.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.fromLTRB(24, 8, 24, MediaQuery.of(context).padding.bottom + 16),
                      child: SizedBox(
                        width: double.infinity,
                        child: TextButton.icon(
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.error,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: BorderSide(color: AppColors.error.withOpacity(0.2)),
                            ),
                          ),
                          onPressed: () async {
                            await box.clear();
                            AppToast.success(context, 'All notifications cleared');
                          },
                          icon: const Icon(CupertinoIcons.trash, size: 16),
                          label: const Text(
                            'Clear All',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _loadUserPreference() async {
    String? preference = await _storage.read(key: 'sos_preference');
    String? contactOrState = await _storage.read(key: 'sos_value');

    if (preference == null || contactOrState == null) {
      final myBox = Hive.box('mybox');
      final hasShownShowcase = myBox.get('showcase_nav', defaultValue: false);

      if (!hasShownShowcase) {
        final listenable = myBox.listenable(keys: ['showcase_nav']);
        late void Function() listener;
        listener = () {
          final completed = myBox.get('showcase_nav', defaultValue: false);
          if (completed) {
            listenable.removeListener(listener);
            Future.delayed(const Duration(milliseconds: 1000), () {
              if (mounted) _showChoiceDialog();
            });
          }
        };
        listenable.addListener(listener);
      } else {
        // Delay to avoid showing dialog immediately during hero animation load
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) _showChoiceDialog();
        });
      }
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
          padding: const EdgeInsets.fromLTRB(32, 12, 32, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag Handle
              Container(
                width: 36,
                height: 5,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBorder : AppColors.border,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 20),
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
            padding: const EdgeInsets.fromLTRB(32, 12, 32, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 5,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkBorder : AppColors.border,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
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
            padding: const EdgeInsets.fromLTRB(32, 12, 32, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 5,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkBorder : AppColors.border,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
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
                padding: const EdgeInsets.only(top: 20, bottom: 12),
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
                padding: const EdgeInsets.only(top: 8),
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
                    const SizedBox(height: 75), // Optimized padding for FAB
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
              gradient: const LinearGradient(
                colors: [AppColors.accent, Color(0xFFFF5E3A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.4),
                  blurRadius: 20,
                  spreadRadius: 1,
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
      child: FutureBuilder<String?>(
        future: _fetchNickname(),
        builder: (context, snapshot) {
          final nickname = snapshot.data ?? 'Friend';
          final firstLetter = nickname.isNotEmpty ? nickname[0].toUpperCase() : 'F';
          final hasData = snapshot.connectionState != ConnectionState.waiting;

          return Row(
            children: [
              widget.menuKey != null
                  ? Showcase(
                      key: widget.menuKey!,
                      title: 'Settings & Profile',
                      description: 'Tap here to open the menu where you can access your profile, configure App Lock, change theme, and sign out.',
                      targetShapeBorder: const CircleBorder(),
                      tooltipBackgroundColor: AppColors.primary,
                      tooltipBorderRadius: BorderRadius.circular(16),
                      tooltipPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      showArrow: true,
                      titleTextStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      descTextStyle: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                      ),
                      child: GestureDetector(
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
                              width: 1.5,
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
                    )
                  : GestureDetector(
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
                            width: 1.5,
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
                child: hasData
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getTimeGreeting(),
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            nickname.isNotEmpty ? nickname : 'Friend',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.textPrimary,
                              letterSpacing: -0.8,
                            ),
                          ),
                        ],
                      )
                    : Shimmer.fromColors(
                        baseColor: isDark
                            ? AppColors.darkShimmerBase
                            : AppColors.shimmerBase,
                        highlightColor: isDark
                            ? AppColors.darkShimmerHighlight
                            : AppColors.shimmerHighlight,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 100,
                              height: 14,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              width: 150,
                              height: 26,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
              const SizedBox(width: 16),
              hasData
                  ? ValueListenableBuilder(
                      valueListenable: Hive.box('notificationsBox').listenable(),
                      builder: (context, Box box, _) {
                        final int unreadCount = box.values
                            .where((item) => (item as Map)['isRead'] == false)
                            .length;

                        return GestureDetector(
                          onTap: () => _showNotificationsBottomSheet(),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isDark ? AppColors.darkSurface2 : AppColors.surface,
                                  border: Border.all(
                                    color: isDark ? AppColors.darkBorder : AppColors.border,
                                    width: 1.5,
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
                                alignment: Alignment.center,
                                child: Icon(
                                  CupertinoIcons.bell,
                                  size: 22,
                                  color: isDark
                                      ? AppColors.darkTextPrimary
                                      : AppColors.textPrimary,
                                ),
                              ),
                              if (unreadCount > 0)
                                Positioned(
                                  right: -2,
                                  top: -2,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: AppColors.error,
                                      shape: BoxShape.circle,
                                    ),
                                    constraints: const BoxConstraints(
                                      minWidth: 18,
                                      minHeight: 18,
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      '$unreadCount',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    )
                  : Shimmer.fromColors(
                      baseColor: isDark
                          ? AppColors.darkShimmerBase
                          : AppColors.shimmerBase,
                      highlightColor: isDark
                          ? AppColors.darkShimmerHighlight
                          : AppColors.shimmerHighlight,
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
            ],
          );
        },
      ),
    );
  }

  void _showBreathingDialog(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (context) => _BreathingGuideDialog(isDark: isDark),
    );
  }

  Widget _buildAnimatedHeroCard(bool isDark) {
    return AnimatedBuilder(
      animation: _heroBreathController,
      builder: (context, child) {
        // Creates a subtle scale pulsing effect (breathe in, breathe out)
        final scale = 1.0 + (_heroBreathController.value * 0.015);
        return Transform.scale(
          scale: scale,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.mediumImpact();
                _showBreathingDialog(context, isDark);
              },
              child: Container(
                width: double.infinity,
                height: 180,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [AppColors.darkPrimaryLight, AppColors.darkSurface2]
                        : [const Color(0xFFE5F5F3), Colors.white],
                  ),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: isDark
                        ? AppColors.darkPrimary.withValues(alpha: 0.25)
                        : AppColors.primary.withValues(alpha: 0.25),
                    width: 1.5,
                  ),
                  boxShadow: [
                    if (!isDark)
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.06),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -30,
                        top: -30,
                        child: Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: (isDark ? AppColors.darkPrimary : AppColors.primary)
                                .withValues(alpha: 0.05),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 20, 20, 20),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? AppColors.darkPrimary.withValues(alpha: 0.15)
                                          : AppColors.primary.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.spa_rounded,
                                          size: 14,
                                          color: isDark
                                              ? AppColors.darkPrimary
                                              : AppColors.primary,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Mindful Breathing',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: isDark
                                                ? AppColors.darkPrimary
                                                : AppColors.primary,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Take a Calm Moment',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      color: isDark
                                          ? AppColors.darkTextPrimary
                                          : AppColors.textPrimary,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Tap to start a guided 4-7-8 breathing exercise.',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isDark
                                          ? AppColors.darkTextSecondary
                                          : AppColors.textSecondary,
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: Center(
                                child: Lottie.asset(
                                  'assets/lottie/Breathing.json',
                                  height: 110,
                                  width: 110,
                                  repeat: true,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildReliefSection(double screenWidth, bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          _PremiumReliefCard(
            icon: Icons.water_drop_rounded,
            label: 'Anxiety\n& Panic',
            routeName: '/anxietypanic',
            screenWidth: screenWidth,
            tintColor: AppColors.primary,
            isDark: isDark,
          ),
          const SizedBox(width: 12),
          _PremiumReliefCard(
            icon: Icons.nights_stay_rounded,
            label: 'Depression\nSupport',
            routeName: '/depression',
            screenWidth: screenWidth,
            tintColor: Colors.indigoAccent,
            isDark: isDark,
          ),
          const SizedBox(width: 12),
          _PremiumReliefCard(
            icon: Icons.healing_rounded,
            label: 'Self Harm\nIdeation',
            routeName: '/selfharm',
            screenWidth: screenWidth,
            tintColor: Colors.teal,
            isDark: isDark,
          ),
          const SizedBox(width: 12),
          _PremiumReliefCard(
            icon: CupertinoIcons.infinite,
            label: 'Autism\n& ADHD',
            routeName: '/autismadhd',
            screenWidth: screenWidth,
            tintColor: Colors.blueAccent,
            isDark: isDark,
          ),
        ],
      ),
    );
  }
}

class _PremiumReliefCard extends StatefulWidget {
  final IconData icon;
  final String label;
  final String routeName;
  final double screenWidth;
  final Color tintColor;
  final bool isDark;

  const _PremiumReliefCard({
    required this.icon,
    required this.label,
    required this.routeName,
    required this.screenWidth,
    required this.tintColor,
    required this.isDark,
  });

  @override
  State<_PremiumReliefCard> createState() => _PremiumReliefCardState();
}

class _PremiumReliefCardState extends State<_PremiumReliefCard> {
  bool _isPressed = false;

  List<Color> _getGradientColors() {
    if (widget.isDark) {
      if (widget.routeName == '/anxietypanic') {
        return [AppColors.darkSurface, const Color(0xFF102725)];
      } else if (widget.routeName == '/depression') {
        return [AppColors.darkSurface, const Color(0xFF151930)];
      } else if (widget.routeName == '/autismadhd') {
        return [AppColors.darkSurface, const Color(0xFF102130)];
      } else {
        return [AppColors.darkSurface, const Color(0xFF2B1914)];
      }
    } else {
      if (widget.routeName == '/anxietypanic') {
        return [Colors.white, const Color(0xFFE8F6F4)];
      } else if (widget.routeName == '/depression') {
        return [Colors.white, const Color(0xFFEEF0FC)];
      } else if (widget.routeName == '/autismadhd') {
        return [Colors.white, const Color(0xFFEBF3FC)];
      } else {
        return [Colors.white, const Color(0xFFFFF2EE)];
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final gradientColors = _getGradientColors();
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        HapticFeedback.lightImpact();
        Navigator.pushNamed(context, widget.routeName);
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutBack,
        child: Container(
          width: (widget.screenWidth - 60) / 3.3,
          height: 135,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: gradientColors,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: widget.isDark
                  ? widget.tintColor.withValues(alpha: 0.25)
                  : widget.tintColor.withValues(alpha: 0.2),
              width: 1.5,
            ),
            boxShadow: [
              if (!widget.isDark)
                BoxShadow(
                  color: widget.tintColor.withValues(alpha: 0.1),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              if (widget.isDark)
                BoxShadow(
                  color: widget.tintColor.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
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
                  color: widget.tintColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.icon,
                  size: 26,
                  color: widget.tintColor,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                widget.label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: widget.isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
                  height: 1.25,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
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

  List<Color> _getGradientColors() {
    final isGoals = widget.title.contains("Goals");
    if (widget.isDark) {
      return isGoals
          ? [AppColors.darkSurface, const Color(0xFF102724)]
          : [AppColors.darkSurface, const Color(0xFF2C1914)];
    } else {
      return isGoals
          ? [Colors.white, const Color(0xFFEAF7F5)]
          : [Colors.white, const Color(0xFFFFF0EB)];
    }
  }

  Color _getAccentColor() {
    final isGoals = widget.title.contains("Goals");
    return isGoals ? AppColors.primary : AppColors.accent;
  }

  @override
  Widget build(BuildContext context) {
    final gradientColors = _getGradientColors();
    final accentColor = _getAccentColor();
    final isGoals = widget.title.contains("Goals");

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
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradientColors,
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: widget.isDark
                  ? accentColor.withValues(alpha: 0.2)
                  : AppColors.border,
              width: 1.5,
            ),
            boxShadow: [
              if (!widget.isDark)
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.05),
                  blurRadius: 16,
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
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isGoals ? "DAILY TRACKING" : "SELF REFLECTION",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: accentColor,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: widget.isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.textPrimary,
                        letterSpacing: -0.6,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: widget.isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Text(
                          isGoals ? "Open Goals" : "Start Writing",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: accentColor,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 11,
                          color: accentColor,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: widget.isDark
                      ? accentColor.withValues(alpha: 0.15)
                      : accentColor.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(
                  isGoals ? Icons.fact_check_rounded : Icons.create_rounded,
                  size: 32,
                  color: accentColor,
                ),
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

class _BreathingGuideDialog extends StatefulWidget {
  final bool isDark;
  const _BreathingGuideDialog({required this.isDark});

  @override
  State<_BreathingGuideDialog> createState() => _BreathingGuideDialogState();
}

class _BreathingGuideDialogState extends State<_BreathingGuideDialog> {
  int _secondsRemaining = 4;
  String _currentPhase = 'Inhale';
  late Timer _timer;
  int _phaseIndex = 0; // 0: Inhale, 1: Hold, 2: Exhale, 3: Hold

  final List<String> _phases = ['Inhale', 'Hold', 'Exhale', 'Hold'];
  final List<int> _durations = [4, 7, 8, 4];
  final List<Color> _colors = [
    AppColors.primary,
    const Color(0xFFFFB300),
    AppColors.accent,
    const Color(0xFFFFB300)
  ];

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_secondsRemaining > 1) {
          _secondsRemaining--;
        } else {
          _phaseIndex = (_phaseIndex + 1) % 4;
          _currentPhase = _phases[_phaseIndex];
          _secondsRemaining = _durations[_phaseIndex];
          HapticFeedback.lightImpact();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentColor = _colors[_phaseIndex];
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        decoration: BoxDecoration(
          color: widget.isDark ? AppColors.darkSurface : AppColors.surface,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: widget.isDark ? AppColors.darkBorder : AppColors.border,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: currentColor.withValues(alpha: 0.15),
              blurRadius: 24,
              spreadRadius: 4,
            ),
          ],
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: widget.isDark ? AppColors.darkSurface2 : AppColors.primaryLight,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.close_rounded,
                    size: 20,
                    color: widget.isDark ? AppColors.darkTextPrimary : AppColors.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Breathing Space',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: widget.isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Find your baseline calm',
              style: TextStyle(
                fontSize: 14,
                color: widget.isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              width: 200,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedContainer(
                    duration: const Duration(seconds: 4),
                    curve: Curves.easeInOut,
                    width: _currentPhase == 'Inhale' ? 190 : (_currentPhase == 'Exhale' ? 140 : 170),
                    height: _currentPhase == 'Inhale' ? 190 : (_currentPhase == 'Exhale' ? 140 : 170),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: currentColor.withValues(alpha: 0.08),
                      border: Border.all(
                        color: currentColor.withValues(alpha: 0.3),
                        width: 4,
                      ),
                    ),
                  ),
                  Lottie.asset(
                    'assets/lottie/Breathing.json',
                    height: 150,
                    width: 150,
                    repeat: true,
                    fit: BoxFit.contain,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 300),
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: currentColor,
                letterSpacing: -0.5,
              ),
              child: Text(_currentPhase),
            ),
            const SizedBox(height: 8),
            Text(
              '$_secondsRemaining seconds remaining',
              style: TextStyle(
                fontSize: 14,
                color: widget.isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
