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
      // Scaffold background color is automatically inherited from the theme
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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                children: [
                  // ── Avatar Section ──────────────────────────────────
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.tertiary, // primaryLight mapped to tertiary in theme
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: theme.colorScheme.primary.withOpacity(0.2), 
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: theme.shadowColor.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            _profileInitial ?? 'U',
                            style: theme.textTheme.displayMedium?.copyWith(
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondary, // Accent color mapped to secondary
                          shape: BoxShape.circle,
                          border: Border.all(color: theme.colorScheme.surface, width: 2),
                        ),
                        child: Icon(
                          Icons.edit_rounded,
                          size: 14,
                          color: theme.colorScheme.onSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Your Profile',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'This information is private and secure',
                    style: theme.textTheme.bodyMedium,
                  ),

                  const SizedBox(height: 32),

                  // ── Form Card ───────────────────────────────
                  Card(
                    // Card styling is inherited directly from AppTheme's cardTheme
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          _buildInput(
                            context,
                            context.tr('prof_username'),
                            _usernameController,
                            Icons.person_outline_rounded,
                          ),
                          const SizedBox(height: 16),
                          _buildInput(
                            context,
                            context.tr('prof_nickname'),
                            _nicknameController,
                            Icons.tag_rounded,
                          ),
                          const SizedBox(height: 16),
                          _buildInput(
                            context,
                            context.tr('prof_phone'),
                            TextEditingController(text: _phoneNumber),
                            Icons.phone_outlined,
                            readOnly: true,
                          ),
                          const SizedBox(height: 16),
                          _buildDropdown(context),
                          const SizedBox(height: 16),
                          _buildInput(
                            context,
                            context.tr('prof_age'),
                            _ageController,
                            Icons.cake_outlined,
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 32),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isSaving ? null : _saveProfile,
                              child: _isSaving
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : Text(context.tr('prof_save')),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // Helper widget builder using dynamic Theme context
  Widget _buildInput(
    BuildContext context,
    String label,
    TextEditingController controller,
    IconData icon, {
    bool readOnly = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    final theme = Theme.of(context);
    
    return TextField(
      controller: controller,
      readOnly: readOnly,
      keyboardType: keyboardType,
      style: theme.textTheme.bodyLarge?.copyWith(
        color: readOnly ? theme.textTheme.bodyMedium?.color : theme.textTheme.bodyLarge?.color,
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(
          icon, 
          size: 20, 
          color: theme.textTheme.bodyMedium?.color,
        ),
        suffixIcon: readOnly 
            ? Icon(Icons.lock_outline_rounded, size: 16, color: theme.textTheme.bodySmall?.color) 
            : null,
        // If readOnly, slightly dim the background by ignoring the default filled color
        filled: true,
        fillColor: readOnly 
            ? theme.colorScheme.surfaceContainerHighest.withOpacity(0.3) 
            : theme.inputDecorationTheme.fillColor,
      ),
    );
  }

  Widget _buildDropdown(BuildContext context) {
    final theme = Theme.of(context);

    return DropdownButtonFormField<String>(
      value: _selectedGender,
      style: theme.textTheme.bodyLarge,
      dropdownColor: theme.colorScheme.surface,
      iconEnabledColor: theme.colorScheme.primary,
      decoration: InputDecoration(
        labelText: context.tr('prof_gender'),
        prefixIcon: Icon(
          Icons.person_pin_outlined, 
          size: 20, 
          color: theme.textTheme.bodyMedium?.color,
        ),
      ),
      items: _genders
          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
          .toList(),
      onChanged: (val) {
        if (val != null) {
          setState(() => _selectedGender = val);
        }
      },
    );
  }
}