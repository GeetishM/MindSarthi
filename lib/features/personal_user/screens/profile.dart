import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

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

  @override
  void initState() {
    super.initState();
    _loadUserData();
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
      toastification.show(
        context: context,
        title: const Text("Please fill all fields"),
        type: ToastificationType.warning,
      );
      return;
    }

    if (int.tryParse(_ageController.text.trim()) == null) {
      toastification.show(
        context: context,
        title: const Text("Age must be a number"),
        type: ToastificationType.error,
      );
      return;
    }

    final user = _auth.currentUser;
    if (user == null) return;

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

    await _firestore.collection('users').doc(user.uid).set(data, SetOptions(merge: true));

    toastification.show(
      context: context,
      title: const Text("Profile saved!"),
      type: ToastificationType.success,
    );

    setState(() {
      _profileInitial = initial;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        centerTitle: true,
        backgroundColor: Colors.blueGrey,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 6,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.blueGrey[400],
                        child: Text(
                          _profileInitial ?? 'U',
                          style: const TextStyle(
                            fontSize: 40,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildInput("Username", _usernameController, Icons.person),
                      const SizedBox(height: 15),
                      _buildInput("Nickname", _nicknameController, Icons.tag),
                      const SizedBox(height: 15),
                      _buildInput(
                        "Phone Number",
                        TextEditingController(text: _phoneNumber),
                        Icons.phone,
                        readOnly: true,
                      ),
                      const SizedBox(height: 15),
                      _buildDropdown("Gender", _genders, _selectedGender, (val) {
                        setState(() => _selectedGender = val!);
                      }),
                      const SizedBox(height: 15),
                      _buildInput("Age", _ageController, Icons.calendar_today,
                          keyboardType: TextInputType.number),
                      const SizedBox(height: 25),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueGrey,
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _saveProfile,
                        icon: const Icon(Icons.save),
                        label: const Text("Save", style: TextStyle(fontSize: 16)),
                      ),
                    ],
                  ),
                ),
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
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> options, String value, Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.transgender),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      items: options.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: onChanged,
    );
  }
}
