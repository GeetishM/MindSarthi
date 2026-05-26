import 'dart:io';
import 'package:appwrite/appwrite.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'package:mindsarthi/core/theme/app_theme.dart';
import 'package:mindsarthi/core/theme/app_toast.dart';
import 'package:mindsarthi/core/localization/app_localizations.dart';
import 'package:mindsarthi/core/services/appwrite_service.dart';
import 'package:mindsarthi/core/constants/appwrite_constants.dart';
import 'package:mindsarthi/features/auth/auth_repository.dart';
import 'package:mindsarthi/core/services/notification_service.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _genderController = TextEditingController();

  String _phoneNumber = '';
  String _phoneNumberCountryCode = 'IN';
  String? _selectedGender;
  String? _profileInitial;
  File? _localImageFile;
  String? _profileImageUrl;

  final List<String> _genders = ['Male', 'Female', 'Other'];
  final _dobFormatter = MaskTextInputFormatter(
    mask: '##/##/####',
    filter: {"#": RegExp(r'[0-9]')},
    type: MaskAutoCompletionType.lazy,
  );

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _nicknameController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    _genderController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final user = ref.read(authStateProvider).value;
    if (user != null) {
      try {
        final databases = AppwriteService().databases;
        final doc = await databases.getDocument(
          databaseId: AppwriteConstants.databaseId,
          collectionId: AppwriteConstants.usersCollectionId,
          documentId: user.$id,
        );
        final data = doc.data;
        final prefs = await SharedPreferences.getInstance();
        final localImageUrl = prefs.getString('profile_image_url_${user.$id}');
        final localDob = prefs.getString('profile_dob_${user.$id}');

        setState(() {
          _phoneNumber = data['phoneNumber'] ?? '';
          
          // Parse loaded phone number
          String rawPhone = _phoneNumber;
          String initialNumber = rawPhone;
          String initialCountry = 'IN';
          if (rawPhone.startsWith('+91')) {
            initialNumber = rawPhone.substring(3);
            initialCountry = 'IN';
          } else if (rawPhone.startsWith('+1')) {
            initialNumber = rawPhone.substring(2);
            initialCountry = 'US';
          } else if (rawPhone.startsWith('+')) {
            if (rawPhone.length > 4) {
              initialNumber = rawPhone.substring(4);
            }
          }
          _phoneController.text = initialNumber;
          _phoneNumberCountryCode = initialCountry;

          _usernameController.text = data['username'] ?? '';
          final loadedNickname = data['nickname'] as String?;
          final displayNickname = (loadedNickname == 'Personal User' ||
                  loadedNickname == 'Professional User' ||
                  loadedNickname == 'Organizational User')
              ? ''
              : (loadedNickname ?? '');
          _nicknameController.text = displayNickname;
          final loadedGender = data['gender'] as String?;
          _selectedGender = (loadedGender == null || loadedGender.trim().isEmpty) ? null : loadedGender;
          _genderController.text = _selectedGender ?? '';
          _dobController.text = data['dob'] ?? localDob ?? '';
          _profileImageUrl = data['profileImageUrl'] ?? localImageUrl ?? '';
          
          _profileInitial = data['profileInitial'] ??
              (_usernameController.text.isNotEmpty
                  ? _usernameController.text[0].toUpperCase()
                  : null);
          _isLoading = false;
        });
      } catch (e) {
        final prefs = await SharedPreferences.getInstance();
        final localImageUrl = prefs.getString('profile_image_url_${user.$id}');
        final localDob = prefs.getString('profile_dob_${user.$id}');
        final localUsername = prefs.getString('profile_username_${user.$id}');
        final localNickname = prefs.getString('profile_nickname_${user.$id}');
        final localPhone = prefs.getString('profile_phone_${user.$id}');
        final localPhoneCode = prefs.getString('profile_phone_code_${user.$id}');
        final localGender = prefs.getString('profile_gender_${user.$id}');
        final localInitial = prefs.getString('profile_initial_${user.$id}');

        setState(() {
          _usernameController.text = localUsername ?? '';
          final displayNickname = (localNickname == 'Personal User' ||
                  localNickname == 'Professional User' ||
                  localNickname == 'Organizational User')
              ? ''
              : (localNickname ?? '');
          _nicknameController.text = displayNickname;
          _phoneNumber = localPhone ?? '';
          
          String initialNumber = _phoneNumber;
          String initialCountry = localPhoneCode ?? 'IN';
          if (_phoneNumber.startsWith('+91')) {
            initialNumber = _phoneNumber.substring(3);
          } else if (_phoneNumber.startsWith('+1')) {
            initialNumber = _phoneNumber.substring(2);
          } else if (_phoneNumber.startsWith('+')) {
            if (_phoneNumber.length > 4) {
              initialNumber = _phoneNumber.substring(4);
            }
          }
          _phoneController.text = initialNumber;
          _phoneNumberCountryCode = initialCountry;
          
          _selectedGender = (localGender == null || localGender.trim().isEmpty) ? null : localGender;
          _genderController.text = _selectedGender ?? '';
          _dobController.text = localDob ?? '';
          _profileImageUrl = localImageUrl ?? '';
          
          _profileInitial = localInitial ??
              (_usernameController.text.isNotEmpty
                  ? _usernameController.text[0].toUpperCase()
                  : null);
          _isLoading = false;
        });
        debugPrint('Error loading user profile from Appwrite (using local cache fallback): $e');
      }
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
        
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Change Profile Photo',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: const Icon(Icons.photo_library_rounded, color: AppColors.primary),
                  title: Text('Choose from Gallery', style: TextStyle(color: textPrimary)),
                  onTap: () async {
                    Navigator.pop(context);
                    final file = await picker.pickImage(
                      source: ImageSource.gallery,
                      imageQuality: 70,
                    );
                    if (file != null) {
                      setState(() {
                        _localImageFile = File(file.path);
                      });
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt_rounded, color: AppColors.primary),
                  title: Text('Take a Photo', style: TextStyle(color: textPrimary)),
                  onTap: () async {
                    Navigator.pop(context);
                    final file = await picker.pickImage(
                      source: ImageSource.camera,
                      imageQuality: 70,
                    );
                    if (file != null) {
                      setState(() {
                        _localImageFile = File(file.path);
                      });
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<String?> _uploadProfileImage(File file) async {
    try {
      final appwrite = AppwriteService();
      final storage = Storage(appwrite.client);
      final uniqueId = ID.unique();
      final uploadedFile = await storage.createFile(
        bucketId: AppwriteConstants.mediaBucketId,
        fileId: uniqueId,
        file: InputFile.fromPath(
          path: file.path,
          filename: file.path.split('/').last,
        ),
      );
      final viewUrl = 'https://cloud.appwrite.io/v1/storage/buckets/${AppwriteConstants.mediaBucketId}/files/${uploadedFile.$id}/view?project=${appwrite.client.config['project']}';
      return viewUrl;
    } catch (e) {
      debugPrint('Error uploading profile image: $e');
      return null;
    }
  }

  DateTime? _parseDate(String input) {
    try {
      final parts = input.split('/');
      if (parts.length != 3) return null;
      final day = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final year = int.parse(parts[2]);
      final date = DateTime(year, month, day);
      if (date.year == year && date.month == month && date.day == day) {
        return date;
      }
    } catch (_) {}
    return null;
  }

  int _calculateAge(DateTime birthDate) {
    DateTime today = DateTime.now();
    int age = today.year - birthDate.year;
    int month1 = today.month;
    int month2 = birthDate.month;
    if (month2 > month1) {
      age--;
    } else if (month1 == month2) {
      int day1 = today.day;
      int day2 = birthDate.day;
      if (day2 > day1) {
        age--;
      }
    }
    return age;
  }

  Future<void> _selectDateOfBirth(BuildContext context) async {
    DateTime initialDate = DateTime.now().subtract(const Duration(days: 365 * 18));
    if (_dobController.text.isNotEmpty) {
      final parsed = _parseDate(_dobController.text);
      if (parsed != null) {
        initialDate = parsed;
      }
    }
    
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Theme.of(context).colorScheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      final formatted = DateFormat('dd/MM/yyyy').format(picked);
      setState(() {
        _dobController.text = formatted;
      });
    }
  }

  Future<void> _saveProfile() async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return;

    setState(() => _isSaving = true);

    String? imageUrl = _profileImageUrl;
    if (_localImageFile != null) {
      final uploadedUrl = await _uploadProfileImage(_localImageFile!);
      if (uploadedUrl != null) {
        imageUrl = uploadedUrl;
      } else {
        if (mounted) {
          AppToast.error(context, 'Failed to upload profile photo');
        }
        setState(() => _isSaving = false);
        return;
      }
    }

    String calculatedAge = '';
    bool dobValid = false;
    if (_dobController.text.isNotEmpty) {
      final dobDate = _parseDate(_dobController.text);
      if (dobDate != null) {
        calculatedAge = _calculateAge(dobDate).toString();
        dobValid = true;
      }
    }

    final initial = _usernameController.text.isNotEmpty
        ? _usernameController.text.trim()[0].toUpperCase()
        : 'U';

    final data = {
      'uid': user.$id,
      'phoneNumber': _phoneNumber,
      'username': _usernameController.text.trim(),
      'nickname': _nicknameController.text.trim(),
      'gender': _selectedGender ?? '',
      'age': calculatedAge,
      'dob': _dobController.text.trim(),
      'profileInitial': initial,
      'profileImageUrl': imageUrl,
    };

    // Save to SharedPreferences first as a local cache/fallback
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profile_username_${user.$id}', _usernameController.text.trim());
      await prefs.setString('profile_nickname_${user.$id}', _nicknameController.text.trim());
      await prefs.setString('profile_phone_${user.$id}', _phoneNumber);
      await prefs.setString('profile_phone_code_${user.$id}', _phoneNumberCountryCode);
      await prefs.setString('profile_gender_${user.$id}', _selectedGender ?? '');
      await prefs.setString('profile_dob_${user.$id}', _dobController.text.trim());
      await prefs.setString('profile_age_${user.$id}', calculatedAge);
      await prefs.setString('profile_initial_${user.$id}', initial);
      if (imageUrl != null) {
        await prefs.setString('profile_image_url_${user.$id}', imageUrl);
      }
    } catch (prefError) {
      debugPrint('Failed to save profile to SharedPreferences: $prefError');
    }

    try {
      final databases = AppwriteService().databases;
      try {
        await databases.updateDocument(
          databaseId: AppwriteConstants.databaseId,
          collectionId: AppwriteConstants.usersCollectionId,
          documentId: user.$id,
          data: data,
        );
      } on AppwriteException catch (ae) {
        // Handle database attribute schema mismatches gracefully
        if (ae.code == 400 || ae.message?.contains('Attribute') == true) {
          final fallbackData = {
            'uid': user.$id,
            'phoneNumber': _phoneNumber,
            'username': _usernameController.text.trim(),
            'nickname': _nicknameController.text.trim(),
            'gender': _selectedGender ?? '',
            'age': calculatedAge,
            'profileInitial': initial,
          };
          await databases.updateDocument(
            databaseId: AppwriteConstants.databaseId,
            collectionId: AppwriteConstants.usersCollectionId,
            documentId: user.$id,
            data: fallbackData,
          );
          
          final prefs = await SharedPreferences.getInstance();
          if (imageUrl != null) {
            await prefs.setString('profile_image_url_${user.$id}', imageUrl);
          }
          await prefs.setString('profile_dob_${user.$id}', _dobController.text.trim());
        } else if (ae.code == 404) {
          // If the error indicates that the database itself is missing, don't try to create the doc.
          if (ae.message?.contains('database_not_found') == true || ae.response?.toString().contains('database_not_found') == true) {
            throw ae;
          }
          
          try {
            await databases.createDocument(
              databaseId: AppwriteConstants.databaseId,
              collectionId: AppwriteConstants.usersCollectionId,
              documentId: user.$id,
              data: data,
            );
          } on AppwriteException catch (createAe) {
            if (createAe.code == 400 || createAe.message?.contains('Attribute') == true) {
              final fallbackData = {
                'uid': user.$id,
                'phoneNumber': _phoneNumber,
                'username': _usernameController.text.trim(),
                'nickname': _nicknameController.text.trim(),
                'gender': _selectedGender ?? '',
                'age': calculatedAge,
                'profileInitial': initial,
              };
              await databases.createDocument(
                databaseId: AppwriteConstants.databaseId,
                collectionId: AppwriteConstants.usersCollectionId,
                documentId: user.$id,
                data: fallbackData,
              );
              final prefs = await SharedPreferences.getInstance();
              if (imageUrl != null) {
                await prefs.setString('profile_image_url_${user.$id}', imageUrl);
              }
              await prefs.setString('profile_dob_${user.$id}', _dobController.text.trim());
            } else {
              rethrow;
            }
          }
        } else {
          rethrow;
        }
      }

      // Check completeness: username, nickname, age (valid DOB), and phoneNumber
      final isComplete = _usernameController.text.trim().isNotEmpty &&
          _nicknameController.text.trim().isNotEmpty &&
          _phoneNumber.trim().isNotEmpty &&
          dobValid;

      // Schedule or cancel completion notification reminder
      NotificationService.scheduleProfileCompletionReminder(!isComplete);

      setState(() {
        _profileInitial = initial;
        _profileImageUrl = imageUrl;
        _isSaving = false;
      });

      if (mounted) {
        AppToast.success(context, context.tr('prof_saved'));
      }
    } catch (e) {
      setState(() => _isSaving = false);
      final errorString = e.toString();
      final isDatabaseNotFound = errorString.contains('database_not_found') || errorString.contains('404');
      
      if (isDatabaseNotFound) {
        // Complete the local saving sequence since it is successfully saved locally
        final isComplete = _usernameController.text.trim().isNotEmpty &&
            _nicknameController.text.trim().isNotEmpty &&
            _phoneNumber.trim().isNotEmpty &&
            dobValid;
        NotificationService.scheduleProfileCompletionReminder(!isComplete);
        
        setState(() {
          _profileInitial = initial;
          _profileImageUrl = imageUrl;
        });
        
        if (mounted) {
          AppToast.success(
            context, 
            'Profile saved locally!', 
            description: 'Database "mindsarthi_db" not found in Appwrite. Please create it in your console.'
          );
        }
      } else {
        if (mounted) {
          AppToast.error(context, 'Failed to save profile', description: errorString);
        }
      }
    }
  }

  Widget _buildInitialsAvatar(ThemeData theme) {
    return Center(
      child: Text(
        _profileInitial ?? 'U',
        style: theme.textTheme.displayMedium?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _animateWidget(Widget child, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (index * 80)),
      curve: Curves.easeOutQuint,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1.0 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  Widget _buildAvatar(ThemeData theme, bool isDark) {
    final activeColor = theme.colorScheme.primary;
    final accentColor = theme.colorScheme.secondary;
    
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                activeColor,
                accentColor,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: activeColor.withValues(alpha: isDark ? 0.3 : 0.15),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.all(4),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? AppColors.darkSurface : AppColors.white,
            ),
            padding: const EdgeInsets.all(3),
            child: CircleAvatar(
              radius: 50,
              backgroundColor: isDark ? AppColors.darkSurface2 : AppColors.primaryLight,
              child: _localImageFile != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(50),
                      child: Image.file(
                        _localImageFile!,
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                      ),
                    )
                  : (_profileImageUrl != null && _profileImageUrl!.isNotEmpty)
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(50),
                          child: Image.network(
                            _profileImageUrl!,
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => _buildInitialsAvatar(theme),
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Shimmer.fromColors(
                                baseColor: isDark ? AppColors.darkShimmerBase : AppColors.shimmerBase,
                                highlightColor: isDark ? AppColors.darkShimmerHighlight : AppColors.shimmerHighlight,
                                child: Container(
                                  width: 100,
                                  height: 100,
                                  decoration: const BoxDecoration(
                                    color: Colors.grey,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              );
                            },
                          ),
                        )
                      : _buildInitialsAvatar(theme),
            ),
          ),
        ),
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: accentColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: isDark ? AppColors.darkSurface : AppColors.white,
                width: 2.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.camera_alt_rounded,
              size: 16,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          context.tr('prof_title'),
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: theme.colorScheme.primary,
                strokeWidth: 2.5,
              ),
            )
          : Stack(
              children: [
                // Top premium gradient background banner
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 250,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [
                                theme.colorScheme.primary.withValues(alpha: 0.25),
                                theme.colorScheme.primary.withValues(alpha: 0.0),
                              ]
                            : [
                                theme.colorScheme.primary.withValues(alpha: 0.15),
                                theme.colorScheme.primary.withValues(alpha: 0.0),
                              ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),
                SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                    child: Column(
                      children: [
                        _buildAvatar(theme, isDark),
                        const SizedBox(height: 18),
                        Text(
                          'Your Profile',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        
                        // Premium secure data badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: isDark 
                                ? AppColors.darkSurface2.withValues(alpha: 0.8) 
                                : AppColors.primaryLight.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: theme.colorScheme.primary.withValues(alpha: 0.15),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.lock_outline_rounded,
                                size: 14,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Private & Secure',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: theme.colorScheme.primary,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 28),

                        // Form card
                        _animateWidget(
                          Container(
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(
                                color: isDark 
                                    ? AppColors.darkBorder.withValues(alpha: 0.5) 
                                    : AppColors.border.withValues(alpha: 0.5),
                                width: 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.03),
                                  blurRadius: 30,
                                  offset: const Offset(0, 12),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Personal Information',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                
                                _buildInput(
                                  context,
                                  context.tr('prof_username'),
                                  _usernameController,
                                  Icons.person_outline_rounded,
                                ),
                                const SizedBox(height: 20),
                                _buildInput(
                                  context,
                                  context.tr('prof_nickname'),
                                  _nicknameController,
                                  Icons.tag_rounded,
                                ),
                                const SizedBox(height: 20),
                                
                                _buildPhoneField(context, isDark),
                                const SizedBox(height: 20),
                                
                                _buildGenderInput(context),
                                const SizedBox(height: 20),
                                
                                _buildDobInput(context),
                                const SizedBox(height: 32),
                                
                                // Premium Save Button with Gradient and Shadow
                                InkWell(
                                  onTap: _isSaving ? null : _saveProfile,
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    height: 56,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20),
                                      gradient: LinearGradient(
                                        colors: _isSaving
                                            ? [
                                                primaryColor.withValues(alpha: 0.6),
                                                primaryColor.withValues(alpha: 0.8),
                                              ]
                                            : [
                                                primaryColor,
                                                isDark ? const Color(0xFF238E82) : const Color(0xFF22847A),
                                              ],
                                      ),
                                      boxShadow: _isSaving
                                          ? null
                                          : [
                                              BoxShadow(
                                                color: primaryColor.withValues(alpha: isDark ? 0.35 : 0.25),
                                                blurRadius: 18,
                                                offset: const Offset(0, 8),
                                              ),
                                            ],
                                    ),
                                    alignment: Alignment.center,
                                    child: _isSaving
                                        ? const SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.5,
                                              color: Colors.white,
                                            ),
                                          )
                                        : Text(
                                            context.tr('prof_save'),
                                            style: const TextStyle(
                                              fontSize: 16,
                                              color: Colors.white,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: 0.3,
                                            ),
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          1,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildInput(
    BuildContext context,
    String label,
    TextEditingController controller,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: theme.textTheme.bodyLarge?.copyWith(
        fontWeight: FontWeight.w500,
        fontSize: 15,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: isDark ? AppColors.darkTextSecondary.withValues(alpha: 0.7) : AppColors.textSecondary.withValues(alpha: 0.7),
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        floatingLabelStyle: TextStyle(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 4.0, right: 2.0),
          child: Icon(
            icon, 
            size: 20, 
            color: theme.colorScheme.primary.withValues(alpha: 0.7),
          ),
        ),
        filled: true,
        fillColor: isDark 
            ? AppColors.darkSurface2.withValues(alpha: 0.5) 
            : AppColors.primaryLight.withValues(alpha: 0.3),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark ? AppColors.darkBorder.withValues(alpha: 0.5) : AppColors.border.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: theme.colorScheme.primary,
            width: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneField(BuildContext context, bool isDark) {
    final theme = Theme.of(context);
    
    return IntlPhoneField(
      controller: _phoneController,
      style: theme.textTheme.bodyLarge?.copyWith(
        fontWeight: FontWeight.w500,
        fontSize: 15,
      ),
      dropdownTextStyle: theme.textTheme.bodyLarge?.copyWith(
        fontWeight: FontWeight.w500,
        fontSize: 15,
      ),
      showCountryFlag: true,
      decoration: InputDecoration(
        labelText: context.tr('prof_phone'),
        labelStyle: TextStyle(
          color: isDark ? AppColors.darkTextSecondary.withValues(alpha: 0.7) : AppColors.textSecondary.withValues(alpha: 0.7),
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        floatingLabelStyle: TextStyle(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 4.0, right: 2.0),
          child: Icon(
            Icons.phone_outlined,
            size: 20,
            color: theme.colorScheme.primary.withValues(alpha: 0.7),
          ),
        ),
        filled: true,
        fillColor: isDark 
            ? AppColors.darkSurface2.withValues(alpha: 0.5) 
            : AppColors.primaryLight.withValues(alpha: 0.3),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark ? AppColors.darkBorder.withValues(alpha: 0.5) : AppColors.border.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: theme.colorScheme.primary,
            width: 1.5,
          ),
        ),
        counterText: '',
      ),
      initialCountryCode: _phoneNumberCountryCode,
      onChanged: (phone) {
        _phoneNumber = phone.completeNumber;
      },
      onCountryChanged: (country) {
        _phoneNumberCountryCode = country.code;
      },
    );
  }

  void _showGenderPicker(BuildContext context) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final isDark = theme.brightness == Brightness.dark;
        final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
        
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('prof_gender'),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                ..._genders.map((gender) {
                  final isSelected = _selectedGender == gender;
                  return ListTile(
                    leading: Icon(
                      gender == 'Male'
                          ? Icons.male_rounded
                          : gender == 'Female'
                              ? Icons.female_rounded
                              : Icons.transgender_rounded,
                      color: isSelected ? theme.colorScheme.primary : theme.iconTheme.color,
                    ),
                    title: Text(
                      gender,
                      style: TextStyle(
                        color: textPrimary,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    trailing: isSelected
                        ? Icon(Icons.check_circle_rounded, color: theme.colorScheme.primary)
                        : null,
                    onTap: () {
                      setState(() {
                        _selectedGender = gender;
                        _genderController.text = gender;
                      });
                      Navigator.pop(context);
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGenderInput(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return TextFormField(
      controller: _genderController,
      readOnly: true,
      onTap: () => _showGenderPicker(context),
      style: theme.textTheme.bodyLarge?.copyWith(
        fontWeight: FontWeight.w500,
        fontSize: 15,
      ),
      decoration: InputDecoration(
        labelText: context.tr('prof_gender'),
        hintText: context.tr('prof_select_gender'),
        labelStyle: TextStyle(
          color: isDark ? AppColors.darkTextSecondary.withValues(alpha: 0.7) : AppColors.textSecondary.withValues(alpha: 0.7),
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        floatingLabelStyle: TextStyle(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 4.0, right: 2.0),
          child: Icon(
            Icons.person_pin_outlined, 
            size: 20, 
            color: theme.colorScheme.primary.withValues(alpha: 0.7),
          ),
        ),
        suffixIcon: Icon(
          Icons.keyboard_arrow_down_rounded,
          color: theme.colorScheme.primary.withValues(alpha: 0.7),
          size: 24,
        ),
        filled: true,
        fillColor: isDark 
            ? AppColors.darkSurface2.withValues(alpha: 0.5) 
            : AppColors.primaryLight.withValues(alpha: 0.3),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark ? AppColors.darkBorder.withValues(alpha: 0.5) : AppColors.border.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: theme.colorScheme.primary,
            width: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildDobInput(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return TextFormField(
      controller: _dobController,
      keyboardType: TextInputType.datetime,
      inputFormatters: [_dobFormatter],
      style: theme.textTheme.bodyLarge?.copyWith(
        fontWeight: FontWeight.w500,
        fontSize: 15,
      ),
      decoration: InputDecoration(
        labelText: context.tr('prof_dob'),
        hintText: 'DD/MM/YYYY',
        labelStyle: TextStyle(
          color: isDark ? AppColors.darkTextSecondary.withValues(alpha: 0.7) : AppColors.textSecondary.withValues(alpha: 0.7),
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        floatingLabelStyle: TextStyle(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 4.0, right: 2.0),
          child: Icon(
            Icons.calendar_today_outlined,
            size: 18,
            color: theme.colorScheme.primary.withValues(alpha: 0.7),
          ),
        ),
        suffixIcon: Padding(
          padding: const EdgeInsets.only(right: 4.0),
          child: IconButton(
            icon: const Icon(Icons.date_range_rounded, size: 22),
            color: theme.colorScheme.primary,
            onPressed: () => _selectDateOfBirth(context),
          ),
        ),
        filled: true,
        fillColor: isDark 
            ? AppColors.darkSurface2.withValues(alpha: 0.5) 
            : AppColors.primaryLight.withValues(alpha: 0.3),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark ? AppColors.darkBorder.withValues(alpha: 0.5) : AppColors.border.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: theme.colorScheme.primary,
            width: 1.5,
          ),
        ),
      ),
    );
  }
}