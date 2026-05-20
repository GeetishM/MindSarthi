import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mindsarthi/core/theme/app_theme.dart';
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(context.tr('prof_title')),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 2.5,
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // ── Avatar ──────────────────────────────────
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.border, width: 2),
                    ),
                    child: Center(
                      child: Text(
                        _profileInitial ?? 'U',
                        style: const TextStyle(
                          fontSize: 36,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Your Profile',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'This information is private and secure',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ── Form card ───────────────────────────────
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _buildInput(context.tr('prof_username'), _usernameController, Icons.person_outline_rounded),
                        const SizedBox(height: 14),
                        _buildInput(context.tr('prof_nickname'), _nicknameController, Icons.tag_rounded),
                        const SizedBox(height: 14),
                        _buildInput(
                          context.tr('prof_phone'),
                          TextEditingController(text: _phoneNumber),
                          Icons.phone_outlined,
                          readOnly: true,
                        ),
                        const SizedBox(height: 14),
                        _buildDropdown(context),
                        const SizedBox(height: 14),
                        _buildInput(
                          context.tr('prof_age'),
                          _ageController,
                          Icons.cake_outlined,
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _saveProfile,
                            child: _isSaving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: AppColors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(context.tr('prof_save')),
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

  Widget _buildInput(
    String label,
    TextEditingController controller,
    IconData icon, {
    bool readOnly = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      keyboardType: keyboardType,
      style: const TextStyle(
        fontSize: 14,
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20, color: AppColors.textSecondary),
        filled: true,
        fillColor: readOnly ? AppColors.background : AppColors.white,
      ),
    );
  }

  Widget _buildDropdown(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: _selectedGender,
      style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: context.tr('prof_gender'),
        prefixIcon: const Icon(Icons.person_pin_outlined, size: 20, color: AppColors.textSecondary),
        filled: true,
        fillColor: AppColors.white,
      ),
      items: _genders
          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
          .toList(),
      onChanged: (val) => setState(() => _selectedGender = val!),
    );
  }
}
