import 'package:flutter/material.dart';

class UserSelection extends StatelessWidget {
  const UserSelection({super.key});

  @override
  State<UserSelection> createState() => _UserSelectionState();
}

class _UserSelectionState extends State<UserSelection> {
  String? selectedRole;

  void _selectRole(String role) {
    setState(() {
      selectedRole = role;
    });
  }

  void _continue() {
    if (selectedRole == null) {
      toastification.show(
        context: context,
        title: const Text("Please select a role to continue"),
        type: ToastificationType.warning,
        style: ToastificationStyle.flat,
        alignment: Alignment.topCenter,
        autoCloseDuration: const Duration(seconds: 2),
      );
    } else {
      // Navigate based on selected role
      switch (selectedRole) {
        case 'personal':
          Navigator.pushReplacementNamed(context, '/personalauth');
          break;
        case 'professional':
          Navigator.pushReplacementNamed(context, '/professionalauth');
          break;
        case 'organization':
          Navigator.pushReplacementNamed(context, '/organizationalauth');
          break;
      }
    }
  }

  Widget buildRoleCard({
    required String title,
    required String subtitle,
    required String description,
    required String roleKey,
    required String imagePath,
    required double imageHeight,
    required double imageWidth,
    required double fontScale,
  }) {
    final isSelected = selectedRole == roleKey;

    return GestureDetector(
      onTap: () => _selectRole(roleKey),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? Colors.deepPurpleAccent : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color:
              isSelected ? Colors.deepPurple.withOpacity(0.05) : Colors.white,
        ),
        child: Row(
          children: [
            // Text section
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16 * fontScale,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14 * fontScale,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13 * fontScale,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // Image
            SvgPicture.asset(
              imagePath,
              height: imageHeight,
              width: imageWidth,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final fontScale = size.width / 375; // base width for scaling
    final isSmall = size.height < 600;

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/welcome');
          },
        ),
        title: const Text(""),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Choose your role to get started",
                style: TextStyle(
                  fontSize: 20 * fontScale,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "This helps us personalize your space and show you the right tools.",
                style: TextStyle(
                  fontSize: 14 * fontScale,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 20),

              // Role Cards
              buildRoleCard(
                title: "Personal User",
                subtitle: "I’m here for myself",
                description:
                    "To build healthier habits and access everyday support tools",
                roleKey: "personal",
                imagePath: "assets/illustrations/curiosity-pana 1.svg",
                imageHeight: size.width * 0.25,
                imageWidth: size.width * 0.25,
                fontScale: fontScale,
              ),
              buildRoleCard(
                title: "Professional User",
                subtitle: "I’m here as a Mental Health Professional",
                description:
                    "To offer support, manage clients, and grow my practice",
                roleKey: "professional",
                imagePath: "assets/illustrations/curiosity-pana 1.svg",
                imageHeight: size.width * 0.25,
                imageWidth: size.width * 0.25,
                fontScale: fontScale,
              ),
              buildRoleCard(
                title: "Organizational User",
                subtitle: "I’m here as part of my Organization",
                description:
                    "To access wellness tools provided by the workplace",
                roleKey: "organization",
                imagePath: "assets/illustrations/curiosity-pana 1.svg",
                imageHeight: size.width * 0.25,
                imageWidth: size.width * 0.25,
                fontScale: fontScale,
              ),

              const SizedBox(height: 30),

              // Continue Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _continue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurpleAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'Continue',
                    style: TextStyle(
                      fontSize: 16 * fontScale,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}