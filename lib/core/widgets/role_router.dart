import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mindsarthi/core/theme/app_theme.dart';
import 'package:mindsarthi/features/organizational_user/screens/org_nav.dart';
import 'package:mindsarthi/features/personal_user/screens/nav.dart';
import 'package:mindsarthi/features/professional_user/screens/professional_nav.dart';
import 'package:shimmer/shimmer.dart';

/// Routes the authenticated user to the correct Nav screen based on their
/// Firestore [userRole] field.
///
/// Supported roles:
///   - `personal`       → NavBar (personal user)
///   - `professional`   → NavBar (fallback until ProfessionalNavBar exists)
///   - `org`            → NavBar (fallback until OrgNavBar exists)
///   - missing / null   → NavBar (defaults to personal)
class RoleRouter extends StatefulWidget {
  const RoleRouter({super.key});

  @override
  State<RoleRouter> createState() => _RoleRouterState();
}

class _RoleRouterState extends State<RoleRouter> {
  String? _role;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchRole();
  }

  Future<void> _fetchRole() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        if (mounted) {
          setState(() {
            _role = 'personal';
            _loading = false;
          });
        }
        return;
      }

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (!mounted) return;

      final data = doc.data();
      final role = data?['userRole'] as String?;

      setState(() {
        _role = role ?? 'personal';
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _role = 'personal';
          _loading = false;
        });
      }
      debugPrint('RoleRouter: Failed to fetch user role — $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const _RoleLoadingScreen();

    // Route based on Firestore userRole
    switch (_role) {
      case 'professional':
        return const ProfessionalNav();
      case 'org':
        return const OrgNav();
      case 'personal':
      default:
        return const NavBar();
    }
  }
}

class _RoleLoadingScreen extends StatelessWidget {
  const _RoleLoadingScreen();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shimmerBase =
        isDark ? AppColors.darkShimmerBase : AppColors.shimmerBase;
    final shimmerHighlight =
        isDark ? AppColors.darkShimmerHighlight : AppColors.shimmerHighlight;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header shimmer
              Shimmer.fromColors(
                baseColor: shimmerBase,
                highlightColor: shimmerHighlight,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 120,
                      height: 16,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurface : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 200,
                      height: 28,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurface : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Hero card shimmer
              Shimmer.fromColors(
                baseColor: shimmerBase,
                highlightColor: shimmerHighlight,
                child: Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : Colors.white,
                    borderRadius: BorderRadius.circular(32),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Content shimmer rows
              Shimmer.fromColors(
                baseColor: shimmerBase,
                highlightColor: shimmerHighlight,
                child: Column(
                  children: List.generate(4, (i) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        width: double.infinity,
                        height: 80,
                        decoration: BoxDecoration(
                          color:
                              isDark ? AppColors.darkSurface : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
