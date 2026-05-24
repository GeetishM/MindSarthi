import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mindsarthi/core/theme/app_toast.dart';
import 'package:mindsarthi/core/localization/app_localizations.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();

  String _phoneNumber = '';
  String _selectedGender = 'Male';
  String? _profileInitial;

  final List<String> _genders = ['Male', 'Female', 'Other'];
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final user = _auth.currentUser;
    if (user != null) {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      final data = doc.data();

      setState(() {
        _phoneNumber = data?['phoneNumber'] ?? user.phoneNumber ?? '';
        _usernameController.text = data?['username'] ?? '';
        _nicknameController.text = data?['nickname'] ?? '';
        _selectedGender = data?['gender'] ?? 'Male';
        _ageController.text = data?['age'] ?? '';
        _profileInitial = data?['profileInitial'] ??
            (_usernameController.text.isNotEmpty
                ? _usernameController.text[0].toUpperCase()
                : null);
        _isLoading = false;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (_usernameController.text.trim().isEmpty ||
        _nicknameController.text.trim().isEmpty ||
        _ageController.text.trim().isEmpty) {
      AppToast.warning(context, 'Please fill all fields');
      return;
    }

    if (int.tryParse(_ageController.text.trim()) == null) {
      AppToast.error(context, 'Age must be a valid number');
      return;
    }

    final user = _auth.currentUser;
    if (user == null) return;

    setState(() => _isSaving = true);

    final initial = _usernameController.text.trim()[0].toUpperCase();

    final data = {
      'uid': user.uid,
      'phoneNumber': _phoneNumber,
      'username': _usernameController.text.trim(),
      'nickname': _nicknameController.text.trim(),
      'gender': _selectedGender,
      'age': _ageController.text.trim(),
      'profileInitial': initial,
    };

    await _firestore
        .collection('users')
        .doc(user.uid)
        .set(data, SetOptions(merge: true));

    setState(() {
      _profileInitial = initial;
      _isSaving = false;
    });

    if (mounted) {
      AppToast.success(context, context.tr('prof_saved'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('prof_title')),
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: theme.colorScheme.primary,
                strokeWidth: 2.5,
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              child: Column(
                children: [
                  // ── Avatar Section ──────────────────────────────────
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        width: 104,
                        height: 104,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.tertiary.withOpacity(0.5),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: theme.colorScheme.primary.withOpacity(0.15),
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: theme.shadowColor.withOpacity(0.04),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            _profileInitial ?? 'U',
                            style: theme.textTheme.displayMedium?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondary,
                          shape: BoxShape.circle,
                          border: Border.all(color: theme.colorScheme.surface, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: theme.shadowColor.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.edit_rounded,
                          size: 16,
                          color: theme.colorScheme.onSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Your Profile',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'This information is private and secure',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      letterSpacing: 0.1,
                    ),
                  ),

                  const SizedBox(height: 40),

                  // ── Form Container ───────────────────────────────
                  Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant.withOpacity(0.3),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: theme.shadowColor.withOpacity(0.03),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      children: [
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
                        _buildInput(
                          context,
                          context.tr('prof_phone'),
                          TextEditingController(text: _phoneNumber),
                          Icons.phone_outlined,
                          readOnly: true,
                        ),
                        const SizedBox(height: 20),
                        
                        // Premium Dropdown
                        _buildDropdown(context),
                        
                        const SizedBox(height: 20),
                        _buildInput(
                          context,
                          context.tr('prof_age'),
                          _ageController,
                          Icons.cake_outlined,
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 40),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _saveProfile,
                            style: ElevatedButton.styleFrom(
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: _isSaving
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : Text(
                                    context.tr('prof_save'),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // ── Helper Builders ──────────────────────────────────────────────

  Widget _buildInput(
    BuildContext context,
    String label,
    TextEditingController controller,
    IconData icon, {
    bool readOnly = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    final theme = Theme.of(context);
    
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      keyboardType: keyboardType,
      style: theme.textTheme.bodyLarge?.copyWith(
        fontWeight: FontWeight.w500,
        color: readOnly ? theme.textTheme.bodyMedium?.color : theme.textTheme.bodyLarge?.color,
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(
          icon, 
          size: 22, 
          color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8),
        ),
        suffixIcon: readOnly 
            ? Icon(
                Icons.lock_outline_rounded, 
                size: 18, 
                color: theme.textTheme.bodySmall?.color?.withOpacity(0.6)
              ) 
            : null,
        filled: true,
        fillColor: readOnly 
            ? theme.colorScheme.surfaceContainerHighest.withOpacity(0.2) 
            : theme.inputDecorationTheme.fillColor,
      ),
    );
  }

  Widget _buildDropdown(BuildContext context) {
    final theme = Theme.of(context);

    return DropdownButtonFormField<String>(
      value: _selectedGender,
      isExpanded: true,
      style: theme.textTheme.bodyLarge?.copyWith(
        fontWeight: FontWeight.w500,
      ),
      dropdownColor: theme.colorScheme.surface,
      elevation: 6,
      borderRadius: BorderRadius.circular(20), // Smooth, premium menu edges
      icon: Icon(
        Icons.keyboard_arrow_down_rounded, // Much cleaner than default arrow
        color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8),
        size: 26,
      ),
      decoration: InputDecoration(
        labelText: context.tr('prof_gender'),
        prefixIcon: Icon(
          Icons.person_pin_outlined, 
          size: 22, 
          color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8),
        ),
        filled: true,
        fillColor: theme.inputDecorationTheme.fillColor,
      ),
      items: _genders
          .map((e) => DropdownMenuItem(
                value: e, 
                child: Text(e),
              ))
          .toList(),
      onChanged: (val) {
        if (val != null) {
          setState(() => _selectedGender = val);
        }
      },
    );
  }
}